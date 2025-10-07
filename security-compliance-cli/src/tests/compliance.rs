use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum ComplianceTests {
    CraDataProtection,
    CraVulnerabilityManagement,
    RedSecurityRequirements,
    IncidentResponse,
    AuditLogging,
}

#[async_trait]
impl SecurityTest for ComplianceTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::CraDataProtection => self.test_cra_data_protection(target).await,
            Self::CraVulnerabilityManagement => self.test_cra_vulnerability_management(target).await,
            Self::RedSecurityRequirements => self.test_red_security_requirements(target).await,
            Self::IncidentResponse => self.test_incident_response(target).await,
            Self::AuditLogging => self.test_audit_logging(target).await,
        };

        let duration = start_time.elapsed();
        
        match result {
            Ok((status, message, details)) => Ok(create_test_result(
                self.test_id(),
                self.test_name(),
                self.category(),
                status,
                &message,
                details,
                duration,
            )),
            Err(e) => Ok(create_test_result(
                self.test_id(),
                self.test_name(),
                self.category(),
                TestStatus::Error,
                &format!("Test execution failed: {}", e),
                None,
                duration,
            )),
        }
    }

    fn test_id(&self) -> &str {
        match self {
            Self::CraDataProtection => "compliance_001",
            Self::CraVulnerabilityManagement => "compliance_002",
            Self::RedSecurityRequirements => "compliance_003",
            Self::IncidentResponse => "compliance_004",
            Self::AuditLogging => "compliance_005",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::CraDataProtection => "CRA Data Protection (Article 11)",
            Self::CraVulnerabilityManagement => "CRA Vulnerability Management",
            Self::RedSecurityRequirements => "RED Security Requirements (3.3)",
            Self::IncidentResponse => "Incident Response Capability",
            Self::AuditLogging => "Security Audit Logging",
        }
    }

    fn category(&self) -> &str {
        "compliance"
    }

    fn description(&self) -> &str {
        match self {
            Self::CraDataProtection => "Verify EU CRA Article 11 data protection requirements",
            Self::CraVulnerabilityManagement => "Check CRA vulnerability handling and patching",
            Self::RedSecurityRequirements => "Verify UK CE RED Essential Requirements 3.3",
            Self::IncidentResponse => "Check incident response and reporting capabilities",
            Self::AuditLogging => "Verify security event logging and audit trails",
        }
    }
}

impl ComplianceTests {
    async fn test_cra_data_protection(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // CRA Article 11 requires data protection by design and by default
        let mut compliance_items = Vec::new();
        let mut details = Vec::new();
        
        // Check filesystem encryption (required for data at rest)
        let luks_check = target.execute_command("lsblk -f | grep -i luks").await?;
        if luks_check.stdout.contains("crypto_LUKS") {
            compliance_items.push("Data at rest encryption (LUKS)");
        }
        details.push(format!("LUKS encryption: {}", !luks_check.stdout.is_empty()));
        
        // Check secure communications (TLS)
        let tls_check = target.execute_command("openssl version 2>/dev/null || echo 'not_available'").await?;
        if !tls_check.stdout.contains("not_available") {
            compliance_items.push("Secure communications (TLS)");
        }
        details.push(format!("TLS support: {}", tls_check.stdout.trim()));
        
        // Check access controls
        let access_control = target.execute_command("ls -la /etc/passwd /etc/shadow | grep -E '^-r--------'").await?;
        if !access_control.stdout.is_empty() {
            compliance_items.push("Access controls");
        }
        details.push(format!("Access controls: {}", !access_control.stdout.is_empty()));
        
        // Check secure boot (integrity protection)
        let secure_boot = target.execute_command("dmesg | grep -i 'ahab\\|secure.*boot'").await?;
        if secure_boot.stdout.contains("AHAB") {
            compliance_items.push("Boot integrity (AHAB)");
        }
        details.push(format!("Secure boot: {}", secure_boot.stdout.contains("AHAB")));
        
        let compliance_score = compliance_items.len();
        let details_str = format!("CRA Article 11 compliance items: {:?}\n{}", compliance_items, details.join("\n"));
        
        if compliance_score >= 3 {
            Ok((TestStatus::Passed, format!("CRA data protection compliant ({}/4 items)", compliance_score), Some(details_str)))
        } else if compliance_score >= 2 {
            Ok((TestStatus::Warning, format!("Partial CRA compliance ({}/4 items)", compliance_score), Some(details_str)))
        } else {
            Ok((TestStatus::Failed, format!("CRA non-compliant ({}/4 items)", compliance_score), Some(details_str)))
        }
    }

