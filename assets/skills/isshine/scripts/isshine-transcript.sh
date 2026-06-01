#!/bin/bash
# isshine Transcript — locate and extract user inputs from conversation
# Usage: isshine-transcript.sh <subcommand> [args...]
#
# Subcommands:
#   locate <session_ref>              — Find the transcript file for a session
#   extract <transcript_path>         — Extract user inputs from transcript
#   extract-window <path> <start> <end> [format]
#                                      — Extract user inputs between checkpoint refs
#   classify <transcript_path>        — Classify inputs as "directional" vs "general"
#   classify-window <path> <start> <end>
#                                      — Classify user inputs between checkpoint refs
#
# The transcript is Claude Code's conversation history.
# session_ref from .isshine.yaml can be:
#   - A session ID: "session_abc123"
#   - A timestamp range: "2026-06-01T10:00:00Z..2026-06-01T11:00:00Z"
#   - A message index range: "msg:5..msg:12"
#
# Checkpoint refs accepted by extract-window/classify-window:
#   - ISO timestamp: "2026-06-01T10:00:00Z"
#   - Message index: "msg:5" (1-based index of non-empty transcript lines)

set -euo pipefail

# --- Color helpers ---
red() { echo -e "\033[31m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }

# --- JSONL helpers ---

json_field() {
  local line="$1"
  local field="$2"
  echo "$line" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || true
}

json_content() {
  local line="$1"
  echo "$line" | sed 's/.*"content"[[:space:]]*:[[:space:]]*"//' | sed 's/"[[:space:]]*}$//' || echo "$line"
}

ref_kind() {
  local ref="$1"
  if [[ "$ref" =~ ^msg:[0-9]+$ ]]; then
    echo "msg"
  elif [ -n "$ref" ] && [ "$ref" != "null" ]; then
    echo "time"
  else
    echo "empty"
  fi
}

ref_msg_index() {
  local ref="$1"
  echo "${ref#msg:}"
}

line_in_window() {
  local line="$1"
  local line_index="$2"
  local start_ref="$3"
  local end_ref="$4"

  local start_kind
  local end_kind
  start_kind=$(ref_kind "$start_ref")
  end_kind=$(ref_kind "$end_ref")

  if [ "$start_kind" = "msg" ]; then
    local start_index
    start_index=$(ref_msg_index "$start_ref")
    if [ "$line_index" -lt "$start_index" ]; then
      return 1
    fi
  elif [ "$start_kind" = "time" ]; then
    local timestamp
    timestamp=$(json_field "$line" "timestamp")
    if [ -z "$timestamp" ] || [[ "$timestamp" < "$start_ref" ]]; then
      return 1
    fi
  fi

  if [ "$end_kind" = "msg" ]; then
    local end_index
    end_index=$(ref_msg_index "$end_ref")
    if [ "$line_index" -gt "$end_index" ]; then
      return 1
    fi
  elif [ "$end_kind" = "time" ]; then
    local timestamp
    timestamp=$(json_field "$line" "timestamp")
    if [ -z "$timestamp" ] || [[ "$timestamp" > "$end_ref" ]]; then
      return 1
    fi
  fi

  return 0
}

# --- Locate transcript ---

cmd_locate() {
  local session_ref="$1"

  if [ -z "$session_ref" ] || [ "$session_ref" = "null" ]; then
    red "ERROR: session_ref is empty or null"
    exit 1
  fi

  # Claude Code stores history in ~/.claude/history.jsonl
  local history_file="${HOME}/.claude/history.jsonl"

  if [ -f "$history_file" ]; then
    echo "$history_file"
    return
  fi

  # Fallback: check project-local transcript directory
  local project_transcript="${HOME}/.claude/projects/$(basename "$(pwd)")/transcript.jsonl"
  if [ -f "$project_transcript" ]; then
    echo "$project_transcript"
    return
  fi

  red "ERROR: Could not locate transcript for session_ref: ${session_ref}"
  red "Checked: ${history_file}, ${project_transcript}"
  exit 1
}

# --- Extract user inputs from transcript ---

cmd_extract() {
  local transcript_path="$1"
  local output_format="${2:-markdown}"  # markdown | json

  if [ ! -f "$transcript_path" ]; then
    red "ERROR: Transcript file not found: ${transcript_path}"
    exit 1
  fi

  # Claude Code history.jsonl format: one JSON object per line
  # Each line has: { "role": "user"|"assistant", "content": "...", "timestamp": "..." }
  #
  # We extract all messages where role=user

  if [ "$output_format" = "json" ]; then
    echo "["
    local first=true
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      local role
      role=$(json_field "$line" "role")
      if [ "$role" = "user" ]; then
        if [ "$first" != "true" ]; then
          echo ","
        fi
        first=false
        echo "$line"
      fi
    done < "$transcript_path"
    echo "]"
  else
    # Markdown output: each user input as a block with timestamp
    local index=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      local role
      role=$(json_field "$line" "role")
      if [ "$role" = "user" ]; then
        index=$((index + 1))
        local timestamp
        timestamp=$(json_field "$line" "timestamp")
        timestamp="${timestamp:-unknown}"
        local content
        content=$(json_content "$line")

        echo "### User Input #${index}"
        echo ""
        echo "> **Time**: ${timestamp}"
        echo ""
        echo "\`\`\`"
        echo "$content"
        echo "\`\`\`"
        echo ""
        echo "---"
        echo ""
      fi
    done < "$transcript_path"
  fi
}

# --- Extract user inputs within a checkpoint window ---

cmd_extract_window() {
  local transcript_path="$1"
  local start_ref="${2:-null}"
  local end_ref="${3:-null}"
  local output_format="${4:-markdown}"  # markdown | json

  if [ ! -f "$transcript_path" ]; then
    red "ERROR: Transcript file not found: ${transcript_path}"
    exit 1
  fi

  if [ -z "$start_ref" ] || [ "$start_ref" = "null" ] || [ -z "$end_ref" ] || [ "$end_ref" = "null" ]; then
    yellow "WARNING: checkpoint window incomplete; falling back to full transcript extraction"
    cmd_extract "$transcript_path" "$output_format"
    return
  fi

  if [ "$output_format" = "json" ]; then
    echo "["
    local first=true
    local line_index=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      line_index=$((line_index + 1))
      if ! line_in_window "$line" "$line_index" "$start_ref" "$end_ref"; then
        continue
      fi

      local role
      role=$(json_field "$line" "role")
      if [ "$role" = "user" ]; then
        if [ "$first" != "true" ]; then
          echo ","
        fi
        first=false
        echo "$line"
      fi
    done < "$transcript_path"
    echo "]"
  else
    local index=0
    local line_index=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      line_index=$((line_index + 1))
      if ! line_in_window "$line" "$line_index" "$start_ref" "$end_ref"; then
        continue
      fi

      local role
      role=$(json_field "$line" "role")
      if [ "$role" = "user" ]; then
        index=$((index + 1))
        local timestamp
        timestamp=$(json_field "$line" "timestamp")
        timestamp="${timestamp:-unknown}"
        local content
        content=$(json_content "$line")

        echo "### Human Input Candidate #${index}"
        echo ""
        echo "> **Time**: ${timestamp}"
        echo ""
        echo "\`\`\`"
        echo "$content"
        echo "\`\`\`"
        echo ""
        echo "---"
        echo ""
      fi
    done < "$transcript_path"
  fi
}

# --- Classify inputs as "directional" vs "general" ---

cmd_classify() {
  local transcript_path="$1"

  if [ ! -f "$transcript_path" ]; then
    red "ERROR: Transcript file not found: ${transcript_path}"
    exit 1
  fi

  echo "=== Directional Input Classification ==="
  echo ""
  echo "Directional inputs are user messages that:"
  echo "  1. Contain explicit decisions or constraints"
  echo "  2. Define scope boundaries"
  echo "  3. Specify acceptance criteria"
  echo "  4. Reference anti-goals or principles"
  echo "  5. Are longer than 50 words (likely well-thought-out)"
  echo ""

  local index=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local role
    role=$(json_field "$line" "role")
    if [ "$role" != "user" ]; then
      continue
    fi

    index=$((index + 1))
    local content
    content=$(json_content "$line")

    # Heuristic scoring for "directional" quality
    local score=0
    local reasons=""

    # Word count (rough)
    local word_count
    word_count=$(echo "$content" | wc -w 2>/dev/null || echo "0")

    if [ "$word_count" -gt 50 ]; then
      score=$((score + 2))
      reasons="${reasons}long-form, "
    fi

    # Contains decision markers
    if echo "$content" | grep -qiE "(必须|一定|不能|禁止|应该|选择|决定|采用|方案|边界|范围)" 2>/dev/null; then
      score=$((score + 3))
      reasons="${reasons}decision-language(zh), "
    fi

    if echo "$content" | grep -qiE "(must|must not|should|shall|decide|choose|approach|boundary|scope|never)" 2>/dev/null; then
      score=$((score + 3))
      reasons="${reasons}decision-language(en), "
    fi

    # Contains acceptance criteria markers
    if echo "$content" | grep -qiE "(验收|检查|验证|确认|✓|✅|- \[ \]|- \[x\])" 2>/dev/null; then
      score=$((score + 2))
      reasons="${reasons}acceptance-criteria, "
    fi

    # References to spec files or principles
    if echo "$content" | grep -qiE "(philosophy|anti-goal|principle|原则|反目标|设计系统)" 2>/dev/null; then
      score=$((score + 2))
      reasons="${reasons}principle-reference, "
    fi

    # Classification
    local classification
    if [ "$score" -ge 5 ]; then
      classification="🎯 DIRECTIONAL"
    elif [ "$score" -ge 2 ]; then
      classification="🔍 POTENTIALLY_DIRECTIONAL"
    else
      classification="💬 GENERAL"
    fi

    echo "[#${index}] ${classification} (score: ${score})"
    echo "    Reasons: ${reasons}none"
    echo "    Preview: $(echo "$content" | head -c 120)..."
    echo ""
  done < "$transcript_path"
}

# --- Classify inputs within a checkpoint window ---

cmd_classify_window() {
  local transcript_path="$1"
  local start_ref="${2:-null}"
  local end_ref="${3:-null}"

  if [ ! -f "$transcript_path" ]; then
    red "ERROR: Transcript file not found: ${transcript_path}"
    exit 1
  fi

  if [ -z "$start_ref" ] || [ "$start_ref" = "null" ] || [ -z "$end_ref" ] || [ "$end_ref" = "null" ]; then
    yellow "WARNING: checkpoint window incomplete; falling back to full transcript classification"
    cmd_classify "$transcript_path"
    return
  fi

  echo "=== Directional Input Classification (checkpoint window) ==="
  echo "Window: ${start_ref} .. ${end_ref}"
  echo ""

  local tmp
  tmp=$(mktemp 2>/dev/null || mktemp -t isshine-transcript)
  local line_index=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    line_index=$((line_index + 1))
    if line_in_window "$line" "$line_index" "$start_ref" "$end_ref"; then
      echo "$line" >> "$tmp"
    fi
  done < "$transcript_path"

  cmd_classify "$tmp"
  rm -f "$tmp"
}

# --- Main dispatch ---

main() {
  if [ $# -lt 1 ]; then
    echo "Usage: isshine-transcript.sh <subcommand> [args...]"
    echo ""
    echo "Subcommands:"
    echo "  locate <session_ref>           Find transcript file for a session"
    echo "  extract <path> [markdown|json]  Extract user inputs"
    echo "  extract-window <path> <start> <end> [markdown|json]"
    echo "                                  Extract user inputs within checkpoint refs"
    echo "  classify <path>                 Classify inputs as directional vs general"
    echo "  classify-window <path> <start> <end>"
    echo "                                  Classify inputs within checkpoint refs"
    echo ""
    echo "The session_ref from .isshine.yaml points to the conversation window."
    echo "This script locates the transcript and extracts user inputs from it."
    exit 1
  fi

  local subcommand="$1"
  shift

  case "$subcommand" in
    locate)    cmd_locate "$@" ;;
    extract)   cmd_extract "$@" ;;
    extract-window) cmd_extract_window "$@" ;;
    classify)  cmd_classify "$@" ;;
    classify-window) cmd_classify_window "$@" ;;
    *)
      red "ERROR: Unknown subcommand: '$subcommand'"
      exit 1
      ;;
  esac
}

main "$@"
