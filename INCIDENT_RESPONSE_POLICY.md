# Incident Response Policy
**Document Type**: Operational Policy  
**Version**: 1.0  
**Effective Date**: October 2025  
**Owner**: Security Team, Dynamic Devices Ltd  
**Review Cycle**: Annual  

---

## 1. Purpose and Scope

This policy establishes Dynamic Devices Ltd's incident response procedures for security incidents affecting our embedded devices and infrastructure, ensuring compliance with EU CRA requirements.

**Scope**: All Dynamic Devices products, development infrastructure, and customer deployments.

## 2. Incident Classification

### 2.1 Severity Levels

**CRITICAL** - Immediate response required (0-1 hour)
- Complete system compromise or unauthorized root access
- Cryptographic key compromise
- Boot security failure preventing device startup
- Active data exfiltration or ransomware

**HIGH** - Response required within 4 hours
- Service disruption affecting multiple devices
- Unauthorized network access or privilege escalation
- OTA update system compromise
- Vulnerability with active exploitation

**MEDIUM** - Response required within 24 hours
- Configuration tampering or unauthorized changes
- Suspicious network activity or reconnaissance
- Failed authentication attempts above threshold
- Non-critical service failures

**LOW** - Response required within 72 hours
- Information gathering attempts
- Minor service disruptions
- Policy violations without security impact

### 2.2 Incident Types

- **Security Breach**: Unauthorized access to systems or data
- **Malware**: Malicious software detection
- **Data Breach**: Unauthorized data access or exfiltration
- **System Compromise**: Device or infrastructure compromise
- **Denial of Service**: Service availability attacks
- **Physical Security**: Unauthorized physical access

## 3. Detection and Monitoring

### 3.1 Automated Detection Systems

**System Monitoring**:
```bash
# Service failure detection
systemctl status --failed

# Security event monitoring
journalctl -p err -f --since "1 hour ago"

# Network security monitoring
iptables -L -n -v | grep -E "(DROP|REJECT)"
```

**File Integrity Monitoring**:
```bash
# Critical configuration changes
find /etc -type f -newer /tmp/last_security_check

# Boot partition integrity
sha256sum /boot/* > /tmp/boot_integrity.log
```

**Network Monitoring**:
```bash
# Active connections
ss -tuln | grep -v "127.0.0.1"

# Unusual traffic patterns
netstat -i | awk 'NR>2 {print $1, $3, $7}'
```

### 3.2 Log Aggregation

**System Logs**: `journalctl` centralized logging
**Security Logs**: `iptables` logging for network events
**Application Logs**: Service-specific log files in `/var/log/`
**Audit Logs**: File system and access logging

## 4. Response Procedures

### 4.1 Initial Response (First 15 Minutes)

1. **Incident Identification**
   - Verify incident authenticity
   - Determine initial severity level
   - Document time of detection

2. **Immediate Containment**
   ```bash
   # Network isolation (if required)
   iptables -I INPUT -j DROP
   iptables -I OUTPUT -j DROP
   
   # Service isolation
   systemctl stop <compromised-service>
   
   # Preserve evidence
   cp -r /var/log/ /tmp/incident-$(date +%Y%m%d-%H%M%S)/
   ```

3. **Notification**
   - Alert security team: security@dynamicdevices.co.uk
   - Notify management for HIGH/CRITICAL incidents
   - Document in incident tracking system

### 4.2 Investigation Phase

1. **Evidence Collection**
   ```bash
   # System state capture
   ps aux > /tmp/processes.log
   netstat -tulpn > /tmp/network.log
   lsof > /tmp/open_files.log
   
   # Log analysis
   journalctl --since "24 hours ago" > /tmp/system_logs.log
   
   # File system analysis
   find / -type f -newer /tmp/incident_start -ls > /tmp/changed_files.log
   ```

2. **Root Cause Analysis**
   - Identify attack vector
   - Determine scope of compromise
   - Assess data/system impact

3. **Risk Assessment**
   - Evaluate ongoing threat
   - Determine business impact
   - Assess regulatory implications

### 4.3 Containment and Eradication

1. **System Isolation**
   - Network segmentation
   - Service shutdown if necessary
   - User access revocation

2. **Threat Removal**
   ```bash
   # Malware removal
   clamav-scan --infected --remove /
   
   # Configuration restoration
   ostree admin deploy <known-good-commit>
   
   # Service restoration
   systemctl restart <affected-services>
   ```

