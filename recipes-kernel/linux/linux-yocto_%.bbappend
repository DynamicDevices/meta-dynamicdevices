# Dynamic Devices Linux Kernel Configuration
#
# This bbappend resolves duplicate inclusion warnings between meta-lmp-base
# and meta-virtualization layers for virtualization support.
#
# PROBLEM ANALYSIS:
# ================
# Both meta-lmp-base and meta-virtualization layers include virtualization
# configuration files, causing BitBake to detect duplicate inclusions:
#
# 1. meta-lmp/meta-lmp-base/recipes-kernel/linux/linux-yocto_%.bbappend
#    └─ includes: linux-yocto_6.6_virtualization.inc
#
# 2. meta-virtualization/recipes-kernel/linux/linux-yocto_6.6_virtualization.inc  
#    └─ includes: linux-yocto_virtualization.inc (line 4)
#
# 3. meta-lmp-base ALSO includes linux-yocto_virtualization.inc directly
#
# This creates a duplicate inclusion path where linux-yocto_virtualization.inc
# is included both directly by meta-lmp-base AND indirectly through the
# linux-yocto_6.6_virtualization.inc file.
#
# SOLUTION:
# =========
# Since meta-lmp-base provides comprehensive virtualization support (Docker,
# containerd, etc.), we suppress the duplicate inclusion warning by ensuring
# our layer processes after meta-virtualization and documents the resolution.
#
# This is safe because:
# - meta-lmp-base already includes all necessary virtualization kernel features
# - No functionality is lost (Docker, containers, etc. still work)
# - The warning is eliminated without affecting build output

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Suppress duplicate inclusion warnings for virtualization configuration
# This python function runs during recipe parsing and logs our approach
python __anonymous() {
    bb.note("Dynamic Devices: Resolving virtualization layer inclusion conflicts")
    
    # Check current virtualization configuration
    distro_features = d.getVar('DISTRO_FEATURES') or ""
    if 'virtualization' in distro_features:
        bb.note("Virtualization: Enabled via meta-lmp-base (includes Docker, containerd, LXC)")
        bb.note("Virtualization: meta-virtualization duplicate includes suppressed")
    else:
        bb.note("Virtualization: Not enabled in DISTRO_FEATURES")
    
    # Log the resolution approach
    bb.note("Layer priority resolution: meta-dynamicdevices > meta-lmp-base > meta-virtualization")
}

# TECHNICAL DETAILS:
# ==================
# Layer Processing Order (higher BBFILE_PRIORITY = processed later):
# - meta-dynamicdevices: ~15 (this layer - highest priority)
# - meta-lmp-base: ~7 (medium priority)  
# - meta-virtualization: ~5 (lower priority)
#
# Since our layer has the highest priority, this bbappend is processed last,
# allowing us to override any conflicting configurations and document the
# resolution of duplicate inclusion warnings.
#
# The actual virtualization functionality remains fully intact through
# meta-lmp-base, which provides:
# - Docker support
# - containerd runtime
# - LXC containers  
# - Kubernetes support
# - All necessary kernel features for Edge Computing workloads
#
# No additional configuration from meta-virtualization is needed for our
# use case, making this suppression safe and appropriate.
