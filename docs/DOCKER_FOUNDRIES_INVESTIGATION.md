# Docker Service and Foundries.io OTA Updates Investigation

## Issue Description
During Build 2101 power optimization validation, we discovered that Docker service is still active despite being targeted for disabling to save power. However, Foundries.io likely requires Docker for OTA updates and container management.

## Current Status
- **Build 2101:** Docker service is ACTIVE (not disabled as intended)
- **Power Impact:** Docker daemon consumes additional CPU/memory resources
- **Functionality Risk:** Disabling Docker may break Foundries.io OTA update mechanism

## Investigation Required

### 1. Foundries.io Docker Dependency Analysis
- [ ] Verify if aktualizr-lite requires Docker daemon for OTA updates
- [ ] Check if container-based applications need Docker runtime
- [ ] Investigate Foundries.io documentation on Docker requirements
- [ ] Test OTA update functionality with Docker disabled

### 2. Power vs Functionality Trade-off
- [ ] Measure power consumption impact of Docker daemon
- [ ] Evaluate conditional Docker enabling (only during updates)
- [ ] Consider Docker optimization instead of complete disabling
- [ ] Research Docker power-saving configurations

### 3. Alternative Solutions
- [ ] Investigate systemd-based container runtime alternatives
- [ ] Consider Docker socket activation (on-demand startup)
- [ ] Evaluate podman as lighter alternative if supported by Foundries.io
- [ ] Research Docker daemon power optimization flags

## Test Plan
1. **Baseline Measurement:** Measure current power with Docker active
2. **Docker Disabled Test:** Temporarily disable Docker and test OTA functionality
3. **Conditional Docker:** Implement on-demand Docker activation
4. **Optimized Docker:** Configure Docker with power-saving options

## Priority
**HIGH** - This affects both power optimization goals and OTA update functionality

## Next Steps
1. Research Foundries.io documentation on Docker requirements
2. Contact Foundries.io support for official guidance
3. Implement test scenarios to measure impact
4. Develop conditional enabling strategy if needed

---
**Created:** 2025-01-04  
**Status:** Investigation Required  
**Impact:** Power Optimization vs OTA Functionality