3. **System Hardening**
   - Apply security patches
   - Update firewall rules
   - Strengthen access controls

### 4.4 Recovery Phase

1. **System Restoration**
   ```bash
   # Verify system integrity
   ostree fsck
   
   # Restore from backup if necessary
   ostree admin deploy <backup-commit>
   
   # Service validation
   systemctl status --all
   ```

2. **Monitoring Enhancement**
   - Increase logging levels
   - Deploy additional monitoring
   - Implement specific detection rules

3. **Business Continuity**
   - Restore normal operations
   - Communicate with stakeholders
   - Update incident status

## 5. Communication Plan

### 5.1 Internal Communication

**Security Team**: Immediate notification for all incidents
**Management**: Within 1 hour for HIGH/CRITICAL incidents
**Development Team**: As needed for technical response
**Legal/Compliance**: For incidents with regulatory implications

### 5.2 External Communication

**Customers**: Within 24 hours for incidents affecting their deployments
**Regulatory Bodies**: As required by law (GDPR, CRA reporting requirements)
**Law Enforcement**: For criminal activity
**Third-Party Vendors**: If their systems are involved

### 5.3 Regulatory Reporting

**EU CRA Compliance**: Report significant cybersecurity incidents to relevant authorities within 24 hours
**GDPR Compliance**: Report personal data breaches within 72 hours to supervisory authority
**Sector-Specific Requirements**: Additional reporting as applicable

## 6. Post-Incident Activities

### 6.1 Lessons Learned

1. **Incident Review Meeting** (within 1 week)
   - Timeline reconstruction
   - Response effectiveness assessment
   - Improvement opportunities identification

2. **Documentation Update**
   - Update incident response procedures
   - Revise detection rules
   - Enhance monitoring capabilities

3. **Training Updates**
   - Staff training on new procedures
   - Simulation exercises
   - Knowledge sharing sessions

### 6.2 Continuous Improvement

- **Quarterly Reviews**: Policy and procedure updates
- **Annual Testing**: Full incident response simulation
- **Metrics Tracking**: Response times, detection accuracy, recovery success rates

## 7. Roles and Responsibilities

### 7.1 Incident Response Team

**Incident Commander**: Overall incident management and decision making
**Security Analyst**: Technical investigation and analysis
**System Administrator**: System containment and recovery
**Communications Lead**: Internal and external communications
**Legal/Compliance**: Regulatory requirements and legal implications

### 7.2 Contact Information

**Primary Contacts**:
- Security Team: security@dynamicdevices.co.uk
- Emergency Contact: +44 (0) [REDACTED]
- Management Escalation: ajlennon@dynamicdevices.co.uk

**External Contacts**:
- Legal Counsel: [REDACTED]
- Cyber Insurance: [REDACTED]
- Law Enforcement: 101 (UK non-emergency) / 999 (emergency)

## 8. Tools and Resources

### 8.1 Technical Tools

**Log Analysis**: `journalctl`, `grep`, `awk`, custom scripts
**Network Analysis**: `iptables`, `netstat`, `ss`, `tcpdump`
**System Analysis**: `ps`, `lsof`, `find`, `ostree`
**Forensics**: `dd`, `sha256sum`, evidence preservation scripts

### 8.2 Documentation Templates

- Incident Report Template
- Communication Templates
- Evidence Collection Checklist
- Recovery Verification Checklist

## 9. Training and Awareness

### 9.1 Regular Training

- **Monthly**: Security awareness updates
- **Quarterly**: Incident response procedure review
- **Annually**: Full incident response simulation

### 9.2 Competency Requirements

All incident response team members must demonstrate:
- Understanding of incident classification
- Proficiency with response tools
- Knowledge of communication procedures
- Compliance with legal requirements

## 10. Policy Maintenance

**Review Schedule**: Annual review or after significant incidents
**Update Authority**: Security Team with management approval
**Distribution**: All staff, incident response team, management
**Version Control**: Maintained in company documentation system

---

## Appendices

### Appendix A: Emergency Contact List
[Internal contact details - REDACTED for security]

### Appendix B: System Architecture Diagrams
[Reference to technical documentation]

### Appendix C: Legal and Regulatory Requirements
[Detailed compliance requirements by jurisdiction]

### Appendix D: Incident Report Template
[Standardized incident documentation format]

---

**Document Control**:
- Created: October 2025
- Last Modified: October 2025
- Next Review: October 2026
- Classification: Internal Use Only
