# Pre-Build Verification Checklist

## Overview
Foundries.io builds take a LONG TIME to run. This checklist ensures comprehensive verification of changes before triggering any build to avoid wasted time and multiple build failures.

## Critical Principle
**NEVER trigger a build without comprehensive analysis of ALL potential knock-on effects.**

## Pre-Build Verification Process

### 1. Root Cause Analysis
- [ ] **Identify exact error messages** and failure points
- [ ] **Understand WHY the error occurs** (not just what failed)
- [ ] **Trace dependencies** that lead to the error
- [ ] **Document the complete failure chain**

### 2. Solution Completeness Check
- [ ] **Address ALL aspects** of the identified problem
- [ ] **Check for similar issues** in other parts of the codebase
- [ ] **Verify solution doesn't create new problems**
- [ ] **Ensure fix is comprehensive**, not just symptomatic

### 3. Configuration Conflict Analysis
- [ ] **Scan ALL config files** for potential conflicts
- [ ] **Check layer priorities** and override behavior
- [ ] **Verify no other configs re-enable** what you're disabling
- [ ] **Check base defconfig implications**

### 4. Dependency Impact Assessment
- [ ] **Identify ALL systems** that might depend on changed functionality
- [ ] **Check boot scripts** for command dependencies
- [ ] **Verify system initialization** doesn't expect removed features
- [ ] **Check logging/security systems** for functionality expectations

### 5. Cross-Component Verification
- [ ] **Device tree consistency** with config changes
- [ ] **Recipe dependencies** and build order implications
- [ ] **Kernel vs U-Boot** configuration alignment
- [ ] **Runtime vs build-time** dependency separation

### 6. Local Testing (When Possible)
- [ ] **Compile individual components** locally if feasible
- [ ] **Test configuration parsing** with kas/bitbake
- [ ] **Verify syntax** of all modified files
- [ ] **Check for obvious errors** before cloud build

### 7. Historical Pattern Analysis
- [ ] **Review previous similar failures** and their solutions
- [ ] **Check if this type of fix** has been attempted before
- [ ] **Learn from past mistakes** and incomplete fixes
- [ ] **Avoid repeating failed approaches**

## Build Trigger Decision Matrix

### HIGH Confidence (Proceed with build)
- ✅ Root cause clearly identified and understood
- ✅ Solution addresses ALL aspects of the problem
- ✅ No configuration conflicts found
- ✅ No apparent knock-on effects
- ✅ Similar to previously successful fixes
- ✅ Local testing passed (if applicable)

### MEDIUM Confidence (Additional verification needed)
- ⚠️ Root cause partially understood
- ⚠️ Solution addresses main issue but uncertainties remain
- ⚠️ Minor configuration concerns
- ⚠️ Some potential knock-on effects identified
- ⚠️ **ACTION**: Perform additional analysis before build

### LOW Confidence (DO NOT BUILD)
- ❌ Root cause unclear or multiple theories
- ❌ Solution is experimental or symptomatic
- ❌ Configuration conflicts detected
- ❌ Significant knock-on effects likely
- ❌ **ACTION**: More investigation required

## Common Failure Patterns to Avoid

### 1. Incomplete Disabling
- **Problem**: Disabling drivers but not commands that use them
- **Example**: Disabled RTC drivers but left CMD_DATE enabled
- **Solution**: Disable entire functional chain

### 2. Layer Priority Issues
- **Problem**: Other layers overriding your configurations
- **Example**: Base defconfig re-enabling what you disabled
- **Solution**: Use explicit disables, check layer order

### 3. Dependency Chain Breaks
- **Problem**: Removing something other components expect
- **Example**: Disabling I2C but leaving I2C-dependent drivers
- **Solution**: Trace ALL dependencies before changes

### 4. Configuration Conflicts
- **Problem**: Multiple configs setting same option differently
- **Example**: One file sets CONFIG_X=y, another sets CONFIG_X=n
- **Solution**: Ensure consistent configuration across all files

## Build Efficiency Guidelines

### Time-Saving Practices
1. **Batch related fixes** into single build when possible
2. **Verify locally first** using kas/bitbake when feasible
3. **Learn from build logs** to catch patterns early
4. **Document solutions** to avoid repeating analysis

### Waste Prevention
1. **Never assume "obvious" fixes** will work
2. **Always check for side effects** before building
3. **Verify configuration completeness** thoroughly
4. **Test incrementally** when possible

## Emergency Build Cancellation
- **When to cancel**: If you realize a mistake after triggering
- **How to minimize waste**: Cancel early if possible
- **Recovery strategy**: Have rollback plan ready

## Documentation Requirements
- **Document analysis process** for each build
- **Record verification steps taken**
- **Note any assumptions made**
- **Track success/failure patterns**

## Example Verification (Build 2022 RTC Fix)

### Problem Analysis
- ✅ **Root cause**: cmd/date.c calls rtc_reset/rtc_set/rtc_get functions
- ✅ **Why it occurs**: RTC drivers disabled but command framework still enabled
- ✅ **Complete chain**: CMD_DATE → rtc_* functions → undefined references

### Solution Verification
- ✅ **Comprehensive fix**: Disable drivers + commands + framework
- ✅ **No conflicts**: Scanned all configs, no RTC re-enabling found
- ✅ **No knock-on effects**: No boot scripts or system dependencies on date command
- ✅ **Historical precedent**: Similar command disabling has worked before

### Confidence Level: HIGH ✅
**Decision**: Proceed with build 2022

---

**Remember**: Every minute spent on thorough verification saves hours of build time and debugging. The goal is to get builds right the first time, not to build quickly and fail repeatedly.
