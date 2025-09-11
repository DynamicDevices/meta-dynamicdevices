/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * E-Ink Dual Chip Select Control Library
 * Copyright 2025 Dynamic Devices Ltd
 * 
 * Handles CS0 and CS1 GPIO control for left/right E-Ink display halves
 */

#ifndef EINK_CS_CONTROL_H
#define EINK_CS_CONTROL_H

#include <stdint.h>
#include <stdbool.h>

/* GPIO mappings for i.MX93 E-Ink board */
#define CS0_GPIO    529    /* GPIO2_IO17 (512 + 17) - Left half */
#define CS1_GPIO    619    /* GPIO1_IO11 (608 + 11) - Right half */

/* CS selection options */
typedef enum {
    EINK_CS_NONE = 0,    /* Both deselected */
    EINK_CS_LEFT,        /* Left half selected (CS0 active) */
    EINK_CS_RIGHT        /* Right half selected (CS1 active) */
} eink_cs_selection_t;

/* CS status structure */
typedef struct {
    bool cs0_active;     /* true if CS0 is LOW (selected) */
    bool cs1_active;     /* true if CS1 is LOW (selected) */
    eink_cs_selection_t selection;
} eink_cs_status_t;

/* Function prototypes */

/**
 * Initialize E-Ink CS GPIOs
 * Exports GPIOs, sets them as outputs, and deselects both halves
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_init(void);

/**
 * Select left display half (CS0 active, CS1 inactive)
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_select_left(void);

/**
 * Select right display half (CS0 inactive, CS1 active)
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_select_right(void);

/**
 * Deselect both display halves (both CS lines HIGH)
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_deselect_all(void);

/**
 * Select display half by enum
 * 
 * @param selection Which half to select
 * @return 0 on success, -1 on error
 */
int eink_cs_select(eink_cs_selection_t selection);

/**
 * Get current CS status
 * 
 * @param status Pointer to status structure to fill
 * @return 0 on success, -1 on error
 */
int eink_cs_get_status(eink_cs_status_t *status);

/**
 * Test CS switching functionality
 * Performs comprehensive test of all CS operations
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_test(void);

/**
 * Cleanup CS GPIOs
 * Deselects both halves and unexports GPIOs
 * 
 * @return 0 on success, -1 on error
 */
int eink_cs_cleanup(void);

/**
 * Set CS debug mode
 * 
 * @param enable true to enable debug output, false to disable
 */
void eink_cs_set_debug(bool enable);

#endif /* EINK_CS_CONTROL_H */
