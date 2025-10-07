use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, check_command_success, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum RuntimeSecurityTests {
    FilesystemEncryption,
    FirewallActive,
    SelinuxStatus,
    SshConfiguration,
    UserPermissions,
    ServiceHardening,
    KernelProtections,
}

#[async_trait]
impl SecurityTest for RuntimeSecurityTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::FilesystemEncryption => self.test_filesystem_encryption(target).await,
            Self::FirewallActive => self.test_firewall_active(target).await,
            Self::SelinuxStatus => self.test_selinux_status(target).await,
            Self::SshConfiguration => self.test_ssh_configuration(target).await,
            Self::UserPermissions => self.test_user_permissions(target).await,
            Self::ServiceHardening => self.test_service_hardening(target).await,
            Self::KernelProtections => self.test_kernel_protections(target).await,
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
            Self::FilesystemEncryption => "runtime_001",
            Self::FirewallActive => "runtime_002",
            Self::SelinuxStatus => "runtime_003",
            Self::SshConfiguration => "runtime_004",
            Self::UserPermissions => "runtime_005",
            Self::ServiceHardening => "runtime_006",
            Self::KernelProtections => "runtime_007",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::FilesystemEncryption => "Filesystem Encryption (LUKS)",
            Self::FirewallActive => "Firewall Configuration",
            Self::SelinuxStatus => "SELinux Status",
            Self::SshConfiguration => "SSH Security Configuration",
            Self::UserPermissions => "User Permission Security",
            Self::ServiceHardening => "Service Hardening",
            Self::KernelProtections => "Kernel Security Protections",
        }
    }

    fn category(&self) -> &str {
        "runtime"
    }

    fn description(&self) -> &str {
        match self {
            Self::FilesystemEncryption => "Verify that the root filesystem is encrypted with LUKS",
            Self::FirewallActive => "Check that iptables/netfilter firewall is properly configured",
            Self::SelinuxStatus => "Verify SELinux security framework status",
            Self::SshConfiguration => "Validate SSH daemon security configuration",
            Self::UserPermissions => "Check user account security and permissions",
            Self::ServiceHardening => "Verify system service security hardening",
            Self::KernelProtections => "Check kernel security features and protections",
        }
    }
}

impl RuntimeSecurityTests {
    async fn test_filesystem_encryption(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for LUKS encrypted devices
        let luks_check = target.execute_command("lsblk -f | grep -i luks").await?;
        
        // Check for dm-crypt devices
        let dmcrypt_check = target.execute_command("ls -la /dev/mapper/ | grep -v control").await?;
        
        // Check if cryptsetup is available
        let cryptsetup = target.execute_command("which cryptsetup").await?;
        
        // Check mount points for encrypted filesystems
        let mount_check = target.execute_command("mount | grep -E 'crypt|luks|mapper'").await?;
        
        let mut details = Vec::new();
        details.push(format!("LUKS devices: {}", luks_check.stdout));
        details.push(format!("Device mapper: {}", dmcrypt_check.stdout));
        details.push(format!("Encrypted mounts: {}", mount_check.stdout));
        
        if luks_check.stdout.contains("crypto_LUKS") || mount_check.stdout.contains("mapper") {
            Ok((TestStatus::Passed, "LUKS filesystem encryption detected".to_string(), Some(details.join("\n"))))
        } else if dmcrypt_check.stdout.lines().count() > 1 {
            // More than just 'control' device exists
            Ok((TestStatus::Warning, "Device mapper present but LUKS not confirmed".to_string(), Some(details.join("\n"))))
        } else if cryptsetup.exit_code == 0 {
            Ok((TestStatus::Warning, "Cryptsetup available but no encrypted filesystems detected".to_string(), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "No filesystem encryption detected".to_string(), Some(details.join("\n"))))
        }
    }

