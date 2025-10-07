use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum HardwareSecurityTests {
    EdgeLockEnclave,
    SecureEnclaveStatus,
    HardwareRootOfTrust,
    CryptoAcceleration,
    RandomNumberGenerator,
}

#[async_trait]
impl SecurityTest for HardwareSecurityTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::EdgeLockEnclave => self.test_edgelock_enclave(target).await,
            Self::SecureEnclaveStatus => self.test_secure_enclave_status(target).await,
            Self::HardwareRootOfTrust => self.test_hardware_root_of_trust(target).await,
            Self::CryptoAcceleration => self.test_crypto_acceleration(target).await,
            Self::RandomNumberGenerator => self.test_random_number_generator(target).await,
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
            Self::EdgeLockEnclave => "hardware_001",
            Self::SecureEnclaveStatus => "hardware_002",
            Self::HardwareRootOfTrust => "hardware_003",
            Self::CryptoAcceleration => "hardware_004",
            Self::RandomNumberGenerator => "hardware_005",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::EdgeLockEnclave => "EdgeLock Enclave (ELE)",
            Self::SecureEnclaveStatus => "Secure Enclave Status",
            Self::HardwareRootOfTrust => "Hardware Root of Trust",
            Self::CryptoAcceleration => "Crypto Hardware Acceleration",
            Self::RandomNumberGenerator => "Hardware RNG",
        }
    }

    fn category(&self) -> &str {
        "hardware"
    }

    fn description(&self) -> &str {
        match self {
            Self::EdgeLockEnclave => "Verify i.MX93 EdgeLock Enclave is functional",
            Self::SecureEnclaveStatus => "Check secure enclave hardware status",
            Self::HardwareRootOfTrust => "Verify hardware root of trust implementation",
            Self::CryptoAcceleration => "Check hardware cryptographic acceleration",
            Self::RandomNumberGenerator => "Verify hardware random number generator",
        }
    }
}

impl HardwareSecurityTests {
    async fn test_edgelock_enclave(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for EdgeLock Enclave in dmesg
        let ele_check = target.execute_command("dmesg | grep -i 'ele\\|edgelock\\|s4muap'").await?;
        
        // Check for ELE device nodes
        let ele_devices = target.execute_command("ls -la /dev/ | grep -i ele").await?;
        
        // Check for ELE in /proc/devices
        let ele_proc = target.execute_command("cat /proc/devices | grep -i ele").await?;
        
        let mut details = Vec::new();
        details.push(format!("ELE dmesg: {}", ele_check.stdout));
        details.push(format!("ELE devices: {}", ele_devices.stdout));
        details.push(format!("ELE proc: {}", ele_proc.stdout));
        
        if ele_check.stdout.contains("ELE") || ele_check.stdout.contains("s4muap") {
            Ok((TestStatus::Passed, "EdgeLock Enclave detected and active".to_string(), Some(details.join("\n"))))
        } else if !ele_devices.stdout.is_empty() || !ele_proc.stdout.is_empty() {
            Ok((TestStatus::Warning, "ELE devices present but not confirmed active".to_string(), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "EdgeLock Enclave not detected".to_string(), Some(details.join("\n"))))
        }
    }

    async fn test_secure_enclave_status(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Run ELE test if available
        let ele_test = target.execute_command("simple-ele-test info 2>/dev/null || echo 'test_not_available'").await?;
        
        // Check for secure enclave services
        let enclave_services = target.execute_command("systemctl list-units | grep -i 'enclave\\|secure'").await?;
        
        let details = format!("ELE test: {}\nEnclave services: {}", ele_test.stdout, enclave_services.stdout);
        
        if ele_test.stdout.contains("ELE") && !ele_test.stdout.contains("test_not_available") {
            Ok((TestStatus::Passed, "Secure enclave test successful".to_string(), Some(details)))
        } else if !enclave_services.stdout.is_empty() {
            Ok((TestStatus::Warning, "Enclave services detected but test unavailable".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Skipped, "Secure enclave test tools not available".to_string(), Some(details)))
        }
    }

    async fn test_hardware_root_of_trust(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for hardware root of trust indicators
        let rot_check = target.execute_command("dmesg | grep -i 'root.*trust\\|fuse\\|otp\\|hab\\|ahab'").await?;
        
        // Check for secure boot fuses
        let fuse_check = target.execute_command("find /sys -name '*fuse*' -o -name '*otp*' 2>/dev/null | head -5").await?;
        
        let details = format!("RoT indicators: {}\nFuse/OTP: {}", rot_check.stdout, fuse_check.stdout);
        
        if rot_check.stdout.contains("AHAB") || rot_check.stdout.contains("fuse") {
            Ok((TestStatus::Passed, "Hardware root of trust indicators found".to_string(), Some(details)))
        } else if !fuse_check.stdout.is_empty() {
            Ok((TestStatus::Warning, "Fuse/OTP hardware present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No hardware root of trust detected".to_string(), Some(details)))
        }
    }

    async fn test_crypto_acceleration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for crypto hardware
        let crypto_hw = target.execute_command("cat /proc/crypto | grep -A5 -B5 'driver.*caam\\|driver.*imx'").await?;
        
        // Check for hardware crypto modules
        let crypto_modules = target.execute_command("lsmod | grep -E 'caam\\|imx.*crypt'").await?;
        
        // Check for crypto devices
        let crypto_devices = target.execute_command("ls -la /dev/ | grep -i crypto").await?;
        
        let mut details = Vec::new();
        details.push(format!("Crypto hardware: {}", crypto_hw.stdout));
        details.push(format!("Crypto modules: {}", crypto_modules.stdout));
        details.push(format!("Crypto devices: {}", crypto_devices.stdout));
        
        if crypto_hw.stdout.contains("caam") || crypto_hw.stdout.contains("imx") {
            Ok((TestStatus::Passed, "Hardware crypto acceleration detected".to_string(), Some(details.join("\n"))))
        } else if !crypto_modules.stdout.is_empty() {
            Ok((TestStatus::Warning, "Crypto modules loaded but hardware unclear".to_string(), Some(details.join("\n"))))
        } else {
            Ok((TestStatus::Failed, "No hardware crypto acceleration detected".to_string(), Some(details.join("\n"))))
        }
    }

    async fn test_random_number_generator(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for hardware RNG
        let hwrng = target.execute_command("cat /proc/sys/kernel/random/entropy_avail").await?;
        
        // Check for RNG devices
        let rng_devices = target.execute_command("ls -la /dev/*random* /dev/hwrng 2>/dev/null || echo 'not_found'").await?;
        
        // Check RNG quality
        let rng_quality = target.execute_command("cat /sys/class/misc/hw_random/rng_current 2>/dev/null || echo 'not_available'").await?;
        
        let entropy: u32 = hwrng.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Entropy available: {}\nRNG devices: {}\nRNG current: {}", 
                             entropy, rng_devices.stdout, rng_quality.stdout);
        
        if entropy > 1000 && rng_devices.stdout.contains("hwrng") {
            Ok((TestStatus::Passed, format!("Hardware RNG active (entropy: {})", entropy), Some(details)))
        } else if entropy > 500 {
            Ok((TestStatus::Warning, format!("RNG available but low entropy ({})", entropy), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Insufficient entropy ({})", entropy), Some(details)))
        }
    }
}
