#!/bin/bash
# isshine State — unified interface for .isshine.yaml state management
# Usage: isshine-state.sh <subcommand> <feature-slug> [args...]
#
# Subcommands:
#   init <slug> <workflow>            — Initialize .isshine.yaml with defaults
#   get <slug> <field>                — Read a field value from .isshine.yaml
#   set <slug> <field> <val>          — Update a field value
#   transition <slug> <event>         — Apply a validated state transition
#   check <slug> <phase>              — Verify entry requirements for a phase
#
# Workflows: full, quick
# Phases: init, define, design, issue, done
# Events: init-complete, define-complete, design-complete, issue-complete

set -euo pipefail

# --- Color output helpers ---

red() { echo -e "\033[31m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }

# --- Input validation ---

validate_slug() {
  local slug="$1"
  if [ -z "$slug" ]; then
    red "ERROR: Feature slug cannot be empty" >&2
    exit 1
  fi
  if [[ ! "$slug" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    red "ERROR: Invalid feature slug: '$slug'" >&2
    red "Valid characters: a-z, A-Z, 0-9, -, _" >&2
    exit 1
  fi
  if [[ "$slug" =~ \.\. ]]; then
    red "ERROR: Feature slug cannot contain '..' (path traversal not allowed)" >&2
    exit 1
  fi
}

validate_enum() {
  local value="$1"
  shift
  local valid_values=("$@")
  for valid in "${valid_values[@]}"; do
    if [ "$value" = "$valid" ]; then
      return 0
    fi
  done
  red "ERROR: Invalid value: '$value'" >&2
  red "Valid values: ${valid_values[*]}" >&2
  exit 1
}

# --- YAML helpers ---

strip_inline_comment() {
  # Remove inline comments from YAML values (preserving quoted strings)
  local val="$1"
  if [[ "$val" =~ ^\" ]] || [[ "$val" =~ ^\' ]]; then
    echo "$val"
    return
  fi
  echo "$val" | sed 's/ #.*//'
}

strip_wrapping_quotes() {
  local val="$1"
  val="${val#\"}"; val="${val%\"}"
  val="${val#\'}"; val="${val%\'}"
  echo "$val"
}

yaml_field() {
  local field="$1"
  local yaml_file="$2"
  if [ -f "$yaml_file" ]; then
    local value
    value=$(grep "^${field}:" "$yaml_file" 2>/dev/null | head -1 | sed "s/^${field}: *//" || true)
    value=$(strip_inline_comment "$value")
    strip_wrapping_quotes "$value"
  fi
}

# --- Path helper ---

feature_dir() {
  local slug="$1"
  echo "feature/${slug}"
}

state_file() {
  local slug="$1"
  echo "feature/${slug}/.isshine.yaml"
}

# --- Subcommand: init ---

cmd_init() {
  local slug="$1"
  local workflow="${2:-full}"

  validate_slug "$slug"
  validate_enum "$workflow" "full" "quick"

  local dir
  dir=$(feature_dir "$slug")
  mkdir -p "$dir"

  local state
  state=$(state_file "$slug")

  if [ -f "$state" ]; then
    yellow "WARNING: .isshine.yaml already exists for '$slug', overwriting"
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$state" << YAML
# isshine state — auto-generated, do not edit manually while a workflow is active
phase: init
workflow: ${workflow}
session_ref: null
issue_context_start_ref: "${now}"
issue_context_end_ref: null
proposal: proposal.md
harness: harness.md
design: design.md
tasks: tasks.md
technical_design: technical-design.md
risks: risks.md
issue_number: null
issue_url: null
created_at: "${now}"
updated_at: "${now}"
YAML

  green "Initialized ${workflow} workflow for '${slug}' at ${state}"
}

# --- Subcommand: get ---

cmd_get() {
  local slug="$1"
  local field="$2"

  validate_slug "$slug"

  local state
  state=$(state_file "$slug")

  if [ ! -f "$state" ]; then
    red "ERROR: .isshine.yaml not found for '${slug}'"
    red "Run 'isshine-state.sh init ${slug}' first"
    exit 1
  fi

  local value
  value=$(yaml_field "$field" "$state")
  echo "$value"
}

# --- Subcommand: set ---

cmd_set() {
  local slug="$1"
  local field="$2"
  local value="$3"

  validate_slug "$slug"

  local state
  state=$(state_file "$slug")

  if [ ! -f "$state" ]; then
    red "ERROR: .isshine.yaml not found for '${slug}'"
    red "Run 'isshine-state.sh init ${slug}' first"
    exit 1
  fi

  # Field whitelist
  local allowed_fields=("phase" "session_ref" "issue_context_start_ref" "issue_context_end_ref" "proposal" "harness" "design" "tasks" "technical_design" "risks" "issue_number" "issue_url")
  local found=false
  for allowed in "${allowed_fields[@]}"; do
    if [ "$field" = "$allowed" ]; then
      found=true
      break
    fi
  done
  if [ "$found" != "true" ]; then
    red "ERROR: Cannot set unknown field: '$field'"
    red "Allowed fields: ${allowed_fields[*]}"
    exit 1
  fi

  # Enum validation for phase
  if [ "$field" = "phase" ]; then
    validate_enum "$value" "init" "define" "design" "issue" "done"
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

  # Update field using awk (cross-platform, no sed -i)
  if grep -q "^${field}:" "$state" 2>/dev/null; then
    awk -v f="$field" -v v="$value" '
      $1 == f ":" { print f ": " v; next }
      { print }
    ' "$state" > "${state}.tmp" && mv "${state}.tmp" "$state"
  else
    red "ERROR: Field '${field}' not found in ${state}"
    exit 1
  fi

  # Update timestamp
  awk -v ts="$now" '
    $1 == "updated_at:" { print "updated_at: \"" ts "\""; next }
    { print }
  ' "$state" > "${state}.tmp" && mv "${state}.tmp" "$state"

  green "Set ${field}=${value} for '${slug}'"
}

# --- Subcommand: transition ---

cmd_transition() {
  local slug="$1"
  local event="$2"

  validate_slug "$slug"
  validate_enum "$event" "init-complete" "define-complete" "design-complete" "issue-complete"

  local state
  state=$(state_file "$slug")

  if [ ! -f "$state" ]; then
    red "ERROR: .isshine.yaml not found for '${slug}'"
    exit 1
  fi

  local current_phase
  current_phase=$(yaml_field "phase" "$state")

  # Transition map
  case "$event" in
    init-complete)
      if [ "$current_phase" != "init" ]; then
        red "ERROR: Cannot apply init-complete: current phase is '$current_phase' (expected 'init')"
        exit 1
      fi
      cmd_set "$slug" "phase" "define"
      ;;
    define-complete)
      if [ "$current_phase" != "define" ]; then
        red "ERROR: Cannot apply define-complete: current phase is '$current_phase' (expected 'define')"
        exit 1
      fi
      local workflow
      workflow=$(yaml_field "workflow" "$state")
      if [ "$workflow" = "quick" ]; then
        cmd_set "$slug" "phase" "issue"
      else
        cmd_set "$slug" "phase" "design"
      fi
      ;;
    design-complete)
      if [ "$current_phase" != "design" ]; then
        red "ERROR: Cannot apply design-complete: current phase is '$current_phase' (expected 'design')"
        exit 1
      fi
      cmd_set "$slug" "phase" "issue"
      ;;
    issue-complete)
      if [ "$current_phase" != "issue" ]; then
        red "ERROR: Cannot apply issue-complete: current phase is '$current_phase' (expected 'issue')"
        exit 1
      fi
      cmd_set "$slug" "phase" "done"
      ;;
  esac

  green "Transitioned '${slug}': ${current_phase} → $(yaml_field "phase" "$state")"
}

# --- Subcommand: check ---

cmd_check() {
  local slug="$1"
  local phase="$2"

  validate_slug "$slug"
  validate_enum "$phase" "init" "define" "design" "issue" "done"

  local state
  state=$(state_file "$slug")

  if [ ! -f "$state" ]; then
    red "CHECK FAILED: .isshine.yaml not found for '${slug}'"
    exit 1
  fi

  local current_phase
  current_phase=$(yaml_field "phase" "$state")

  if [ "$current_phase" != "$phase" ]; then
    red "CHECK FAILED: Expected phase '${phase}', but current phase is '${current_phase}'"
    exit 1
  fi

  local dir
  dir=$(feature_dir "$slug")

  case "$phase" in
    design)
      # Verify definition artifacts exist before deep design.
      for artifact in "proposal.md" "harness.md" "design.md" "tasks.md"; do
        if [ ! -f "${dir}/${artifact}" ] || [ ! -s "${dir}/${artifact}" ]; then
          red "CHECK FAILED: ${artifact} is missing or empty in ${dir}"
          exit 1
        fi
      done
      ;;
    issue)
      local workflow
      workflow=$(yaml_field "workflow" "$state")

      local artifacts
      if [ "$workflow" = "quick" ]; then
        artifacts="proposal.md design.md tasks.md"
      else
        artifacts="proposal.md harness.md design.md tasks.md technical-design.md risks.md"
      fi

      # Verify all workflow-required artifacts exist
      for artifact in $artifacts; do
        if [ ! -f "${dir}/${artifact}" ] || [ ! -s "${dir}/${artifact}" ]; then
          red "CHECK FAILED: ${artifact} is missing or empty in ${dir}"
          exit 1
        fi
      done
      ;;
  esac

  green "CHECK PASSED: '${slug}' is in phase '${phase}'"
}

# --- Main dispatch ---

main() {
  if [ $# -lt 2 ]; then
    echo "Usage: isshine-state.sh <subcommand> <feature-slug> [args...]"
    echo ""
    echo "Subcommands:"
    echo "  init <slug> <workflow>       Initialize .isshine.yaml (workflow: full|quick)"
    echo "  get <slug> <field>           Read a field value"
    echo "  set <slug> <field> <val>     Update a field value"
    echo "  transition <slug> <event>    Apply a state transition"
    echo "  check <slug> <phase>         Verify entry requirements"
    echo ""
    echo "Events: init-complete, define-complete, design-complete, issue-complete"
    echo "Phases: init, define, design, issue, done"
    exit 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    init)       cmd_init "$@" ;;
    get)        cmd_get "$@" ;;
    set)        cmd_set "$@" ;;
    transition) cmd_transition "$@" ;;
    check)      cmd_check "$@" ;;
    *)
      red "ERROR: Unknown subcommand: '$subcommand'"
      exit 1
      ;;
  esac
}

main "$@"
