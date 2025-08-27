#!/bin/bash

# Cleanup failed and cancelled GitHub Actions workflow runs
# Requires: gh CLI authenticated and configured

set -e

REPO="DynamicDevices/meta-dynamicdevices"
WORKFLOW_NAME="KAS Build CI"

echo "🧹 Cleaning up failed/cancelled GitHub Actions workflow runs..."
echo "📂 Repository: $REPO"
echo "🔧 Workflow: $WORKFLOW_NAME"

# Check if gh CLI is available and authenticated
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "📥 Install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI is not authenticated"
    echo "🔐 Run: gh auth login"
    exit 1
fi

echo ""
echo "🔍 Finding failed and cancelled workflow runs..."

# Get failed runs
FAILED_RUNS=$(gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --status failure --json databaseId --jq ".[].databaseId")
CANCELLED_RUNS=$(gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --status cancelled --json databaseId --jq ".[].databaseId")

# Combine and count
ALL_FAILED_RUNS=$(echo -e "$FAILED_RUNS\n$CANCELLED_RUNS" | grep -v '^$' | sort -u)

if [ -z "$ALL_FAILED_RUNS" ]; then
    echo "✅ No failed or cancelled workflow runs found"
    exit 0
fi

RUN_COUNT=$(echo "$ALL_FAILED_RUNS" | wc -l)
echo "🗑️  Found $RUN_COUNT failed/cancelled workflow runs to delete"

echo ""
echo "📋 Failed runs:"
gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --status failure --limit 10

echo ""
echo "📋 Cancelled runs:"
gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --status cancelled --limit 10

echo ""
read -r -p "⚠️  Delete all $RUN_COUNT failed/cancelled workflow runs? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]([eE][sS])?$ ]]; then
    echo "❌ Deletion cancelled"
    exit 0
fi

echo ""
echo "🗑️  Deleting failed/cancelled workflow runs..."

DELETED_COUNT=0
FAILED_COUNT=0

for run_id in $ALL_FAILED_RUNS; do
    echo -n "Deleting run $run_id... "
    if gh run delete "$run_id" --repo "$REPO" >/dev/null 2>&1; then
        echo "✅ deleted"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    else
        echo "❌ failed"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    
    # Add small delay to avoid rate limiting
    sleep 0.5
done

echo ""
echo "📊 Cleanup Summary:"
echo "✅ Successfully deleted: $DELETED_COUNT runs"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "❌ Failed to delete: $FAILED_COUNT runs"
fi

echo ""
echo "📊 Remaining workflow runs:"
gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --limit 10

echo ""
echo "🎉 Cleanup completed!"
