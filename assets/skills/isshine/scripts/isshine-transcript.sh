#!/bin/bash
# isshine Transcript — locate and extract user inputs from conversation
# Usage: isshine-transcript.sh <subcommand> [args...]
#
# Subcommands:
#   locate <session_ref>              — Find the transcript file for a session
#   extract <transcript_path>         — Extract user inputs from transcript
#   classify <transcript_path>        — Classify inputs as "directional" vs "general"
#
# The transcript is Claude Code's conversation history.
# session_ref from .isshine.yaml can be:
#   - A session ID: "session_abc123"
#   - A timestamp range: "2026-06-01T10:00:00Z..2026-06-01T11:00:00Z"
#   - A message index range: "msg:5..msg:12"

set -euo pipefail

# --- Color helpers ---
red() { echo -e "\033[31m$1\033[0m" >&2; }
yellow() { echo -e "\033[33m$1\033[0m" >&2; }
green() { echo -e "\033[32m$1\033[0m" >&2; }

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
      role=$(echo "$line" | grep -o '"role"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || true)
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
      role=$(echo "$line" | grep -o '"role"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || true)
      if [ "$role" = "user" ]; then
        index=$((index + 1))
        local timestamp
        timestamp=$(echo "$line" | grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "unknown")
        local content
        content=$(echo "$line" | sed 's/.*"content"[[:space:]]*:[[:space:]]*"//' | sed 's/"[[:space:]]*}$//' || echo "$line")

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
    role=$(echo "$line" | grep -o '"role"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || true)
    if [ "$role" != "user" ]; then
      continue
    fi

    index=$((index + 1))
    local content
    content=$(echo "$line" | sed 's/.*"content"[[:space:]]*:[[:space:]]*"//' | sed 's/"[[:space:]]*}$//' || echo "$line")

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

# --- Main dispatch ---

main() {
  if [ $# -lt 1 ]; then
    echo "Usage: isshine-transcript.sh <subcommand> [args...]"
    echo ""
    echo "Subcommands:"
    echo "  locate <session_ref>           Find transcript file for a session"
    echo "  extract <path> [markdown|json]  Extract user inputs"
    echo "  classify <path>                 Classify inputs as directional vs general"
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
    classify)  cmd_classify "$@" ;;
    *)
      red "ERROR: Unknown subcommand: '$subcommand'"
      exit 1
      ;;
  esac
}

main "$@"
