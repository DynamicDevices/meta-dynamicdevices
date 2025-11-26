/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * E-Ink Dual Chip Select Control Library
 * Copyright 2025 Dynamic Devices Ltd
 */

#include "eink-cs-control.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

/* Debug output control */
static bool debug_enabled = false;

/* GPIO sysfs paths */
#define GPIO_EXPORT_PATH    "/sys/class/gpio/export"
#define GPIO_UNEXPORT_PATH  "/sys/class/gpio/unexport"
#define GPIO_BASE_PATH      "/sys/class/gpio/gpio"

/* Helper macros */
#define DEBUG_PRINT(fmt, ...) do { \
    if (debug_enabled) { \
        printf("[EINK_CS] " fmt "\n", ##__VA_ARGS__); \
    } \
} while(0)

#define ERROR_PRINT(fmt, ...) \
    fprintf(stderr, "[EINK_CS ERROR] " fmt "\n", ##__VA_ARGS__)

/* Helper functions */
static int gpio_export(int gpio) {
    char gpio_str[16];
    int fd, ret;
    
    snprintf(gpio_str, sizeof(gpio_str), "%d", gpio);
    
    fd = open(GPIO_EXPORT_PATH, O_WRONLY);
    if (fd < 0) {
        ERROR_PRINT("Failed to open GPIO export: %s", strerror(errno));
        return -1;
    }
    
    ret = write(fd, gpio_str, strlen(gpio_str));
    close(fd);
    
    if (ret < 0 && errno != EBUSY) {
        ERROR_PRINT("Failed to export GPIO %d: %s", gpio, strerror(errno));
        return -1;
    }
    
    return 0;
}

static int gpio_unexport(int gpio) {
    char gpio_str[16];
    int fd, ret;
    
    snprintf(gpio_str, sizeof(gpio_str), "%d", gpio);
    
    fd = open(GPIO_UNEXPORT_PATH, O_WRONLY);
    if (fd < 0) {
        ERROR_PRINT("Failed to open GPIO unexport: %s", strerror(errno));
        return -1;
    }
    
    ret = write(fd, gpio_str, strlen(gpio_str));
    close(fd);
    
    if (ret < 0) {
        ERROR_PRINT("Failed to unexport GPIO %d: %s", gpio, strerror(errno));
        return -1;
    }
    
    return 0;
}

static int gpio_set_direction(int gpio, const char *direction) {
    char path[64];
    int fd, ret;
    
    snprintf(path, sizeof(path), GPIO_BASE_PATH "%d/direction", gpio);
    
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        ERROR_PRINT("Failed to open GPIO %d direction: %s", gpio, strerror(errno));
        return -1;
    }
    
    ret = write(fd, direction, strlen(direction));
    close(fd);
    
    if (ret < 0) {
        ERROR_PRINT("Failed to set GPIO %d direction: %s", gpio, strerror(errno));
        return -1;
    }
    
    return 0;
}

static int gpio_set_value(int gpio, int value) {
    char path[64];
    char value_str[2];
    int fd, ret;
    
    snprintf(path, sizeof(path), GPIO_BASE_PATH "%d/value", gpio);
    snprintf(value_str, sizeof(value_str), "%d", value ? 1 : 0);
    
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        ERROR_PRINT("Failed to open GPIO %d value: %s", gpio, strerror(errno));
        return -1;
    }
    
    ret = write(fd, value_str, 1);
    close(fd);
    
    if (ret < 0) {
        ERROR_PRINT("Failed to set GPIO %d value: %s", gpio, strerror(errno));
        return -1;
    }
    
    return 0;
}

static int gpio_get_value(int gpio) {
    char path[64];
    char value_str[2];
    int fd, ret;
    
    snprintf(path, sizeof(path), GPIO_BASE_PATH "%d/value", gpio);
    
    fd = open(path, O_RDONLY);
    if (fd < 0) {
        ERROR_PRINT("Failed to open GPIO %d value: %s", gpio, strerror(errno));
        return -1;
    }
    
    ret = read(fd, value_str, 1);
    close(fd);
    
    if (ret < 0) {
        ERROR_PRINT("Failed to read GPIO %d value: %s", gpio, strerror(errno));
        return -1;
    }
    
    return (value_str[0] == '1') ? 1 : 0;
}

/* Public API functions */

int eink_cs_init(void) {
    DEBUG_PRINT("Initializing E-Ink CS GPIOs...");
    
    /* Export both GPIOs */
    if (gpio_export(CS0_GPIO) < 0) {
        return -1;
    }
    
    if (gpio_export(CS1_GPIO) < 0) {
        return -1;
    }
    
    /* Small delay to allow sysfs to settle */
    usleep(100000); /* 100ms */
    
    /* Set both as outputs */
    if (gpio_set_direction(CS0_GPIO, "out") < 0) {
        return -1;
    }
    
    if (gpio_set_direction(CS1_GPIO, "out") < 0) {
        return -1;
    }
    
    /* Set both HIGH (inactive - not selected) initially */
    if (gpio_set_value(CS0_GPIO, 1) < 0) {
        return -1;
    }
    
    if (gpio_set_value(CS1_GPIO, 1) < 0) {
        return -1;
    }
    
    DEBUG_PRINT("CS GPIOs initialized - both deselected (HIGH)");
    return 0;
}

