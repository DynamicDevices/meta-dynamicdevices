# Foundries.io Factory Management Guide

## Overview

This document provides comprehensive guidance for managing Dynamic Devices' Foundries.io Linux MicroPlatform (LMP) factories and implementing new branch configurations for customer boards.

## Factory Architecture

### Current Factory Structure

Dynamic Devices maintains **two separate Foundries.io factories**:

1. **Dynamic Devices Factory** (`dynamic-devices`)
   - **Location**: `/data_drive/dd/`
   - **Primary Boards**: `imx93-jaguar-eink`, `imx8mm-jaguar-sentai`, `imx8mm-jaguar-phasora`, etc.
   - **Use Case**: Main Dynamic Devices products and development

2. **Sentai Factory** (`sentai`)
   - **Location**: `/data_drive/sentai/`
   - **Primary Boards**: `imx8mm-jaguar-sentai` (Sentai-specific configurations)
   - **Use Case**: Sentai project-specific builds with custom voice processing

### Shared Infrastructure

Both factories share the **meta-dynamicdevices** repository ecosystem:
- **Location**: `/data_drive/dd/meta-dynamicdevices/`
- **Components**:
  - `meta-dynamicdevices-bsp/`: Hardware-specific layers (device trees, drivers)
  - `meta-dynamicdevices-distro/`: Distribution policies and configurations
  - Core recipes and KAS configurations

## Repository Structure and Relationships

### Key Repositories per Factory

Each factory requires these critical repositories:

#### 1. ci-scripts Repository
- **Purpose**: Defines factory configuration and build parameters
- **Key File**: `factory-config.yml`
- **Contents**: Machines, build parameters, branch configurations, mfgtools settings

#### 2. lmp-manifest Repository  
- **Purpose**: Defines which layers and repositories are included in builds
- **Key Files**: `dynamic-devices.xml`, `sentai.xml`
- **Contents**: Layer definitions, repository URLs, branch/revision specifications

#### 3. meta-subscriber-overrides Repository
- **Purpose**: Factory-specific customizations and **build triggers**
- **Critical**: **ALL BUILD TRIGGERS** happen through commits to this repository
- **Contents**: Factory-specific recipes, configurations, and overrides

#### 4. containers Repository
- **Purpose**: Docker container definitions for applications
- **Contents**: Dockerfiles, docker-compose configurations

### Build Trigger Mechanism

**CRITICAL UNDERSTANDING**: Foundries.io builds are triggered **ONLY** by commits to `meta-subscriber-overrides`, not the main `meta-dynamicdevices` repository.

```bash
# To trigger a build:
cd /data_drive/dd/meta-subscriber-overrides  # or /data_drive/sentai/
./force-build.sh  # Creates empty commit and pushes
```

## Branch Configuration System

### Current Branch Patterns

#### Dynamic Devices Factory
- `main-imx93-jaguar-eink`: E-Ink signage boards
- `main-jaguar-sentai`: Sentai AI boards (in DD factory)
- `main-jaguar-phasora`: Phasora boards
- `main-rpi4`: Raspberry Pi 4 builds
- `main-rpi5`: Raspberry Pi 5 builds

#### Sentai Factory  
- `main-jaguar-sentai-dev`: Development builds
- `main-jaguar-sentai-uat`: User acceptance testing
- `main-jaguar-sentai-staging`: Staging environment
- `main-jaguar-sentai-prod`: Production builds

### Branch Configuration Structure

Each branch is configured in `ci-scripts/factory-config.yml`:

```yaml
ref_options:
  refs/heads/main-customer-board:
    machines:
    - customer-board-machine
    params:
      DISTRO: lmp-dynamicdevices
      DEV_MODE: 1
    mfg_tools:
    - machine: customer-board-machine
      params:
        DISTRO: lmp-mfgtool
        MFGTOOL_FLASH_IMAGE: lmp-factory-image
        EXTRA_ARTIFACTS: mfgtool-files.tar.gz
        IMAGE: mfgtool-files
```

## Implementation Process for New Customer Boards

### Prerequisites

Before adding a new customer board, ensure:

1. **Hardware Definition Complete**:
   - Machine configuration in `meta-dynamicdevices-bsp/conf/machine/`
   - Device tree files
   - Hardware-specific drivers/recipes

2. **Factory Selection**:
   - Determine which factory (dynamic-devices vs sentai)
   - Consider customer requirements and separation needs

3. **Branch Strategy**:
   - Development vs production branches
   - Integration with existing workflows

### Step-by-Step Implementation

