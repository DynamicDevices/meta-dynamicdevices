use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum ContainerSecurityTests {
    DockerDaemonSecurity,
    ContainerImageSecurity,
    ContainerRuntimeSecurity,
    PodmanSecurity,
    ContainerNetworkSecurity,
    ContainerResourceLimits,
    ContainerUserNamespaces,
    ContainerSelinuxContext,
    ContainerCapabilities,
    ContainerSeccomp,
}

#[async_trait]
impl SecurityTest for ContainerSecurityTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::DockerDaemonSecurity => self.test_docker_daemon_security(target).await,
            Self::ContainerImageSecurity => self.test_container_image_security(target).await,
            Self::ContainerRuntimeSecurity => self.test_container_runtime_security(target).await,
            Self::PodmanSecurity => self.test_podman_security(target).await,
            Self::ContainerNetworkSecurity => self.test_container_network_security(target).await,
            Self::ContainerResourceLimits => self.test_container_resource_limits(target).await,
            Self::ContainerUserNamespaces => self.test_container_user_namespaces(target).await,
            Self::ContainerSelinuxContext => self.test_container_selinux_context(target).await,
            Self::ContainerCapabilities => self.test_container_capabilities(target).await,
            Self::ContainerSeccomp => self.test_container_seccomp(target).await,
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
            Self::DockerDaemonSecurity => "container_001",
            Self::ContainerImageSecurity => "container_002",
            Self::ContainerRuntimeSecurity => "container_003",
            Self::PodmanSecurity => "container_004",
            Self::ContainerNetworkSecurity => "container_005",
            Self::ContainerResourceLimits => "container_006",
            Self::ContainerUserNamespaces => "container_007",
            Self::ContainerSelinuxContext => "container_008",
            Self::ContainerCapabilities => "container_009",
            Self::ContainerSeccomp => "container_010",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::DockerDaemonSecurity => "Docker Daemon Security",
            Self::ContainerImageSecurity => "Container Image Security",
            Self::ContainerRuntimeSecurity => "Container Runtime Security",
            Self::PodmanSecurity => "Podman Security Configuration",
            Self::ContainerNetworkSecurity => "Container Network Security",
            Self::ContainerResourceLimits => "Container Resource Limits",
            Self::ContainerUserNamespaces => "Container User Namespaces",
            Self::ContainerSelinuxContext => "Container SELinux Context",
            Self::ContainerCapabilities => "Container Capabilities",
            Self::ContainerSeccomp => "Container Seccomp Profiles",
        }
    }

    fn category(&self) -> &str {
        "container"
    }

    fn description(&self) -> &str {
        match self {
            Self::DockerDaemonSecurity => "Verify Docker daemon security configuration",
            Self::ContainerImageSecurity => "Check container image security and scanning",
            Self::ContainerRuntimeSecurity => "Verify container runtime security settings",
            Self::PodmanSecurity => "Check Podman rootless security configuration",
            Self::ContainerNetworkSecurity => "Verify container network isolation and security",
            Self::ContainerResourceLimits => "Check container resource limits and quotas",
            Self::ContainerUserNamespaces => "Verify user namespace isolation",
            Self::ContainerSelinuxContext => "Check SELinux container contexts",
            Self::ContainerCapabilities => "Verify container capability restrictions",
            Self::ContainerSeccomp => "Check seccomp security profiles",
        }
    }
}

impl ContainerSecurityTests {
    async fn test_docker_daemon_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check Docker daemon configuration
        let docker_status = target.execute_command("systemctl is-active docker 2>/dev/null || echo 'inactive'").await?;
        let docker_config = target.execute_command("cat /etc/docker/daemon.json 2>/dev/null || echo '{}'").await?;
        
        // Check Docker daemon process arguments
        let docker_process = target.execute_command("ps aux | grep dockerd | grep -v grep || echo 'not_running'").await?;
        
        // Check Docker socket permissions
        let docker_socket = target.execute_command("ls -la /var/run/docker.sock 2>/dev/null || echo 'not_found'").await?;
        
        // Check Docker group membership
        let docker_group = target.execute_command("getent group docker 2>/dev/null || echo 'not_found'").await?;
        
        let mut security_features = Vec::new();
        let mut security_issues = Vec::new();
        
