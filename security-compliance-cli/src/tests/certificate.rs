use crate::{
    error::Result,
    target::Target,
    tests::{create_test_result, SecurityTest, TestResult, TestStatus},
};
use async_trait::async_trait;
use std::time::Instant;

pub enum CertificateTests {
    X509CertificateValidation,
    PkiInfrastructure,
    CertificateExpiration,
    CertificateChainValidation,
    CertificateRevocation,
    CertificateStorage,
    CaCertificateManagement,
    TlsCertificateValidation,
    CertificateRotation,
    CertificateCompliance,
}

#[async_trait]
impl SecurityTest for CertificateTests {
    async fn run(&self, target: &mut Target) -> Result<TestResult> {
        let start_time = Instant::now();
        
        let result = match self {
            Self::X509CertificateValidation => self.test_x509_certificate_validation(target).await,
            Self::PkiInfrastructure => self.test_pki_infrastructure(target).await,
            Self::CertificateExpiration => self.test_certificate_expiration(target).await,
            Self::CertificateChainValidation => self.test_certificate_chain_validation(target).await,
            Self::CertificateRevocation => self.test_certificate_revocation(target).await,
            Self::CertificateStorage => self.test_certificate_storage(target).await,
            Self::CaCertificateManagement => self.test_ca_certificate_management(target).await,
            Self::TlsCertificateValidation => self.test_tls_certificate_validation(target).await,
            Self::CertificateRotation => self.test_certificate_rotation(target).await,
            Self::CertificateCompliance => self.test_certificate_compliance(target).await,
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
            Self::X509CertificateValidation => "certificate_001",
            Self::PkiInfrastructure => "certificate_002",
            Self::CertificateExpiration => "certificate_003",
            Self::CertificateChainValidation => "certificate_004",
            Self::CertificateRevocation => "certificate_005",
            Self::CertificateStorage => "certificate_006",
            Self::CaCertificateManagement => "certificate_007",
            Self::TlsCertificateValidation => "certificate_008",
            Self::CertificateRotation => "certificate_009",
            Self::CertificateCompliance => "certificate_010",
        }
    }

    fn test_name(&self) -> &str {
        match self {
            Self::X509CertificateValidation => "X.509 Certificate Validation",
            Self::PkiInfrastructure => "PKI Infrastructure",
            Self::CertificateExpiration => "Certificate Expiration Monitoring",
            Self::CertificateChainValidation => "Certificate Chain Validation",
            Self::CertificateRevocation => "Certificate Revocation (CRL/OCSP)",
            Self::CertificateStorage => "Certificate Storage Security",
            Self::CaCertificateManagement => "CA Certificate Management",
            Self::TlsCertificateValidation => "TLS Certificate Validation",
            Self::CertificateRotation => "Certificate Rotation",
            Self::CertificateCompliance => "Certificate Compliance",
        }
    }

    fn category(&self) -> &str {
        "certificate"
    }

    fn description(&self) -> &str {
        match self {
            Self::X509CertificateValidation => "Verify X.509 certificate validation processes",
            Self::PkiInfrastructure => "Check PKI infrastructure and certificate authorities",
            Self::CertificateExpiration => "Monitor certificate expiration and renewal",
            Self::CertificateChainValidation => "Verify certificate chain validation",
            Self::CertificateRevocation => "Check certificate revocation mechanisms",
            Self::CertificateStorage => "Verify secure certificate storage",
            Self::CaCertificateManagement => "Check CA certificate management",
            Self::TlsCertificateValidation => "Verify TLS certificate validation",
            Self::CertificateRotation => "Check certificate rotation mechanisms",
            Self::CertificateCompliance => "Verify certificate compliance standards",
        }
    }
}

impl CertificateTests {
    async fn test_x509_certificate_validation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check OpenSSL availability and version
        let openssl_version = target.execute_command("openssl version 2>/dev/null || echo 'not_available'").await?;
        
        // Check system certificate store
        let cert_store = target.execute_command("ls -la /etc/ssl/certs/ | wc -l").await?;
        let ca_bundle = target.execute_command("ls -la /etc/ssl/certs/ca-certificates.crt 2>/dev/null || echo 'not_found'").await?;
        