int eink_cs_select_left(void) {
    DEBUG_PRINT("Selecting left display half (CS0 active)");
    
    /* CS0 LOW (active), CS1 HIGH (inactive) */
    if (gpio_set_value(CS0_GPIO, 0) < 0) {
        return -1;
    }
    
    if (gpio_set_value(CS1_GPIO, 1) < 0) {
        return -1;
    }
    
    /* Verify the selection */
    int cs0_val = gpio_get_value(CS0_GPIO);
    int cs1_val = gpio_get_value(CS1_GPIO);
    
    if (cs0_val < 0 || cs1_val < 0) {
        return -1;
    }
    
    if (cs0_val == 0 && cs1_val == 1) {
        DEBUG_PRINT("Left half selected (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return 0;
    } else {
        ERROR_PRINT("Failed to select left half (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return -1;
    }
}

int eink_cs_select_right(void) {
    DEBUG_PRINT("Selecting right display half (CS1 active)");
    
    /* CS0 HIGH (inactive), CS1 LOW (active) */
    if (gpio_set_value(CS0_GPIO, 1) < 0) {
        return -1;
    }
    
    if (gpio_set_value(CS1_GPIO, 0) < 0) {
        return -1;
    }
    
    /* Verify the selection */
    int cs0_val = gpio_get_value(CS0_GPIO);
    int cs1_val = gpio_get_value(CS1_GPIO);
    
    if (cs0_val < 0 || cs1_val < 0) {
        return -1;
    }
    
    if (cs0_val == 1 && cs1_val == 0) {
        DEBUG_PRINT("Right half selected (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return 0;
    } else {
        ERROR_PRINT("Failed to select right half (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return -1;
    }
}

int eink_cs_deselect_all(void) {
    DEBUG_PRINT("Deselecting both display halves");
    
    /* Both CS lines HIGH (inactive) */
    if (gpio_set_value(CS0_GPIO, 1) < 0) {
        return -1;
    }
    
    if (gpio_set_value(CS1_GPIO, 1) < 0) {
        return -1;
    }
    
    /* Verify deselection */
    int cs0_val = gpio_get_value(CS0_GPIO);
    int cs1_val = gpio_get_value(CS1_GPIO);
    
    if (cs0_val < 0 || cs1_val < 0) {
        return -1;
    }
    
    if (cs0_val == 1 && cs1_val == 1) {
        DEBUG_PRINT("Both halves deselected (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return 0;
    } else {
        ERROR_PRINT("Failed to deselect both halves (CS0=%d, CS1=%d)", cs0_val, cs1_val);
        return -1;
    }
}

int eink_cs_select(eink_cs_selection_t selection) {
    switch (selection) {
        case EINK_CS_NONE:
            return eink_cs_deselect_all();
        case EINK_CS_LEFT:
            return eink_cs_select_left();
        case EINK_CS_RIGHT:
            return eink_cs_select_right();
        default:
            ERROR_PRINT("Invalid CS selection: %d", selection);
            return -1;
    }
}

int eink_cs_get_status(eink_cs_status_t *status) {
    if (!status) {
        ERROR_PRINT("NULL status pointer");
        return -1;
    }
    
    int cs0_val = gpio_get_value(CS0_GPIO);
    int cs1_val = gpio_get_value(CS1_GPIO);
    
    if (cs0_val < 0 || cs1_val < 0) {
        return -1;
    }
    
    status->cs0_active = (cs0_val == 0);
    status->cs1_active = (cs1_val == 0);
    
    if (status->cs0_active && !status->cs1_active) {
        status->selection = EINK_CS_LEFT;
    } else if (!status->cs0_active && status->cs1_active) {
        status->selection = EINK_CS_RIGHT;
    } else if (!status->cs0_active && !status->cs1_active) {
        status->selection = EINK_CS_NONE;
    } else {
        /* Both active - invalid state */
        ERROR_PRINT("Invalid CS state: both CS0 and CS1 active");
        return -1;
    }
    
    return 0;
}

int eink_cs_test(void) {
    DEBUG_PRINT("Testing CS switching functionality...");
    
    /* Initialize */
    if (eink_cs_init() < 0) {
        return -1;
    }
    
    /* Test deselect all */
    DEBUG_PRINT("=== Testing deselect all ===");
    if (eink_cs_deselect_all() < 0) {
        return -1;
    }
    sleep(1);
    
    /* Test left selection */
    DEBUG_PRINT("=== Testing left half selection ===");
    if (eink_cs_select_left() < 0) {
        return -1;
    }
    sleep(1);
    
    /* Test right selection */
    DEBUG_PRINT("=== Testing right half selection ===");
    if (eink_cs_select_right() < 0) {
        return -1;
    }
    sleep(1);
    
    /* Test rapid switching */
    DEBUG_PRINT("=== Testing rapid switching ===");
    for (int i = 0; i < 5; i++) {
        DEBUG_PRINT("Switch cycle %d/5", i + 1);
        if (eink_cs_select_left() < 0) {
            return -1;
        }
        usleep(100000); /* 100ms */
        if (eink_cs_select_right() < 0) {
            return -1;
        }
        usleep(100000); /* 100ms */
    }
    
    /* Return to deselected state */
    if (eink_cs_deselect_all() < 0) {
        return -1;
    }
    
    DEBUG_PRINT("CS switching test completed successfully!");
    return 0;
}

int eink_cs_cleanup(void) {
    DEBUG_PRINT("Cleaning up CS GPIO exports...");
    
    /* Deselect both before cleanup */
    eink_cs_deselect_all(); /* Ignore errors during cleanup */
    
    /* Unexport GPIOs */
    gpio_unexport(CS0_GPIO); /* Ignore errors during cleanup */
    gpio_unexport(CS1_GPIO); /* Ignore errors during cleanup */
    
    DEBUG_PRINT("CS GPIO cleanup completed");
    return 0;
}

void eink_cs_set_debug(bool enable) {
    debug_enabled = enable;
    DEBUG_PRINT("Debug mode %s", enable ? "enabled" : "disabled");
}
