# Security Compliance CLI

A comprehensive Rust-based security compliance testing framework designed for embedded Linux devices, specifically targeting the imx93-jaguar-eink board running Foundries.io Linux Micro Platform (LmP). This tool provides automated security testing capabilities for regulatory compliance including UK CE RED and EU CRA requirements.

## 🚀 Features

### Comprehensive Security Testing
- **Boot Security**: Secure boot chain, signature verification, module signing
- **Runtime Security**: Filesystem encryption, firewall, SELinux, SSH security
- **Hardware Security**: EdgeLock Enclave, secure enclave, hardware RNG
- **Network Security**: Port analysis, service security, WiFi/Bluetooth security
- **Container Security**: Docker/Podman hardening, image scanning, runtime security
- **Certificate Management**: X.509 validation, PKI infrastructure, certificate rotation
- **Compliance Testing**: CRA/RED regulatory requirements, audit trails
- **Production Hardening**: Post-deployment security validation

### Advanced Capabilities
- **Dual Testing Modes**: Pre-production (development) vs Production (hardened) testing
- **Multiple Output Formats**: Human-readable, JSON, JUnit XML, Markdown
- **SSH-Based Remote Testing**: Secure connection with multiplexing
- **Configurable Test Suites**: Customizable test combinations
- **Parallel Execution**: Efficient concurrent testing
- **Comprehensive Reporting**: Detailed results with remediation guidance

## 📋 Prerequisites

- Rust 1.70+ with Cargo
- SSH access to target device
- OpenSSL development libraries
- For cross-compilation: ARM64 toolchain

## 🛠️ Installation

### From Source
```bash
git clone git@github.com:DynamicDevices/security-compliance-cli.git
cd security-compliance-cli
cargo build --release
```

### Cross-Compilation for ARM64
```bash
# Install cross-compilation target
rustup target add aarch64-unknown-linux-gnu

# Build for ARM64
./build-aarch64.sh

# Deploy to target device
./deploy-target.sh <target-ip>
```

## 🔧 Configuration

### Command Line Configuration
```bash
# Basic usage with inline parameters
security-compliance-cli test \
    --target-ip 192.168.0.36 \
    --target-port 22 \
    --target-username fio \
    --target-password fio \
    --mode production
```

### Configuration File
Create `config.toml` in the project root or `~/.config/security-compliance-cli/config.toml`:

```toml
[target]
ip = "192.168.0.36"
port = 22
username = "fio"
password = "fio"
# Alternatively, use SSH key authentication
# private_key_path = "/home/user/.ssh/id_rsa"

[test]
suite = "all"
mode = "pre-production"  # or "production"
continue_on_failure = false
parallel = true
timeout_per_test = 60
retries = 2

[output]
format = "human"  # human, json, junit, markdown
detailed_report = true
log_level = "info"
```

## 📚 Usage Examples

### Basic Testing
```bash
# Run all tests in pre-production mode
cargo run -- test --target-ip 192.168.0.36

# Run specific test suite
cargo run -- test --test-suite boot --target-ip 192.168.0.36

# Production mode testing (strict compliance)
cargo run -- test --mode production --target-ip 192.168.0.36
```

### Advanced Usage
```bash
# Generate detailed JSON report
cargo run -- test \
    --target-ip 192.168.0.36 \
    --output-format json \
    --detailed-report \
    > security_report.json

# Run only compliance tests with custom timeout
cargo run -- test \
    --test-suite compliance \
    --target-ip 192.168.0.36 \
    --timeout 120 \
    --continue-on-failure

# Test specific categories
cargo run -- test --test-suite hardware,network --target-ip 192.168.0.36

# Generate JUnit XML for CI/CD
cargo run -- test \
    --target-ip 192.168.0.36 \
    --output-format junit \
    > test_results.xml
```

### Information Commands
```bash
# List all available tests
cargo run -- list

# List tests in specific category
cargo run -- list --category boot

# Validate configuration
cargo run -- validate --config-file config.toml

# Show version and build info
cargo run -- --version
```

## 🧪 Test Categories

### Boot Security Tests (`boot`)
- `boot_001`: Secure Boot Enabled
- `boot_002`: U-Boot Signature Verification  
- `boot_003`: Kernel Signature Verification
- `boot_004`: Module Signing Active
- `boot_005`: OP-TEE Signature Verification
- `boot_006`: TF-A Signature Verification
- `boot_007`: Complete Boot Chain Verification

### Runtime Security Tests (`runtime`)
- `runtime_001`: Filesystem Encryption (LUKS)
- `runtime_002`: Firewall Configuration
- `runtime_003`: SELinux Status
- `runtime_004`: SSH Security Configuration
- `runtime_005`: User Permission Security
- `runtime_006`: Service Hardening
- `runtime_007`: Kernel Security Protections

### Hardware Security Tests (`hardware`)
- `hardware_001`: EdgeLock Enclave (ELE)
- `hardware_002`: Secure Enclave Status
- `hardware_003`: Hardware Root of Trust
- `hardware_004`: Crypto Hardware Acceleration
- `hardware_005`: Hardware RNG

### Network Security Tests (`network`)
- `network_001`: Open Network Ports
- `network_002`: Network Services Security
- `network_003`: WiFi Security Configuration
- `network_004`: Bluetooth Security
- `network_005`: Network Encryption

### Container Security Tests (`container`)
- `container_001`: Docker Daemon Security
- `container_002`: Container Image Security
- `container_003`: Container Runtime Security
- `container_004`: Podman Security Configuration
- `container_005`: Container Network Security
- `container_006`: Container Resource Limits
- `container_007`: Container User Namespaces
- `container_008`: Container SELinux Context
- `container_009`: Container Capabilities
- `container_010`: Container Seccomp Profiles

