use clap::{Parser, Subcommand, ValueEnum};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "security-compliance-cli")]
#[command(about = "Security compliance testing for Dynamic Devices embedded systems")]
#[command(version = env!("CARGO_PKG_VERSION"))]
#[command(author = "Alex J Lennon <ajlennon@dynamicdevices.co.uk>")]
pub struct Cli {
    /// Target IP address
    #[arg(short = 'H', long, default_value = "192.168.0.36")]
    pub host: String,

    /// Target SSH port
    #[arg(short, long, default_value = "22")]
    pub port: u16,

    /// SSH username
    #[arg(short, long, default_value = "fio")]
    pub user: String,

    /// SSH password
    #[arg(short = 'P', long, default_value = "fio")]
    pub password: String,

    /// SSH connection timeout in seconds
    #[arg(long, default_value = "30")]
    pub timeout: u64,

    /// Output format
    #[arg(short = 'f', long, default_value = "human")]
    pub format: OutputFormat,

    /// Verbose output
    #[arg(short, long, action = clap::ArgAction::Count)]
    pub verbose: u8,

    /// Configuration file
    #[arg(short, long)]
    pub config: Option<PathBuf>,

    /// Output file for results
    #[arg(short, long)]
    pub output: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Run security compliance tests
    Test {
    /// Test suite to run
    #[arg(short, long, default_value = "all")]
    test_suite: TestSuite,

    /// Testing mode (pre-production vs production)
    #[arg(short, long, default_value = "pre-production")]
    mode: TestMode,

    /// Continue on test failure
    #[arg(long)]
    continue_on_failure: bool,

    /// Generate detailed report
    #[arg(long)]
    detailed_report: bool,
    },
    /// List available tests
    List,
    /// Validate configuration file
    Validate {
        /// Configuration file to validate
        config_file: PathBuf,
    },
}

#[derive(Clone, ValueEnum)]
pub enum OutputFormat {
    /// Human-readable output with colors and progress
    Human,
    /// JSON structured output
    Json,
    /// JUnit XML format for CI integration
    Junit,
    /// Markdown report format
    Markdown,
}

#[derive(Clone, ValueEnum)]
pub enum TestSuite {
    /// Run all security compliance tests
    All,
    /// Boot security tests (secure boot, signatures)
    Boot,
    /// Runtime security tests (firewall, encryption)
    Runtime,
    /// Hardware security tests (secure enclave, TPM)
    Hardware,
    /// Network security tests
    Network,
    /// Compliance tests (CRA, RED specific)
    Compliance,
    /// Production hardening tests
    Production,
    /// Development/testing specific tests
    Development,
    /// Custom test suite from config
    Custom,
}

#[derive(Clone, ValueEnum)]
pub enum TestMode {
    /// Pre-production testing (development/CI builds)
    PreProduction,
    /// Production testing (hardened, deployed systems)
    Production,
}
