use crate::{
    cli::TestSuite,
    error::{Error, Result},
    target::{Target, SystemInfo},
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tracing::{debug, info, warn};

pub mod boot;
pub mod hardware;
pub mod network;
pub mod runtime;
pub mod compliance;

pub use boot::BootSecurityTests;
pub use hardware::HardwareSecurityTests;
pub use network::NetworkSecurityTests;
pub use runtime::RuntimeSecurityTests;
pub use compliance::ComplianceTests;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestResult {
    pub test_id: String,
    pub test_name: String,
    pub category: String,
    pub status: TestStatus,
    pub message: String,
    pub details: Option<String>,
    pub duration: Duration,
    pub timestamp: DateTime<Utc>,
    pub metadata: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TestStatus {
    Passed,
    Failed,
    Warning,
    Skipped,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestSuiteResults {
    pub suite_name: String,
    pub total_tests: usize,
    pub passed: usize,
    pub failed: usize,
    pub warnings: usize,
    pub skipped: usize,
    pub errors: usize,
    pub duration: Duration,
    pub timestamp: DateTime<Utc>,
    pub system_info: SystemInfo,
    pub results: Vec<TestResult>,
}

impl TestSuiteResults {
    pub fn overall_passed(&self) -> bool {
        self.failed == 0 && self.errors == 0
    }

    pub fn success_rate(&self) -> f64 {
        if self.total_tests == 0 {
            return 100.0;
        }
        (self.passed as f64 / self.total_tests as f64) * 100.0
    }
}

pub trait SecurityTest {
    async fn run(&self, target: &mut Target) -> Result<TestResult>;
    fn test_id(&self) -> &str;
    fn test_name(&self) -> &str;
    fn category(&self) -> &str;
    fn description(&self) -> &str;
}

pub struct TestRegistry {
    tests: HashMap<String, Box<dyn SecurityTest + Send + Sync>>,
}

impl TestRegistry {
    pub fn new() -> Self {
        let mut registry = Self {
            tests: HashMap::new(),
        };
        
        // Register all test categories
        registry.register_boot_tests();
        registry.register_hardware_tests();
        registry.register_runtime_tests();
        registry.register_network_tests();
        registry.register_compliance_tests();
        
        registry
    }

    fn register_boot_tests(&mut self) {
        // Boot security tests
        self.register(Box::new(BootSecurityTests::SecureBootEnabled));
        self.register(Box::new(BootSecurityTests::UBootSigned));
        self.register(Box::new(BootSecurityTests::KernelSigned));
        self.register(Box::new(BootSecurityTests::ModuleSigning));
        self.register(Box::new(BootSecurityTests::OpteeSigned));
        self.register(Box::new(BootSecurityTests::TfaSigned));
        self.register(Box::new(BootSecurityTests::BootChainVerification));
    }

    fn register_hardware_tests(&mut self) {
        // Hardware security tests
        self.register(Box::new(HardwareSecurityTests::EdgeLockEnclave));
        self.register(Box::new(HardwareSecurityTests::SecureEnclaveStatus));
        self.register(Box::new(HardwareSecurityTests::HardwareRootOfTrust));
        self.register(Box::new(HardwareSecurityTests::CryptoAcceleration));
        self.register(Box::new(HardwareSecurityTests::RandomNumberGenerator));
    }

    fn register_runtime_tests(&mut self) {
        // Runtime security tests
        self.register(Box::new(RuntimeSecurityTests::FilesystemEncryption));
        self.register(Box::new(RuntimeSecurityTests::FirewallActive));
        self.register(Box::new(RuntimeSecurityTests::SelinuxStatus));
        self.register(Box::new(RuntimeSecurityTests::SshConfiguration));
        self.register(Box::new(RuntimeSecurityTests::UserPermissions));
        self.register(Box::new(RuntimeSecurityTests::ServiceHardening));
        self.register(Box::new(RuntimeSecurityTests::KernelProtections));
    }

    fn register_network_tests(&mut self) {
        // Network security tests
        self.register(Box::new(NetworkSecurityTests::OpenPorts));
        self.register(Box::new(NetworkSecurityTests::NetworkServices));
        self.register(Box::new(NetworkSecurityTests::WifiSecurity));
        self.register(Box::new(NetworkSecurityTests::BluetoothSecurity));
        self.register(Box::new(NetworkSecurityTests::NetworkEncryption));
    }

    fn register_compliance_tests(&mut self) {
        // Compliance-specific tests
        self.register(Box::new(ComplianceTests::CraDataProtection));
        self.register(Box::new(ComplianceTests::CraVulnerabilityManagement));
        self.register(Box::new(ComplianceTests::RedSecurityRequirements));
        self.register(Box::new(ComplianceTests::IncidentResponse));
        self.register(Box::new(ComplianceTests::AuditLogging));
    }

    fn register(&mut self, test: Box<dyn SecurityTest + Send + Sync>) {
        self.tests.insert(test.test_id().to_string(), test);
    }

    pub fn get_tests_for_suite(&self, suite: &TestSuite) -> Vec<&str> {
        match suite {
            TestSuite::All => self.tests.keys().map(|k| k.as_str()).collect(),
            TestSuite::Boot => self.get_tests_by_category("boot"),
            TestSuite::Runtime => self.get_tests_by_category("runtime"),
            TestSuite::Hardware => self.get_tests_by_category("hardware"),
            TestSuite::Network => self.get_tests_by_category("network"),
            TestSuite::Compliance => self.get_tests_by_category("compliance"),
            TestSuite::Custom => {
                // TODO: Load from config file
                vec![]
            }
        }
    }

    fn get_tests_by_category(&self, category: &str) -> Vec<&str> {
        self.tests
            .iter()
            .filter(|(_, test)| test.category() == category)
            .map(|(id, _)| id.as_str())
            .collect()
    }

    pub fn get_test(&self, test_id: &str) -> Option<&(dyn SecurityTest + Send + Sync)> {
        self.tests.get(test_id).map(|t| t.as_ref())
    }

    pub fn list_tests(&self) {
        println!("Available Security Compliance Tests:");
        println!("==================================");
        
        let mut categories: HashMap<String, Vec<&str>> = HashMap::new();
        
        for (test_id, test) in &self.tests {
            categories
                .entry(test.category().to_string())
                .or_insert_with(Vec::new)
                .push(test_id);
        }

        for (category, test_ids) in categories {
            println!("\n📁 {} Tests:", category.to_uppercase());
            for test_id in test_ids {
                if let Some(test) = self.get_test(test_id) {
                    println!("  🔍 {} - {}", test.test_id(), test.test_name());
                    println!("      {}", test.description());
                }
            }
        }
    }
}

pub fn list_available_tests() {
    let registry = TestRegistry::new();
    registry.list_tests();
}

// Helper functions for common test patterns
pub fn create_test_result(
    test_id: &str,
    test_name: &str,
    category: &str,
    status: TestStatus,
    message: &str,
    details: Option<String>,
    duration: Duration,
) -> TestResult {
    TestResult {
        test_id: test_id.to_string(),
        test_name: test_name.to_string(),
        category: category.to_string(),
        status,
        message: message.to_string(),
        details,
        duration,
        timestamp: Utc::now(),
        metadata: HashMap::new(),
    }
}

pub async fn check_command_success(
    target: &mut Target,
    command: &str,
    expected_pattern: Option<&str>,
) -> Result<bool> {
    let result = target.execute_command(command).await?;
    
    if result.exit_code != 0 {
        return Ok(false);
    }

    if let Some(pattern) = expected_pattern {
        let regex = regex::Regex::new(pattern)?;
        Ok(regex.is_match(&result.stdout))
    } else {
        Ok(true)
    }
}
