#!/usr/bin/env bash
set -e

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

    TOTAL_FAILED=$(wc -l < mainsummary.log)
    if [ "$TOTAL_FAILED" -le "$MAX_FAILED_LINES" ]; then
        FAILED_LIST=$(cat mainsummary.log)
    else
        FAILED_LIST=$(head -n $MAX_FAILED_LINES mainsummary.log)
        REMAINING=$((TOTAL_FAILED - MAX_FAILED_LINES))
        FAILED_LIST="$FAILED_LIST"$'\n'"... +$REMAINING more failed tests"
    fi
    FAILED_LIST="\`\`\`
$FAILED_LIST
\`\`\`"
fi


if [[ "$OPEN_FAILED" -eq 0 && "$OPEN_CRASHES" -eq 0 ]]; then
    OPEN_STATUS="✅ No open issues unresolved!"
    OPEN_FAILED_LIST="No runtime or compile-time errors found :partying_face:"
else
    OPEN_STATUS="⚠️ Some open issue tests remain unfixed"

    TOTAL_FAILED=$(wc -l < opensummary.log)
    if [ "$TOTAL_FAILED" -le "$MAX_FAILED_LINES" ]; then
        OPEN_FAILED_LIST=$(cat opensummary.log)
    else
        OPEN_FAILED_LIST=$(head -n $MAX_FAILED_LINES opensummary.log)
        REMAINING=$((TOTAL_FAILED - MAX_FAILED_LINES))
        OPEN_FAILED_LIST="$FAILED_LIST"$'\n'"... +$REMAINING more failed tests"
    fi
    OPEN_FAILED_LIST="\`\`\`
$OPEN_FAILED_LIST
\`\`\`"
fi

# Build description with literal newlines
DESCRIPTION="## $STATUS
### Passed: $PASSED, Failed: $FAILED, Crashes: $CRASHES
$FAILED_LIST
## $OPEN_STATUS
### Passed: $OPEN_PASSED, Failed: $OPEN_FAILED, Crashes: $OPEN_CRASHES
$OPEN_FAILED_LIST"

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
