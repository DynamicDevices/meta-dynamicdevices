use anyhow::Result;
use clap::Parser;
use security_compliance_cli::{
    cli::{Cli, Commands},
    config::Config,
    runner::TestRunner,
    target::Target,
};
use std::process;
use tracing::{error, info};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let cli = Cli::parse();

    // Load configuration
    let config = Config::from_cli(&cli)?;
    
    info!("Security Compliance CLI v{}", env!("CARGO_PKG_VERSION"));
    info!("Target: {}:{}", config.target.host, config.target.port);

    match cli.command {
        Commands::Test { test_suite, .. } => {
            let target = Target::new(config.target)?;
            let mut runner = TestRunner::new(target, config.output)?;
            
            let results = runner.run_tests(&test_suite).await?;
            
            if results.overall_passed() {
                info!("✅ All security compliance tests PASSED");
                process::exit(0);
            } else {
                error!("❌ Security compliance tests FAILED");
                process::exit(1);
            }
        }
        Commands::List => {
            security_compliance_cli::tests::list_available_tests();
        }
        Commands::Validate { config_file } => {
            let config = Config::from_file(&config_file)?;
            println!("✅ Configuration file is valid");
            println!("{:#?}", config);
        }
    }

    Ok(())
}