    async fn test_firewall_active(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check iptables rules
        let iptables = target.execute_command("iptables -L -n").await?;
        
        // Check if iptables service is running
        let iptables_service = target.execute_command("systemctl is-active iptables 2>/dev/null || echo 'not_running'").await?;
        
        // Check for netfilter modules
        let netfilter_modules = target.execute_command("lsmod | grep -E 'iptable|netfilter|nf_'").await?;
        
        let mut details = Vec::new();
        details.push(format!("iptables rules:\n{}", iptables.stdout));
        details.push(format!("Netfilter modules: {}", netfilter_modules.stdout));
        
        if iptables.exit_code == 0 && !iptables.stdout.contains("Chain INPUT (policy ACCEPT)") {
            Ok((TestStatus::Passed, "Firewall rules configured".to_string(), Some(details.join("\n"))))
        } else if iptables.exit_code == 0 {
            Ok((TestStatus::Warning, "iptables available but default ACCEPT policy".to_string(), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "No firewall configuration detected".to_string(), Some(details.join("\n"))))
        }
    }

    async fn test_selinux_status(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check SELinux status
        let selinux_status = target.execute_command("getenforce 2>/dev/null || echo 'not_available'").await?;
        
        // Check SELinux config
        let selinux_config = target.execute_command("cat /etc/selinux/config 2>/dev/null || echo 'not_found'").await?;
        
        // Check if SELinux filesystem is mounted
        let selinux_fs = target.execute_command("mount | grep selinux").await?;
        
        let mut details = Vec::new();
        details.push(format!("SELinux status: {}", selinux_status.stdout.trim()));
        details.push(format!("SELinux config: {}", selinux_config.stdout));
        
        match selinux_status.stdout.trim() {
            "Enforcing" => Ok((TestStatus::Passed, "SELinux is enforcing".to_string(), Some(details.join("\n")))),
            "Permissive" => Ok((TestStatus::Warning, "SELinux is permissive (not enforcing)".to_string(), Some(details.join("\n")))),
            "Disabled" => Ok((TestStatus::Warning, "SELinux is disabled".to_string(), Some(details.join("\n")))),
            "not_available" => Ok((TestStatus::Skipped, "SELinux not available on this system".to_string(), None)),
            _ => Ok((TestStatus::Warning, "SELinux status unknown".to_string(), Some(details.join("\n")))),
        }
    }

    async fn test_ssh_configuration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check SSH configuration
        let ssh_config = target.execute_command("cat /etc/ssh/sshd_config | grep -E '^[^#]*(PermitRootLogin|PasswordAuthentication|Protocol|Port)'").await?;
        
        // Check SSH service status
        let ssh_status = target.execute_command("systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo 'not_running'").await?;
        
        let mut security_issues = Vec::new();
        let mut security_good = Vec::new();
        
        if ssh_config.stdout.contains("PermitRootLogin yes") {
            security_issues.push("Root login permitted");
        } else if ssh_config.stdout.contains("PermitRootLogin no") {
            security_good.push("Root login disabled");
        }
        
        if ssh_config.stdout.contains("PasswordAuthentication yes") {
            security_issues.push("Password authentication enabled");
        } else if ssh_config.stdout.contains("PasswordAuthentication no") {
            security_good.push("Password authentication disabled");
        }
        
        let details = format!("SSH Config:\n{}\nGood: {:?}\nIssues: {:?}", ssh_config.stdout, security_good, security_issues);
        
