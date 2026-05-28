# IIO debug_reg_read/debug_reg_write Safe Implementation Patterns

**Category:** Type Safety
**Priority:** CRITICAL
**Applies to:** All no-OS IIO drivers

## Problem: Unsafe Pointer Casts

**❌ UNSAFE PATTERN (DO NOT USE):**

```c
static int32_t device_iio_reg_read(void *dev, uint32_t reg, uint32_t *readval)
{
    struct device_iio_desc *iio_device = dev;
    struct device_dev *device = iio_device->device_dev;

    switch (reg) {
    case DEVICE_REG_WORD:
        // ❌ UNSAFE: Casting uint32_t* to uint16_t*
        return device_read_word(device, reg, (uint16_t *)readval);

    case DEVICE_REG_BYTE:
        // ❌ UNSAFE: Casting uint32_t* to uint8_t*
        return device_read_byte(device, reg, (uint8_t *)readval);

    default:
        return -EINVAL;
    }
}
```

## Why This Is Unsafe

### 1. Alignment Issues
On some architectures (ARM, MIPS), misaligned pointer access causes:
- **Bus errors** (program crash)
- **Silent data corruption**
- **Performance penalties**

### 2. Endianness Problems
Pointer casts assume memory layout, which varies by architecture:

```
Little-endian (x86, ARM):
Address: 0x00  0x01  0x02  0x03
Value:   0x12  0x34  0x56  0x78
         └─────┘
         *(uint16_t*) = 0x3412

Big-endian (some MIPS, PowerPC):
Address: 0x00  0x01  0x02  0x03
Value:   0x78  0x56  0x34  0x12
         └─────┘
         *(uint16_t*) = 0x7856
```

### 3. Strict Aliasing Violations
C99/C11 strict aliasing rules prohibit accessing the same memory through incompatible pointer types. Compilers can optimize assuming this, leading to **undefined behavior**.

## ✅ SAFE PATTERN (ALWAYS USE THIS)

### Pattern 1: Intermediate Variable (RECOMMENDED)

```c
static int32_t device_iio_reg_read(void *dev, uint32_t reg, uint32_t *readval)
{
    struct device_iio_desc *iio_device = dev;
    struct device_dev *device = iio_device->device_dev;
    int ret;
    uint16_t word_val;
    uint8_t byte_val;

    switch (reg) {
    case DEVICE_REG_WORD:
        // ✅ SAFE: Use intermediate variable
        ret = device_read_word(device, reg, &word_val);
        if (ret)
            return ret;
        *readval = word_val;  // Safe 16->32 promotion
        return 0;

    case DEVICE_REG_BYTE:
        // ✅ SAFE: Use intermediate variable
        ret = device_read_byte(device, reg, &byte_val);
        if (ret)
            return ret;
        *readval = byte_val;  // Safe 8->32 promotion
        return 0;

    default:
        return -EINVAL;
    }
}
```

### Pattern 2: Scoped Blocks (ALTERNATIVE)

```c
static int32_t device_iio_reg_read(void *dev, uint32_t reg, uint32_t *readval)
{
    struct device_iio_desc *iio_device = dev;
    struct device_dev *device = iio_device->device_dev;
    int ret;

    switch (reg) {
    case DEVICE_REG_WORD:
    {
        // ✅ SAFE: Scoped block with local variable
        uint16_t word;
        ret = device_read_word(device, reg, &word);
        if (ret)
            return ret;
        *readval = word;
        return 0;
    }

    case DEVICE_REG_BYTE:
    {
        // ✅ SAFE: Scoped block with local variable
        uint8_t byte;
        ret = device_read_byte(device, reg, &byte);
        if (ret)
            return ret;
        *readval = byte;
        return 0;
    }

    default:
        return -EINVAL;
    }
}
```

## Complete Example: PMBus Device

Based on LT7170 (safe implementation) vs LTM4686 (unsafe implementation that should NOT be used as reference).