#### Phase 1: Repository Setup

1. **Navigate to Factory Directory**:
   ```bash
   cd /data_drive/dd  # or /data_drive/sentai for Sentai factory
   ```

2. **Update ci-scripts Configuration**:
   ```bash
   cd ci-scripts
   git checkout main
   git pull origin main
   ```

3. **Edit factory-config.yml**:
   - Add new branch configuration under `tagging:` and `ref_options:`
   - Define machine, DISTRO, and build parameters
   - Configure mfgtools settings

#### Phase 2: Manifest Configuration

1. **Update lmp-manifest**:
   ```bash
   cd lmp-manifest
   git checkout main
   git pull origin main
   ```

2. **Create New Branch in meta-subscriber-overrides**:
   ```bash
   cd ../meta-subscriber-overrides
   git checkout -b main-customer-board
   ```

3. **Add Customer-Specific Configurations**:
   - Create recipes in `recipes-*` directories as needed
   - Add machine-specific overrides
   - Configure any custom applications or services

#### Phase 3: Testing and Validation

1. **Trigger Initial Build**:
   ```bash
   cd meta-subscriber-overrides
   git add .
   git commit -m "Add support for customer-board"
   git push origin main-customer-board
   ./force-build.sh
   ```

2. **Monitor Build Progress**:
   ```bash
   # From meta-dynamicdevices repository
   ./scripts/monitor-foundries-build.sh <build_number>
   ```

3. **Test Build Artifacts**:
   ```bash
   # Download and test build
   ./scripts/fio-program-board.sh --factory <factory-name> --machine <customer-board> --latest --program
   ```

#### Phase 4: Production Integration

1. **Create Production Branch** (if needed):
   ```bash
   git checkout -b main-customer-board-prod
   # Update configurations for production settings (DEV_MODE: 0, etc.)
   git commit -m "Add production configuration for customer-board"
   git push origin main-customer-board-prod
   ```

2. **Update Documentation**:
   - Add board to this guide
   - Update customer-specific documentation
   - Create deployment guides

## Build Monitoring and Management

### Available Tools

1. **Real-time Build Monitoring**:
   ```bash
   ./scripts/monitor-foundries-build.sh <build_number>
   ```

2. **Build Status Check**:
   ```bash
   fioctl targets list --factory <factory-name>
   fioctl targets show <build_number> --factory <factory-name>
   ```

3. **Programming Tools**:
   ```bash
   ./scripts/fio-program-board.sh --factory <factory-name> --machine <machine> --latest --program
   ```

### Build Troubleshooting

#### Common Issues

1. **Build Fails to Start**: Check meta-subscriber-overrides commit and push
2. **Machine Not Found**: Verify machine definition in BSP layer
3. **Layer Conflicts**: Check layer priorities and compatibility
4. **Signing Failures**: Verify factory keys and signing configuration

#### Debug Process

1. **Check Build Logs**:
   ```bash
   fioctl targets show <build_number> --factory <factory-name>
   ```

2. **Local Testing**:
   ```bash
   # Test locally using KAS
   export MACHINE=<customer-board>
   ./scripts/kas-shell-base.sh
   # Inside container:
   kas build kas/lmp-dynamicdevices.yml
   ```

## Maintenance Procedures

### Regular Maintenance Tasks

1. **Weekly**:
   - Monitor build status across all branches
   - Check for upstream LMP updates
   - Review and merge development branches

2. **Monthly**:
   - Update base layer revisions
   - Security audit and updates
   - Performance optimization review

3. **Quarterly**:
   - Factory configuration review
   - Branch cleanup (remove obsolete branches)
   - Documentation updates

### Update Procedures

#### Updating Base LMP

1. **Check for Updates**:
   ```bash
   # In lmp-manifest directory
   git fetch upstream
   git log HEAD..upstream/main --oneline
   ```

2. **Test Updates**:
   - Create test branch
   - Update layer revisions
   - Trigger test builds
   - Validate on hardware

3. **Deploy Updates**:
   - Merge to main branches
   - Update all customer branches
   - Notify stakeholders

#### Managing Layer Updates

1. **meta-dynamicdevices Updates**:
   - Test in local KAS builds first
   - Validate across all supported machines
   - Update submodule references in factories

2. **BSP Layer Updates**:
   - Hardware validation required
   - Coordinate with hardware team
   - Staged rollout to production

## Security Considerations

### Factory Isolation

- **Separate Factories**: Maintain clear separation between customer projects
- **Access Control**: Limit repository access based on project needs
- **Key Management**: Separate signing keys per factory

