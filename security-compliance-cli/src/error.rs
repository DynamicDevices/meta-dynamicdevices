use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("SSH connection failed: {0}")]
    SshConnection(String),

    #[error("SSH authentication failed: {0}")]
    SshAuth(String),

    #[error("Command execution failed: {0}")]
    CommandExecution(String),

    #[error("Test failed: {test_name} - {reason}")]
    TestFailure { test_name: String, reason: String },

    #[error("Configuration error: {0}")]
    Config(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON parsing error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("Regex error: {0}")]
    Regex(#[from] regex::Error),

    #[error("SSH2 error: {0}")]
    Ssh2(#[from] ssh2::Error),
}

pub type Result<T> = std::result::Result<T, Error>;
