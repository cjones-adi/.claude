# IIO Scale/Offset Attribute Requirement

## Overview

**Date**: May 2026
**Issue**: LTM4700 IIO driver missing scale/offset attributes
**Severity**: High - Non-compliant with Linux IIO subsystem standards
**Status**: ✅ Resolved - Pattern documented for future implementations

## Problem Statement

The LTM4700 IIO driver was initially implemented without `scale` and `offset` attributes for sensor channels (voltage, current, temperature, power). This was identified during PR review with the comment:

> "the only gripe i have about this iio device is that these channels (voltage, current, temperature etc.) should also implement the offset and the scale attributes, so that a user can read the value and convert to corresponding measurement units like Volt, Ampere, Celsius"

## Root Cause

The AI-assisted driver development workflow did not explicitly require scale/offset attributes, leading to an incomplete IIO implementation despite following the 6-commit pattern and passing all other quality checks.

## IIO Subsystem Standard

The Linux IIO subsystem uses a standard conversion formula:

```
processed_value = (raw + offset) * scale
```

Where:
- **`raw`**: Unprocessed hardware value (typically in milli-units for no-OS)
- **`offset`**: Additive offset (often 0, but device-specific)
- **`scale`**: Multiplicative scale factor for unit conversion

### Non-Compliant Implementation (Before):

```c
/* LTM4700 IIO voltage input attributes */
static struct iio_attribute ltm4700_iio_voltage_input_attrs[] = {
    {
        .name = "raw",
        .priv = LTM4700_IIO_VIN,
        .show = ltm4700_iio_read_attr,  // Returns pre-formatted string "12.345"
    },
    END_ATTRIBUTES_ARRAY
};
```

**Problems:**
- Returns pre-formatted string instead of raw integer
- No scale/offset for userspace conversion
- Incompatible with libiio, pyadi-iio, and other IIO tools

### Compliant Implementation (After):

```c
/* LTM4700 IIO voltage input attributes */
static struct iio_attribute ltm4700_iio_voltage_input_attrs[] = {
    {
        .name = "raw",
        .priv = LTM4700_IIO_VIN,
        .show = ltm4700_iio_read_raw,   // Returns integer: 12345
    },
    {
        .name = "scale",
        .show = ltm4700_iio_read_scale, // Returns 0.001
    },
    {
        .name = "offset",
        .show = ltm4700_iio_read_offset, // Returns 0
    },
    END_ATTRIBUTES_ARRAY
};
```

## When Scale/Offset is Required

### ✅ REQUIRED For:
- **Voltage channels** (input/output) → Scale to Volts
- **Current channels** (input/output) → Scale to Amperes
- **Temperature channels** → Scale to degrees Celsius
- **Power channels** (input/output) → Scale to Watts
- **Frequency channels** → Scale to Hertz
- **Any sensor measurement channel** → Scale to standard SI units

### ❌ NOT Required For:
- **Control attributes** (operation, enable, mode)
- **Configuration attributes** (command, max, margins)
- **Status/debug attributes** (device_id, status_word)
- **Available/enum attributes** (operation_available)

## Reference Implementations

### no-OS Ecosystem (18+ drivers with scale/offset):

| Driver | Device Type | Scale Pattern |
|--------|-------------|---------------|
| **LTM4700** | PMBus Regulator | Constant fractional (0.001) for all channels |
| **LTM4686** | PMBus Regulator | Constant fractional (0.001) for all channels |
| **MAX31855** | Temperature | Channel-specific (62.5µ°C, 250m°C) |
| **AD7606** | ADC | Dynamic based on voltage range configuration |
| **ADIS** | IMU | Channel-specific for accel/gyro/temp |
| **ADXL367** | Accelerometer | Range-based scale table |

### Common Scale Patterns:

1. **Constant Fractional** (most common for PMBus/power devices):
   ```c
   int device_iio_read_scale(void *device, char *buf, uint32_t len,
                             const struct iio_ch_info *channel,
                             intptr_t priv)
   {
       int vals[2];

       vals[0] = 1;
       vals[1] = (int)MILLI;  // 0.001

       return iio_format_value(buf, len, IIO_VAL_FRACTIONAL, 2, (int32_t *)vals);
   }
   ```

2. **Integer Plus Micro** (common for temperature):
   ```c
   int device_iio_read_scale(void *device, char *buf, uint32_t len,
                             const struct iio_ch_info *channel,
                             intptr_t priv)
   {
       int vals[2];

       vals[0] = 62;      // Integer part
       vals[1] = 500000;  // Micro part (0.5)
       // Result: 62.5

       return iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, (int32_t *)vals);
   }
   ```

3. **Channel-Specific** (when different channels have different scales):
   ```c
   int device_iio_read_scale(void *device, char *buf, uint32_t len,
                             const struct iio_ch_info *channel,
                             intptr_t priv)
   {
       int vals[2];

       switch (channel->address) {
       case DEVICE_IIO_VIN_CHAN:
           vals[0] = 1;
           vals[1] = (int)MILLI;
           break;
       case DEVICE_IIO_TEMP_CHAN:
           vals[0] = 125;  // Different scale for temperature
           break;
       }

       return iio_format_value(buf, len, IIO_VAL_FRACTIONAL, 2, (int32_t *)vals);
   }
   ```

## Complete Implementation Example (LTM4700)

