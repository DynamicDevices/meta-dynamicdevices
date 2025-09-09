/*
 * Simple EdgeLock Enclave Test Utility for i.MX93
 * This provides basic ELE testing when the full NXP test suite isn't available
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

#define ELE_MAILBOX_PATH "/sys/bus/platform/devices/44230000.mailbox"
#define ELE_OCOTP_PATH "/sys/bus/nvmem/devices/ELE-OCOTP0"
#define ELE_RESERVED_MEM_START 0x90000000UL
#define ELE_RESERVED_MEM_SIZE 0x100000UL

void print_usage(const char *prog_name) {
    printf("Simple ELE Test Utility for i.MX93\n");
    printf("Usage: %s [command]\n\n", prog_name);
    printf("Commands:\n");
    printf("  info     - Display ELE hardware information\n");
    printf("  status   - Check ELE status and availability\n");
    printf("  mailbox  - Test ELE mailbox communication\n");
    printf("  ocotp    - Test ELE OCOTP access\n");
    printf("  memory   - Check ELE reserved memory\n");
    printf("  all      - Run all tests\n");
    printf("  help     - Show this help message\n");
}

int check_ele_hardware() {
    struct stat st;
    int score = 0;
    
    printf("=== ELE Hardware Detection ===\n");
    
    // Check ELE mailbox
    if (stat(ELE_MAILBOX_PATH, &st) == 0) {
        printf("✅ ELE Mailbox found: %s\n", ELE_MAILBOX_PATH);
        score++;
    } else {
        printf("❌ ELE Mailbox not found: %s\n", ELE_MAILBOX_PATH);
    }
    
    // Check ELE OCOTP
    if (stat(ELE_OCOTP_PATH, &st) == 0) {
        printf("✅ ELE OCOTP found: %s\n", ELE_OCOTP_PATH);
        score++;
    } else {
        printf("❌ ELE OCOTP not found: %s\n", ELE_OCOTP_PATH);
    }
    
    // Check for ELE in device tree
    if (stat("/proc/device-tree/__symbols__/s4muap", &st) == 0) {
        printf("✅ ELE device tree symbol found\n");
        score++;
    } else {
        printf("❌ ELE device tree symbol not found\n");
    }
    
    printf("\nELE Hardware Score: %d/3\n", score);
    return score;
}

int test_ele_mailbox() {
    char path[256];
    FILE *file;
    
    printf("\n=== ELE Mailbox Test ===\n");
    
    // Check mailbox driver
    snprintf(path, sizeof(path), "%s/driver", ELE_MAILBOX_PATH);
    if (access(path, R_OK) == 0) {
        printf("✅ ELE Mailbox driver accessible\n");
        
        // Try to read driver name
        snprintf(path, sizeof(path), "%s/driver/uevent", ELE_MAILBOX_PATH);
        file = fopen(path, "r");
        if (file) {
            char line[256];
            while (fgets(line, sizeof(line), file)) {
                if (strstr(line, "DRIVER=")) {
                    printf("   Driver: %s", line + 7);
                    break;
                }
            }
            fclose(file);
        }
    } else {
        printf("❌ ELE Mailbox driver not accessible\n");
        return 0;
    }
    
    return 1;
}

int test_ele_ocotp() {
    char path[256];
    struct stat st;
    
    printf("\n=== ELE OCOTP Test ===\n");
    
    // Check OCOTP device
    snprintf(path, sizeof(path), "%s/nvmem", ELE_OCOTP_PATH);
    if (stat(path, &st) == 0) {
        printf("✅ ELE OCOTP device accessible\n");
        printf("   Size: %ld bytes\n", st.st_size);
        
        // Check if readable
        if (access(path, R_OK) == 0) {
            printf("✅ ELE OCOTP readable\n");
        } else {
            printf("⚠️  ELE OCOTP not readable (may require root)\n");
        }
    } else {
        printf("❌ ELE OCOTP device not accessible\n");
        return 0;
    }
    
    return 1;
}

int test_ele_memory() {
    printf("\n=== ELE Memory Test ===\n");
    printf("ELE Reserved Memory: 0x%08lx - 0x%08lx (%lu KB)\n", 
           ELE_RESERVED_MEM_START, 
           ELE_RESERVED_MEM_START + ELE_RESERVED_MEM_SIZE - 1,
           ELE_RESERVED_MEM_SIZE / 1024);
    
    // Check if memory region is mentioned in /proc/iomem
    FILE *iomem = fopen("/proc/iomem", "r");
    if (iomem) {
        char line[256];
        int found = 0;
        while (fgets(line, sizeof(line), iomem)) {
            if (strstr(line, "90000000") && strstr(line, "ele")) {
                printf("✅ ELE memory region found in /proc/iomem:\n   %s", line);
                found = 1;
                break;
            }
        }
        fclose(iomem);
        
        if (!found) {
            printf("⚠️  ELE memory region not explicitly found in /proc/iomem\n");
        }
    }
    
    return 1;
}

void show_ele_status() {
    printf("\n=== ELE Status Summary ===\n");
    
    int hw_score = check_ele_hardware();
    
    if (hw_score >= 2) {
        printf("\n🎉 ELE Hardware appears to be functional!\n");
        printf("   Recommendation: ELE should work with proper software support\n");
    } else if (hw_score == 1) {
        printf("\n⚠️  ELE Hardware partially detected\n");
        printf("   Recommendation: Check kernel configuration and device tree\n");
    } else {
        printf("\n❌ ELE Hardware not detected\n");
        printf("   Recommendation: Verify board support and kernel configuration\n");
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char *command = argv[1];
    
    printf("Simple ELE Test Utility for i.MX93\n");
    printf("===================================\n");
    
    if (strcmp(command, "info") == 0 || strcmp(command, "all") == 0) {
        check_ele_hardware();
    }
    
    if (strcmp(command, "status") == 0 || strcmp(command, "all") == 0) {
        show_ele_status();
    }
    
    if (strcmp(command, "mailbox") == 0 || strcmp(command, "all") == 0) {
        test_ele_mailbox();
    }
    
    if (strcmp(command, "ocotp") == 0 || strcmp(command, "all") == 0) {
        test_ele_ocotp();
    }
    
    if (strcmp(command, "memory") == 0 || strcmp(command, "all") == 0) {
        test_ele_memory();
    }
    
    if (strcmp(command, "help") == 0) {
        print_usage(argv[0]);
    }
    
    return 0;
}
