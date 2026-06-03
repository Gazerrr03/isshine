#!/bin/bash
# isshine Check — completeness validator
# Usage: isshine-check.sh <feature-slug> [--json]
#
# Reads template Spec definitions and validates that required sections
# in the feature's artifacts are present and non-empty (not just placeholders).
#
# Spec format in templates:
#   > **Spec**:
#   > - `## Section Name` — must be non-empty, [constraint]
#
# Exit codes:
#   0 — all checks pass
#   1 — completeness check failed (missing or empty sections)
#   2 — runtime error (file not found, etc.)

set -euo pipefail

# --- Color helpers ---
red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }

# --- Extract Spec requirements from a template file ---
# Returns lines in format: "section_name|constraint"
extract_spec() {
  local template_file="$1"
  if [ ! -f "$template_file" ]; then
    return
  fi

  # Parse the Spec block: lines between "> **Spec**:" and the next non-> line
  # Spec entries look like: > - `## Section Name` — must be non-empty
  awk '
    /^> \*\*Spec\*\*:/ { in_spec=1; next }
    in_spec && /^> - `## / {
      # Extract section name and constraint
      line = $0
      # Remove leading "> - `"
      sub(/^> - `/, "", line)
      # Extract section name (between ## and backtick)
      idx = index(line, "`")
      if (idx > 0) {
        section = substr(line, 1, idx - 1)
        # Remove "## " prefix
        sub(/^## /, "", section)
        constraint = substr(line, idx + 1)
        # Remove " — " prefix from constraint
        sub(/^ — /, "", constraint)
        print section "|" constraint
      }
    }
    in_spec && /^[^>]/ { in_spec=0 }
  ' "$template_file"
}

# --- Check if a section exists and is non-empty in a markdown file ---
check_section() {
  local md_file="$1"
  local section_name="$2"

  if [ ! -f "$md_file" ]; then
    echo "MISSING_FILE"
    return
  fi

  # Check if the ## Section exists and has content after it
  # We look for the section header, then check if the next non-empty line
  # before the next ## header exists
  local has_content
  has_content=$(awk -v sec="## ${section_name}" '
    $0 ~ "^" sec "[[:space:]]*$" { found=1; next }
    found && /^## / { exit }
    found && /^[[:space:]]*$/ { next }
    found && /./ {
      # Check it is not a placeholder
      if ($0 !~ /^\[.*\]$/) { print "HAS_CONTENT"; exit }
      if ($0 ~ /^\[\.\.\.\]$/) { print "PLACEHOLDER"; exit }
      print "HAS_CONTENT"; exit
    }
    END { if (found) print "EMPTY" }
  ' "$md_file" || true)

  case "$has_content" in
    HAS_CONTENT) echo "OK" ;;
    PLACEHOLDER) echo "PLACEHOLDER" ;;
    EMPTY) echo "EMPTY" ;;
    *) echo "NOT_FOUND" ;;
  esac
}

# --- Main check logic ---

cmd_check() {
  local slug="$1"
  local json_output="${2:-false}"

  local feature_dir="feature/${slug}"
  local templates_dir="assets/templates"

  if [ ! -d "$feature_dir" ]; then
    red "ERROR: Feature directory not found: ${feature_dir}"
    exit 2
  fi

  local total_checks=0
  local passed_checks=0
  local failed_checks=0
  local issues=""

  # Map of feature artifact → template file
  local artifacts=(
    "proposal.md:${templates_dir}/feature/proposal.md"
    "harness.md:${templates_dir}/feature/harness.md"
    "design.md:${templates_dir}/feature/design.md"
    "tasks.md:${templates_dir}/feature/tasks.md"
    "technical-design.md:${templates_dir}/feature/technical-design.md"
    "risks.md:${templates_dir}/feature/risks.md"
  )

  echo "=== Completeness Check: ${slug} ==="
  echo ""

  for mapping in "${artifacts[@]}"; do
    local artifact="${mapping%%:*}"
    local template="${mapping##*:}"
    local artifact_path="${feature_dir}/${artifact}"

    echo "--- ${artifact} ---"

    if [ ! -f "$artifact_path" ]; then
      yellow "  SKIP: file not found"
      echo ""
      continue
    fi

    # Extract spec requirements from template
    local specs
    specs=$(extract_spec "$template")

    if [ -z "$specs" ]; then
      yellow "  SKIP: no Spec defined in template"
      echo ""
      continue
    fi

    # Check each required section
    while IFS='|' read -r section constraint; do
      [ -z "$section" ] && continue
      total_checks=$((total_checks + 1))

      local result
      result=$(check_section "$artifact_path" "$section")

      case "$result" in
        OK)
          passed_checks=$((passed_checks + 1))
          green "  ✓ ${section}"
          ;;
        PLACEHOLDER)
          failed_checks=$((failed_checks + 1))
          red "  ✗ ${section} — PLACEHOLDER (content is still a placeholder: [...])"
          issues="${issues}${artifact}:${section}=PLACEHOLDER\n"
          ;;
        EMPTY)
          failed_checks=$((failed_checks + 1))
          red "  ✗ ${section} — EMPTY (section exists but has no content)"
          issues="${issues}${artifact}:${section}=EMPTY\n"
          ;;
        NOT_FOUND)
          failed_checks=$((failed_checks + 1))
          red "  ✗ ${section} — NOT FOUND (section header missing)"
          issues="${issues}${artifact}:${section}=NOT_FOUND\n"
          ;;
        MISSING_FILE)
          failed_checks=$((failed_checks + 1))
          red "  ✗ ${section} — FILE MISSING"
          issues="${issues}${artifact}:${section}=MISSING_FILE\n"
          ;;
      esac
    done <<< "$specs"
    echo ""
  done

  # --- Summary ---
  echo "=== Summary ==="
  echo "Total: ${total_checks} | Passed: ${passed_checks} | Failed: ${failed_checks}"

  if [ "$failed_checks" -gt 0 ]; then
    echo ""
    red "COMPLETENESS CHECK FAILED"
    echo ""
    echo "Issues:"
    echo -e "$issues"

    if [ "$json_output" = "--json" ]; then
      echo ""
      echo "{ \"status\": \"failed\", \"total\": ${total_checks}, \"passed\": ${passed_checks}, \"failed\": ${failed_checks} }"
    fi
    exit 1
  else
    echo ""
    green "COMPLETENESS CHECK PASSED"

    if [ "$json_output" = "--json" ]; then
      echo "{ \"status\": \"passed\", \"total\": ${total_checks}, \"passed\": ${passed_checks}, \"failed\": 0 }"
    fi
  fi
}

# --- Main dispatch ---

main() {
  if [ $# -lt 1 ]; then
    echo "Usage: isshine-check.sh <feature-slug> [--json]"
    echo ""
    echo "Validates that all Spec-defined sections in feature artifacts"
    echo "are present and contain non-placeholder content."
    exit 1
  fi

  local slug="$1"
  local json="${2:-false}"

  cmd_check "$slug" "$json"
}

main "$@"
