use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum NetworkSecurityTests {
    OpenPorts,
    NetworkServices,
    WifiSecurity,
    BluetoothSecurity,
    NetworkEncryption,
}

#[async_trait]
impl SecurityTest for NetworkSecurityTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::OpenPorts => self.test_open_ports(target).await,
            Self::NetworkServices => self.test_network_services(target).await,
            Self::WifiSecurity => self.test_wifi_security(target).await,
            Self::BluetoothSecurity => self.test_bluetooth_security(target).await,
            Self::NetworkEncryption => self.test_network_encryption(target).await,
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
            Self::OpenPorts => "network_001",
            Self::NetworkServices => "network_002",
            Self::WifiSecurity => "network_003",
            Self::BluetoothSecurity => "network_004",
            Self::NetworkEncryption => "network_005",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::OpenPorts => "Open Network Ports",
            Self::NetworkServices => "Network Services Security",
            Self::WifiSecurity => "WiFi Security Configuration",
            Self::BluetoothSecurity => "Bluetooth Security",
            Self::NetworkEncryption => "Network Encryption",
        }
    }

    fn category(&self) -> &str {
        "network"
    }

    fn description(&self) -> &str {
        match self {
            Self::OpenPorts => "Check for unnecessary open network ports",
            Self::NetworkServices => "Verify network service security configuration",
            Self::WifiSecurity => "Check WiFi security settings and protocols",
            Self::BluetoothSecurity => "Verify Bluetooth security configuration",
            Self::NetworkEncryption => "Check network traffic encryption capabilities",
        }
    }
}

