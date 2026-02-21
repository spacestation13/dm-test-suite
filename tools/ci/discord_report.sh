#!/usr/bin/env bash
set -e

# Environment variables expected:
# DISCORD_WEBHOOK_URL, PASSED, FAILED, CRASHES

source buildByond.conf

MAX_FAILED_LINES=10

# Determine color and status
if [[ "$FAILED" -eq 0 && "$CRASHES" -eq 0 ]]; then
    COLOR=3066993
    STATUS="✅ All tests passed"
    FAILED_LIST="No runtime or compile-time errors found :partying_face:"
else
    COLOR=15158332
    STATUS="❌ Some tests failed or crashed"

    TOTAL_FAILED=$(wc -l < summary.log)
    if [ "$TOTAL_FAILED" -le "$MAX_FAILED_LINES" ]; then
        FAILED_LIST=$(cat summary.log)
    else
        FAILED_LIST=$(head -n $MAX_FAILED_LINES summary.log)
        REMAINING=$((TOTAL_FAILED - MAX_FAILED_LINES))
        FAILED_LIST="$FAILED_LIST"$'\n'"... +$REMAINING more failed tests"
    fi
    FAILED_LIST="\`\`\`
$FAILED_LIST
\`\`\`"
fi

# Build description with literal newlines
DESCRIPTION="## $STATUS
### Passed: $PASSED, Failed: $FAILED, Crashes: $CRASHES
$FAILED_LIST"

# Send embed to Discord, preserving newlines
message=`echo "$DESCRIPTION" | jq -Rs --arg title "${BYOND_MAJOR_VERSION}.${BYOND_MINOR_VERSION} Unit Test Results" \
  --arg url "$ACTION_URL" \
  --argjson color "$COLOR" \
  '{embeds: [{title: $title, description: ., url: $url, color: $color}]}'`
  
echo $message | curl -H "Content-Type: application/json" \
         -X POST \
         -d @- \
         "$DISCORD_WEBHOOK_URL"

echo $message | curl -H "Content-Type: application/json" \
         -X POST \
         -d @- \
         "$BYONDCORD_WEBHOOK_URL"
