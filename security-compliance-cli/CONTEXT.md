# Security Compliance CLI - Project Context

## Overview

The Security Compliance CLI is a comprehensive Rust-based testing framework designed to validate security compliance for embedded Linux devices, specifically targeting the imx93-jaguar-eink board running Foundries.io Linux Micro Platform (LmP). This tool provides automated security testing capabilities for regulatory compliance including UK CE RED and EU CRA requirements.

## Project Architecture

### Core Components

1. **CLI Interface** (`src/cli.rs`)
   - Command-line argument parsing using `clap`
   - Support for multiple test suites and output formats
   - Pre-production vs Production testing modes

2. **Test Framework** (`src/tests/`)
   - Modular test organization by security domain
   - Async test execution with SSH connectivity
   - Comprehensive result reporting and analysis

3. **Target Management** (`src/target.rs`, `src/ssh.rs`)
   - SSH-based remote device communication
   - Connection multiplexing for efficiency
   - Secure authentication and session management

4. **Configuration Management** (`src/config.rs`)
   - TOML-based configuration files
   - Environment-specific settings
   - Test suite customization

## Test Categories

### 1. Boot Security (`src/tests/boot.rs`)
- Secure Boot Chain Verification
- U-Boot, OP-TEE, TF-A Signature Validation
- Kernel and Module Signing
- Complete Boot Chain Analysis

### 2. Runtime Security (`src/tests/runtime.rs`)
- Filesystem Encryption (LUKS)
- Firewall Configuration
- SELinux Status and Policies
- SSH Security Configuration
- User Permission Auditing
- Service Hardening
- Kernel Security Protections

### 3. Hardware Security (`src/tests/hardware.rs`)
- EdgeLock Enclave (ELE) Verification
- Secure Enclave Status
- Hardware Root of Trust
- Crypto Hardware Acceleration
- Hardware Random Number Generator

### 4. Network Security (`src/tests/network.rs`)
- Open Port Analysis
- Network Service Security
- WiFi Security Configuration
- Bluetooth Security
- Network Encryption Protocols

### 5. Compliance Testing (`src/tests/compliance.rs`)
- CRA Data Protection (Article 11)
- CRA Vulnerability Management
- RED Security Requirements (3.3)
- Incident Response Capability
- Security Audit Logging

### 6. Container Security (`src/tests/container.rs`)
- Docker/Podman Security Configuration
- Container Image Security and Scanning
- Container Runtime Security
- Network Isolation and Resource Limits
- User Namespaces and Capabilities
- SELinux Container Contexts
- Seccomp Security Profiles

### 7. Certificate Management (`src/tests/certificate.rs`)
- X.509 Certificate Validation
- PKI Infrastructure Assessment
- Certificate Expiration Monitoring
- Certificate Chain Validation
- Certificate Revocation (CRL/OCSP)
- Secure Certificate Storage
- CA Certificate Management
- TLS Certificate Validation
- Certificate Rotation Mechanisms
- Certificate Compliance Standards

### 8. Production Hardening (`src/tests/production.rs`)
- Production-specific security validations
- Post-deployment hardening verification
- Critical security configurations for production environments

## Testing Modes

### Pre-Production Mode
- Suitable for development and CI/CD builds
- Allows certain tests to be skipped or marked as warnings
- Focuses on security foundation verification
- Does not require production hardening steps

### Production Mode
- Strict compliance checking for deployed systems
- All security tests must pass
- Validates production hardening measures
- Ensures complete regulatory compliance

## Target Platform

### Primary Target: imx93-jaguar-eink Board
- **SoC**: NXP i.MX93 with EdgeLock Enclave
- **OS**: Foundries.io Linux Micro Platform v95 (Scarthgap)
- **BSP**: meta-dynamicdevices custom layers
- **Security Features**:
  - Hardware Root of Trust (i.MX93 ELE)
  - Secure Boot Chain: ROM → AHAB → U-Boot → TF-A → OP-TEE → Linux
  - PMU MCUboot with ECDSA P-256 signatures
  - LUKS filesystem encryption
  - Kernel module signing
  - OTA updates via OSTree

## Regulatory Compliance

### UK CE RED (Radio Equipment Directive)
- Health and Safety Requirements (Article 3.1a)
- EMC Requirements (Article 3.1b)
- Radio Spectrum Efficiency (Article 3.2)
- Additional Security Requirements (Article 3.3)

### EU CRA (Cyber Resilience Act)
- Cybersecurity Risk Assessment (Article 10)
- Data Protection Requirements (Article 11)
- Vulnerability Handling (Article 12)
- Incident Response (Article 13)
- Security Updates (Article 14)

## Development Workflow

### Local Development
1. Clone repository: `git clone git@github.com:DynamicDevices/security-compliance-cli.git`
2. Install Rust toolchain and dependencies
3. Configure target device connection
4. Run tests: `cargo run -- test --target-ip <IP> --mode pre-production`

### Cross-Compilation for ARM64
1. Install cross-compilation toolchain
2. Use provided build script: `./build-aarch64.sh`
3. Deploy to target: `./deploy-target.sh <target-ip>`

### CI/CD Integration
- GitHub Actions workflow for automated testing
- Multi-target builds (x86_64, aarch64)
- Automated linting and security scanning
- Release automation with artifact generation

## Output Formats

- **Human**: Colored terminal output with progress indicators
- **JSON**: Machine-readable structured output
- **JUnit**: XML format for CI/CD integration
- **Markdown**: Documentation-friendly format

## Security Considerations

### Connection Security
- SSH key-based authentication preferred
- Password authentication with secure storage
- Connection multiplexing for efficiency
- Timeout and retry mechanisms

### Test Isolation
- Non-destructive testing approach
- Read-only system analysis where possible
- Minimal system impact during testing
- Comprehensive logging and audit trails

## Extension Points

### Adding New Tests
1. Create test function in appropriate module
2. Implement `SecurityTest` trait
3. Add test to enum and runner
4. Update documentation and examples

### Custom Test Suites
1. Define custom test combinations
2. Configure via TOML files
3. Support for environment-specific requirements
4. Integration with existing test framework

## Dependencies

### Core Dependencies
- `clap`: Command-line interface
- `serde`: Serialization/deserialization
- `tokio`: Async runtime
- `ssh2`: SSH connectivity
- `anyhow`/`thiserror`: Error handling

### Development Dependencies
- `tokio-test`: Async testing utilities
- `mockall`: Mocking framework
- `tempfile`: Temporary file management

## Future Enhancements

### Planned Features
- Time synchronization security tests
- Physical tamper detection
- Supply chain verification (SBOM)
- Regulatory audit trails
- Enhanced reporting and analytics
- Integration with security scanning tools

### Performance Optimizations
- Parallel test execution
- Cached SSH connections
- Incremental testing modes
- Test result caching

## Support and Maintenance

### Version Management
- Semantic versioning (SemVer)
- Release notes and changelog
- Backward compatibility considerations
- Migration guides for major versions

### Documentation
- Comprehensive API documentation
- Usage examples and tutorials
- Troubleshooting guides
- Best practices documentation

---

**Last Updated**: October 7, 2025  
**Version**: 0.1.0  
**Target Platform**: imx93-jaguar-eink / Foundries.io LmP  
**Compliance Standards**: UK CE RED, EU CRA