```c
/**
 * @brief Read raw attribute for a specific channel.
 */
int ltm4700_iio_read_raw(void *device, char *buf, uint32_t len,
                         const struct iio_ch_info *channel,
                         intptr_t priv)
{
    struct ltm4700_iio_desc *iio_desc = device;
    struct ltm4700_dev *dev = iio_desc->ltm4700_dev;
    int val, ret;

    switch (priv) {
    case LTM4700_IIO_VIN:
        ret = ltm4700_read_value(dev, 0, LTM4700_VIN, &val);
        if (ret)
            return ret;
        return iio_format_value(buf, len, IIO_VAL_INT, 1, &val);

    case LTM4700_IIO_IIN:
        ret = ltm4700_read_value(dev, 0, LTM4700_IIN, &val);
        if (ret)
            return ret;
        return iio_format_value(buf, len, IIO_VAL_INT, 1, &val);

    // ... other sensor channels

    default:
        return -EINVAL;
    }
}

/**
 * @brief Read scale attribute for a specific channel.
 */
int ltm4700_iio_read_scale(void *device, char *buf, uint32_t len,
                           const struct iio_ch_info *channel,
                           intptr_t priv)
{
    int vals[2];

    /* All values are in milli-units, so scale is 0.001 (1/1000) */
    vals[0] = 1;
    vals[1] = (int)MILLI;

    return iio_format_value(buf, len, IIO_VAL_FRACTIONAL, 2, (int32_t *)vals);
}

/**
 * @brief Read offset attribute for a specific channel.
 */
int ltm4700_iio_read_offset(void *device, char *buf, uint32_t len,
                            const struct iio_ch_info *channel,
                            intptr_t priv)
{
    int val = 0;
    return iio_format_value(buf, len, IIO_VAL_INT, 1, &val);
}

/* Apply to all sensor attribute arrays */
static struct iio_attribute ltm4700_iio_voltage_input_attrs[] = {
    {
        .name = "raw",
        .priv = LTM4700_IIO_VIN,
        .show = ltm4700_iio_read_raw,
    },
    {
        .name = "scale",
        .show = ltm4700_iio_read_scale,
    },
    {
        .name = "offset",
        .show = ltm4700_iio_read_offset,
    },
    END_ATTRIBUTES_ARRAY
};
```

## PR Review Checklist Addition

### **✅ IIO Implementation Standards:**
- [ ] Complete 6-commit pattern followed
- [ ] IIO integration (for monitoring devices)
  - [ ] **IIO scale/offset attributes** (REQUIRED for sensor channels) ⚠️ **COMMONLY MISSED**
    - [ ] Voltage channels have scale/offset
    - [ ] Current channels have scale/offset
    - [ ] Temperature channels have scale/offset
    - [ ] Power channels have scale/offset
    - [ ] Frequency channels have scale/offset
  - [ ] raw attribute returns integer values (not formatted strings)
  - [ ] scale uses iio_format_value() with IIO_VAL_FRACTIONAL or IIO_VAL_INT_PLUS_MICRO
  - [ ] offset uses iio_format_value() with IIO_VAL_INT

## Unit Test Pattern

```c
/* Test raw attribute returns integer */
void test_iio_raw_returns_integer_value(void)
{
    char buf[100];
    int ret;

    ltm4700_read_value_ExpectAndReturn(ltm4700_dev, 0, LTM4700_VIN, NULL, 0);
    ltm4700_read_value_IgnoreArg_value();
    ltm4700_read_value_ReturnThruPtr_value(&test_value);

    ret = ltm4700_iio_read_raw(iio_desc, buf, sizeof(buf), &channel, LTM4700_IIO_VIN);

    TEST_ASSERT_GREATER_THAN(0, ret);
    TEST_ASSERT_EQUAL_INT(test_value, atoi(buf));  // Should be integer, not "12.345"
}

/* Test scale returns expected fractional value */
void test_iio_scale_returns_expected_value(void)
{
    char buf[100];
    int ret;

    ret = ltm4700_iio_read_scale(iio_desc, buf, sizeof(buf), &channel, 0);

    TEST_ASSERT_GREATER_THAN(0, ret);
    TEST_ASSERT_EQUAL_STRING("0.001000000", buf);  // IIO_VAL_FRACTIONAL format
}

/* Test offset returns zero */
void test_iio_offset_returns_zero(void)
{
    char buf[100];
    int ret;

    ret = ltm4700_iio_read_offset(iio_desc, buf, sizeof(buf), &channel, 0);

    TEST_ASSERT_GREATER_THAN(0, ret);
    TEST_ASSERT_EQUAL_STRING("0", buf);
}
```

## Userspace Usage Example

### Before (Non-compliant):
```bash
$ cat /sys/bus/iio/devices/iio:device0/in_voltage0_raw
12.345  # Pre-formatted, can't be processed by tools
```

### After (Compliant):
```bash
$ cat /sys/bus/iio/devices/iio:device0/in_voltage0_raw
12345  # Raw value in milli-volts

$ cat /sys/bus/iio/devices/iio:device0/in_voltage0_scale
0.001  # Scale factor

$ cat /sys/bus/iio/devices/iio:device0/in_voltage0_offset
0      # Offset

# Python with pyadi-iio:
import iio
dev = iio.Device(uri="serial:/dev/ttyUSB0,230400")
voltage = dev.channels[0].attrs['raw'].value * dev.channels[0].attrs['scale'].value
# voltage = 12345 * 0.001 = 12.345 V
```

## Summary

The LTM4700 IIO driver implementation revealed a gap in the AI-assisted driver development workflow: the requirement for scale/offset attributes was not explicitly documented or checked. This has been corrected through:

1. ✅ Created this reference document for future implementations
2. ✅ Added explicit IIO scale/offset requirement to PR checklist
3. ✅ Established unit test patterns for scale/offset verification
4. ✅ Documented common patterns from 18+ no-OS IIO drivers

**Future Implementations**: All IIO drivers with sensor channels MUST include scale/offset attributes following the patterns documented here.

**Reference**: LTM4700 driver (drivers/power/ltm4700/iio_ltm4700.c lines 220-610)
