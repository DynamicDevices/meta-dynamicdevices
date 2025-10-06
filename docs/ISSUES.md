# Outstanding Issues

## Build Performance

### Issue: Pin SRCREV for eink-power-cli to improve build performance
**Priority**: Medium  
**Status**: Open  
**Created**: 2025-10-06  

**Problem**: 
The `eink-power-cli` recipe uses `SRCREV = "${AUTOREV}"` which forces a git fetch and rebuild on every build, resulting in 0% sstate cache reuse for this recipe and its dependencies.

**Impact**:
- Forces rebuild of `eink-power-cli` on every build (~3-5 minutes)
- Cascades to dependent recipes, reducing overall cache efficiency
- Current build analysis shows 93% cache hit rate, but could be higher

**Solution**:
Once `eink-power-cli` development stabilizes, pin to a specific commit:
```bb
# Replace: SRCREV = "${AUTOREV}"
# With:    SRCREV = "56d8ca9f23abc123..."  # Pin to specific commit
```

**When to Fix**:
- After eink-power-cli recipe is stable and working correctly
- After initial board testing is complete
- Before production builds

**Current Status**: 
- Recipe is still under active development with frequent changes
- Build 2139 in progress to verify final recipe fix
- Keeping AUTOREV for now to facilitate rapid development iteration

---

## Recipe Development

### Issue: Secure boot signing verification needed
**Priority**: High  
**Status**: In Progress  
**Created**: 2025-10-06  

**Problem**: 
Need to verify that secure boot signing is working correctly in Foundries builds.

**Status**: 
- Secure boot signing enabled in `ci-scripts/factory-config.yml`
- Build 2139 testing both eink-power-cli fix and secure boot signing
- Awaiting build completion for verification

---

*Add new issues above this line*
