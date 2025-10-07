use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum ProductionTests {
    DefaultPasswordChanged,
    FirewallConfigured,
    FoundriesRegistration,
    SshHardening,
    UserAccountSecurity,
    ServiceMinimization,
    LoggingConfiguration,
    UpdateMechanismActive,
    CertificateManagement,
    ProductionReadiness,
}

#[async_trait]
impl SecurityTest for ProductionTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::DefaultPasswordChanged => self.test_default_password_changed(target).await,
            Self::FirewallConfigured => self.test_firewall_configured(target).await,
            Self::FoundriesRegistration => self.test_foundries_registration(target).await,
            Self::SshHardening => self.test_ssh_hardening(target).await,
            Self::UserAccountSecurity => self.test_user_account_security(target).await,
            Self::ServiceMinimization => self.test_service_minimization(target).await,
            Self::LoggingConfiguration => self.test_logging_configuration(target).await,
            Self::UpdateMechanismActive => self.test_update_mechanism_active(target).await,
            Self::CertificateManagement => self.test_certificate_management(target).await,
            Self::ProductionReadiness => self.test_production_readiness(target).await,
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
            Self::DefaultPasswordChanged => "production_001",
            Self::FirewallConfigured => "production_002",
            Self::FoundriesRegistration => "production_003",
            Self::SshHardening => "production_004",
            Self::UserAccountSecurity => "production_005",
            Self::ServiceMinimization => "production_006",
            Self::LoggingConfiguration => "production_007",
            Self::UpdateMechanismActive => "production_008",
            Self::CertificateManagement => "production_009",
            Self::ProductionReadiness => "production_010",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::DefaultPasswordChanged => "Default Password Changed",
            Self::FirewallConfigured => "Firewall Properly Configured",
            Self::FoundriesRegistration => "Foundries.io Registration",
            Self::SshHardening => "SSH Production Hardening",
            Self::UserAccountSecurity => "User Account Security",
            Self::ServiceMinimization => "Service Minimization",
            Self::LoggingConfiguration => "Production Logging",
            Self::UpdateMechanismActive => "OTA Update Mechanism",
            Self::CertificateManagement => "Certificate Management",
            Self::ProductionReadiness => "Overall Production Readiness",
        }
    }

    fn category(&self) -> &str {
        "production"
    }

    fn description(&self) -> &str {
        match self {
            Self::DefaultPasswordChanged => "Verify default passwords have been changed",
            Self::FirewallConfigured => "Check that firewall rules are properly configured for production",
            Self::FoundriesRegistration => "Verify device is registered with Foundries.io",
            Self::SshHardening => "Check SSH configuration meets production security standards",
            Self::UserAccountSecurity => "Verify user accounts are properly secured for production",
            Self::ServiceMinimization => "Check that only necessary services are running",
            Self::LoggingConfiguration => "Verify production logging is properly configured",
            Self::UpdateMechanismActive => "Check that OTA update mechanism is active and working",
            Self::CertificateManagement => "Verify proper certificate management and rotation",
            Self::ProductionReadiness => "Overall assessment of production readiness",
        }
    }
}

impl ProductionTests {
    async fn test_default_password_changed(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check if we can still login with default credentials
        // This test assumes we're already connected, so we check shadow file timestamps
        let shadow_info = target.execute_command("stat -c '%Y' /etc/shadow 2>/dev/null || echo '0'").await?;
        let passwd_info = target.execute_command("stat -c '%Y' /etc/passwd 2>/dev/null || echo '0'").await?;
        
        // Check for common default users with potential default passwords
        let default_users = target.execute_command("grep -E '^(admin|user|root|fio):' /etc/passwd | cut -d: -f1").await?;
        
        // Check password aging
        let password_aging = target.execute_command("chage -l root 2>/dev/null | grep 'Password expires' || echo 'not_set'").await?;
        
        let shadow_time: u64 = shadow_info.stdout.trim().parse().unwrap_or(0);
        let passwd_time: u64 = passwd_info.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Shadow modified: {}\nPasswd modified: {}\nDefault users: {}\nPassword aging: {}", 
                             shadow_time, passwd_time, default_users.stdout.trim(), password_aging.stdout.trim());
        