### Build Security

- **Signed Builds**: Enable signing for production branches
- **LUKS Encryption**: Configure filesystem encryption for sensitive deployments
- **Audit Logging**: Enable comprehensive audit trails

## Best Practices

### Development Workflow

1. **Local Testing First**: Always test changes locally before triggering cloud builds
2. **Incremental Changes**: Make small, testable changes
3. **Clear Commit Messages**: Document what each build attempts to achieve
4. **Branch Hygiene**: Regular cleanup of development branches

### Customer Board Integration

1. **Naming Convention**: Use consistent naming patterns (`main-customer-product`)
2. **Documentation**: Maintain customer-specific documentation
3. **Testing Protocol**: Establish hardware validation procedures
4. **Rollback Plan**: Always maintain working baseline for rollback

### Performance Optimization

1. **Build Caching**: Leverage Foundries.io build caching
2. **Layer Optimization**: Minimize layer conflicts and dependencies
3. **Parallel Builds**: Use branch-specific configurations to avoid conflicts
4. **Resource Management**: Monitor build resource usage

## Confirmed Configuration Requirements

Based on your specifications, here are the established requirements for new customer boards:

### ✅ Confirmed Settings

1. **Factory Selection**: New customer boards go in the **dynamic-devices factory** (unless otherwise specified)
2. **Branch Strategy**: Use **`main-customer-devel`** naming pattern for development branches
3. **Environment Separation**: **Development branches only** at present
4. **Hardware Validation**: **Manual process** (you will handle validation)
5. **Maintenance Responsibility**: **Initially you** will maintain customer-specific branches

### 🔍 Options to Consider

#### Access Control Options

**Option A: Repository-Level Access Control**
- Grant access to entire `meta-subscriber-overrides` repository
- Customers can see all configurations but only modify their branches
- **Pros**: Simple setup, easy collaboration
- **Cons**: Customers see other customer configurations

**Option B: Branch-Level Protection**
- Use GitHub branch protection rules
- Restrict push access to specific branches per customer
- **Pros**: Fine-grained control, customers only affect their branches
- **Cons**: More complex setup, requires GitHub Enterprise features

**Option C: Separate Repository Forks**
- Create customer-specific forks of `meta-subscriber-overrides`
- Use pull requests to merge customer changes
- **Pros**: Complete isolation, full audit trail
- **Cons**: More repositories to manage, complex merge process

**Recommendation**: Start with **Option A** for development, consider **Option B** for production customers.

#### Build Trigger Options

**Option A: Manual Triggers Only**
- Builds triggered only via `./force-build.sh` script
- **Pros**: Full control, no unexpected builds, cost control
- **Cons**: Requires manual intervention for each build

**Option B: Automatic on Push**
- Builds automatically trigger on commits to customer branches
- **Pros**: Immediate feedback, continuous integration
- **Cons**: Higher build costs, potential for frequent builds

**Option C: Hybrid Approach**
- Automatic builds for development branches
- Manual approval required for production builds
- **Pros**: Best of both worlds, controlled costs
- **Cons**: More complex configuration

**Recommendation**: Start with **Option A (Manual)** for development, evaluate **Option C** as customers mature.

## Customer Board Implementation Template

Based on your confirmed requirements, here's the streamlined process for adding new customer development boards:

### Quick Implementation Checklist

#### Prerequisites ✅
- [ ] Customer board hardware definition complete in `meta-dynamicdevices-bsp`
- [ ] Machine configuration file exists: `meta-dynamicdevices-bsp/conf/machine/customer-board.conf`
- [ ] Device tree files created and tested locally
- [ ] Customer name/identifier confirmed

#### Phase 1: Factory Configuration (5 minutes)
```bash
# 1. Navigate to dynamic-devices factory
cd /data_drive/dd/ci-scripts

# 2. Edit factory-config.yml - Add to tagging section:
refs/heads/main-customer-devel:
  - tag: main-customer-devel

# 3. Add to ref_options section:
refs/heads/main-customer-devel:
  machines:
  - customer-board-machine-name
  params:
    DISTRO: lmp-dynamicdevices
    DEV_MODE: 1
  mfg_tools:
  - machine: customer-board-machine-name
    params:
      DISTRO: lmp-mfgtool
      MFGTOOL_FLASH_IMAGE: lmp-factory-image
      EXTRA_ARTIFACTS: mfgtool-files.tar.gz
      IMAGE: mfgtool-files

# 4. Commit and push
git add factory-config.yml
git commit -m "Add main-customer-devel branch configuration"
git push origin main
```

