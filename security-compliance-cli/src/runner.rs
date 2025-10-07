use crate::{
    cli::TestSuite,
    config::OutputConfig,
    error::Result,
    output::OutputHandler,
    target::Target,
    tests::{TestRegistry, TestSuiteResults, TestStatus},
};
use chrono::Utc;
use std::time::Instant;
use tracing::{info, warn, error};

pub struct TestRunner {
    target: Target,
    output_handler: OutputHandler,
    registry: TestRegistry,
}

impl TestRunner {
    pub fn new(target: Target, output_config: OutputConfig) -> Result<Self> {
        let output_handler = OutputHandler::new(output_config)?;
        let registry = TestRegistry::new();
        
        Ok(Self {
            target,
            output_handler,
            registry,
        })
    }

    pub async fn run_tests(&mut self, test_suite: &TestSuite) -> Result<TestSuiteResults> {
        info!("Starting security compliance test suite: {:?}", test_suite);
        
        let start_time = Instant::now();
        
        // Connect to target
        self.target.connect().await?;
        
        // Get system information
        let system_info = self.target.get_system_info().await?;
        info!("Target system: {}", system_info.uname);
        
        // Get tests for the suite
        let test_ids = self.registry.get_tests_for_suite(test_suite);
        info!("Running {} tests", test_ids.len());
        
        let mut results = Vec::new();
        let mut passed = 0;
        let mut failed = 0;
        let mut warnings = 0;
        let mut skipped = 0;
        let mut errors = 0;
        
        // Initialize progress reporting
        self.output_handler.start_test_suite(&format!("{:?}", test_suite), test_ids.len()).await?;
        
        // Run each test
        for (index, test_id) in test_ids.iter().enumerate() {
            if let Some(test) = self.registry.get_test(test_id) {
                info!("Running test {}/{}: {} - {}", index + 1, test_ids.len(), test.test_id(), test.test_name());
                
                self.output_handler.start_test(test.test_id(), test.test_name()).await?;
                
                let result = test.run(&mut self.target).await?;
                
                match result.status {
                    TestStatus::Passed => {
                        passed += 1;
                        info!("✅ {} PASSED: {}", result.test_id, result.message);
                    }
                    TestStatus::Failed => {
                        failed += 1;
                        error!("❌ {} FAILED: {}", result.test_id, result.message);
                    }
                    TestStatus::Warning => {
                        warnings += 1;
                        warn!("⚠️  {} WARNING: {}", result.test_id, result.message);
                    }
                    TestStatus::Skipped => {
                        skipped += 1;
                        info!("⏭️  {} SKIPPED: {}", result.test_id, result.message);
                    }
                    TestStatus::Error => {
                        errors += 1;
                        error!("💥 {} ERROR: {}", result.test_id, result.message);
                    }
                }
                
                self.output_handler.complete_test(&result).await?;
                results.push(result);
            } else {
                error!("Test not found: {}", test_id);
            }
        }
        
        // Disconnect from target
        self.target.disconnect().await?;
        
        let duration = start_time.elapsed();
        
        let suite_results = TestSuiteResults {
            suite_name: format!("{:?}", test_suite),
            total_tests: test_ids.len(),
            passed,
            failed,
            warnings,
            skipped,
            errors,
            duration,
            timestamp: Utc::now(),
            system_info,
            results,
        };
        
        // Complete test suite reporting
        self.output_handler.complete_test_suite(&suite_results).await?;
        
        info!("Test suite completed in {:?}", duration);
        info!("Results: {} passed, {} failed, {} warnings, {} skipped, {} errors", 
              passed, failed, warnings, skipped, errors);
        
        Ok(suite_results)
    }
}
