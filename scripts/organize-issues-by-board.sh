#!/bin/bash

# Organize existing issues by board and create board-specific milestones
# Since gh project command is not available, we'll use milestones for organization
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating board-specific milestones for issue organization..."

# Create milestones for each board
echo "Creating Edge AI Board milestone..."
gh api repos/DynamicDevices/meta-dynamicdevices/milestones -f title="Edge AI Board (imx8mm-jaguar-sentai)" -f description="Issues specific to the Edge AI Board platform including TAS2563 audio, sensors, AI processing, and connectivity features." -f state="open" || echo "Milestone may already exist"

echo "Creating Edge EInk Board milestone..."
gh api repos/DynamicDevices/meta-dynamicdevices/milestones -f title="Edge EInk Board (imx93-jaguar-eink)" -f description="Issues specific to the Edge EInk Board platform including low-power management, wireless connectivity, and e-ink display functionality." -f state="open" || echo "Milestone may already exist"

echo "Creating Edge EV Board milestone..."
gh api repos/DynamicDevices/meta-dynamicdevices/milestones -f title="Edge EV Board (imx8mm-jaguar-phasora)" -f description="Issues specific to the Edge EV Board platform including energy management, power monitoring, and EV applications." -f state="open" || echo "Milestone may already exist"

echo "Creating Cross-Platform milestone..."
gh api repos/DynamicDevices/meta-dynamicdevices/milestones -f title="Cross-Platform & Infrastructure" -f description="Issues affecting multiple boards or general infrastructure including build system, recipes, documentation, and shared components." -f state="open" || echo "Milestone may already exist"

echo ""
echo "Organizing existing issues by board..."

# Edge AI Board Issues (board: edge-ai label)
echo "Assigning Edge AI Board issues to milestone..."
gh issue edit 13 --repo "$REPO" --milestone "Edge AI Board (imx8mm-jaguar-sentai)"  # TAS2563 DSP firmware
gh issue edit 10 --repo "$REPO" --milestone "Edge AI Board (imx8mm-jaguar-sentai)"  # STUSB4500 power controller  
gh issue edit 1 --repo "$REPO" --milestone "Edge AI Board (imx8mm-jaguar-sentai)"   # STT22H sensor values

# Edge EV Board Issues (board: edge-ev label)
echo "Assigning Edge EV Board issues to milestone..."
gh issue edit 6 --repo "$REPO" --milestone "Edge EV Board (imx8mm-jaguar-phasora)"   # Phasora DTS GPIO

# Cross-Platform Issues (affects multiple boards or general infrastructure)
echo "Assigning Cross-Platform issues to milestone..."
gh issue edit 12 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"  # Hardware documentation verification
gh issue edit 11 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"  # Device tree pinctrl organization
gh issue edit 9 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"   # QA check failures
gh issue edit 8 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"   # Recipe license information
gh issue edit 7 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"   # TODO comments resolution
gh issue edit 5 --repo "$REPO" --milestone "Cross-Platform & Infrastructure"   # Remove salt value

echo ""
echo "✅ Issues organized by board-specific milestones!"
echo ""
echo "MILESTONE ORGANIZATION:"
echo ""
echo "🤖 EDGE AI BOARD (3 issues):"
echo "  #13: TAS2563 DSP Firmware Enhancement [HIGH]"
echo "  #10: STUSB4500 Power Controller [HIGH]"
echo "  #1: STT22H Sensor Values [HIGH]"
echo ""
echo "⚡ EDGE EV BOARD (1 issue):"
echo "  #6: Phasora DTS GPIO Settings [HIGH]"
echo ""
echo "🔧 CROSS-PLATFORM & INFRASTRUCTURE (6 issues):"
echo "  #12: Hardware Documentation Verification [MEDIUM]"
echo "  #11: Device Tree Pinctrl Organization [MEDIUM]"
echo "  #9: QA Check Failures [MEDIUM]"
echo "  #8: Recipe License Information [CRITICAL]"
echo "  #7: TODO Comments Resolution [MEDIUM]"
echo "  #5: Remove Salt Value [LOW]"
echo ""
echo "📊 BOARD-SPECIFIC WORKLOAD:"
echo "👨‍🔧 Mike-Hull (Hardware): 4 issues (3 Edge AI + 1 Edge EV)"
echo "👨‍💻 ajlennon (Software): 4 issues (all Cross-Platform)"
echo "📋 Documentation: 2 issues (Cross-Platform)"
echo ""
echo "View milestones at: https://github.com/$REPO/milestones"
echo ""
echo "NOTE: If you need full GitHub Projects (kanban boards), you can create them"
echo "manually in the GitHub web interface and add these milestones to them."