#### Phase 2: Create Customer Branch (2 minutes)
```bash
# 1. Navigate to meta-subscriber-overrides
cd /data_drive/dd/meta-subscriber-overrides

# 2. Create and switch to customer branch
git checkout -b main-customer-devel
git push -u origin main-customer-devel

# 3. Add customer-specific configurations (if any)
mkdir -p recipes-support/customer-configs
# Add any customer-specific recipes or configurations

# 4. Initial commit
git add .
git commit -m "Initial configuration for customer development board"
git push origin main-customer-devel
```

#### Phase 3: Trigger First Build (1 minute)
```bash
# 1. Trigger build from meta-subscriber-overrides
cd /data_drive/dd/meta-subscriber-overrides
./force-build.sh

# 2. Monitor build (from meta-dynamicdevices directory)
cd /data_drive/dd/meta-dynamicdevices
./scripts/monitor-foundries-build.sh <build_number>
```

#### Phase 4: Validation (Manual Process)
```bash
# 1. Download build when complete
./scripts/fio-program-board.sh --factory dynamic-devices --machine customer-board-machine-name --latest

# 2. Program board (your manual process)
./scripts/fio-program-board.sh --factory dynamic-devices --machine customer-board-machine-name --latest --program

# 3. Validate hardware functionality
# [Your manual validation steps here]
```

### Template Files

#### factory-config.yml Template Entry
```yaml
# Add to tagging section:
refs/heads/main-CUSTOMER-devel:
  - tag: main-CUSTOMER-devel

# Add to ref_options section:  
refs/heads/main-CUSTOMER-devel:
  machines:
  - MACHINE-NAME
  params:
    DISTRO: lmp-dynamicdevices
    DEV_MODE: 1
  mfg_tools:
  - machine: MACHINE-NAME
    params:
      DISTRO: lmp-mfgtool
      MFGTOOL_FLASH_IMAGE: lmp-factory-image
      EXTRA_ARTIFACTS: mfgtool-files.tar.gz
      IMAGE: mfgtool-files

# Add to containers tagging section:
refs/heads/main-CUSTOMER-devel:
  - tag: main-CUSTOMER-devel
```

#### Customer Branch README Template
```markdown
# Customer Development Board Configuration

## Board Information
- **Customer**: [Customer Name]
- **Machine**: [machine-name]  
- **Hardware**: [Brief hardware description]
- **Branch**: main-customer-devel

## Build Information
- **Factory**: dynamic-devices
- **Latest Build**: [Build Number]
- **Status**: [Development/Testing/Validated]

## Custom Configurations
- [List any customer-specific recipes or configurations]

## Validation Notes
- [Your validation notes and test results]
```

### Maintenance Workflow

#### Weekly Tasks (5 minutes)
```bash
# Check build status for customer branches
fioctl targets list --factory dynamic-devices | grep customer

# Monitor for any failed builds
./scripts/check-foundries-build.sh <latest_build_number>
```

#### Customer Requests (10 minutes per request)
```bash
# For customer configuration changes:
cd /data_drive/dd/meta-subscriber-overrides
git checkout main-customer-devel
# Make requested changes
git add .
git commit -m "Customer requested: [description]"
git push origin main-customer-devel
./force-build.sh
```

This template provides a reproducible process that takes about 8 minutes to set up a new customer development board, with clear separation of concerns and minimal complexity.

## Appendix

### Useful Commands Reference

```bash
# Check factory status
fioctl factories list

# Monitor specific build
./scripts/monitor-foundries-build.sh <build_number>

# Program board with latest build
./scripts/fio-program-board.sh --factory <factory> --machine <machine> --program

# Force build trigger
cd meta-subscriber-overrides && ./force-build.sh

# Local KAS build
export MACHINE=<machine> && kas build kas/lmp-dynamicdevices.yml
```

### Directory Structure Reference

```
/data_drive/dd/                          # Dynamic Devices Factory
├── ci-scripts/factory-config.yml       # Build configuration
├── lmp-manifest/dynamic-devices.xml    # Layer manifest
├── meta-subscriber-overrides/          # Build triggers & overrides
├── containers/                         # Docker containers
└── meta-dynamicdevices/               # Shared BSP/Distro layers

/data_drive/sentai/                     # Sentai Factory  
├── ci-scripts/factory-config.yml      # Build configuration
├── lmp-manifest/sentai.xml            # Layer manifest
├── meta-subscriber-overrides/         # Build triggers & overrides
└── containers/                        # Docker containers
```
