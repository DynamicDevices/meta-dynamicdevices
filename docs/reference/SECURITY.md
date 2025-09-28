# Security Policy

## Reporting Security Vulnerabilities

Dynamic Devices takes security seriously. We appreciate your efforts to responsibly disclose security vulnerabilities.

### How to Report a Security Issue

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities to us directly:

- **Email**: [security@dynamicdevices.co.uk](mailto:security@dynamicdevices.co.uk)
- **Subject Line**: `[SECURITY] meta-dynamicdevices: Brief description`

### What to Include

When reporting a security vulnerability, please include:

1. **Layer/Recipe Affected**: Which part of meta-dynamicdevices is affected
2. **Vulnerability Type**: Buffer overflow, privilege escalation, etc.
3. **Impact Assessment**: Potential security impact and affected systems
4. **Reproduction Steps**: Clear steps to reproduce the vulnerability
5. **Proof of Concept**: If available, include PoC code or demonstration
6. **Suggested Fix**: If you have ideas for remediation

### Response Timeline

- **Initial Response**: Within 48 hours of report receipt
- **Vulnerability Assessment**: Within 5 business days
- **Fix Development**: Timeline depends on severity and complexity
- **Public Disclosure**: Coordinated with reporter after fix is available

### Security Update Process

1. **Triage**: Security team evaluates severity and impact
2. **Development**: Fix developed and tested in private branch
3. **Testing**: Comprehensive testing across affected board variants
4. **Release**: Security update released with advisory
5. **Disclosure**: Public disclosure after users have time to update

### Supported Versions

We provide security updates for:

| Version | Supported |
|---------|-----------|
| Latest main branch | ✅ Yes |
| Latest release tag | ✅ Yes |
| Previous release | ⚠️ Critical fixes only |
| Older releases | ❌ No |

### Security Best Practices

When using meta-dynamicdevices:

#### Production Deployments
- **Disable Debug Features**: Remove `debug-tweaks` and development tools
- **Enable Security Features**: Use secure boot, verified boot, and encryption
- **Regular Updates**: Keep layer and dependencies up to date
- **Network Security**: Use VPN, firewall rules, and secure protocols

#### Development Environment
- **Isolated Testing**: Use separate networks for development boards
- **Secure Credentials**: Never commit secrets, keys, or passwords
- **Code Review**: Review all changes for security implications
- **Dependency Scanning**: Monitor for vulnerable dependencies

### Security Contacts

- **Primary Contact**: [security@dynamicdevices.co.uk](mailto:security@dynamicdevices.co.uk)
- **Technical Lead**: [ajlennon@dynamicdevices.co.uk](mailto:ajlennon@dynamicdevices.co.uk)
- **Hardware Security**: [mike@dynamicdevices.co.uk](mailto:mike@dynamicdevices.co.uk)

### CVE Process

For vulnerabilities requiring CVE assignment:

1. We will work with you to request CVE from MITRE or GitHub
2. CVE details will be coordinated with fix release
3. Public disclosure will reference CVE number
4. Security advisory will be published on GitHub Security Advisories

### Recognition

We believe in recognizing security researchers who help improve our security:

- **Hall of Fame**: Public recognition (with permission)
- **Coordinated Disclosure**: Professional handling of vulnerability disclosure
- **Technical Discussion**: Opportunity to discuss fix implementation

### Legal

This security policy is designed to be compatible with responsible disclosure practices. We will not pursue legal action against security researchers who:

- Make good faith efforts to avoid privacy violations and data destruction
- Only interact with accounts they own or have explicit permission to access
- Do not violate any applicable laws or regulations
- Follow this disclosure policy

---

**Note**: This security policy applies specifically to the meta-dynamicdevices Yocto layer. For security issues with underlying components (Linux kernel, U-Boot, etc.), please report to the appropriate upstream maintainers.

For general inquiries: [info@dynamicdevices.co.uk](mailto:info@dynamicdevices.co.uk)