```c
/**
 * @brief Read register value.
 * @param dev     - The iio device structure.
 * @param reg     - Register to read.
 * @param readval - Read value.
 * @return 0 in case of success, negative error code otherwise.
 */
static int32_t ltm4700_iio_reg_read(void *dev, uint32_t reg, uint32_t *readval)
{
    struct ltm4700_iio_desc *iio_ltm4700 = dev;
    struct ltm4700_dev *ltm4700 = iio_ltm4700->ltm4700_dev;
    int ret;
    uint8_t byte_val;
    uint16_t word_val;
    uint8_t block[4] = {0};

    switch (reg) {
    /* Byte registers */
    case LTM4700_PAGE:
    case LTM4700_OPERATION:
    case LTM4700_ON_OFF_CONFIG:
    case LTM4700_WRITE_PROTECT:
        ret = ltm4700_read_byte(ltm4700, reg, &byte_val);
        if (ret)
            return ret;
        *readval = byte_val;  // Safe 8->32 promotion
        return 0;

    /* Word registers */
    case LTM4700_VOUT_COMMAND:
    case LTM4700_VOUT_MAX:
    case LTM4700_FREQUENCY_SWITCH:
    case LTM4700_READ_VIN:
    case LTM4700_READ_VOUT:
    case LTM4700_READ_IOUT:
    case LTM4700_READ_TEMPERATURE_1:
        ret = ltm4700_read_word(ltm4700, ltm4700->page, reg, &word_val);
        if (ret)
            return ret;
        *readval = word_val;  // Safe 16->32 promotion
        return 0;

    /* Block registers (multi-byte) */
    case LTM4700_MFR_ID:
    case LTM4700_MFR_MODEL:
        ret = ltm4700_read_block_data(ltm4700, ltm4700->page,
                                       reg, block, 4);
        if (ret)
            return ret;

        // Safe byte-by-byte assembly
        *readval = (uint32_t)block[0] << 24 |
                   (uint32_t)block[1] << 16 |
                   (uint32_t)block[2] << 8 |
                   (uint32_t)block[3];
        return 0;

    default:
        return -EINVAL;
    }
}
```

## Reference Implementations

### ✅ GOOD Examples (Follow These)
- **drivers/power/lt7170/iio_lt7170.c** - Uses safe intermediate variable pattern
- **drivers/power/lt8491/iio_lt8491.c** - Uses safe intermediate variable pattern
- **drivers/temperature/max31827/iio_max31827.c** - Uses safe pattern

### ❌ BAD Examples (DO NOT Use as Reference)
- **drivers/power/ltm4686/iio_ltm4686.c** - Uses unsafe `(uint16_t *)readval` casts
- **drivers/power/lt7182s/iio_lt7182s.c** - Uses unsafe `(uint16_t *)readval` casts
- **drivers/power/ltp8800/iio_ltp8800.c** - Uses unsafe `(uint16_t *)readval` casts

**Note:** These drivers have legacy code that predates type safety reviews. They work on current platforms (x86, ARM little-endian) but are not portable and violate C strict aliasing rules.

## Review Checker Integration

The automated review checker (`.claude/tools/pre-commit/review-checker.py`) flags this pattern:

```
⚠️ iio_device.c:137 - Potentially unsafe pointer cast
    💡 Consider using no_os_get_unaligned_*() functions for safe access
```

**Category:** Type Safety (31 occurrences, 6.1% of PR review issues)

**Historical PR Comment:**
> *"I think casting &prod_id[1] to uint16_t* causes buffer overflow"* (PR review database)

## Implementation Checklist

When implementing `debug_reg_read`/`debug_reg_write`:

- [ ] **Declare intermediate variables** (`uint8_t byte_val`, `uint16_t word_val`)
- [ ] **Read into intermediate variable** first
- [ ] **Check return value** before using data
- [ ] **Assign to output pointer** after validation
- [ ] **Use safe type promotion** (implicit 8->32, 16->32 is always safe)
- [ ] **Never cast output pointer** to smaller type
- [ ] **Test on multiple platforms** if possible (x86, ARM)

## Related Documentation

- **Type Safety Issues**: `.claude/docs/reference/no-os-review-pattern-analysis.md` (Section 3)
- **Review Pattern Database**: `.claude/data/review_patterns_6month.json`
- **IIO Implementation**: `.claude/gen-ai-agents/skills/no-os-iio/reference/implementation.md`

## Summary

**Golden Rule:** When `debug_reg_read` receives a `uint32_t *readval` parameter, ALWAYS use an intermediate variable of the correct size, then promote the value safely. NEVER cast the pointer to a smaller type.

This ensures:
- ✅ Portable code across all architectures
- ✅ No alignment issues
- ✅ No strict aliasing violations
- ✅ Explicit type conversions
- ✅ Better code readability
