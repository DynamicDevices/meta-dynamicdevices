use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum TimeSyncTests {
    NtpConfiguration,
    SystemTimeAccuracy,
    TimeSourceValidation,
    SecureTimeProtocols,
    TimeSynchronizationSecurity,
    ChronoSecurity,
    TimeZoneConfiguration,
    SystemClockProtection,
    NetworkTimeProtocols,
    TimeAuditTrail,
}

#[async_trait]
impl SecurityTest for TimeSyncTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::NtpConfiguration => self.test_ntp_configuration(target).await,
            Self::SystemTimeAccuracy => self.test_system_time_accuracy(target).await,
            Self::TimeSourceValidation => self.test_time_source_validation(target).await,
            Self::SecureTimeProtocols => self.test_secure_time_protocols(target).await,
            Self::TimeSynchronizationSecurity => self.test_time_synchronization_security(target).await,
            Self::ChronoSecurity => self.test_chrono_security(target).await,
            Self::TimeZoneConfiguration => self.test_timezone_configuration(target).await,
            Self::SystemClockProtection => self.test_system_clock_protection(target).await,
            Self::NetworkTimeProtocols => self.test_network_time_protocols(target).await,
            Self::TimeAuditTrail => self.test_time_audit_trail(target).await,
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
            Self::NtpConfiguration => "timesync_001",
            Self::SystemTimeAccuracy => "timesync_002",
            Self::TimeSourceValidation => "timesync_003",
            Self::SecureTimeProtocols => "timesync_004",
            Self::TimeSynchronizationSecurity => "timesync_005",
            Self::ChronoSecurity => "timesync_006",
            Self::TimeZoneConfiguration => "timesync_007",
            Self::SystemClockProtection => "timesync_008",
            Self::NetworkTimeProtocols => "timesync_009",
            Self::TimeAuditTrail => "timesync_010",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::NtpConfiguration => "NTP Configuration",
            Self::SystemTimeAccuracy => "System Time Accuracy",
            Self::TimeSourceValidation => "Time Source Validation",
            Self::SecureTimeProtocols => "Secure Time Protocols",
            Self::TimeSynchronizationSecurity => "Time Synchronization Security",
            Self::ChronoSecurity => "Chrono Security",
            Self::TimeZoneConfiguration => "Time Zone Configuration",
            Self::SystemClockProtection => "System Clock Protection",
            Self::NetworkTimeProtocols => "Network Time Protocols",
            Self::TimeAuditTrail => "Time Audit Trail",
        }
    }

    fn category(&self) -> &str {
        "timesync"
    }

    fn description(&self) -> &str {
        match self {
            Self::NtpConfiguration => "Verify NTP daemon configuration and security",
            Self::SystemTimeAccuracy => "Check system time accuracy and drift",
            Self::TimeSourceValidation => "Validate time source authenticity",
            Self::SecureTimeProtocols => "Check secure time synchronization protocols",
            Self::TimeSynchronizationSecurity => "Verify time sync security measures",
            Self::ChronoSecurity => "Check chronometer and time security",
            Self::TimeZoneConfiguration => "Verify time zone configuration security",
            Self::SystemClockProtection => "Check system clock protection mechanisms",
            Self::NetworkTimeProtocols => "Verify network time protocol security",
            Self::TimeAuditTrail => "Check time-related audit trails",
        }
    }
}

impl TimeSyncTests {
    async fn test_ntp_configuration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check NTP daemon status
        let ntp_status = target.execute_command("systemctl is-active ntp 2>/dev/null || systemctl is-active ntpd 2>/dev/null || systemctl is-active chronyd 2>/dev/null || echo 'no_ntp'").await?;
        
        // Check NTP configuration
        let ntp_config = target.execute_command("cat /etc/ntp.conf 2>/dev/null || cat /etc/chrony/chrony.conf 2>/dev/null || cat /etc/chrony.conf 2>/dev/null || echo 'no_config'").await?;
        
        // Check NTP servers
        let ntp_servers = target.execute_command("ntpq -p 2>/dev/null || chronyc sources 2>/dev/null || echo 'no_servers'").await?;
        
        // Check NTP authentication
        let ntp_auth = target.execute_command("grep -E 'key|auth' /etc/ntp.conf 2>/dev/null || grep -E 'key|auth' /etc/chrony.conf 2>/dev/null || echo 'no_auth'").await?;
        