        if security_issues.is_empty() && !security_good.is_empty() {
            Ok((TestStatus::Passed, "SSH configuration secure".to_string(), Some(details)))
        } else if security_issues.len() <= 1 {
            Ok((TestStatus::Warning, format!("SSH has {} security issues", security_issues.len()), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("SSH has {} security issues", security_issues.len()), Some(details)))
        }
    }

    async fn test_user_permissions(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for users with UID 0 (root privileges)
        let root_users = target.execute_command("awk -F: '$3 == 0 { print $1 }' /etc/passwd").await?;
        
        // Check sudo configuration
        let sudo_config = target.execute_command("cat /etc/sudoers.d/* 2>/dev/null | grep -v '^#' | head -10").await?;
        
        // Check for users with shell access
        let shell_users = target.execute_command("grep -E '/bin/(bash|sh|zsh)$' /etc/passwd | wc -l").await?;
        
        let mut details = Vec::new();
        details.push(format!("Root users: {}", root_users.stdout));
        details.push(format!("Shell users count: {}", shell_users.stdout.trim()));
        details.push(format!("Sudo config: {}", sudo_config.stdout));
        
        let root_count = root_users.stdout.lines().count();
        let shell_count: usize = shell_users.stdout.trim().parse().unwrap_or(0);
        
        if root_count == 1 && shell_count <= 3 {
            Ok((TestStatus::Passed, "User permissions appear secure".to_string(), Some(details.join("\n"))))
        } else if root_count <= 2 && shell_count <= 5 {
            Ok((TestStatus::Warning, "User permissions need review".to_string(), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "Too many privileged users detected".to_string(), Some(details.join("\n"))))
        }
    }

    async fn test_service_hardening(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check running services
        let services = target.execute_command("systemctl list-units --type=service --state=running --no-pager | grep -v '@'").await?;
        
        // Check for unnecessary services
        let potentially_risky = ["telnet", "ftp", "rsh", "rlogin", "tftp"];
        let mut risky_services = Vec::new();
        
        for service in &potentially_risky {
            if services.stdout.contains(service) {
                risky_services.push(*service);
            }
        }
        
        // Count total running services
        let service_count = services.stdout.lines().filter(|line| line.contains(".service")).count();
        
        let details = format!("Running services: {}\nRisky services: {:?}", service_count, risky_services);
        
        if risky_services.is_empty() && service_count <= 20 {
            Ok((TestStatus::Passed, "Service hardening looks good".to_string(), Some(details)))
        } else if risky_services.is_empty() {
            Ok((TestStatus::Warning, format!("Many services running ({})", service_count), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Risky services detected: {:?}", risky_services), Some(details)))
        }
    }

    async fn test_kernel_protections(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check kernel protection features
        let mut protections = Vec::new();
        let mut details = Vec::new();
        
        // Check ASLR
        let aslr = target.execute_command("cat /proc/sys/kernel/randomize_va_space 2>/dev/null || echo '0'").await?;
        if aslr.stdout.trim() == "2" {
            protections.push("ASLR");
        }
        details.push(format!("ASLR: {}", aslr.stdout.trim()));
        
        // Check DEP/NX bit
        let nx_check = target.execute_command("grep -i nx /proc/cpuinfo | head -1").await?;
        if !nx_check.stdout.is_empty() {
            protections.push("NX/DEP");
        }
        details.push(format!("NX support: {}", !nx_check.stdout.is_empty()));
        
        // Check kernel pointer restriction
        let kptr = target.execute_command("cat /proc/sys/kernel/kptr_restrict 2>/dev/null || echo '0'").await?;
        if kptr.stdout.trim() != "0" {
            protections.push("KPTR_RESTRICT");
        }
        details.push(format!("KPTR_RESTRICT: {}", kptr.stdout.trim()));
        
        // Check dmesg restriction
        let dmesg_restrict = target.execute_command("cat /proc/sys/kernel/dmesg_restrict 2>/dev/null || echo '0'").await?;
        if dmesg_restrict.stdout.trim() == "1" {
            protections.push("DMESG_RESTRICT");
        }
        details.push(format!("DMESG_RESTRICT: {}", dmesg_restrict.stdout.trim()));
        
        let protection_count = protections.len();
        let details_str = details.join("\n");
        
        if protection_count >= 3 {
            Ok((TestStatus::Passed, format!("Kernel protections active: {:?}", protections), Some(details_str)))
        } else if protection_count >= 1 {
            Ok((TestStatus::Warning, format!("Some kernel protections active: {:?}", protections), Some(details_str)))
        } else {
            Ok((TestStatus::Failed, "No kernel protections detected".to_string(), Some(details_str)))
        }
    }
}
