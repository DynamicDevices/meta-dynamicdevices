# Outstanding Issues

## Development Workflow Optimization

### Issue: Implement Rapid Development Workflow for New Boards
**Priority**: High  
**Status**: In Progress  
**Created**: 2025-10-06  
**Assignee**: Development Team  

**Problem**: 
Current development cycle for new boards is too slow:
- Full image rebuilds take 30-90 minutes
- Complete reflashing and testing cycle is time-consuming
- No clear distinction between runtime development and boot-level development
- Limited tools for rapid iteration on kernel modules, applications, and bootloader changes

**Impact**:
- Slow development cycles reduce productivity
- Difficult to iterate quickly on hardware-specific features
- Testing changes requires lengthy build-flash-test cycles
- New board bring-up takes excessive time

**Solution Overview**:
Implement two-tier development workflow:
1. **Runtime Development**: Deploy to running Linux (kernel modules, applications, userspace)
2. **Boot-Level Development**: Requires serial console access (U-Boot, device trees, bootloader)

**Implementation Tasks**:

#### Phase 1: Foundation Scripts ✅ COMPLETED
- [x] Create `kas-dev-kernel.sh` - Kernel development workflow
- [x] Create `kas-dev-recipe.sh` - Recipe development workflow  
- [x] Create `kas-dev-boot.sh` - Boot-level development workflow
- [x] Ensure all scripts use kas-container consistently

#### Phase 2: Runtime Development Workflow 🔄 IN PROGRESS
- [ ] **Task 2.1**: Test and refine `kas-dev-kernel.sh`
  - [ ] Test kernel building and deployment
  - [ ] Test devtool modify workflow
  - [ ] Validate SCP deployment to running targets
  - [ ] Add TFTP deployment option for faster iteration
- [ ] **Task 2.2**: Test and refine `kas-dev-recipe.sh`
  - [ ] Test recipe modification workflow
  - [ ] Test new recipe creation
  - [ ] Validate devtool deploy-target functionality
  - [ ] Add recipe testing automation
- [ ] **Task 2.3**: Implement module-specific deployment
  - [ ] Out-of-tree kernel module development
  - [ ] Rapid module rebuild and deployment
  - [ ] Module testing automation

#### Phase 3: Boot-Level Development Workflow 🔄 IN PROGRESS  
- [ ] **Task 3.1**: Test and refine `kas-dev-boot.sh`
  - [ ] Test U-Boot building and programming
  - [ ] Test device tree building and deployment
  - [ ] Validate serial console integration
- [ ] **Task 3.2**: Enhance serial console automation
  - [ ] Improve U-Boot shell access automation
  - [ ] Add automated boot testing with pass/fail detection
  - [ ] Implement boot stage timing analysis
- [ ] **Task 3.3**: Network boot setup (optional)
  - [ ] TFTP server configuration for kernel deployment
  - [ ] U-Boot network boot automation
  - [ ] PXE boot setup for ultimate speed

#### Phase 4: Integration and Documentation 📋 PENDING
- [ ] **Task 4.1**: Create comprehensive documentation
  - [ ] Workflow decision tree (runtime vs boot-level)
  - [ ] Setup guides for each development type
  - [ ] Troubleshooting guides
- [ ] **Task 4.2**: Integration testing
  - [ ] Test complete workflows on multiple boards
  - [ ] Validate time savings vs traditional approach
  - [ ] Performance benchmarking
- [ ] **Task 4.3**: CI/CD integration
  - [ ] Automated testing of development scripts
  - [ ] Integration with existing build monitoring
  - [ ] Hardware-in-the-loop testing automation

#### Phase 5: Advanced Features 🔮 FUTURE
- [ ] **Task 5.1**: Build performance optimization
  - [ ] Implement ccache optimization recommendations
  - [ ] Add parallel build tuning
  - [ ] Shared sstate cache configuration
- [ ] **Task 5.2**: Target board management
  - [ ] Multi-board testing automation
  - [ ] Board pool management
  - [ ] Remote board access (lab integration)
- [ ] **Task 5.3**: Development environment containers
  - [ ] Containerized development environments
  - [ ] Reproducible development setups
  - [ ] Cloud development environment support

**Success Criteria**:
- [ ] Kernel changes: 60+ min → 5-10 min (50+ min saved)
- [ ] Module development: 30+ min → 2-5 min (25+ min saved)
- [ ] Recipe iteration: 45+ min → 10-15 min (30+ min saved)
- [ ] Boot-level changes: 90+ min → 20-30 min (60+ min saved)
- [ ] New board bring-up time reduced by 60%+

**Testing Checklist**:
- [ ] Test on imx93-jaguar-eink board
- [ ] Test on imx8mm-jaguar-sentai board
- [ ] Test kernel module development workflow
- [ ] Test application recipe development workflow
- [ ] Test U-Boot modification workflow
- [ ] Test device tree modification workflow
- [ ] Validate serial console automation
- [ ] Performance benchmarking vs traditional workflow

**Dependencies**:
- Existing kas build system
- Serial console hardware setup
- Python3 with pyserial for serial automation
- Target boards accessible via SSH for runtime deployment

**Notes**:
- Scripts follow existing kas-container patterns for consistency
- All development uses kas-based workflows (no direct bitbake)
- Clear separation between runtime and boot-level development
- Extensive use of existing serial console tools in `scripts/serial_console/`

---

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
- Build 2140 in progress to verify final recipe fix
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
- Build 2140 testing both eink-power-cli fix and secure boot signing
- Awaiting build completion for verification

---

*Add new issues above this line*
