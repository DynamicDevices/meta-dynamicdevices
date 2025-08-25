#!/bin/bash

# Add additional useful labels for better project management
# Requires: gh CLI authenticated

set -e

REPO="DynamicDevices/meta-dynamicdevices"

echo "Creating additional useful labels for project management..."

# COMPONENT/AREA LABELS - Help identify which part of the system is affected

echo "Creating component/area labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="component: device-tree" -f color="7B68EE" -f description="Device tree related issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="component: recipes" -f color="32CD32" -f description="Yocto recipe related issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="component: build-system" -f color="FF6347" -f description="Build system and configuration issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="component: documentation" -f color="40E0D0" -f description="Documentation and wiki related issues" || echo "Label may already exist"

# BOARD-SPECIFIC LABELS - Important for hardware-specific issues

echo "Creating board-specific labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="board: edge-ai" -f color="FF1493" -f description="Edge AI Board (imx8mm-jaguar-sentai) specific issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="board: edge-eink" -f color="9370DB" -f description="Edge EInk Board (imx93-jaguar-eink) specific issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="board: edge-ev" -f color="FF8C00" -f description="Edge EV Board (imx8mm-jaguar-phasora) specific issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="board: edge-gw" -f color="00CED1" -f description="Edge GW Board (imx8mm-jaguar-inst) specific issues" || echo "Label may already exist"

# IMPACT/SCOPE LABELS - Help understand the breadth of impact

echo "Creating impact/scope labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="impact: breaking-change" -f color="B22222" -f description="Changes that may break existing functionality" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="impact: security" -f color="8B0000" -f description="Security-related issues" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="impact: performance" -f color="FF4500" -f description="Performance-related issues" || echo "Label may already exist"

# STATUS/WORKFLOW LABELS - Help track progress

echo "Creating status/workflow labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="status: needs-testing" -f color="FFA500" -f description="Needs testing on hardware" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="status: blocked" -f color="DC143C" -f description="Blocked by other issues or external dependencies" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="status: needs-review" -f color="DAA520" -f description="Needs code or design review" || echo "Label may already exist"

# EFFORT/COMPLEXITY LABELS - Beyond time estimates

echo "Creating effort/complexity labels..."

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="complexity: simple" -f color="90EE90" -f description="Simple, straightforward fix" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="complexity: complex" -f color="FF6B6B" -f description="Complex issue requiring deep investigation" || echo "Label may already exist"

gh api repos/DynamicDevices/meta-dynamicdevices/labels -f name="needs: hardware-testing" -f color="FFB347" -f description="Requires testing on physical hardware" || echo "Label may already exist"

echo ""
echo "✅ Additional labels created successfully!"
echo ""
echo "Now applying relevant labels to existing issues..."

# Apply component labels to existing issues

echo "Adding component labels to existing issues..."

# Device tree issues
gh issue edit 11 --repo "$REPO" --add-label "component: device-tree"
gh issue edit 10 --repo "$REPO" --add-label "component: device-tree" 
gh issue edit 6 --repo "$REPO" --add-label "component: device-tree"

# Recipe issues
gh issue edit 8 --repo "$REPO" --add-label "component: recipes"
gh issue edit 9 --repo "$REPO" --add-label "component: recipes"

# Documentation issues
gh issue edit 12 --repo "$REPO" --add-label "component: documentation"

# Board-specific labels
gh issue edit 10 --repo "$REPO" --add-label "board: edge-ai"  # STUSB4500 on Edge AI board
gh issue edit 1 --repo "$REPO" --add-label "board: edge-ai"   # STT22H sensor on Edge AI
gh issue edit 6 --repo "$REPO" --add-label "board: edge-ev"   # Phasora is Edge EV board

# Impact labels
gh issue edit 8 --repo "$REPO" --add-label "impact: security"  # License compliance
gh issue edit 5 --repo "$REPO" --add-label "impact: security"  # Salt value removal

# Complexity labels
gh issue edit 6 --repo "$REPO" --add-label "complexity: simple"   # Simple GPIO change
gh issue edit 5 --repo "$REPO" --add-label "complexity: simple"   # Simple config cleanup
gh issue edit 12 --repo "$REPO" --add-label "complexity: complex" # Systematic verification
gh issue edit 7 --repo "$REPO" --add-label "complexity: complex"  # Many TODO items

# Hardware testing needed
gh issue edit 10 --repo "$REPO" --add-label "needs: hardware-testing"  # STUSB4500 needs testing
gh issue edit 1 --repo "$REPO" --add-label "needs: hardware-testing"   # Sensor testing
gh issue edit 6 --repo "$REPO" --add-label "needs: hardware-testing"   # GPIO testing
gh issue edit 11 --repo "$REPO" --add-label "needs: hardware-testing"  # Pinctrl testing

echo ""
echo "✅ All additional labels applied successfully!"
echo ""
echo "SUMMARY OF NEW LABEL CATEGORIES:"
echo ""
echo "🔧 COMPONENT LABELS:"
echo "  • component: device-tree"
echo "  • component: recipes" 
echo "  • component: build-system"
echo "  • component: documentation"
echo ""
echo "🏷️ BOARD-SPECIFIC LABELS:"
echo "  • board: edge-ai (imx8mm-jaguar-sentai)"
echo "  • board: edge-eink (imx93-jaguar-eink)"
echo "  • board: edge-ev (imx8mm-jaguar-phasora)" 
echo "  • board: edge-gw (imx8mm-jaguar-inst)"
echo ""
echo "⚠️ IMPACT LABELS:"
echo "  • impact: breaking-change"
echo "  • impact: security"
echo "  • impact: performance"
echo ""
echo "📊 STATUS/WORKFLOW LABELS:"
echo "  • status: needs-testing"
echo "  • status: blocked"
echo "  • status: needs-review"
echo ""
echo "🧩 COMPLEXITY LABELS:"
echo "  • complexity: simple"
echo "  • complexity: complex"
echo "  • needs: hardware-testing"
echo ""
echo "These labels will help with:"
echo "• Filtering issues by component/board"
echo "• Understanding impact and risk"
echo "• Tracking workflow status"
echo "• Planning testing requirements"
echo "• Identifying complexity levels"
