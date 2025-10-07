use crate::{
    config::TargetConfig,
    error::{Error, Result},
    target::CommandResult,
};
use ssh2::Session;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::{Duration, Instant};
use tracing::{debug, warn};

pub struct SshClient {
    config: TargetConfig,
    session: Option<Session>,
}

impl SshClient {
    pub fn new(config: &TargetConfig) -> Result<Self> {
        Ok(Self {
            config: config.clone(),
            session: None,
        })
    }

    pub async fn connect(&mut self) -> Result<()> {
        let tcp = TcpStream::connect(format!("{}:{}", self.config.host, self.config.port))
            .map_err(|e| Error::SshConnection(format!("TCP connection failed: {}", e)))?;

        tcp.set_read_timeout(Some(Duration::from_secs(self.config.timeout)))
            .map_err(|e| Error::SshConnection(format!("Failed to set read timeout: {}", e)))?;

        let mut sess = Session::new()
            .map_err(|e| Error::SshConnection(format!("Failed to create SSH session: {}", e)))?;

        sess.set_tcp_stream(tcp);
        sess.handshake()
            .map_err(|e| Error::SshConnection(format!("SSH handshake failed: {}", e)))?;

        sess.userauth_password(&self.config.user, &self.config.password)
            .map_err(|e| Error::SshAuth(format!("Password authentication failed: {}", e)))?;

        if !sess.authenticated() {
            return Err(Error::SshAuth("Authentication failed".to_string()));
        }

        debug!("SSH connection established to {}@{}:{}", 
               self.config.user, self.config.host, self.config.port);

        self.session = Some(sess);
        Ok(())
    }

    pub async fn execute_command(&mut self, command: &str) -> Result<CommandResult> {
        self.execute_command_with_timeout(command, Duration::from_secs(60)).await
    }

    pub async fn execute_command_with_timeout(&mut self, command: &str, timeout: Duration) -> Result<CommandResult> {
        let session = self.session.as_ref()
            .ok_or_else(|| Error::SshConnection("Not connected".to_string()))?;

        let mut channel = session.channel_session()
            .map_err(|e| Error::CommandExecution(format!("Failed to create channel: {}", e)))?;

        let start_time = Instant::now();

        channel.exec(command)
            .map_err(|e| Error::CommandExecution(format!("Failed to execute command: {}", e)))?;

        let mut stdout = String::new();
        let mut stderr = String::new();

        // Read stdout
        channel.read_to_string(&mut stdout)
            .map_err(|e| Error::CommandExecution(format!("Failed to read stdout: {}", e)))?;

        // Read stderr
        channel.stderr().read_to_string(&mut stderr)
            .map_err(|e| Error::CommandExecution(format!("Failed to read stderr: {}", e)))?;

        channel.wait_close()
            .map_err(|e| Error::CommandExecution(format!("Failed to close channel: {}", e)))?;

        let exit_code = channel.exit_status()
            .map_err(|e| Error::CommandExecution(format!("Failed to get exit status: {}", e)))?;

        let duration = start_time.elapsed();

        if duration > timeout {
            warn!("Command '{}' took {:?}, which exceeds timeout of {:?}", command, duration, timeout);
        }

        debug!("Command '{}' completed in {:?} with exit code {}", command, duration, exit_code);

        Ok(CommandResult {
            stdout,
            stderr,
            exit_code,
            duration,
        })
    }

    pub async fn disconnect(&mut self) -> Result<()> {
        if let Some(mut session) = self.session.take() {
            session.disconnect(None, "Disconnecting", None)
                .map_err(|e| Error::SshConnection(format!("Failed to disconnect: {}", e)))?;
        }
        Ok(())
    }
}
