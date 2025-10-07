use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, check_command_success, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum BootSecurityTests {
    SecureBootEnabled,
    UBootSigned,
    KernelSigned,
    ModuleSigning,
    OpteeSigned,
    TfaSigned,
    BootChainVerification,
}

#[async_trait]
impl SecurityTest for BootSecurityTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::SecureBootEnabled => self.test_secure_boot_enabled(target).await,
            Self::UBootSigned => self.test_uboot_signed(target).await,
            Self::KernelSigned => self.test_kernel_signed(target).await,
            Self::ModuleSigning => self.test_module_signing(target).await,
            Self::OpteeSigned => self.test_optee_signed(target).await,
            Self::TfaSigned => self.test_tfa_signed(target).await,
            Self::BootChainVerification => self.test_boot_chain_verification(target).await,
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
            Self::SecureBootEnabled => "boot_001",
            Self::UBootSigned => "boot_002",
            Self::KernelSigned => "boot_003",
            Self::ModuleSigning => "boot_004",
            Self::OpteeSigned => "boot_005",
            Self::TfaSigned => "boot_006",
            Self::BootChainVerification => "boot_007",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::SecureBootEnabled => "Secure Boot Enabled",
            Self::UBootSigned => "U-Boot Signature Verification",
            Self::KernelSigned => "Kernel Signature Verification",
            Self::ModuleSigning => "Module Signing Active",
            Self::OpteeSigned => "OP-TEE Signature Verification",
            Self::TfaSigned => "TF-A Signature Verification",
            Self::BootChainVerification => "Complete Boot Chain Verification",
        }
    }

    fn category(&self) -> &str {
        "boot"
    }

    fn description(&self) -> &str {
        match self {
            Self::SecureBootEnabled => "Verify that secure boot is enabled and functioning",
            Self::UBootSigned => "Check that U-Boot bootloader is properly signed and verified",
            Self::KernelSigned => "Verify kernel image signature validation",
            Self::ModuleSigning => "Ensure kernel module signing is active and enforced",
            Self::OpteeSigned => "Check OP-TEE trusted OS signature verification",
            Self::TfaSigned => "Verify TF-A (ARM Trusted Firmware) signature validation",
            Self::BootChainVerification => "Complete verification of the entire secure boot chain",
        }
    }
}

impl BootSecurityTests {
    async fn test_secure_boot_enabled(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for AHAB (Advanced High Assurance Boot) on i.MX93
        let ahab_check = target.execute_command("dmesg | grep -i 'ahab\\|secure.*boot\\|hab'").await?;
        
        if ahab_check.stdout.contains("AHAB") || ahab_check.stdout.contains("secure boot") {
            Ok((TestStatus::Passed, "Secure boot (AHAB) is enabled".to_string(), Some(ahab_check.stdout)))
        } else {
            // Check for other secure boot indicators
            let secure_indicators = target.execute_command("cat /proc/cmdline | grep -i secure").await?;
            if !secure_indicators.stdout.is_empty() {
                Ok((TestStatus::Warning, "Secure boot indicators found but AHAB not confirmed".to_string(), Some(secure_indicators.stdout)))
            } else {
                Ok((TestStatus::Failed, "No secure boot indicators found".to_string(), None))
            }
        }
    }

    async fn test_uboot_signed(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check U-Boot signature verification in boot log
        let uboot_sig = target.execute_command("dmesg | grep -i 'u-boot.*sign\\|verified\\|signature'").await?;
        
        if uboot_sig.stdout.contains("verified") || uboot_sig.stdout.contains("signature") {
            Ok((TestStatus::Passed, "U-Boot signature verification detected".to_string(), Some(uboot_sig.stdout)))
        } else {
            // Check for FIT image verification
            let fit_check = target.execute_command("dmesg | grep -i 'fit.*verif\\|fit.*sign'").await?;
            if !fit_check.stdout.is_empty() {
                Ok((TestStatus::Passed, "FIT image verification active".to_string(), Some(fit_check.stdout)))
            } else {
                Ok((TestStatus::Failed, "No U-Boot signature verification found".to_string(), None))
            }
        }
    }

