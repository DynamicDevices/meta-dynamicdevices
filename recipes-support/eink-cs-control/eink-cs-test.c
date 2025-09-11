/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * E-Ink Dual Chip Select Test Program
 * Copyright 2025 Dynamic Devices Ltd
 */

#include "eink-cs-control.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void print_usage(const char *prog_name) {
    printf("Usage: %s [command]\n", prog_name);
    printf("\n");
    printf("Commands:\n");
    printf("  init      - Initialize CS GPIOs (both deselected)\n");
    printf("  left      - Select left display half (CS0 active)\n");
    printf("  right     - Select right display half (CS1 active)\n");
    printf("  deselect  - Deselect both halves (both inactive)\n");
    printf("  status    - Show current CS status\n");
    printf("  test      - Run comprehensive CS switching test\n");
    printf("  cleanup   - Clean up GPIO exports\n");
    printf("\n");
    printf("GPIO Mappings:\n");
    printf("  CS0 (Left):  GPIO %d (GPIO2_IO17)\n", CS0_GPIO);
    printf("  CS1 (Right): GPIO %d (GPIO1_IO11)\n", CS1_GPIO);
    printf("\n");
    printf("CS Logic: Active LOW (0=selected, 1=deselected)\n");
}

static void print_status(void) {
    eink_cs_status_t status;
    
    if (eink_cs_get_status(&status) < 0) {
        printf("ERROR: Failed to get CS status\n");
        return;
    }
    
    printf("CS Status: CS0=%s, CS1=%s\n", 
           status.cs0_active ? "ACTIVE" : "inactive",
           status.cs1_active ? "ACTIVE" : "inactive");
    
    switch (status.selection) {
        case EINK_CS_NONE:
            printf("Active: None (both deselected)\n");
            break;
        case EINK_CS_LEFT:
            printf("Active: Left half (CS0)\n");
            break;
        case EINK_CS_RIGHT:
            printf("Active: Right half (CS1)\n");
            break;
    }
}

int main(int argc, char *argv[]) {
    const char *command = (argc > 1) ? argv[1] : "help";
    
    /* Enable debug output */
    eink_cs_set_debug(true);
    
    if (strcmp(command, "init") == 0) {
        if (eink_cs_init() < 0) {
            fprintf(stderr, "Failed to initialize CS GPIOs\n");
            return 1;
        }
        printf("CS GPIOs initialized successfully\n");
        
    } else if (strcmp(command, "left") == 0) {
        if (eink_cs_init() < 0 || eink_cs_select_left() < 0) {
            fprintf(stderr, "Failed to select left half\n");
            return 1;
        }
        printf("Left half selected successfully\n");
        
    } else if (strcmp(command, "right") == 0) {
        if (eink_cs_init() < 0 || eink_cs_select_right() < 0) {
            fprintf(stderr, "Failed to select right half\n");
            return 1;
        }
        printf("Right half selected successfully\n");
        
    } else if (strcmp(command, "deselect") == 0 || strcmp(command, "none") == 0) {
        if (eink_cs_init() < 0 || eink_cs_deselect_all() < 0) {
            fprintf(stderr, "Failed to deselect both halves\n");
            return 1;
        }
        printf("Both halves deselected successfully\n");
        
    } else if (strcmp(command, "status") == 0) {
        print_status();
        
    } else if (strcmp(command, "test") == 0) {
        if (eink_cs_test() < 0) {
            fprintf(stderr, "CS test failed\n");
            return 1;
        }
        printf("CS test completed successfully\n");
        
    } else if (strcmp(command, "cleanup") == 0) {
        if (eink_cs_cleanup() < 0) {
            fprintf(stderr, "Failed to cleanup CS GPIOs\n");
            return 1;
        }
        printf("CS GPIO cleanup completed\n");
        
    } else {
        print_usage(argv[0]);
        return (strcmp(command, "help") == 0) ? 0 : 1;
    }
    
    return 0;
}
