#!/bin/bash

# GitHub Issue Creation Script
# Usage: ./create-github-issue.sh "Issue Title" "Issue Body" "label1,label2"

set -e

REPO="DynamicDevices/meta-dynamicdevices"
GITHUB_TOKEN_FILE="$HOME/.github_token"

# Check for token
if [ -z "$GITHUB_TOKEN" ] && [ -f "$GITHUB_TOKEN_FILE" ]; then
    GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN not set and ~/.github_token not found"
    echo "Please set GITHUB_TOKEN environment variable or create ~/.github_token file"
    exit 1
fi

# Parse arguments
TITLE="$1"
BODY="$2"
LABELS="$3"

if [ -z "$TITLE" ]; then
    echo "Usage: $0 \"Issue Title\" \"Issue Body\" \"label1,label2\""
    exit 1
fi

# Create JSON payload
JSON_PAYLOAD=$(cat << EOF
{
  "title": "$TITLE",
  "body": "$BODY"
}
EOF
)

# Add labels if provided
if [ -n "$LABELS" ]; then
    LABELS_JSON=$(echo "$LABELS" | jq -R 'split(",") | map(strip)')
    JSON_PAYLOAD=$(echo "$JSON_PAYLOAD" | jq ".labels = $LABELS_JSON")
fi

# Create the issue
echo "Creating GitHub issue: $TITLE"
curl -X POST \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD" \
     "https://api.github.com/repos/$REPO/issues" | jq '.html_url'

echo "Issue created successfully!"
