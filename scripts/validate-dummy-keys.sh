#!/bin/bash
# validate-dummy-keys.sh - Validate that dummy signing keys contain proper licensing metadata
# Copyright (c) 2025 Dynamic Devices Ltd.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC}: $message"
            ((PASSED_CHECKS++))
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC}: $message"
            ((FAILED_CHECKS++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARN${NC}: $message"
            ;;
    esac
    ((TOTAL_CHECKS++))
}

# Function to check if a file contains required metadata
check_file_metadata() {
    local file_path=$1
    local file_type=$2
    
    print_status "INFO" "Checking $file_type: $file_path"
    
    if [[ ! -f "$file_path" ]]; then
        print_status "FAIL" "File does not exist: $file_path"
        return 1
    fi
    
    # Required metadata strings (key parts only for more flexible matching)
    local required_strings=(
        "COPYRIGHT NOTICE"
        "Dynamic Devices Ltd"
        "meta-dynamicdevices"
        "github.com/DynamicDevices/meta-dynamicdevices"
        "support@dynamicdevices.co.uk"
        "DEVELOPMENT ONLY"
        "dynamicdevices.co.uk"
        "COMMERCIAL_LICENSE_REQUIRED"
    )
    
    local missing_strings=()
    
    for required_string in "${required_strings[@]}"; do
        if ! grep -q "$required_string" "$file_path"; then
            missing_strings+=("$required_string")
        fi
    done
    
    if [[ ${#missing_strings[@]} -eq 0 ]]; then
        print_status "PASS" "All required metadata found in $file_path"
        return 0
    else
        print_status "FAIL" "Missing metadata in $file_path:"
        for missing in "${missing_strings[@]}"; do
            echo -e "  ${RED}- Missing:${NC} $missing"
        done
        return 1
    fi
}

# Function to check watermark strings
check_watermark_strings() {
    local file_path=$1
    local expected_watermark=$2
    
    if grep -q "$expected_watermark" "$file_path"; then
        print_status "PASS" "Watermark string found: $expected_watermark"
        return 0
    else
        print_status "FAIL" "Watermark string missing: $expected_watermark"
        return 1
    fi
}

# Main validation function
main() {
    echo -e "${BLUE}🔍 Validating Dummy Signing Keys Licensing Metadata${NC}"
    echo "=================================================="
    
    # Check if factory-keys directory exists
    if [[ ! -d "conf/factory-keys" ]]; then
        print_status "FAIL" "Factory keys directory does not exist: conf/factory-keys"
        exit 1
    fi
    
    print_status "INFO" "Found factory-keys directory"
    
    # Define expected files and their watermarks
    declare -A key_files=(
        ["conf/factory-keys/ubootdev.key"]="DUMMY_UBOOT_KEY_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
        ["conf/factory-keys/spldev.key"]="DUMMY_SPL_KEY_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
        ["conf/factory-keys/uefi/DB.key"]="DUMMY_UEFI_KEY_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
    )
    
    declare -A cert_files=(
        ["conf/factory-keys/ubootdev.crt"]="DUMMY_UBOOT_CERT_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
        ["conf/factory-keys/spldev.crt"]="DUMMY_SPL_CERT_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
        ["conf/factory-keys/uefi/DB.crt"]="DUMMY_UEFI_CERT_DYNAMIC_DEVICES_COPYRIGHT_2025_COMMERCIAL_LICENSE_REQUIRED"
    )
    
    echo
    echo -e "${BLUE}📋 Checking Private Keys${NC}"
    echo "------------------------"
    
    # Check private keys
    for key_file in "${!key_files[@]}"; do
        check_file_metadata "$key_file" "Private Key"
        check_watermark_strings "$key_file" "${key_files[$key_file]}"
        echo
    done
    
    echo -e "${BLUE}📋 Checking Certificates${NC}"
    echo "------------------------"
    
    # Check certificates
    for cert_file in "${!cert_files[@]}"; do
        check_file_metadata "$cert_file" "Certificate"
        check_watermark_strings "$cert_file" "${cert_files[$cert_file]}"
        echo
    done
    
    # Summary
    echo "=================================================="
    echo -e "${BLUE}📊 Validation Summary${NC}"
    echo "Total checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo
        echo -e "${GREEN}🎉 All dummy signing keys contain proper licensing metadata!${NC}"
        echo -e "${GREEN}✅ IP protection watermarks are correctly embedded${NC}"
        exit 0
    else
        echo
        echo -e "${RED}❌ Validation failed! Some keys are missing required metadata${NC}"
        echo -e "${RED}🚨 This could compromise IP protection for dual-licensed project${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