        // If shadow file is very old (< 1000000000 = before 2001), likely default
        if shadow_time > 1000000000 && passwd_time > 1000000000 {
            Ok((TestStatus::Passed, "Password files have been modified (likely changed from defaults)".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Password files appear to contain defaults".to_string(), Some(details)))
        }
    }

    async fn test_firewall_configured(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check iptables rules for production configuration
        let iptables_rules = target.execute_command("iptables -L -n --line-numbers").await?;
        let iptables_nat = target.execute_command("iptables -t nat -L -n").await?;
        
        // Check for specific production rules
        let input_policy = target.execute_command("iptables -L INPUT | head -1").await?;
        let rule_count = iptables_rules.stdout.lines().filter(|line| line.contains("ACCEPT") || line.contains("DROP") || line.contains("REJECT")).count();
        
        let details = format!("INPUT policy: {}\nRule count: {}\nRules:\n{}\nNAT rules:\n{}", 
                             input_policy.stdout.trim(), rule_count, iptables_rules.stdout, iptables_nat.stdout);
        
        if input_policy.stdout.contains("DROP") || input_policy.stdout.contains("REJECT") {
            if rule_count >= 5 {
                Ok((TestStatus::Passed, "Firewall is properly configured with restrictive policy".to_string(), Some(details)))
            } else {
                Ok((TestStatus::Warning, "Firewall has restrictive policy but few rules".to_string(), Some(details)))
            }
        } else if rule_count >= 10 {
            Ok((TestStatus::Warning, "Firewall has rules but permissive default policy".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Firewall is not properly configured for production".to_string(), Some(details)))
        }
    }

    async fn test_foundries_registration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check aktualizr-lite status and configuration
        let aktualizr_status = target.execute_command("systemctl is-active aktualizr-lite").await?;
        let aktualizr_config = target.execute_command("cat /var/sota/sota.toml 2>/dev/null | head -10").await?;
        
        // Check device credentials
        let device_cert = target.execute_command("ls -la /var/sota/client.pem 2>/dev/null || echo 'not_found'").await?;
        let device_key = target.execute_command("ls -la /var/sota/pkey.pem 2>/dev/null || echo 'not_found'").await?;
        
        // Check recent OTA activity
        let ota_logs = target.execute_command("journalctl -u aktualizr-lite --since '1 day ago' | tail -5").await?;
        
        let details = format!("Aktualizr status: {}\nDevice cert: {}\nDevice key: {}\nConfig: {}\nRecent logs: {}", 
                             aktualizr_status.stdout.trim(), device_cert.stdout.trim(), device_key.stdout.trim(), 
                             aktualizr_config.stdout, ota_logs.stdout);
        
        if aktualizr_status.stdout.trim() == "active" && !device_cert.stdout.contains("not_found") && !device_key.stdout.contains("not_found") {
            Ok((TestStatus::Passed, "Device is registered with Foundries.io and OTA is active".to_string(), Some(details)))
        } else if aktualizr_status.stdout.trim() == "active" {
            Ok((TestStatus::Warning, "OTA service active but credentials unclear".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Device is not properly registered with Foundries.io".to_string(), Some(details)))
        }
    }

    async fn test_ssh_hardening(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check SSH configuration for production hardening
        let ssh_config = target.execute_command("cat /etc/ssh/sshd_config | grep -E '^[^#]*(PermitRootLogin|PasswordAuthentication|Protocol|Port|MaxAuthTries|ClientAliveInterval)'").await?;
        
        // Check for key-based authentication setup
        let authorized_keys = target.execute_command("find /home -name authorized_keys -exec wc -l {} + 2>/dev/null | tail -1").await?;
        
        // Check SSH key algorithms
        let host_keys = target.execute_command("ls -la /etc/ssh/ssh_host_*key.pub | wc -l").await?;
        
        let mut hardening_score = 0;
        let mut issues = Vec::new();
        let mut good_practices = Vec::new();
        
        if ssh_config.stdout.contains("PermitRootLogin no") {
            hardening_score += 2;
            good_practices.push("Root login disabled");
        } else if ssh_config.stdout.contains("PermitRootLogin") {
            issues.push("Root login may be enabled");
        }
        
        if ssh_config.stdout.contains("PasswordAuthentication no") {
            hardening_score += 2;
            good_practices.push("Password authentication disabled");
        } else {
            issues.push("Password authentication may be enabled");
        }
        
        if ssh_config.stdout.contains("MaxAuthTries") {
            hardening_score += 1;
            good_practices.push("Max auth tries configured");
        }
        
        if ssh_config.stdout.contains("ClientAliveInterval") {
            hardening_score += 1;
            good_practices.push("Client alive interval configured");
        }
        
        let authorized_key_count: usize = authorized_keys.stdout.trim().split_whitespace().last().unwrap_or("0").parse().unwrap_or(0);
        if authorized_key_count > 0 {
            hardening_score += 1;
            good_practices.push("SSH keys configured");
        }
        
        let details = format!("SSH config:\n{}\nAuthorized keys: {}\nHost keys: {}\nGood practices: {:?}\nIssues: {:?}", 
                             ssh_config.stdout, authorized_key_count, host_keys.stdout.trim(), good_practices, issues);
        
        if hardening_score >= 5 && issues.is_empty() {
            Ok((TestStatus::Passed, format!("SSH is properly hardened (score: {}/6)", hardening_score), Some(details)))
        } else if hardening_score >= 3 {
            Ok((TestStatus::Warning, format!("SSH partially hardened (score: {}/6)", hardening_score), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("SSH is not properly hardened (score: {}/6)", hardening_score), Some(details)))
        }
    }

    async fn test_user_account_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check user account security for production
        let user_accounts = target.execute_command("cat /etc/passwd | grep -E '/bin/(bash|sh)$' | cut -d: -f1,3,7").await?;
        let locked_accounts = target.execute_command("passwd -S -a 2>/dev/null | grep -E 'L|NP' | wc -l").await?;
        let sudo_users = target.execute_command("grep -E '^%sudo|^%wheel' /etc/group 2>/dev/null || echo 'not_found'").await?;
        
        // Check password policies
        let password_policy = target.execute_command("cat /etc/login.defs | grep -E 'PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE' | grep -v '^#'").await?;
        
        let shell_users: Vec<&str> = user_accounts.stdout.lines().collect();
        let locked_count: usize = locked_accounts.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Shell users ({}):\n{}\nLocked accounts: {}\nSudo config: {}\nPassword policy:\n{}", 
                             shell_users.len(), user_accounts.stdout, locked_count, sudo_users.stdout, password_policy.stdout);
        
        if shell_users.len() <= 3 && locked_count > 0 && !password_policy.stdout.is_empty() {
            Ok((TestStatus::Passed, "User account security is properly configured".to_string(), Some(details)))
        } else if shell_users.len() <= 5 {
            Ok((TestStatus::Warning, "User account security needs improvement".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Too many user accounts or insufficient security".to_string(), Some(details)))
        }
    }

    async fn test_service_minimization(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check that only necessary services are running
        let running_services = target.execute_command("systemctl list-units --type=service --state=running --no-pager | grep -v '@' | wc -l").await?;
        let enabled_services = target.execute_command("systemctl list-unit-files --type=service --state=enabled --no-pager | wc -l").await?;
        
        // Check for potentially unnecessary services
        let risky_services = ["telnet", "ftp", "rsh", "rlogin", "tftp", "cups", "avahi-daemon", "bluetooth"];
        let mut found_risky = Vec::new();
        
        for service in &risky_services {
            let check = target.execute_command(&format!("systemctl is-active {} 2>/dev/null", service)).await?;
            if check.stdout.trim() == "active" {
                found_risky.push(*service);
            }
        }
        
        // List actual running services
        let service_list = target.execute_command("systemctl list-units --type=service --state=running --no-pager | grep -v '@' | awk '{print $1}' | head -20").await?;
        
        let running_count: usize = running_services.stdout.trim().parse().unwrap_or(0);
        let enabled_count: usize = enabled_services.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Running services: {}\nEnabled services: {}\nRisky services found: {:?}\nService list:\n{}", 
                             running_count, enabled_count, found_risky, service_list.stdout);
        
        if found_risky.is_empty() && running_count <= 15 {
            Ok((TestStatus::Passed, "Service minimization is good".to_string(), Some(details)))
        } else if found_risky.len() <= 1 && running_count <= 25 {
            Ok((TestStatus::Warning, "Some service optimization needed".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Too many services running or risky services found".to_string(), Some(details)))
        }
    }

    async fn test_logging_configuration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check production logging configuration
        let syslog_status = target.execute_command("systemctl is-active rsyslog 2>/dev/null || systemctl is-active syslog-ng 2>/dev/null || echo 'inactive'").await?;
        let journal_config = target.execute_command("cat /etc/systemd/journald.conf | grep -E '^[^#]*(Storage|Compress|MaxRetentionSec)' || echo 'default'").await?;
        
        // Check log rotation
        let logrotate_config = target.execute_command("ls /etc/logrotate.d/ | wc -l").await?;
        
        // Check for remote logging
        let remote_logging = target.execute_command("cat /etc/rsyslog.conf 2>/dev/null | grep -E '@.*:514|@@.*:514' || echo 'not_configured'").await?;
        
        // Check log file sizes and permissions
        let log_permissions = target.execute_command("ls -la /var/log/ | grep -E '\\.log$' | head -5").await?;
        
        let logrotate_count: usize = logrotate_config.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Syslog status: {}\nJournal config: {}\nLogrotate configs: {}\nRemote logging: {}\nLog permissions:\n{}", 
                             syslog_status.stdout.trim(), journal_config.stdout, logrotate_count, 
                             remote_logging.stdout.trim(), log_permissions.stdout);
        
        if syslog_status.stdout.trim() == "active" && logrotate_count > 5 && !remote_logging.stdout.contains("not_configured") {
            Ok((TestStatus::Passed, "Production logging is properly configured".to_string(), Some(details)))
        } else if syslog_status.stdout.trim() == "active" && logrotate_count > 3 {
            Ok((TestStatus::Warning, "Basic logging configured but could be improved".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Logging is not properly configured for production".to_string(), Some(details)))
        }
    }

    async fn test_update_mechanism_active(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check OTA update mechanism is working
        let aktualizr_status = target.execute_command("systemctl is-active aktualizr-lite").await?;
        let last_update_check = target.execute_command("journalctl -u aktualizr-lite --since '24 hours ago' | grep -E 'Checking for updates|Update available|No updates' | tail -1").await?;
        
        // Check OSTree status
        let ostree_status = target.execute_command("ostree admin status | head -5").await?;
        
        // Check update configuration
        let update_config = target.execute_command("cat /var/sota/sota.toml 2>/dev/null | grep -E 'server|polling_sec' | head -3").await?;
        
        let details = format!("Aktualizr status: {}\nLast update check: {}\nOSTree status:\n{}\nUpdate config: {}", 
                             aktualizr_status.stdout.trim(), last_update_check.stdout.trim(), ostree_status.stdout, update_config.stdout);
        
        if aktualizr_status.stdout.trim() == "active" && !last_update_check.stdout.is_empty() {
            Ok((TestStatus::Passed, "OTA update mechanism is active and working".to_string(), Some(details)))
        } else if aktualizr_status.stdout.trim() == "active" {
            Ok((TestStatus::Warning, "OTA service active but no recent update checks".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "OTA update mechanism is not active".to_string(), Some(details)))
        }
    }

    async fn test_certificate_management(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check certificate management
        let ssl_certs = target.execute_command("find /etc/ssl/certs -name '*.pem' | wc -l").await?;
        let ca_bundle = target.execute_command("ls -la /etc/ssl/certs/ca-certificates.crt 2>/dev/null || echo 'not_found'").await?;
        
        // Check device certificates
        let device_certs = target.execute_command("find /var/sota -name '*.pem' -o -name '*.crt' | head -5").await?;
        
        // Check certificate expiration (if openssl available)
        let cert_check = target.execute_command("openssl version 2>/dev/null && echo 'available' || echo 'not_available'").await?;
        
        let ssl_count: usize = ssl_certs.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("SSL certificates: {}\nCA bundle: {}\nDevice certificates:\n{}\nOpenSSL: {}", 
                             ssl_count, ca_bundle.stdout.trim(), device_certs.stdout, cert_check.stdout.trim());
        
        if ssl_count > 100 && !ca_bundle.stdout.contains("not_found") && !device_certs.stdout.is_empty() {
            Ok((TestStatus::Passed, "Certificate management is properly configured".to_string(), Some(details)))
        } else if ssl_count > 50 {
            Ok((TestStatus::Warning, "Basic certificate management present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Certificate management is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_production_readiness(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Overall production readiness assessment
        let mut readiness_score = 0;
        let mut readiness_items = Vec::new();
        let mut issues = Vec::new();
        
        // Check system uptime (should be reasonable for production)
        let uptime = target.execute_command("uptime -p").await?;
        if uptime.stdout.contains("day") {
            readiness_score += 1;
            readiness_items.push("System uptime stable");
        }
        
        // Check disk space
        let disk_space = target.execute_command("df -h / | tail -1 | awk '{print $5}' | sed 's/%//'").await?;
        let disk_usage: u32 = disk_space.stdout.trim().parse().unwrap_or(100);
        if disk_usage < 80 {
            readiness_score += 1;
            readiness_items.push("Disk space adequate");
        } else {
            issues.push("Disk space high");
        }
        
        // Check memory usage
        let memory = target.execute_command("free | grep Mem | awk '{printf \"%.0f\", $3/$2 * 100.0}'").await?;
        let mem_usage: u32 = memory.stdout.trim().parse().unwrap_or(100);
        if mem_usage < 80 {
            readiness_score += 1;
            readiness_items.push("Memory usage reasonable");
        } else {
            issues.push("Memory usage high");
        }
        
        // Check load average
        let load_avg = target.execute_command("uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'").await?;
        let load: f32 = load_avg.stdout.trim().parse().unwrap_or(10.0);
        if load < 2.0 {
            readiness_score += 1;
            readiness_items.push("System load reasonable");
        } else {
            issues.push("System load high");
        }
        
        // Check for core dumps
        let core_dumps = target.execute_command("find /var/crash /tmp -name 'core*' -o -name '*.core' 2>/dev/null | wc -l").await?;
        let core_count: u32 = core_dumps.stdout.trim().parse().unwrap_or(0);
        if core_count == 0 {
            readiness_score += 1;
            readiness_items.push("No core dumps found");
        } else {
            issues.push("Core dumps present");
        }
        
        let details = format!("Uptime: {}\nDisk usage: {}%\nMemory usage: {}%\nLoad average: {}\nCore dumps: {}\nReadiness items: {:?}\nIssues: {:?}", 
                             uptime.stdout.trim(), disk_usage, mem_usage, load, core_count, readiness_items, issues);
        
        if readiness_score >= 4 && issues.is_empty() {
            Ok((TestStatus::Passed, format!("System is production ready (score: {}/5)", readiness_score), Some(details)))
        } else if readiness_score >= 3 {
            Ok((TestStatus::Warning, format!("System mostly production ready (score: {}/5)", readiness_score), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("System is not production ready (score: {}/5)", readiness_score), Some(details)))
        }
    }
}
