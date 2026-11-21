// SPDX-License-Identifier: Apache-2.0
#include <errno.h>
#include <fcntl.h>
#include <hardware/lights.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* The V500 LM3532 exposes 0..255 through the DRM panel backlight. */
static int set_backlight(struct light_device_t *dev, const struct light_state_t *state)
{
    (void)dev;
    if (state->brightnessMode == BRIGHTNESS_MODE_LOW_PERSISTENCE)
        return -ENOSYS;
    unsigned int color = state->color;
    int level = (77 * ((color >> 16) & 255) + 150 * ((color >> 8) & 255) +
                 29 * (color & 255)) >> 8;
    char value[5];
    int size = snprintf(value, sizeof(value), "%d\n", level);
    int fd = TEMP_FAILURE_RETRY(open("/sys/class/backlight/panel-backlight/brightness",
                                     O_WRONLY | O_CLOEXEC));
    if (fd < 0)
        return -errno;
    ssize_t written = TEMP_FAILURE_RETRY(write(fd, value, size));
    int result = written == size ? 0 : (written < 0 ? -errno : -EIO);
    close(fd);
    return result;
}

static int close_light(struct hw_device_t *dev)
{
    free(dev);
    return 0;
}

static int open_light(const struct hw_module_t *module, const char *name,
                      struct hw_device_t **out)
{
    if (strcmp(name, LIGHT_ID_BACKLIGHT))
        return -EINVAL;
    struct light_device_t *device = calloc(1, sizeof(*device));
    if (!device)
        return -ENOMEM;
    device->common.tag = HARDWARE_DEVICE_TAG;
    device->common.version = LIGHTS_DEVICE_API_VERSION_2_0;
    device->common.module = (struct hw_module_t *)module;
    device->common.close = close_light;
    device->set_light = set_backlight;
    *out = &device->common;
    return 0;
}

static struct hw_module_methods_t methods = { .open = open_light };

struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .module_api_version = HARDWARE_MODULE_API_VERSION(1, 0),
    .hal_api_version = HARDWARE_HAL_API_VERSION,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "LG V500 panel backlight",
    .author = "V500 project",
    .methods = &methods,
};
