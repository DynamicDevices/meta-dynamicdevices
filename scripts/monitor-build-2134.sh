#!/bin/bash
# Build 2134 Monitoring Script - Eink Power CLI Recipe Fix Test

echo "🔍 Monitoring Build 2134 - Testing eink-power-cli recipe fix"
echo "============================================================"
echo ""

while true; do
    echo "$(date): Checking Build 2134 status..."
    
    # Get build status
    STATUS=$(cd /home/ajlennon/data_drive/dd/meta-dynamicdevices && ./scripts/fio-api.sh builds list | grep "2134" | head -1)
    
    if echo "$STATUS" | grep -q "RUNNING"; then
        echo "🔄 Build 2134 is RUNNING"
        echo "Getting recent logs..."
        cd /home/ajlennon/data_drive/dd/meta-dynamicdevices && ./scripts/fio-api.sh builds logs 2134 imx93-jaguar-eink 10
        echo ""
    elif echo "$STATUS" | grep -q "QUEUED"; then
        echo "⏳ Build 2134 is still QUEUED (waiting for Build 2133 to complete)"
    elif echo "$STATUS" | grep -q "PASSED"; then
        echo "✅ Build 2134 PASSED! Recipe fix successful!"
        echo "🎉 eink-power-cli dependency issue resolved"
        break
    elif echo "$STATUS" | grep -q "FAILED"; then
        echo "❌ Build 2134 FAILED - investigating..."
        cd /home/ajlennon/data_drive/dd/meta-dynamicdevices && ./scripts/fio-api.sh builds search 2134 "ERROR.*dependency"
        break
    else
        echo "⚠️  Unknown status: $STATUS"
    fi
    
    echo "Checking again in 60 seconds..."
    echo ""
    sleep 60
done

echo ""
echo "Build 2134 monitoring complete."
