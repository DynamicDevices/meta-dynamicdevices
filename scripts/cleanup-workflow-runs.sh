#!/bin/bash

# Cleanup old GitHub Actions workflow runs
# Requires: gh CLI authenticated and configured

set -e

REPO="DynamicDevices/meta-dynamicdevices"
WORKFLOW_NAME="KAS Build CI"

echo "🧹 Cleaning up old GitHub Actions workflow runs..."
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
echo "📊 Current workflow runs:"
gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --limit 10

echo ""
read -r -p "🗑️  Delete workflow runs older than how many days? [7]: " DAYS_OLD
DAYS_OLD=${DAYS_OLD:-7}

echo ""
echo "🔍 Finding workflow runs older than $DAYS_OLD days..."

# Get workflow runs older than specified days
CUTOFF_DATE=$(date -d "$DAYS_OLD days ago" --iso-8601)
echo "📅 Cutoff date: $CUTOFF_DATE"

# Get list of old runs
OLD_RUNS=$(gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --json databaseId,createdAt,status,conclusion --jq ".[] | select(.createdAt < \"$CUTOFF_DATE\") | .databaseId")

if [ -z "$OLD_RUNS" ]; then
    echo "✅ No workflow runs older than $DAYS_OLD days found"
    exit 0
fi

RUN_COUNT=$(echo "$OLD_RUNS" | wc -l)
echo "🗑️  Found $RUN_COUNT workflow runs to delete"

echo ""
echo "📋 Runs to be deleted:"
gh run list --repo "$REPO" --workflow="$WORKFLOW_NAME" --json databaseId,createdAt,status,conclusion,headBranch --jq ".[] | select(.createdAt < \"$CUTOFF_DATE\") | \"ID: \(.databaseId) | \(.createdAt) | \(.status) | \(.conclusion // \"none\") | \(.headBranch)\""

echo ""
read -r -p "⚠️  Are you sure you want to delete these $RUN_COUNT workflow runs? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]([eE][sS])?$ ]]; then
    echo "❌ Deletion cancelled"
    exit 0
fi

echo ""
echo "🗑️  Deleting old workflow runs..."

DELETED_COUNT=0
FAILED_COUNT=0

for run_id in $OLD_RUNS; do
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
