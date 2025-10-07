use crate::{
    config::TargetConfig,
    error::{Error, Result},
    ssh::SshClient,
};
use std::time::Duration;
use tracing::{debug, info};

pub struct Target {
    ssh_client: SshClient,
    config: TargetConfig,
}

impl Target {
    pub fn new(config: TargetConfig) -> Result<Self> {
        let ssh_client = SshClient::new(&config)?;
        
        Ok(Self {
            ssh_client,
            config,
        })
    }

    pub async fn connect(&mut self) -> Result<()> {
        info!("Connecting to target {}:{}", self.config.host, self.config.port);
        self.ssh_client.connect().await
    }

    pub async fn execute_command(&mut self, command: &str) -> Result<CommandResult> {
        debug!("Executing command: {}", command);
        self.ssh_client.execute_command(command).await
    }

    pub async fn execute_command_with_timeout(&mut self, command: &str, timeout: Duration) -> Result<CommandResult> {
        debug!("Executing command with timeout {:?}: {}", timeout, command);
        self.ssh_client.execute_command_with_timeout(command, timeout).await
    }

    pub async fn file_exists(&mut self, path: &str) -> Result<bool> {
        let result = self.execute_command(&format!("test -f {} && echo 'exists' || echo 'not_found'", path)).await?;
        Ok(result.stdout.trim() == "exists")
    }

    pub async fn read_file(&mut self, path: &str) -> Result<String> {
        let result = self.execute_command(&format!("cat {}", path)).await?;
        if result.exit_code == 0 {
            Ok(result.stdout)
        } else {
            Err(Error::CommandExecution(format!("Failed to read file {}: {}", path, result.stderr)))
        }
    }

    pub async fn get_system_info(&mut self) -> Result<SystemInfo> {
        let uname = self.execute_command("uname -a").await?;
        let uptime = self.execute_command("uptime").await?;
        let memory = self.execute_command("free -m").await?;
        let kernel_version = self.execute_command("uname -r").await?;
        let os_release = self.read_file("/etc/os-release").await.unwrap_or_default();

        Ok(SystemInfo {
            uname: uname.stdout.trim().to_string(),
            uptime: uptime.stdout.trim().to_string(),
            memory_info: memory.stdout.trim().to_string(),
            kernel_version: kernel_version.stdout.trim().to_string(),
            os_release,
        })
    }

    pub async fn disconnect(&mut self) -> Result<()> {
        info!("Disconnecting from target");
        self.ssh_client.disconnect().await
    }
}

#[derive(Debug, Clone)]
pub struct CommandResult {
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
    pub duration: Duration,
}

#[derive(Debug, Clone)]
pub struct SystemInfo {
    pub uname: String,
    pub uptime: String,
    pub memory_info: String,
    pub kernel_version: String,
    pub os_release: String,
}