    async fn test_cra_vulnerability_management(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for update mechanisms
        let ostree_check = target.execute_command("ostree admin status 2>/dev/null || echo 'not_available'").await?;
        let aktualizr_check = target.execute_command("systemctl is-active aktualizr-lite 2>/dev/null || echo 'not_active'").await?;
        
        // Check for vulnerability scanning tools
        let vuln_tools = target.execute_command("which nmap 2>/dev/null || which lynis 2>/dev/null || echo 'none'").await?;
        
        // Check system update status
        let last_update = target.execute_command("stat -c %Y /var/lib/rpm/rpmdb.sqlite 2>/dev/null || stat -c %Y /var/lib/dpkg/status 2>/dev/null || echo '0'").await?;
        
        let mut compliance_features = Vec::new();
        
        if !ostree_check.stdout.contains("not_available") {
            compliance_features.push("OSTree updates");
        }
        
        if aktualizr_check.stdout.trim() == "active" {
            compliance_features.push("OTA service");
        }
        
        if !vuln_tools.stdout.contains("none") {
            compliance_features.push("Vulnerability tools");
        }
        
        let details = format!("Update mechanism: {:?}\nOTA status: {}\nVuln tools: {}\nLast update: {}", 
                             compliance_features, aktualizr_check.stdout.trim(), vuln_tools.stdout.trim(), last_update.stdout.trim());
        
        if compliance_features.len() >= 2 {
            Ok((TestStatus::Passed, "CRA vulnerability management capable".to_string(), Some(details)))
        } else if compliance_features.len() >= 1 {
            Ok((TestStatus::Warning, "Limited vulnerability management".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No vulnerability management detected".to_string(), Some(details)))
        }
    }

    async fn test_red_security_requirements(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // RED Essential Requirements 3.3 - Security measures
        let mut security_measures = Vec::new();
        let mut details = Vec::new();
        
        // Check encryption
        let encryption = target.execute_command("lsblk -f | grep -i luks").await?;
        if !encryption.stdout.is_empty() {
            security_measures.push("Encryption");
        }
        details.push(format!("Encryption: {}", !encryption.stdout.is_empty()));
        
        // Check authentication
        let auth_check = target.execute_command("cat /etc/pam.d/common-auth 2>/dev/null | grep -v '^#' | head -3").await?;
        if !auth_check.stdout.is_empty() {
            security_measures.push("Authentication");
        }
        details.push(format!("Authentication configured: {}", !auth_check.stdout.is_empty()));
        
        // Check access control
        let access_check = target.execute_command("getfacl /etc/shadow 2>/dev/null | grep -E 'user::|group::'").await?;
        if !access_check.stdout.is_empty() {
            security_measures.push("Access Control");
        }
        details.push(format!("Access control: configured"));
        
        // Check secure communications
        let secure_comm = target.execute_command("netstat -tuln | grep ':22\\|:443\\|:993'").await?;
        if !secure_comm.stdout.is_empty() {
            security_measures.push("Secure Communications");
        }
        details.push(format!("Secure ports: {}", secure_comm.stdout.lines().count()));
        
        let measure_count = security_measures.len();
        let details_str = format!("RED 3.3 security measures: {:?}\n{}", security_measures, details.join("\n"));
        
        if measure_count >= 3 {
            Ok((TestStatus::Passed, format!("RED security compliant ({}/4 measures)", measure_count), Some(details_str)))
        } else if measure_count >= 2 {
            Ok((TestStatus::Warning, format!("Partial RED compliance ({}/4 measures)", measure_count), Some(details_str)))
        } else {
            Ok((TestStatus::Failed, format!("RED non-compliant ({}/4 measures)", measure_count), Some(details_str)))
        }
    }

    async fn test_incident_response(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for incident response capabilities
        let syslog_check = target.execute_command("systemctl is-active rsyslog 2>/dev/null || systemctl is-active syslog-ng 2>/dev/null || echo 'not_active'").await?;
        
        // Check for monitoring tools
        let monitoring = target.execute_command("which journalctl 2>/dev/null && echo 'systemd-journal' || echo 'no_journal'").await?;
        
        // Check for network monitoring
        let netmon = target.execute_command("which tcpdump 2>/dev/null || which netstat 2>/dev/null || echo 'no_netmon'").await?;
        
        // Check for incident response scripts/tools
        let incident_tools = target.execute_command("find /usr/local/bin /opt -name '*incident*' -o -name '*response*' 2>/dev/null | wc -l").await?;
        
        let mut capabilities = Vec::new();
        
        if syslog_check.stdout.trim() == "active" {
            capabilities.push("System logging");
        }
        
        if monitoring.stdout.contains("systemd-journal") {
            capabilities.push("Event monitoring");
        }
        
        if !netmon.stdout.contains("no_netmon") {
            capabilities.push("Network monitoring");
        }
        
        let tool_count: usize = incident_tools.stdout.trim().parse().unwrap_or(0);
        if tool_count > 0 {
            capabilities.push("Incident tools");
        }
        
        let details = format!("Logging: {}\nMonitoring: {}\nNetwork tools: {}\nIncident tools: {}", 
                             syslog_check.stdout.trim(), monitoring.stdout.contains("systemd-journal"), 
                             !netmon.stdout.contains("no_netmon"), tool_count);
        
        if capabilities.len() >= 3 {
            Ok((TestStatus::Passed, "Incident response capability good".to_string(), Some(details)))
        } else if capabilities.len() >= 2 {
            Ok((TestStatus::Warning, "Basic incident response capability".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Limited incident response capability".to_string(), Some(details)))
        }
    }

    async fn test_audit_logging(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check audit logging capabilities
        let auditd = target.execute_command("systemctl is-active auditd 2>/dev/null || echo 'not_active'").await?;
        
        // Check journal logging
        let journal_size = target.execute_command("journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[KMGT]B' || echo '0B'").await?;
        
        // Check log rotation
        let logrotate = target.execute_command("ls -la /etc/logrotate.d/ | wc -l").await?;
        
        // Check security-related logs
        let security_logs = target.execute_command("journalctl --since='1 hour ago' | grep -i 'security\\|auth\\|fail' | wc -l").await?;
        
        let mut audit_features = Vec::new();
        
        if auditd.stdout.trim() == "active" {
            audit_features.push("auditd");
        }
        
        if !journal_size.stdout.contains("0B") {
            audit_features.push("systemd-journal");
        }
        
        let logrotate_configs: usize = logrotate.stdout.trim().parse().unwrap_or(0);
        if logrotate_configs > 2 {
            audit_features.push("log rotation");
        }
        
        let security_events: usize = security_logs.stdout.trim().parse().unwrap_or(0);
        if security_events > 0 {
            audit_features.push("security events");
        }
        
        let details = format!("Audit daemon: {}\nJournal size: {}\nLogrotate configs: {}\nSecurity events (1h): {}", 
                             auditd.stdout.trim(), journal_size.stdout.trim(), logrotate_configs, security_events);
        
        if audit_features.len() >= 3 {
            Ok((TestStatus::Passed, format!("Audit logging comprehensive: {:?}", audit_features), Some(details)))
        } else if audit_features.len() >= 2 {
            Ok((TestStatus::Warning, format!("Basic audit logging: {:?}", audit_features), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Insufficient audit logging".to_string(), Some(details)))
        }
    }
}
