#!/bin/bash
# PostToolUse hook: validate file writes
# Exit 0 = pass, Exit 2 = block with message

FILE_PATH="$1"
PROJECT_ROOT="/home/mi/disk/me/kkk/my-app1"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- P1: Directory whitelist ---
ALLOWED_DIRS=(
  "$PROJECT_ROOT/src"
  "$PROJECT_ROOT/pages"
  "$PROJECT_ROOT/.ai-workspace"
  "$PROJECT_ROOT/.claude"
  "$PROJECT_ROOT/.github"
  "$PROJECT_ROOT/common"
)

in_allowed=false
for dir in "${ALLOWED_DIRS[@]}"; do
  if [[ "$FILE_PATH" == "$dir"* ]]; then
    in_allowed=true
    break
  fi
done

# Also allow project root config files
if [[ "$FILE_PATH" == "$PROJECT_ROOT/manifest.json" ]] || \
   [[ "$FILE_PATH" == "$PROJECT_ROOT/package.json" ]] || \
   [[ "$FILE_PATH" == "$PROJECT_ROOT/app.ux" ]] || \
   [[ "$FILE_PATH" == "$PROJECT_ROOT/.nvmrc" ]]; then
  in_allowed=true
fi

if [ "$in_allowed" = false ]; then
  echo "❌ BLOCKED: Write to '$FILE_PATH' is outside allowed directories."
  echo "   Allowed: src/, pages/, common/, .ai-workspace/, .claude/, .github/, and root config files."
  exit 2
fi

# --- P0: Forbidden content checks for .ux files ---
if [[ "$FILE_PATH" == *.ux ]]; then
  # Check for banned components
  if grep -qE '<icon_font|<icon-font' "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: File contains <icon_font> component (forbidden)."
    echo "   Use <image> + PNG instead."
    exit 2
  fi

  # Check for third-party imports
  if grep -qE "from ['\"](vue|react|angular|axios|lodash|moment|echarts|antd|element-ui|vant)" "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: File imports a forbidden third-party library."
    echo "   Only @system.* and @app.* imports allowed."
    exit 2
  fi
fi

# --- P0: Forbidden dependencies in package.json ---
if [[ "$FILE_PATH" == *"package.json" ]]; then
  BANNED_DEPS="axios|lodash|moment|echarts|vue|react|angular|antd|element-ui|vant|hap-toolkit"
  if grep -qE "\"($BANNED_DEPS)\"" "$FILE_PATH" 2>/dev/null; then
    echo "❌ BLOCKED: package.json contains a forbidden dependency."
    echo "   Banned: axios, lodash, moment, echarts, vue, react, angular, antd, element-ui, vant, hap-toolkit"
    exit 2
  fi
fi

exit 0
