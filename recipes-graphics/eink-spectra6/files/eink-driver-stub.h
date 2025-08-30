/*
 * EL133UF1 E-Ink Display Driver - Stub Header
 * 
 * This is a stub implementation for development purposes.
 * Replace with actual E Ink driver implementation.
 */

#ifndef EINK_DRIVER_STUB_H
#define EINK_DRIVER_STUB_H

#ifdef __cplusplus
extern "C" {
#endif

/* Display dimensions */
#define EINK_WIDTH  1600
#define EINK_HEIGHT 1200

/* Function prototypes */
int eink_init(void);
int eink_cleanup(void);
int eink_clear_display(void);
int eink_update_display(const unsigned char *framebuffer);
int eink_set_pixel(int x, int y, unsigned char value);

#ifdef __cplusplus
}
#endif

#endif /* EINK_DRIVER_STUB_H */
