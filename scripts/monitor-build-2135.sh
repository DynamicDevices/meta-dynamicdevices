#!/bin/bash
# Monitor Build 2135 for the imx93-jaguar-eink machine

BUILD_ID="2135"
FACTORY="dynamic-devices"
MACHINE="imx93-jaguar-eink"
INTERVAL=60 # seconds

# Source the fio-api.sh script for API functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FIO_API_SCRIPT="${SCRIPT_DIR}/fio-api.sh"

if [ ! -f "$FIO_API_SCRIPT" ]; then
    echo "Error: fio-api.sh not found at ${FIO_API_SCRIPT}"
    exit 1
fi

# Load API functions
. "$FIO_API_SCRIPT"

echo "🎯 Setting up Build ${BUILD_ID} monitoring..."

# Loop to continuously check build status and logs
while true; do
    clear
    echo "🔍 Monitoring Build ${BUILD_ID} - Testing eink-power-cli recipe fix"
    echo "============================================================"
    echo "$(date): Checking Build ${BUILD_ID} status..."

    # Get overall build status
    BUILD_STATUS=$(api_call "projects/${FACTORY}/lmp/builds/${BUILD_ID}" | jq -r '.data.build.status')
    MAIN_RUN_STATUS=$(api_call "projects/${FACTORY}/lmp/builds/${BUILD_ID}/runs/${MACHINE}" | jq -r '.data.run.status')

    echo "🔄 Build ${BUILD_ID} is ${BUILD_STATUS}"
    echo "Main run (${MACHINE}) is ${MAIN_RUN_STATUS}"

    if [ "$MAIN_RUN_STATUS" = "FAILED" ]; then
        echo "🚨 Main build run FAILED! Getting last 50 lines of logs:"
        api_call "projects/${FACTORY}/lmp/builds/${BUILD_ID}/runs/${MACHINE}/console.log" | tail -n 50
        echo "============================================================"
        echo "Build ${BUILD_ID} FAILED. Check logs above or on Foundries.io web interface."
        exit 1
    elif [ "$MAIN_RUN_STATUS" = "PASSED" ]; then
        echo "✅ Main build run PASSED! Build ${BUILD_ID} is complete."
        echo "============================================================"
        echo "Build ${BUILD_ID} PASSED. Ready for board testing."
        exit 0
    else
        echo "Getting recent logs..."
        api_call "projects/${FACTORY}/lmp/builds/${BUILD_ID}/runs/${MACHINE}/console.log" | tail -n 10
    fi

    echo "Checking again in ${INTERVAL} seconds..."
    sleep "$INTERVAL"
done