### Certificate Management Tests (`certificate`)
- `certificate_001`: X.509 Certificate Validation
- `certificate_002`: PKI Infrastructure
- `certificate_003`: Certificate Expiration Monitoring
- `certificate_004`: Certificate Chain Validation
- `certificate_005`: Certificate Revocation (CRL/OCSP)
- `certificate_006`: Certificate Storage Security
- `certificate_007`: CA Certificate Management
- `certificate_008`: TLS Certificate Validation
- `certificate_009`: Certificate Rotation
- `certificate_010`: Certificate Compliance

### Compliance Tests (`compliance`)
- `compliance_001`: CRA Data Protection (Article 11)
- `compliance_002`: CRA Vulnerability Management
- `compliance_003`: RED Security Requirements (3.3)
- `compliance_004`: Incident Response Capability
- `compliance_005`: Security Audit Logging

### Production Hardening Tests (`production`)
- Production-specific security validations
- Post-deployment hardening verification
- Critical security configurations for production environments

## 🎯 Testing Modes

### Pre-Production Mode
- **Purpose**: Development and CI/CD builds
- **Behavior**: Allows certain tests to be skipped or marked as warnings
- **Use Case**: Validating security foundation before production hardening
- **Example**: Default password, unconfigured firewall are warnings, not failures

### Production Mode  
- **Purpose**: Deployed, hardened systems
- **Behavior**: All security tests must pass for compliance
- **Use Case**: Final validation of production-ready devices
- **Example**: Default password, unconfigured firewall cause test failure

## 📊 Output Formats

### Human Format (Default)
```
🔒 Security Compliance Test Results
==========================================

✅ Boot Security
   ✅ boot_001: Secure Boot Enabled (0.2s)
   ✅ boot_002: U-Boot Signature Verification (0.3s)
   ⚠️  boot_003: Kernel Signature Verification (0.4s)
      Warning: Some kernel modules unsigned

📊 Summary: 15/17 tests passed, 2 warnings, 0 failures
```

### JSON Format
```json
{
  "test_run": {
    "timestamp": "2025-10-07T14:30:00Z",
    "mode": "production",
    "target": {
      "ip": "192.168.0.36",
      "hostname": "imx93-jaguar-eink"
    },
    "results": [
      {
        "test_id": "boot_001",
        "name": "Secure Boot Enabled",
        "category": "boot",
        "status": "passed",
        "duration_ms": 200,
        "message": "Secure boot is properly enabled",
        "details": "AHAB verified, U-Boot signatures valid"
      }
    ],
    "summary": {
      "total": 17,
      "passed": 15,
      "warnings": 2,
      "failed": 0,
      "errors": 0
    }
  }
}
```

### JUnit XML Format
```xml
<testsuite name="SecurityCompliance" tests="17" failures="0" errors="0" time="12.5">
  <testcase classname="boot" name="boot_001" time="0.2">
    <system-out>Secure boot is properly enabled</system-out>
  </testcase>
  <testcase classname="boot" name="boot_003" time="0.4">
    <warning message="Some kernel modules unsigned"/>
  </testcase>
</testsuite>
```

## 🔧 Development

### Building
```bash
# Debug build
cargo build

# Release build  
cargo build --release

# Run tests
cargo test

# Run with logging
RUST_LOG=debug cargo run -- test --target-ip 192.168.0.36
```

### Adding New Tests
1. Create test function in appropriate module (`src/tests/`)
2. Implement the `SecurityTest` trait
3. Add test to the enum and test runner
4. Update documentation and test lists

### Code Quality
```bash
# Format code
cargo fmt

# Lint code
cargo clippy

# Security audit
cargo audit

# Generate documentation
cargo doc --open
```

## 🐛 Troubleshooting

### Common Issues

**SSH Connection Failed**
```bash
# Test SSH connectivity manually
ssh fio@192.168.0.36

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Use password authentication
cargo run -- test --target-ip 192.168.0.36 --target-password your_password
```

**Permission Denied**
```bash
# Ensure user has sudo access
echo "fio ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/fio_nopasswd

# Or run with sudo on target
cargo run -- test --target-ip 192.168.0.36 --use-sudo
```

**Test Timeouts**
```bash
# Increase timeout
cargo run -- test --target-ip 192.168.0.36 --timeout 120

# Run single test for debugging
cargo run -- test --test-suite boot --test-id boot_001 --target-ip 192.168.0.36
```

### Debug Mode
```bash
# Enable debug logging
RUST_LOG=debug cargo run -- test --target-ip 192.168.0.36

# Save debug output
RUST_LOG=debug cargo run -- test --target-ip 192.168.0.36 2> debug.log
```

## 📄 License

Proprietary - Dynamic Devices Ltd

## 🤝 Contributing

This is a proprietary project for Dynamic Devices Ltd. For internal development:

1. Create feature branch from `main`
2. Implement changes with tests
3. Run full test suite
4. Submit pull request for review

## 📞 Support

- **Internal**: Contact the Security Team
- **Documentation**: See `CONTEXT.md` for detailed project information
- **Issues**: Use GitHub Issues for bug reports and feature requests

## 🏷️ Version History

- **v0.1.0** (2025-10-07): Initial release with comprehensive security testing framework
- **Target Platform**: imx93-jaguar-eink / Foundries.io LmP v95
- **Compliance**: UK CE RED, EU CRA