#!/bin/bash
# PreToolUse hook: block dangerous shell commands
# Exit 0 = allow, Exit 2 = block with message

CMD="$1"

if [ -z "$CMD" ]; then
  exit 0
fi

# --- Block destructive file operations ---
if echo "$CMD" | grep -qE "rm\s+(-rf|-r)\s+(/|~|\.\./|node_modules)"; then
  echo "❌ BLOCKED: Destructive rm command detected."
  echo "   Command: $CMD"
  exit 2
fi

# --- Block unauthorized package installs ---
if echo "$CMD" | grep -qE "npm\s+(install|i|add|uninstall|remove)\s"; then
  echo "❌ BLOCKED: Package modification requires user confirmation."
  echo "   Command: $CMD"
  echo "   Please ask the user before modifying dependencies."
  exit 2
fi

# --- Block network downloads without approval ---
if echo "$CMD" | grep -qE "^(curl|wget|fetch)\s"; then
  echo "❌ BLOCKED: Network download commands require user approval."
  echo "   Command: $CMD"
  exit 2
fi

# --- Block git push (must be explicit user request) ---
if echo "$CMD" | grep -qE "git\s+push"; then
  echo "❌ BLOCKED: git push requires explicit user request."
  echo "   Command: $CMD"
  exit 2
fi

# --- Block writes outside project ---
if echo "$CMD" | grep -qE ">\s*(/etc/|/usr/|/home/mi/(?!disk/me/kkk/my-app1))"; then
  echo "❌ BLOCKED: Write to system/external path detected."
  echo "   Command: $CMD"
  exit 2
fi

# --- P1: Retry guard (detect potential infinite loops) ---
RETRY_LOG="/tmp/claude-retry-$(echo "$CMD" | md5sum | cut -d' ' -f1)"
if [ -f "$RETRY_LOG" ]; then
  COUNT=$(cat "$RETRY_LOG")
  if [ "$COUNT" -ge 3 ]; then
    echo "❌ BLOCKED: Command has been retried 3+ times — likely in a loop."
    echo "   Command: $CMD"
    echo "   Please try a different approach or ask the user for help."
    rm -f "$RETRY_LOG"
    exit 2
  fi
  echo $((COUNT + 1)) > "$RETRY_LOG"
else
  echo "1" > "$RETRY_LOG"
fi

exit 0