        let mut ntp_features = Vec::new();
        let mut ntp_issues = Vec::new();
        
        if !ntp_status.stdout.contains("no_ntp") && ntp_status.stdout.contains("active") {
            ntp_features.push("NTP daemon active");
        } else {
            ntp_issues.push("No active NTP daemon");
        }
        
        if !ntp_config.stdout.contains("no_config") {
            ntp_features.push("NTP configuration present");
        }
        
        if !ntp_servers.stdout.contains("no_servers") && ntp_servers.stdout.lines().count() > 1 {
            ntp_features.push("Multiple NTP servers configured");
        }
        
        if !ntp_auth.stdout.contains("no_auth") {
            ntp_features.push("NTP authentication configured");
        }
        
        let details = format!("NTP status: {}\nConfig: {}\nServers: {}\nAuth: {}\nFeatures: {:?}\nIssues: {:?}", 
                             ntp_status.stdout.trim(), ntp_config.stdout, ntp_servers.stdout, 
                             ntp_auth.stdout, ntp_features, ntp_issues);
        
        if ntp_features.len() >= 3 && ntp_issues.is_empty() {
            Ok((TestStatus::Passed, "NTP configuration is secure and complete".to_string(), Some(details)))
        } else if ntp_features.len() >= 2 {
            Ok((TestStatus::Warning, "NTP configuration is basic but functional".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "NTP configuration is insufficient or missing".to_string(), Some(details)))
        }
    }

    async fn test_system_time_accuracy(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Get system time
        let system_time = target.execute_command("date '+%s'").await?;
        let system_time_readable = target.execute_command("date").await?;
        
        // Get hardware clock
        let hw_clock = target.execute_command("hwclock --show 2>/dev/null || echo 'hwclock_unavailable'").await?;
        
        // Check time synchronization status
        let sync_status = target.execute_command("timedatectl status 2>/dev/null || echo 'timedatectl_unavailable'").await?;
        
        // Check NTP synchronization
        let ntp_sync = target.execute_command("ntpstat 2>/dev/null || chronyc tracking 2>/dev/null || echo 'sync_unavailable'").await?;
        
        // Get current epoch time for comparison (basic check)
        let current_epoch = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let system_epoch: u64 = system_time.stdout.trim().parse().unwrap_or(0);
        let time_diff = if current_epoch > system_epoch {
            current_epoch - system_epoch
        } else {
            system_epoch - current_epoch
        };
        
        let mut time_features = Vec::new();
        let mut time_issues = Vec::new();
        
        if time_diff < 300 { // Within 5 minutes
            time_features.push("System time reasonably accurate");
        } else {
            time_issues.push(format!("System time drift: {} seconds", time_diff));
        }
        
        if sync_status.stdout.contains("synchronized: yes") || sync_status.stdout.contains("NTP enabled") {
            time_features.push("Time synchronization active");
        }
        
        if ntp_sync.stdout.contains("synchronised") || ntp_sync.stdout.contains("System time") {
            time_features.push("NTP synchronization working");
        }
        
        if !hw_clock.stdout.contains("hwclock_unavailable") {
            time_features.push("Hardware clock available");
        }
        
        let details = format!("System time: {} ({})\nHW clock: {}\nSync status: {}\nNTP sync: {}\nTime diff: {}s\nFeatures: {:?}\nIssues: {:?}", 
                             system_epoch, system_time_readable.stdout.trim(), hw_clock.stdout, 
                             sync_status.stdout, ntp_sync.stdout, time_diff, time_features, time_issues);
        
        if time_features.len() >= 3 && time_issues.is_empty() {
            Ok((TestStatus::Passed, "System time accuracy is excellent".to_string(), Some(details)))
        } else if time_features.len() >= 2 && time_diff < 3600 {
            Ok((TestStatus::Warning, "System time accuracy is acceptable".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "System time accuracy is poor".to_string(), Some(details)))
        }
    }

    async fn test_time_source_validation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check configured time sources
        let time_sources = target.execute_command("grep -E '^server|^pool' /etc/ntp.conf 2>/dev/null || grep -E '^server|^pool' /etc/chrony.conf 2>/dev/null || echo 'no_sources'").await?;
        
        // Check time source reachability
        let source_reach = target.execute_command("ntpq -p 2>/dev/null | grep -E '\\*|\\+|o' || chronyc sources 2>/dev/null | grep -E '\\^\\*|\\^\\+' || echo 'no_reachable'").await?;
        
        // Check for secure time sources (NTS, authenticated NTP)
        let secure_sources = target.execute_command("grep -i nts /etc/chrony.conf 2>/dev/null || grep -i 'key\\|auth' /etc/ntp.conf 2>/dev/null || echo 'no_secure'").await?;
        
        // Check time source diversity
        let source_count = time_sources.stdout.lines().filter(|line| !line.trim().is_empty()).count();
        
        let mut validation_features = Vec::new();
        let mut validation_issues = Vec::new();
        
        if source_count >= 3 {
            validation_features.push("Multiple time sources configured");
        } else if source_count >= 1 {
            validation_features.push("Basic time source configured");
        } else {
            validation_issues.push("No time sources configured");
        }
        
        if !source_reach.stdout.contains("no_reachable") {
            validation_features.push("Time sources reachable");
        } else {
            validation_issues.push("No reachable time sources");
        }
        
        if !secure_sources.stdout.contains("no_secure") {
            validation_features.push("Secure time sources configured");
        } else {
            validation_issues.push("No secure time authentication");
        }
        
        // Check for well-known secure time servers
        if time_sources.stdout.contains("pool.ntp.org") || time_sources.stdout.contains("time.cloudflare.com") {
            validation_features.push("Reputable time sources");
        }
        
        let details = format!("Time sources: {}\nReachability: {}\nSecure sources: {}\nSource count: {}\nFeatures: {:?}\nIssues: {:?}", 
                             time_sources.stdout, source_reach.stdout, secure_sources.stdout, source_count, 
                             validation_features, validation_issues);
        
        if validation_features.len() >= 3 && validation_issues.is_empty() {
            Ok((TestStatus::Passed, "Time source validation is comprehensive".to_string(), Some(details)))
        } else if validation_features.len() >= 2 && validation_issues.len() <= 1 {
            Ok((TestStatus::Warning, "Time source validation is adequate".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Time source validation is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_secure_time_protocols(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for NTS (Network Time Security) support
        let nts_support = target.execute_command("chronyc sources -v 2>/dev/null | grep -i nts || echo 'no_nts'").await?;
        
        // Check for authenticated NTP
        let auth_ntp = target.execute_command("grep -E 'keys|trustedkey|requestkey' /etc/ntp.conf 2>/dev/null || echo 'no_auth_ntp'").await?;
        
        // Check for secure time protocols in chrony
        let chrony_security = target.execute_command("grep -E 'nts|authselectmode' /etc/chrony.conf 2>/dev/null || echo 'no_chrony_security'").await?;
        
        // Check for certificate validation
        let cert_validation = target.execute_command("grep -E 'ntscert|ntsca' /etc/chrony.conf 2>/dev/null || echo 'no_cert_validation'").await?;
        
        // Check for time protocol encryption
        let protocol_encryption = target.execute_command("netstat -tulpn 2>/dev/null | grep -E ':123|:4460' | grep -v '127.0.0.1' || echo 'no_encrypted_time'").await?;
        
        let mut security_features = Vec::new();
        
        if !nts_support.stdout.contains("no_nts") {
            security_features.push("NTS (Network Time Security) active");
        }
        
        if !auth_ntp.stdout.contains("no_auth_ntp") {
            security_features.push("Authenticated NTP configured");
        }
        
        if !chrony_security.stdout.contains("no_chrony_security") {
            security_features.push("Chrony security features enabled");
        }
        
        if !cert_validation.stdout.contains("no_cert_validation") {
            security_features.push("Certificate validation configured");
        }
        
        if protocol_encryption.stdout.contains(":4460") {
            security_features.push("Encrypted time protocol detected");
        }
        
        let details = format!("NTS support: {}\nAuth NTP: {}\nChrony security: {}\nCert validation: {}\nProtocol encryption: {}\nFeatures: {:?}", 
                             nts_support.stdout, auth_ntp.stdout, chrony_security.stdout, cert_validation.stdout, 
                             protocol_encryption.stdout, security_features);
        
        if security_features.len() >= 3 {
            Ok((TestStatus::Passed, "Secure time protocols are comprehensively configured".to_string(), Some(details)))
        } else if security_features.len() >= 2 {
            Ok((TestStatus::Warning, "Some secure time protocols are configured".to_string(), Some(details)))
        } else if security_features.len() >= 1 {
            Ok((TestStatus::Warning, "Basic secure time protocol features present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No secure time protocols detected".to_string(), Some(details)))
        }
    }

    async fn test_time_synchronization_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check time sync access controls
        let access_controls = target.execute_command("grep -E 'restrict|allow|deny' /etc/ntp.conf 2>/dev/null || grep -E 'allow|deny' /etc/chrony.conf 2>/dev/null || echo 'no_access_controls'").await?;
        
        // Check time daemon security options
        let daemon_security = target.execute_command("ps aux | grep -E 'ntpd|chronyd' | grep -v grep || echo 'no_daemon'").await?;
        
        // Check for time-based attack protections
        let attack_protection = target.execute_command("grep -E 'maxpoll|minpoll|burst|iburst' /etc/ntp.conf /etc/chrony.conf 2>/dev/null || echo 'no_protection'").await?;
        
        // Check time sync firewall rules
        let firewall_rules = target.execute_command("iptables -L -n 2>/dev/null | grep -E ':123|ntp' || echo 'no_firewall_rules'").await?;
        
        // Check for time sync logging
        let sync_logging = target.execute_command("grep -E 'log|statistics' /etc/chrony.conf /etc/ntp.conf 2>/dev/null || echo 'no_logging'").await?;
        
        let mut security_measures = Vec::new();
        let mut security_issues = Vec::new();
        
        if !access_controls.stdout.contains("no_access_controls") {
            security_measures.push("Access controls configured");
        } else {
            security_issues.push("No access controls for time sync");
        }
        
        if daemon_security.stdout.contains("ntpd") || daemon_security.stdout.contains("chronyd") {
            security_measures.push("Time daemon running");
        }
        
        if !attack_protection.stdout.contains("no_protection") {
            security_measures.push("Attack protection configured");
        }
        
        if !firewall_rules.stdout.contains("no_firewall_rules") {
            security_measures.push("Firewall rules for time sync");
        }
        
        if !sync_logging.stdout.contains("no_logging") {
            security_measures.push("Time sync logging enabled");
        }
        
        let details = format!("Access controls: {}\nDaemon security: {}\nAttack protection: {}\nFirewall rules: {}\nLogging: {}\nMeasures: {:?}\nIssues: {:?}", 
                             access_controls.stdout, daemon_security.stdout, attack_protection.stdout, 
                             firewall_rules.stdout, sync_logging.stdout, security_measures, security_issues);
        
        if security_measures.len() >= 4 && security_issues.is_empty() {
            Ok((TestStatus::Passed, "Time synchronization security is comprehensive".to_string(), Some(details)))
        } else if security_measures.len() >= 3 {
            Ok((TestStatus::Warning, "Time synchronization security is adequate".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Time synchronization security is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_chrono_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check chronyd configuration security
        let chrony_config = target.execute_command("cat /etc/chrony.conf 2>/dev/null | grep -E 'driftfile|rtcsync|makestep' || echo 'no_chrony'").await?;
        
        // Check chrony access restrictions
        let chrony_access = target.execute_command("grep -E 'cmdallow|cmdport' /etc/chrony.conf 2>/dev/null || echo 'no_access_config'").await?;
        
        // Check chrony security features
        let chrony_security = target.execute_command("chronyc tracking 2>/dev/null | grep -E 'Reference|Stratum|Precision' || echo 'tracking_unavailable'").await?;
        
        // Check chrony runtime security
        let chrony_runtime = target.execute_command("chronyc sources -v 2>/dev/null | head -10 || echo 'sources_unavailable'").await?;
        
        let details = format!("Chrony config: {}\nAccess config: {}\nSecurity tracking: {}\nRuntime sources: {}", 
                             chrony_config.stdout, chrony_access.stdout, chrony_security.stdout, chrony_runtime.stdout);
        
        if chrony_config.stdout.contains("no_chrony") {
            Ok((TestStatus::Skipped, "Chrony is not configured".to_string(), Some(details)))
        } else if chrony_security.stdout.contains("Reference ID") && !chrony_access.stdout.contains("no_access_config") {
            Ok((TestStatus::Passed, "Chrony security configuration is comprehensive".to_string(), Some(details)))
        } else if !chrony_security.stdout.contains("tracking_unavailable") {
            Ok((TestStatus::Warning, "Chrony is functional but security could be improved".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Chrony security configuration is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_timezone_configuration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check timezone configuration
        let timezone = target.execute_command("timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo 'timezone_unknown'").await?;
        
        // Check timezone data integrity
        let tz_data = target.execute_command("ls -la /usr/share/zoneinfo/ | head -5").await?;
        
        // Check for timezone security
        let tz_security = target.execute_command("ls -la /etc/localtime").await?;
        
        // Check timezone update mechanism
        let tz_updates = target.execute_command("which tzdata 2>/dev/null || dpkg -l | grep tzdata || rpm -q tzdata 2>/dev/null || echo 'no_tzdata'").await?;
        
        let mut tz_features = Vec::new();
        
        if !timezone.stdout.contains("timezone_unknown") && !timezone.stdout.trim().is_empty() {
            tz_features.push("Timezone properly configured");
        }
        
        if tz_data.stdout.contains("zoneinfo") {
            tz_features.push("Timezone data available");
        }
        
        if tz_security.stdout.contains("/etc/localtime") {
            tz_features.push("Local timezone configured");
        }
        
        if !tz_updates.stdout.contains("no_tzdata") {
            tz_features.push("Timezone data package installed");
        }
        
        let details = format!("Timezone: {}\nTZ data: {}\nLocal time: {}\nTZ updates: {}\nFeatures: {:?}", 
                             timezone.stdout.trim(), tz_data.stdout, tz_security.stdout, tz_updates.stdout, tz_features);
        
        if tz_features.len() >= 3 {
            Ok((TestStatus::Passed, "Timezone configuration is complete and secure".to_string(), Some(details)))
        } else if tz_features.len() >= 2 {
            Ok((TestStatus::Warning, "Timezone configuration is basic but functional".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Timezone configuration is incomplete".to_string(), Some(details)))
        }
    }

    async fn test_system_clock_protection(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check clock protection mechanisms
        let clock_protection = target.execute_command("cat /proc/sys/kernel/time_adj_allowed 2>/dev/null || echo 'not_available'").await?;
        
        // Check RTC (Real Time Clock) protection
        let rtc_protection = target.execute_command("ls -la /dev/rtc* 2>/dev/null").await?;
        
        // Check clock adjustment permissions
        let clock_perms = target.execute_command("ls -la /usr/bin/date /bin/date 2>/dev/null").await?;
        
        // Check for clock tampering protection
        let tamper_protection = target.execute_command("dmesg 2>/dev/null | grep -i 'rtc\\|clock' | tail -5 || echo 'no_clock_messages'").await?;
        
        // Check system clock capabilities
        let clock_caps = target.execute_command("cat /proc/timer_list 2>/dev/null | head -10 || echo 'timer_info_unavailable'").await?;
        
        let mut protection_features = Vec::new();
        
        if !rtc_protection.stdout.is_empty() {
            protection_features.push("RTC devices available");
        }
        
        if clock_perms.stdout.contains("root root") {
            protection_features.push("Date command properly protected");
        }
        
        if !tamper_protection.stdout.contains("no_clock_messages") {
            protection_features.push("Clock system messages available");
        }
        
        if !clock_caps.stdout.contains("timer_info_unavailable") {
            protection_features.push("Timer system information available");
        }
        
        let details = format!("Clock protection: {}\nRTC protection: {}\nClock permissions: {}\nTamper protection: {}\nClock capabilities: {}\nFeatures: {:?}", 
                             clock_protection.stdout.trim(), rtc_protection.stdout, clock_perms.stdout, 
                             tamper_protection.stdout, clock_caps.stdout, protection_features);
        
        if protection_features.len() >= 3 {
            Ok((TestStatus::Passed, "System clock protection is comprehensive".to_string(), Some(details)))
        } else if protection_features.len() >= 2 {
            Ok((TestStatus::Warning, "System clock protection is basic".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Warning, "System clock protection is minimal".to_string(), Some(details)))
        }
    }

    async fn test_network_time_protocols(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check network time protocol versions
        let ntp_versions = target.execute_command("ntpq -c version 2>/dev/null || chronyc tracking 2>/dev/null | grep 'Chrony version' || echo 'no_version_info'").await?;
        
        // Check time protocol security
        let protocol_security = target.execute_command("netstat -tulpn 2>/dev/null | grep ':123' || ss -tulpn 2>/dev/null | grep ':123' || echo 'no_ntp_listening'").await?;
        
        // Check for time protocol vulnerabilities
        let protocol_vulns = target.execute_command("ntpq -c 'rv 0 version' 2>/dev/null | grep -E 'version|leap' || echo 'no_vulnerability_info'").await?;
        
        // Check time protocol encryption
        let protocol_crypto = target.execute_command("grep -E 'crypto|nts' /etc/ntp.conf /etc/chrony.conf 2>/dev/null || echo 'no_crypto'").await?;
        
        let mut protocol_features = Vec::new();
        let mut protocol_issues = Vec::new();
        
        if !ntp_versions.stdout.contains("no_version_info") {
            protocol_features.push("Time protocol version information available");
        }
        
        if protocol_security.stdout.contains(":123") {
            if protocol_security.stdout.contains("127.0.0.1:123") {
                protocol_features.push("NTP listening on localhost only");
            } else {
                protocol_issues.push("NTP listening on all interfaces");
            }
        }
        
        if !protocol_crypto.stdout.contains("no_crypto") {
            protocol_features.push("Cryptographic time protocols configured");
        }
        
        let details = format!("Protocol versions: {}\nProtocol security: {}\nVulnerability info: {}\nCryptography: {}\nFeatures: {:?}\nIssues: {:?}", 
                             ntp_versions.stdout, protocol_security.stdout, protocol_vulns.stdout, 
                             protocol_crypto.stdout, protocol_features, protocol_issues);
        
        if protocol_features.len() >= 3 && protocol_issues.is_empty() {
            Ok((TestStatus::Passed, "Network time protocols are secure".to_string(), Some(details)))
        } else if protocol_features.len() >= 2 {
            Ok((TestStatus::Warning, "Network time protocols are adequately configured".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Network time protocol security is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_time_audit_trail(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check time synchronization logs
        let sync_logs = target.execute_command("journalctl -u ntp -u ntpd -u chronyd --no-pager -n 10 2>/dev/null || echo 'no_sync_logs'").await?;
        
        // Check system time change logs
        let time_change_logs = target.execute_command("journalctl --no-pager | grep -i 'time\\|clock' | tail -5 2>/dev/null || echo 'no_time_logs'").await?;
        
        // Check audit logs for time changes
        let audit_time_logs = target.execute_command("ausearch -k time-change 2>/dev/null | tail -5 || echo 'no_audit_time'").await?;
        
        // Check time-related security events
        let security_time_logs = target.execute_command("grep -i 'time\\|clock\\|ntp' /var/log/auth.log /var/log/secure 2>/dev/null | tail -5 || echo 'no_security_time_logs'").await?;
        
        let mut audit_features = Vec::new();
        
        if !sync_logs.stdout.contains("no_sync_logs") && sync_logs.stdout.lines().count() > 1 {
            audit_features.push("Time synchronization logs available");
        }
        
        if !time_change_logs.stdout.contains("no_time_logs") {
            audit_features.push("System time change logs available");
        }
        
        if !audit_time_logs.stdout.contains("no_audit_time") {
            audit_features.push("Audit trail for time changes");
        }
        
        if !security_time_logs.stdout.contains("no_security_time_logs") {
            audit_features.push("Security logs for time events");
        }
        
        let details = format!("Sync logs: {}\nTime change logs: {}\nAudit logs: {}\nSecurity logs: {}\nFeatures: {:?}", 
                             sync_logs.stdout, time_change_logs.stdout, audit_time_logs.stdout, 
                             security_time_logs.stdout, audit_features);
        
        if audit_features.len() >= 3 {
            Ok((TestStatus::Passed, "Time audit trail is comprehensive".to_string(), Some(details)))
        } else if audit_features.len() >= 2 {
            Ok((TestStatus::Warning, "Time audit trail is adequate".to_string(), Some(details)))
        } else if audit_features.len() >= 1 {
            Ok((TestStatus::Warning, "Basic time audit trail available".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No time audit trail available".to_string(), Some(details)))
        }
    }
}