    async fn test_kernel_signed(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for kernel signature verification
        let kernel_sig = target.execute_command("dmesg | grep -i 'kernel.*sign\\|vmlinuz.*verif'").await?;
        
        // Also check if kernel lockdown is enabled (indicates signed kernel)
        let lockdown = target.execute_command("cat /sys/kernel/security/lockdown 2>/dev/null || echo 'not_available'").await?;
        
        if kernel_sig.stdout.contains("signature") || kernel_sig.stdout.contains("verified") {
            Ok((TestStatus::Passed, "Kernel signature verification active".to_string(), Some(kernel_sig.stdout)))
        } else if lockdown.stdout.contains("integrity") {
            Ok((TestStatus::Passed, "Kernel lockdown mode indicates signed kernel".to_string(), Some(lockdown.stdout)))
        } else {
            Ok((TestStatus::Warning, "Kernel signature verification not clearly detected".to_string(), None))
        }
    }

    async fn test_module_signing(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check if module signing is enabled
        let modsign_check = target.execute_command("cat /proc/sys/kernel/modules_disabled 2>/dev/null || echo '0'").await?;
        
        // Check for module signature verification in dmesg
        let module_sig = target.execute_command("dmesg | grep -i 'module.*sign\\|x509.*cert\\|Factory kernel module signing key'").await?;
        
        // Check loaded modules for signature info
        let signed_modules = target.execute_command("cat /proc/modules | head -5").await?;
        
        if module_sig.stdout.contains("Factory kernel module signing key") {
            Ok((TestStatus::Passed, "Factory kernel module signing key detected".to_string(), Some(module_sig.stdout)))
        } else if module_sig.stdout.contains("module") && module_sig.stdout.contains("sign") {
            Ok((TestStatus::Passed, "Module signing infrastructure detected".to_string(), Some(module_sig.stdout)))
        } else {
            Ok((TestStatus::Failed, "Module signing not detected".to_string(), Some(signed_modules.stdout)))
        }
    }

    async fn test_optee_signed(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for OP-TEE in boot log
        let optee_check = target.execute_command("dmesg | grep -i 'optee\\|trusted.*os'").await?;
        
        if optee_check.stdout.contains("OP-TEE") {
            // Check for signature verification
            let optee_sig = target.execute_command("dmesg | grep -i 'optee.*sign\\|optee.*verif'").await?;
            if !optee_sig.stdout.is_empty() {
                Ok((TestStatus::Passed, "OP-TEE signature verification detected".to_string(), Some(optee_sig.stdout)))
            } else {
                Ok((TestStatus::Warning, "OP-TEE present but signature verification not confirmed".to_string(), Some(optee_check.stdout)))
            }
        } else {
            Ok((TestStatus::Skipped, "OP-TEE not detected on this system".to_string(), None))
        }
    }

    async fn test_tfa_signed(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for TF-A (ARM Trusted Firmware) in boot log
        let tfa_check = target.execute_command("dmesg | grep -i 'tf-a\\|trusted.*firmware\\|bl31'").await?;
        
        if tfa_check.stdout.contains("TF-A") || tfa_check.stdout.contains("BL31") {
            // Check for signature verification
            let tfa_sig = target.execute_command("dmesg | grep -i 'tf-a.*sign\\|firmware.*verif'").await?;
            if !tfa_sig.stdout.is_empty() {
                Ok((TestStatus::Passed, "TF-A signature verification detected".to_string(), Some(tfa_sig.stdout)))
            } else {
                Ok((TestStatus::Warning, "TF-A present but signature verification not confirmed".to_string(), Some(tfa_check.stdout)))
            }
        } else {
            Ok((TestStatus::Skipped, "TF-A not detected on this system".to_string(), None))
        }
    }

    async fn test_boot_chain_verification(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Comprehensive boot chain verification
        let boot_log = target.execute_command("dmesg | grep -i 'verif\\|sign\\|secure\\|ahab\\|hab'").await?;
        
        let mut verified_components = Vec::new();
        let mut details = Vec::new();
        
        if boot_log.stdout.contains("AHAB") {
            verified_components.push("AHAB");
        }
        if boot_log.stdout.contains("signature") {
            verified_components.push("Signatures");
        }
        if boot_log.stdout.contains("verified") {
            verified_components.push("Verification");
        }
        if boot_log.stdout.contains("Factory kernel module signing key") {
            verified_components.push("Module Signing");
        }
        
        details.push(format!("Boot verification components: {:?}", verified_components));
        details.push(boot_log.stdout);
        
        if verified_components.len() >= 3 {
            Ok((TestStatus::Passed, format!("Complete boot chain verification active ({} components)", verified_components.len()), Some(details.join("\n"))))
        } else if verified_components.len() >= 1 {
            Ok((TestStatus::Warning, format!("Partial boot chain verification ({} components)", verified_components.len()), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "No boot chain verification detected".to_string(), Some(details.join("\n"))))
        }
    }
}