impl NetworkSecurityTests {
    async fn test_open_ports(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check listening ports
        let netstat = target.execute_command("netstat -tuln 2>/dev/null || ss -tuln").await?;
        
        // Count open ports
        let port_count = netstat.stdout.lines()
            .filter(|line| line.contains("LISTEN") || line.contains("State"))
            .count();
        
        // Check for risky ports
        let risky_ports = ["21", "23", "25", "53", "80", "135", "139", "445"];
        let mut open_risky = Vec::new();
        
        for port in &risky_ports {
            if netstat.stdout.contains(&format!(":{}", port)) {
                open_risky.push(*port);
            }
        }
        
        let details = format!("Open ports ({}): {}\nRisky ports: {:?}", port_count, netstat.stdout, open_risky);
        
        if open_risky.is_empty() && port_count <= 5 {
            Ok((TestStatus::Passed, format!("Port security good ({} ports)", port_count), Some(details)))
        } else if open_risky.len() <= 1 && port_count <= 10 {
            Ok((TestStatus::Warning, format!("Some security concerns ({} ports, {} risky)", port_count, open_risky.len()), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Security issues ({} risky ports)", open_risky.len()), Some(details)))
        }
    }

    async fn test_network_services(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check network-related services
        let network_services = target.execute_command("systemctl list-units --type=service | grep -E 'network|ssh|http|ftp|telnet'").await?;
        
        // Check NetworkManager status
        let nm_status = target.execute_command("systemctl is-active NetworkManager 2>/dev/null || echo 'not_active'").await?;
        
        let details = format!("Network services: {}\nNetworkManager: {}", network_services.stdout, nm_status.stdout.trim());
        
        let service_lines: Vec<&str> = network_services.stdout.lines().collect();
        let active_services = service_lines.len();
        
        if active_services <= 3 && nm_status.stdout.trim() == "active" {
            Ok((TestStatus::Passed, "Network services properly configured".to_string(), Some(details)))
        } else if active_services <= 5 {
            Ok((TestStatus::Warning, format!("Multiple network services active ({})", active_services), Some(details)))
        } else {
            Ok((TestStatus::Failed, format!("Too many network services ({})", active_services), Some(details)))
        }
    }

    async fn test_wifi_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check WiFi interface
        let wifi_interfaces = target.execute_command("iwconfig 2>/dev/null | grep -E 'IEEE 802.11|ESSID' || echo 'no_wifi'").await?;
        
        // Check WiFi security
        let wifi_security = target.execute_command("iw dev 2>/dev/null | grep -A10 Interface || echo 'iw_not_available'").await?;
        
        // Check for WPA supplicant
        let wpa_status = target.execute_command("systemctl is-active wpa_supplicant 2>/dev/null || echo 'not_active'").await?;
        
        let details = format!("WiFi interfaces: {}\nWiFi security: {}\nWPA status: {}", 
                             wifi_interfaces.stdout, wifi_security.stdout, wpa_status.stdout.trim());
        
        if wifi_interfaces.stdout.contains("no_wifi") {
            Ok((TestStatus::Skipped, "No WiFi interface detected".to_string(), None))
        } else if wpa_status.stdout.trim() == "active" {
            Ok((TestStatus::Passed, "WiFi security (WPA) active".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Warning, "WiFi present but security status unclear".to_string(), Some(details)))
        }
    }

    async fn test_bluetooth_security(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check Bluetooth status
        let bt_status = target.execute_command("systemctl is-active bluetooth 2>/dev/null || echo 'not_active'").await?;
        
        // Check Bluetooth configuration
        let hci_status = target.execute_command("hciconfig 2>/dev/null || echo 'hci_not_available'").await?;
        
        // Check if Bluetooth is discoverable
        let bt_discoverable = target.execute_command("hciconfig | grep -i 'ISCAN\\|PSCAN' 2>/dev/null || echo 'not_discoverable'").await?;
        
        let details = format!("BT status: {}\nHCI status: {}\nDiscoverable: {}", 
                             bt_status.stdout.trim(), hci_status.stdout, bt_discoverable.stdout);
        
        if bt_status.stdout.trim() == "active" {
            if bt_discoverable.stdout.contains("not_discoverable") {
                Ok((TestStatus::Passed, "Bluetooth active but not discoverable".to_string(), Some(details)))
            } else {
                Ok((TestStatus::Warning, "Bluetooth active and may be discoverable".to_string(), Some(details)))
            }
        } else {
            Ok((TestStatus::Passed, "Bluetooth not active (secure)".to_string(), Some(details)))
        }
    }

    async fn test_network_encryption(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for TLS/SSL support
        let tls_support = target.execute_command("openssl version 2>/dev/null || echo 'openssl_not_available'").await?;
        
        // Check for VPN capabilities
        let vpn_support = target.execute_command("which openvpn 2>/dev/null || which strongswan 2>/dev/null || echo 'no_vpn'").await?;
        
        // Check for IPsec
        let ipsec_support = target.execute_command("ip xfrm policy list 2>/dev/null | wc -l").await?;
        
        let mut encryption_features = Vec::new();
        
        if !tls_support.stdout.contains("openssl_not_available") {
            encryption_features.push("OpenSSL/TLS");
        }
        
        if !vpn_support.stdout.contains("no_vpn") {
            encryption_features.push("VPN");
        }
        
        let ipsec_policies: usize = ipsec_support.stdout.trim().parse().unwrap_or(0);
        if ipsec_policies > 0 {
            encryption_features.push("IPsec");
        }
        
        let details = format!("TLS: {}\nVPN: {}\nIPsec policies: {}\nFeatures: {:?}", 
                             tls_support.stdout.trim(), vpn_support.stdout.trim(), ipsec_policies, encryption_features);
        
        if encryption_features.len() >= 2 {
            Ok((TestStatus::Passed, format!("Network encryption available: {:?}", encryption_features), Some(details)))
        } else if encryption_features.len() >= 1 {
            Ok((TestStatus::Warning, format!("Limited encryption support: {:?}", encryption_features), Some(details)))
        } else {
            Ok((TestStatus::Failed, "No network encryption detected".to_string(), Some(details)))
        }
    }
}
