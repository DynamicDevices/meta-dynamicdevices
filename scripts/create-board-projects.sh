#!/bin/bash

# Create GitHub Projects for board-specific issue tracking
# Requires: gh CLI authenticated with project permissions

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating board-specific GitHub Projects..."

# Note: GitHub Projects v2 requires different commands than legacy projects
# We'll create organization-level projects that can include this repository

echo "Creating Edge AI Board Project..."
EDGE_AI_PROJECT=$(gh project create --owner DynamicDevices --title "Edge AI Board (imx8mm-jaguar-sentai)" --body "Hardware and software issues specific to the Edge AI Board platform including audio processing, sensors, connectivity, and AI applications.")

echo "Edge AI Project created: $EDGE_AI_PROJECT"

echo "Creating Edge EInk Board Project..."
EDGE_EINK_PROJECT=$(gh project create --owner DynamicDevices --title "Edge EInk Board (imx93-jaguar-eink)" --body "Hardware and software issues specific to the Edge EInk Board platform including low-power management, wireless connectivity, and e-ink display functionality.")

echo "Edge EInk Project created: $EDGE_EINK_PROJECT"

echo "Creating Edge EV Board Project..."
EDGE_EV_PROJECT=$(gh project create --owner DynamicDevices --title "Edge EV Board (imx8mm-jaguar-phasora)" --body "Hardware and software issues specific to the Edge EV Board platform including energy management, power monitoring, and EV-specific applications.")

echo "Edge EV Project created: $EDGE_EV_PROJECT"

echo "Creating Cross-Platform/General Project..."
GENERAL_PROJECT=$(gh project create --owner DynamicDevices --title "Cross-Platform & Infrastructure" --body "Issues that affect multiple boards or general infrastructure including build system, recipes, documentation, and shared components.")

echo "General Project created: $GENERAL_PROJECT"

echo ""
echo "✅ Board-specific projects created successfully!"
echo ""
echo "PROJECTS CREATED:"
echo "🤖 Edge AI Board: $EDGE_AI_PROJECT"
echo "📱 Edge EInk Board: $EDGE_EINK_PROJECT"  
echo "⚡ Edge EV Board: $EDGE_EV_PROJECT"
echo "🔧 Cross-Platform: $GENERAL_PROJECT"
echo ""
echo "Next steps:"
echo "1. Add relevant issues to each project"
echo "2. Set up project views and workflows"
echo "3. Configure project automation if needed"