        if docker_config.stdout.contains("userns-remap") {
            security_features.push("User namespace remapping");
        } else {
            security_issues.push("No user namespace remapping");
        }
        
        if docker_config.stdout.contains("no-new-privileges") {
            security_features.push("No new privileges");
        }
        
        if docker_config.stdout.contains("seccomp-profile") {
            security_features.push("Custom seccomp profile");
        }
        
        if docker_process.stdout.contains("--selinux-enabled") {
            security_features.push("SELinux enabled");
        }
        
        if docker_socket.stdout.contains("srw-rw----") {
            security_features.push("Proper socket permissions");
        } else {
            security_issues.push("Docker socket permissions too open");
        }
        
        let details = format!("Docker status: {}\nConfig: {}\nProcess: {}\nSocket: {}\nGroup: {}\nSecurity features: {:?}\nIssues: {:?}", 
                             docker_status.stdout.trim(), docker_config.stdout, docker_process.stdout, 
                             docker_socket.stdout, docker_group.stdout, security_features, security_issues);
        
        if docker_status.stdout.trim() == "inactive" {
            Ok((TestStatus::Skipped, "Docker is not running".to_string(), Some(details)))
        } else if security_features.len() >= 3 && security_issues.is_empty() {
            Ok((TestStatus::Passed, "Docker daemon security is well configured".to_string(), Some(details)))
        } else if security_features.len() >= 1 {
            Ok((TestStatus::Warning, format!("Docker security partially configured ({} features, {} issues)", security_features.len(), security_issues.len()), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Docker daemon security is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_container_image_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check container images
        let docker_images = target.execute_command("docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}' 2>/dev/null || echo 'docker_unavailable'").await?;
        let podman_images = target.execute_command("podman images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}' 2>/dev/null || echo 'podman_unavailable'").await?;
        
        // Check for image scanning tools
        let scanning_tools = target.execute_command("which trivy 2>/dev/null || which clair-scanner 2>/dev/null || which anchore-cli 2>/dev/null || echo 'no_scanner'").await?;
        
        // Check for signed images (Docker Content Trust)
        let content_trust = target.execute_command("echo $DOCKER_CONTENT_TRUST 2>/dev/null || echo 'not_set'").await?;
        
        // Check image signatures
        let cosign_check = target.execute_command("which cosign 2>/dev/null && echo 'available' || echo 'not_available'").await?;
        
        let mut security_measures = Vec::new();
        
        if !scanning_tools.stdout.contains("no_scanner") {
            security_measures.push("Image scanning tools available");
        }
        
        if content_trust.stdout.trim() == "1" {
            security_measures.push("Docker Content Trust enabled");
        }
        
        if cosign_check.stdout.contains("available") {
            security_measures.push("Cosign signature verification available");
        }
        
        let image_count = docker_images.stdout.lines().count() + podman_images.stdout.lines().count();
        
        let details = format!("Docker images:\n{}\nPodman images:\n{}\nScanning tools: {}\nContent trust: {}\nCosign: {}\nSecurity measures: {:?}", 
                             docker_images.stdout, podman_images.stdout, scanning_tools.stdout.trim(), 
                             content_trust.stdout.trim(), cosign_check.stdout.trim(), security_measures);
        
        if image_count == 0 {
            Ok((TestStatus::Skipped, "No container images found".to_string(), Some(details)))
        } else if security_measures.len() >= 2 {
            Ok((TestStatus::Passed, "Container image security measures in place".to_string(), Some(details)))
        } else if security_measures.len() >= 1 {
            Ok((TestStatus::Warning, "Some container image security measures present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No container image security measures detected".to_string(), Some(details)))
        }
    }

    async fn test_container_runtime_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check running containers
        let docker_containers = target.execute_command("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'docker_unavailable'").await?;
        let podman_containers = target.execute_command("podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'podman_unavailable'").await?;
        
        // Check container security options
        let container_inspect = target.execute_command("docker ps -q | head -1 | xargs -I {} docker inspect {} --format '{{.HostConfig.SecurityOpt}}' 2>/dev/null || echo 'no_containers'").await?;
        
        // Check for privileged containers
        let privileged_containers = target.execute_command("docker ps --filter 'status=running' --format '{{.Names}}' | xargs -I {} docker inspect {} --format '{{.Name}}: {{.HostConfig.Privileged}}' 2>/dev/null | grep 'true' | wc -l").await?;
        
        // Check container capabilities
        let container_caps = target.execute_command("docker ps -q | head -1 | xargs -I {} docker inspect {} --format '{{.HostConfig.CapAdd}} {{.HostConfig.CapDrop}}' 2>/dev/null || echo 'no_containers'").await?;
        
        let privileged_count: usize = privileged_containers.stdout.trim().parse().unwrap_or(0);
        let container_count = docker_containers.stdout.lines().count() + podman_containers.stdout.lines().count();
        
        let details = format!("Docker containers:\n{}\nPodman containers:\n{}\nSecurity options: {}\nPrivileged containers: {}\nCapabilities: {}", 
                             docker_containers.stdout, podman_containers.stdout, container_inspect.stdout, 
                             privileged_count, container_caps.stdout);
        
        if container_count == 0 {
            Ok((TestStatus::Skipped, "No containers running".to_string(), Some(details)))
        } else if privileged_count == 0 && container_inspect.stdout.contains("seccomp") {
            Ok((TestStatus::Passed, "Container runtime security is properly configured".to_string(), Some(details)))
        } else if privileged_count <= 1 {
            Ok((TestStatus::Warning, format!("Some security concerns ({} privileged containers)", privileged_count), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Security issues detected ({} privileged containers)", privileged_count), Some(details)))
        }
    }

    async fn test_podman_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check Podman rootless configuration
        let podman_version = target.execute_command("podman --version 2>/dev/null || echo 'not_available'").await?;
        let podman_info = target.execute_command("podman info --format json 2>/dev/null | jq -r '.host.security' 2>/dev/null || echo 'info_unavailable'").await?;
        
        // Check rootless setup
        let rootless_check = target.execute_command("podman info 2>/dev/null | grep -E 'rootless|runAsUser' || echo 'not_rootless'").await?;
        
        // Check user namespaces
        let user_ns = target.execute_command("cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo '0'").await?;
        
        // Check subuid/subgid
        let subuid = target.execute_command("cat /etc/subuid 2>/dev/null | wc -l").await?;
        let subgid = target.execute_command("cat /etc/subgid 2>/dev/null | wc -l").await?;
        
        let user_ns_max: u32 = user_ns.stdout.trim().parse().unwrap_or(0);
        let subuid_count: usize = subuid.stdout.trim().parse().unwrap_or(0);
        let subgid_count: usize = subgid.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Podman version: {}\nSecurity info: {}\nRootless: {}\nUser namespaces max: {}\nSubuid entries: {}\nSubgid entries: {}", 
                             podman_version.stdout.trim(), podman_info.stdout, rootless_check.stdout, 
                             user_ns_max, subuid_count, subgid_count);
        
        if podman_version.stdout.contains("not_available") {
            Ok((TestStatus::Skipped, "Podman is not available".to_string(), Some(details)))
        } else if rootless_check.stdout.contains("rootless") && user_ns_max > 0 && subuid_count > 0 {
            Ok((TestStatus::Passed, "Podman rootless security is properly configured".to_string(), Some(details)))
        } else if !rootless_check.stdout.contains("not_rootless") {
            Ok((TestStatus::Warning, "Podman available but rootless configuration unclear".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Podman security configuration insufficient".to_string(), Some(details)))
        }
    }

    async fn test_container_network_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check Docker networks
        let docker_networks = target.execute_command("docker network ls 2>/dev/null || echo 'docker_unavailable'").await?;
        
        // Check network isolation
        let network_inspect = target.execute_command("docker network inspect bridge 2>/dev/null | jq -r '.[] | .Options' 2>/dev/null || echo 'inspect_unavailable'").await?;
        
        // Check container network modes
        let network_modes = target.execute_command("docker ps -q | xargs -I {} docker inspect {} --format '{{.HostConfig.NetworkMode}}' 2>/dev/null | sort | uniq -c || echo 'no_containers'").await?;
        
        // Check for containers with host networking
        let host_network = target.execute_command("docker ps --filter 'network=host' --format '{{.Names}}' 2>/dev/null | wc -l").await?;
        
        let host_network_count: usize = host_network.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Docker networks:\n{}\nNetwork inspection: {}\nNetwork modes: {}\nHost network containers: {}", 
                             docker_networks.stdout, network_inspect.stdout, network_modes.stdout, host_network_count);
        
        if docker_networks.stdout.contains("docker_unavailable") {
            Ok((TestStatus::Skipped, "Docker networking not available".to_string(), Some(details)))
        } else if host_network_count == 0 && docker_networks.stdout.contains("bridge") {
            Ok((TestStatus::Passed, "Container network security is properly isolated".to_string(), Some(details)))
        } else if host_network_count <= 1 {
            Ok((TestStatus::Warning, format!("Some network security concerns ({} host network containers)", host_network_count), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Network security issues ({} containers using host network)", host_network_count), Some(details)))
        }
    }

    async fn test_container_resource_limits(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check container resource limits
        let container_resources = target.execute_command("docker ps -q | xargs -I {} docker inspect {} --format '{{.Name}}: CPU={{.HostConfig.CpuShares}} MEM={{.HostConfig.Memory}}' 2>/dev/null || echo 'no_containers'").await?;
        
        // Check cgroup limits
        let cgroup_version = target.execute_command("stat -fc %T /sys/fs/cgroup/ 2>/dev/null || echo 'unavailable'").await?;
        let cgroup_controllers = target.execute_command("cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || cat /proc/cgroups 2>/dev/null | head -5").await?;
        
        // Check systemd slice limits
        let systemd_slices = target.execute_command("systemctl list-units --type=slice | grep -E 'docker|container' || echo 'no_slices'").await?;
        
        let details = format!("Container resources:\n{}\nCgroup version: {}\nCgroup controllers: {}\nSystemd slices: {}", 
                             container_resources.stdout, cgroup_version.stdout.trim(), cgroup_controllers.stdout, systemd_slices.stdout);
        
        if container_resources.stdout.contains("no_containers") {
            Ok((TestStatus::Skipped, "No containers to check resource limits".to_string(), Some(details)))
        } else if container_resources.stdout.contains("CPU=") && container_resources.stdout.contains("MEM=") {
            Ok((TestStatus::Passed, "Container resource limits are configured".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Warning, "Container resource limits may not be properly configured".to_string(), Some(details)))
        }
    }

    async fn test_container_user_namespaces(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check user namespace support
        let user_ns_enabled = target.execute_command("cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo '0'").await?;
        
        // Check Docker user namespace remapping
        let docker_userns = target.execute_command("docker info 2>/dev/null | grep -i 'userns' || echo 'not_configured'").await?;
        
        // Check container user mapping
        let container_users = target.execute_command("docker ps -q | head -1 | xargs -I {} docker inspect {} --format '{{.Config.User}}' 2>/dev/null || echo 'no_containers'").await?;
        
        // Check /etc/subuid and /etc/subgid
        let subuid_config = target.execute_command("cat /etc/subuid 2>/dev/null | head -3 || echo 'not_configured'").await?;
        
        let max_user_ns: u32 = user_ns_enabled.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Max user namespaces: {}\nDocker user namespaces: {}\nContainer users: {}\nSubuid config: {}", 
                             max_user_ns, docker_userns.stdout, container_users.stdout, subuid_config.stdout);
        
        if max_user_ns > 0 && !docker_userns.stdout.contains("not_configured") {
            Ok((TestStatus::Passed, "Container user namespaces are properly configured".to_string(), Some(details)))
        } else if max_user_ns > 0 {
            Ok((TestStatus::Warning, "User namespaces available but Docker not configured".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "User namespace support is not available".to_string(), Some(details)))
        }
    }

    async fn test_container_selinux_context(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check SELinux status
        let selinux_status = target.execute_command("getenforce 2>/dev/null || echo 'not_available'").await?;
        
        // Check container SELinux contexts
        let container_contexts = target.execute_command("docker ps -q | xargs -I {} docker inspect {} --format '{{.ProcessLabel}}' 2>/dev/null || echo 'no_containers'").await?;
        
        // Check SELinux container policies
        let selinux_policies = target.execute_command("semodule -l 2>/dev/null | grep -E 'container|docker' || echo 'no_policies'").await?;
        
        let details = format!("SELinux status: {}\nContainer contexts: {}\nSELinux policies: {}", 
                             selinux_status.stdout.trim(), container_contexts.stdout, selinux_policies.stdout);
        
        match selinux_status.stdout.trim() {
            "Enforcing" => {
                if !container_contexts.stdout.contains("no_containers") && container_contexts.stdout.contains("container_t") {
                    Ok((TestStatus::Passed, "Container SELinux contexts are properly enforced".to_string(), Some(details)))
                } else {
                    Ok((TestStatus::Warning, "SELinux enforcing but container contexts unclear".to_string(), Some(details)))
                }
            }
            "Permissive" => Ok((TestStatus::Warning, "SELinux permissive - container contexts not enforced".to_string(), Some(details))),
            "Disabled" => Ok((TestStatus::Skipped, "SELinux disabled - no container context enforcement".to_string(), Some(details))),
            _ => Ok((TestStatus::Skipped, "SELinux not available".to_string(), Some(details))),
        }
    }

    async fn test_container_capabilities(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check container capabilities
        let container_caps = target.execute_command("docker ps -q | xargs -I {} docker inspect {} --format '{{.Name}}: Add={{.HostConfig.CapAdd}} Drop={{.HostConfig.CapDrop}}' 2>/dev/null || echo 'no_containers'").await?;
        
        // Check default capability set
        let default_caps = target.execute_command("docker run --rm alpine sh -c 'cat /proc/self/status | grep Cap' 2>/dev/null || echo 'test_unavailable'").await?;
        
        // Check for dangerous capabilities
        let dangerous_caps = ["SYS_ADMIN", "NET_ADMIN", "SYS_MODULE", "SYS_RAWIO"];
        let mut dangerous_found = Vec::new();
        
        for cap in &dangerous_caps {
            if container_caps.stdout.contains(cap) {
                dangerous_found.push(*cap);
            }
        }
        
        let details = format!("Container capabilities:\n{}\nDefault caps test: {}\nDangerous caps found: {:?}", 
                             container_caps.stdout, default_caps.stdout, dangerous_found);
        
        if container_caps.stdout.contains("no_containers") {
            Ok((TestStatus::Skipped, "No containers to check capabilities".to_string(), Some(details)))
        } else if dangerous_found.is_empty() && container_caps.stdout.contains("Drop=") {
            Ok((TestStatus::Passed, "Container capabilities are properly restricted".to_string(), Some(details)))
        } else if dangerous_found.len() <= 1 {
            Ok((TestStatus::Warning, format!("Some dangerous capabilities found: {:?}", dangerous_found), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Multiple dangerous capabilities found: {:?}", dangerous_found), Some(details)))
        }
    }

    async fn test_container_seccomp(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check seccomp support
        let seccomp_support = target.execute_command("grep -i seccomp /boot/config-$(uname -r) 2>/dev/null || echo 'config_unavailable'").await?;
        
        // Check container seccomp profiles
        let container_seccomp = target.execute_command("docker ps -q | xargs -I {} docker inspect {} --format '{{.HostConfig.SecurityOpt}}' 2>/dev/null | grep seccomp || echo 'no_seccomp'").await?;
        
        // Check default seccomp profile
        let default_seccomp = target.execute_command("docker info 2>/dev/null | grep -i seccomp || echo 'not_configured'").await?;
        
        // Check custom seccomp profiles
        let custom_profiles = target.execute_command("find /etc/docker -name '*seccomp*' 2>/dev/null || echo 'no_custom_profiles'").await?;
        
        let details = format!("Seccomp support: {}\nContainer seccomp: {}\nDefault seccomp: {}\nCustom profiles: {}", 
                             seccomp_support.stdout, container_seccomp.stdout, default_seccomp.stdout, custom_profiles.stdout);
        
        if seccomp_support.stdout.contains("CONFIG_SECCOMP=y") {
            if !container_seccomp.stdout.contains("no_seccomp") {
                Ok((TestStatus::Passed, "Container seccomp profiles are active".to_string(), Some(details)))
            } else {
                Ok((TestStatus::Warning, "Seccomp supported but not used by containers".to_string(), Some(details)))
            }
        } else {
            Ok((TestStatus::Failed, "Seccomp support not available or not configured".to_string(), Some(details)))
        }
    }
}