        // Test certificate validation
        let cert_validation_test = target.execute_command("openssl verify /etc/ssl/certs/ca-certificates.crt 2>/dev/null || echo 'validation_failed'").await?;
        
        // Check certificate formats supported
        let cert_formats = target.execute_command("openssl list -digest-algorithms 2>/dev/null | head -5 || echo 'list_unavailable'").await?;
        
        let cert_count: usize = cert_store.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("OpenSSL version: {}\nCertificate store count: {}\nCA bundle: {}\nValidation test: {}\nSupported formats: {}", 
                             openssl_version.stdout.trim(), cert_count, ca_bundle.stdout.trim(), 
                             cert_validation_test.stdout, cert_formats.stdout);
        
        if openssl_version.stdout.contains("not_available") {
            Ok((TestStatus::Failed, "OpenSSL not available for certificate validation".to_string(), Some(details)))
        } else if cert_count > 100 && !ca_bundle.stdout.contains("not_found") {
            Ok((TestStatus::Passed, "X.509 certificate validation infrastructure is complete".to_string(), Some(details)))
        } else if cert_count > 50 {
            Ok((TestStatus::Warning, "Basic certificate validation available but incomplete".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Insufficient certificate validation infrastructure".to_string(), Some(details)))
        }
    }

    async fn test_pki_infrastructure(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for PKI tools
        let pki_tools = target.execute_command("which openssl 2>/dev/null && echo 'openssl' && which certtool 2>/dev/null && echo 'certtool' && which pkcs11-tool 2>/dev/null && echo 'pkcs11' || echo ''").await?;
        
        // Check certificate authorities
        let ca_certs = target.execute_command("find /etc/ssl/certs -name '*.pem' | head -5").await?;
        
        // Check for PKCS#11 support
        let pkcs11_support = target.execute_command("find /usr/lib* -name '*pkcs11*' 2>/dev/null | head -3").await?;
        
        // Check for hardware security modules
        let hsm_support = target.execute_command("ls /dev/tpm* 2>/dev/null || echo 'no_tpm'").await?;
        
        // Check certificate trust stores
        let trust_stores = target.execute_command("find /etc -name '*trust*' -type d 2>/dev/null").await?;
        
        let mut pki_components = Vec::new();
        
        if pki_tools.stdout.contains("openssl") {
            pki_components.push("OpenSSL");
        }
        if pki_tools.stdout.contains("certtool") {
            pki_components.push("GnuTLS certtool");
        }
        if pki_tools.stdout.contains("pkcs11") {
            pki_components.push("PKCS#11 tools");
        }
        if !pkcs11_support.stdout.is_empty() {
            pki_components.push("PKCS#11 libraries");
        }
        if !hsm_support.stdout.contains("no_tpm") {
            pki_components.push("TPM/HSM support");
        }
        
        let details = format!("PKI tools: {}\nCA certificates: {}\nPKCS#11 support: {}\nHSM support: {}\nTrust stores: {}\nComponents: {:?}", 
                             pki_tools.stdout, ca_certs.stdout, pkcs11_support.stdout, hsm_support.stdout, 
                             trust_stores.stdout, pki_components);
        
        if pki_components.len() >= 4 {
            Ok((TestStatus::Passed, "Comprehensive PKI infrastructure available".to_string(), Some(details)))
        } else if pki_components.len() >= 2 {
            Ok((TestStatus::Warning, "Basic PKI infrastructure present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Insufficient PKI infrastructure".to_string(), Some(details)))
        }
    }

    async fn test_certificate_expiration(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check certificate expiration dates
        let system_certs_expiry = target.execute_command("find /etc/ssl/certs -name '*.pem' | head -3 | xargs -I {} openssl x509 -in {} -noout -enddate 2>/dev/null | head -3").await?;
        
        // Check device certificates expiry
        let device_certs_expiry = target.execute_command("find /var/sota -name '*.pem' -o -name '*.crt' | xargs -I {} openssl x509 -in {} -noout -enddate 2>/dev/null || echo 'no_device_certs'").await?;
        
        // Check for certificate monitoring tools
        let cert_monitoring = target.execute_command("which certwatch 2>/dev/null || which cert-monitor 2>/dev/null || echo 'no_monitoring'").await?;
        
        // Check cron jobs for certificate monitoring
        let cron_cert_jobs = target.execute_command("crontab -l 2>/dev/null | grep -i cert || echo 'no_cron_jobs'").await?;
        
        // Parse expiration dates and check for soon-to-expire certificates
        let mut expiry_warnings = Vec::new();
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        // Simple check for "notAfter" dates (this is a basic implementation)
        if system_certs_expiry.stdout.contains("2024") || device_certs_expiry.stdout.contains("2024") {
            expiry_warnings.push("Some certificates may be expiring soon");
        }
        
        let details = format!("System cert expiry: {}\nDevice cert expiry: {}\nMonitoring tools: {}\nCron jobs: {}\nWarnings: {:?}", 
                             system_certs_expiry.stdout, device_certs_expiry.stdout, cert_monitoring.stdout.trim(), 
                             cron_cert_jobs.stdout, expiry_warnings);
        
        if !cert_monitoring.stdout.contains("no_monitoring") && expiry_warnings.is_empty() {
            Ok((TestStatus::Passed, "Certificate expiration monitoring is active".to_string(), Some(details)))
        } else if expiry_warnings.is_empty() {
            Ok((TestStatus::Warning, "No certificate expiration monitoring detected".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Warning, format!("Certificate expiration issues: {:?}", expiry_warnings), Some(details)))
        }
    }

    async fn test_certificate_chain_validation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Test certificate chain validation
        let chain_validation = target.execute_command("openssl verify -CApath /etc/ssl/certs /etc/ssl/certs/ca-certificates.crt 2>/dev/null || echo 'validation_failed'").await?;
        
        // Check intermediate certificates
        let intermediate_certs = target.execute_command("find /etc/ssl/certs -name '*intermediate*' -o -name '*chain*' | wc -l").await?;
        
        // Test chain building
        let chain_building = target.execute_command("openssl s_client -connect google.com:443 -verify_return_error < /dev/null 2>/dev/null | grep -E 'Verify return code|depth' || echo 'test_failed'").await?;
        
        // Check certificate path validation settings
        let path_validation = target.execute_command("cat /etc/ssl/openssl.cnf 2>/dev/null | grep -E 'policy|path' | head -3 || echo 'config_unavailable'").await?;
        
        let intermediate_count: usize = intermediate_certs.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("Chain validation: {}\nIntermediate certs: {}\nChain building test: {}\nPath validation config: {}", 
                             chain_validation.stdout, intermediate_count, chain_building.stdout, path_validation.stdout);
        
        if chain_validation.stdout.contains("OK") && intermediate_count > 0 {
            Ok((TestStatus::Passed, "Certificate chain validation is working correctly".to_string(), Some(details)))
        } else if !chain_validation.stdout.contains("validation_failed") {
            Ok((TestStatus::Warning, "Certificate chain validation partially working".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Certificate chain validation is not working".to_string(), Some(details)))
        }
    }

    async fn test_certificate_revocation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check CRL (Certificate Revocation List) support
        let crl_support = target.execute_command("openssl crl -help 2>&1 | grep -E 'verify|check' | head -2 || echo 'crl_unavailable'").await?;
        
        // Check OCSP (Online Certificate Status Protocol) support
        let ocsp_support = target.execute_command("openssl ocsp -help 2>&1 | grep -E 'url|verify' | head -2 || echo 'ocsp_unavailable'").await?;
        
        // Check for CRL files
        let crl_files = target.execute_command("find /etc/ssl -name '*.crl' | wc -l").await?;
        
        // Check OCSP configuration
        let ocsp_config = target.execute_command("cat /etc/ssl/openssl.cnf 2>/dev/null | grep -i ocsp || echo 'no_ocsp_config'").await?;
        
        // Test OCSP functionality
        let ocsp_test = target.execute_command("timeout 5 openssl s_client -connect google.com:443 -status < /dev/null 2>/dev/null | grep -E 'OCSP|Certificate Status' || echo 'ocsp_test_failed'").await?;
        
        let crl_count: usize = crl_files.stdout.trim().parse().unwrap_or(0);
        
        let mut revocation_features = Vec::new();
        
        if !crl_support.stdout.contains("crl_unavailable") {
            revocation_features.push("CRL support");
        }
        if !ocsp_support.stdout.contains("ocsp_unavailable") {
            revocation_features.push("OCSP support");
        }
        if crl_count > 0 {
            revocation_features.push("CRL files present");
        }
        if !ocsp_config.stdout.contains("no_ocsp_config") {
            revocation_features.push("OCSP configured");
        }
        
        let details = format!("CRL support: {}\nOCSP support: {}\nCRL files: {}\nOCSP config: {}\nOCSP test: {}\nFeatures: {:?}", 
                             crl_support.stdout, ocsp_support.stdout, crl_count, ocsp_config.stdout, 
                             ocsp_test.stdout, revocation_features);
        
        if revocation_features.len() >= 3 {
            Ok((TestStatus::Passed, "Certificate revocation checking is comprehensive".to_string(), Some(details)))
        } else if revocation_features.len() >= 2 {
            Ok((TestStatus::Warning, "Basic certificate revocation support available".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Insufficient certificate revocation checking".to_string(), Some(details)))
        }
    }

    async fn test_certificate_storage(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check certificate storage permissions
        let cert_permissions = target.execute_command("ls -la /etc/ssl/certs/ | head -5").await?;
        let private_key_permissions = target.execute_command("find /etc/ssl/private -type f -exec ls -la {} + 2>/dev/null | head -3 || echo 'no_private_keys'").await?;
        
        // Check certificate store security
        let cert_store_security = target.execute_command("ls -ld /etc/ssl/certs /etc/ssl/private 2>/dev/null").await?;
        
        // Check for encrypted private keys
        let encrypted_keys = target.execute_command("find /etc/ssl/private -name '*.pem' -exec grep -l 'ENCRYPTED' {} + 2>/dev/null | wc -l").await?;
        
        // Check certificate backup
        let cert_backup = target.execute_command("find /var/backups -name '*cert*' -o -name '*ssl*' 2>/dev/null | head -3").await?;
        
        let encrypted_key_count: usize = encrypted_keys.stdout.trim().parse().unwrap_or(0);
        
        let mut security_issues = Vec::new();
        let mut security_features = Vec::new();
        
        if cert_permissions.stdout.contains("rw-r--r--") {
            security_features.push("Proper certificate permissions");
        }
        
        if private_key_permissions.stdout.contains("rw-------") {
            security_features.push("Secure private key permissions");
        } else if !private_key_permissions.stdout.contains("no_private_keys") {
            security_issues.push("Private key permissions too open");
        }
        
        if encrypted_key_count > 0 {
            security_features.push("Encrypted private keys");
        }
        
        if !cert_backup.stdout.is_empty() {
            security_features.push("Certificate backup present");
        }
        
        let details = format!("Cert permissions: {}\nPrivate key permissions: {}\nStore security: {}\nEncrypted keys: {}\nBackup: {}\nFeatures: {:?}\nIssues: {:?}", 
                             cert_permissions.stdout, private_key_permissions.stdout, cert_store_security.stdout, 
                             encrypted_key_count, cert_backup.stdout, security_features, security_issues);
        
        if security_features.len() >= 3 && security_issues.is_empty() {
            Ok((TestStatus::Passed, "Certificate storage security is excellent".to_string(), Some(details)))
        } else if security_features.len() >= 2 && security_issues.len() <= 1 {
            Ok((TestStatus::Warning, "Certificate storage security is adequate".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Certificate storage security is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_ca_certificate_management(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check CA certificate management tools
        let ca_tools = target.execute_command("which update-ca-certificates 2>/dev/null || which ca-certificates-update 2>/dev/null || echo 'no_ca_tools'").await?;
        
        // Check CA certificate count and validity
        let ca_cert_count = target.execute_command("ls /etc/ssl/certs/*.pem 2>/dev/null | wc -l").await?;
        let ca_cert_validity = target.execute_command("find /etc/ssl/certs -name '*.pem' | head -3 | xargs -I {} openssl x509 -in {} -noout -subject -issuer 2>/dev/null | head -6").await?;
        
        // Check for custom CA certificates
        let custom_cas = target.execute_command("find /usr/local/share/ca-certificates -name '*.crt' 2>/dev/null | wc -l").await?;
        
        // Check CA certificate updates
        let ca_update_log = target.execute_command("ls -la /var/log/ca-certificates* 2>/dev/null || echo 'no_update_log'").await?;
        
        let ca_count: usize = ca_cert_count.stdout.trim().parse().unwrap_or(0);
        let custom_ca_count: usize = custom_cas.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("CA tools: {}\nCA cert count: {}\nCA validity: {}\nCustom CAs: {}\nUpdate log: {}", 
                             ca_tools.stdout.trim(), ca_count, ca_cert_validity.stdout, custom_ca_count, ca_update_log.stdout);
        
        if !ca_tools.stdout.contains("no_ca_tools") && ca_count > 100 {
            Ok((TestStatus::Passed, "CA certificate management is properly configured".to_string(), Some(details)))
        } else if ca_count > 50 {
            Ok((TestStatus::Warning, "Basic CA certificate management present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "CA certificate management is insufficient".to_string(), Some(details)))
        }
    }

    async fn test_tls_certificate_validation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Test TLS certificate validation
        let tls_test = target.execute_command("timeout 10 openssl s_client -connect google.com:443 -verify 5 < /dev/null 2>&1 | grep -E 'Verify return code|Certificate chain|depth' | head -5 || echo 'tls_test_failed'").await?;
        
        // Check TLS configuration
        let tls_config = target.execute_command("cat /etc/ssl/openssl.cnf 2>/dev/null | grep -E 'TLS|ssl' | head -3 || echo 'config_unavailable'").await?;
        
        // Check supported TLS versions
        let tls_versions = target.execute_command("openssl s_client -help 2>&1 | grep -E 'tls1|ssl' | head -3 || echo 'version_info_unavailable'").await?;
        
        // Check cipher suites
        let cipher_suites = target.execute_command("openssl ciphers -v 'HIGH:!aNULL:!MD5' 2>/dev/null | wc -l").await?;
        
        let cipher_count: usize = cipher_suites.stdout.trim().parse().unwrap_or(0);
        
        let details = format!("TLS test: {}\nTLS config: {}\nTLS versions: {}\nCipher suites: {}", 
                             tls_test.stdout, tls_config.stdout, tls_versions.stdout, cipher_count);
        
        if tls_test.stdout.contains("Verify return code: 0") && cipher_count > 20 {
            Ok((TestStatus::Passed, "TLS certificate validation is working correctly".to_string(), Some(details)))
        } else if !tls_test.stdout.contains("tls_test_failed") {
            Ok((TestStatus::Warning, "TLS certificate validation partially working".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "TLS certificate validation is not working".to_string(), Some(details)))
        }
    }

    async fn test_certificate_rotation(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check for certificate rotation scripts
        let rotation_scripts = target.execute_command("find /etc/cron* /usr/local/bin -name '*cert*' -o -name '*rotate*' 2>/dev/null | grep -E 'cert|rotate'").await?;
        
        // Check certificate age
        let cert_age = target.execute_command("find /etc/ssl/certs -name '*.pem' -mtime +30 | wc -l").await?;
        
        // Check for automated certificate management (Let's Encrypt, etc.)
        let auto_cert_tools = target.execute_command("which certbot 2>/dev/null || which acme.sh 2>/dev/null || echo 'no_auto_tools'").await?;
        
        // Check certificate renewal configuration
        let renewal_config = target.execute_command("find /etc -name '*renew*' -o -name '*rotation*' 2>/dev/null | head -3").await?;
        
        let old_cert_count: usize = cert_age.stdout.trim().parse().unwrap_or(0);
        
        let mut rotation_features = Vec::new();
        
        if !rotation_scripts.stdout.is_empty() {
            rotation_features.push("Rotation scripts present");
        }
        if !auto_cert_tools.stdout.contains("no_auto_tools") {
            rotation_features.push("Automated certificate tools");
        }
        if !renewal_config.stdout.is_empty() {
            rotation_features.push("Renewal configuration");
        }
        if old_cert_count < 10 {
            rotation_features.push("Certificates appear fresh");
        }
        
        let details = format!("Rotation scripts: {}\nOld certificates: {}\nAuto tools: {}\nRenewal config: {}\nFeatures: {:?}", 
                             rotation_scripts.stdout, old_cert_count, auto_cert_tools.stdout.trim(), 
                             renewal_config.stdout, rotation_features);
        
        if rotation_features.len() >= 3 {
            Ok((TestStatus::Passed, "Certificate rotation is properly configured".to_string(), Some(details)))
        } else if rotation_features.len() >= 2 {
            Ok((TestStatus::Warning, "Basic certificate rotation present".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Certificate rotation is not configured".to_string(), Some(details)))
        }
    }

    async fn test_certificate_compliance(&self, target: &mut Target) -> Result<(TestStatus, String, Option<String>)> {
        // Check certificate compliance standards
        let cert_standards = target.execute_command("openssl x509 -in /etc/ssl/certs/ca-certificates.crt -noout -text 2>/dev/null | grep -E 'Algorithm|Key Usage|Extended Key Usage' | head -5 || echo 'standards_check_failed'").await?;
        
        // Check key lengths
        let key_lengths = target.execute_command("find /etc/ssl/certs -name '*.pem' | head -3 | xargs -I {} openssl x509 -in {} -noout -text 2>/dev/null | grep -E 'Public-Key|RSA|EC' | head -5").await?;
        
        // Check signature algorithms
        let sig_algorithms = target.execute_command("find /etc/ssl/certs -name '*.pem' | head -3 | xargs -I {} openssl x509 -in {} -noout -text 2>/dev/null | grep 'Signature Algorithm' | sort | uniq -c").await?;
        
        // Check for weak algorithms
        let weak_algorithms = target.execute_command("find /etc/ssl/certs -name '*.pem' | xargs -I {} openssl x509 -in {} -noout -text 2>/dev/null | grep -E 'md5|sha1WithRSA' | wc -l").await?;
        
        let weak_count: usize = weak_algorithms.stdout.trim().parse().unwrap_or(0);
        
        let mut compliance_issues = Vec::new();
        let mut compliance_features = Vec::new();
        
        if key_lengths.stdout.contains("2048 bit") || key_lengths.stdout.contains("4096 bit") {
            compliance_features.push("Strong key lengths");
        }
        
        if sig_algorithms.stdout.contains("sha256") {
            compliance_features.push("SHA-256 signatures");
        }
        
        if weak_count > 0 {
            compliance_issues.push(format!("Weak algorithms found: {}", weak_count));
        }
        
        if cert_standards.stdout.contains("Key Usage") {
            compliance_features.push("Proper key usage extensions");
        }
        
        let details = format!("Standards check: {}\nKey lengths: {}\nSignature algorithms: {}\nWeak algorithms: {}\nFeatures: {:?}\nIssues: {:?}", 
                             cert_standards.stdout, key_lengths.stdout, sig_algorithms.stdout, weak_count, 
                             compliance_features, compliance_issues);
        
        if compliance_features.len() >= 3 && compliance_issues.is_empty() {
            Ok((TestStatus::Passed, "Certificate compliance standards are met".to_string(), Some(details)))
        } else if compliance_features.len() >= 2 && compliance_issues.len() <= 1 {
            Ok((TestStatus::Warning, "Most certificate compliance standards met".to_string(), Some(details)))
        } else {
            Ok((TestStatus::Failed, "Certificate compliance standards not met".to_string(), Some(details)))
        }
    }
}
