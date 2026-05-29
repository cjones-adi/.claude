# IIO Data Type Safety - Code Generation and QA Reference

**Category:** Code Quality / Data Safety
**Severity:** Critical (Hardware Damage Risk)
**Applies to:** All IIO driver implementations
**Last Updated:** 2026-05-29

---

## Overview

This document establishes mandatory patterns for safe data type handling in IIO drivers, derived from critical bugs found in LT8460 driver that could cause hardware damage through silent data corruption.

---

## Critical Bug Patterns to AVOID ❌

### 1. Type Aliasing Violations

**WRONG - Unsafe pointer casting:**
```c
// ❌ NEVER DO THIS
int vals[2];  // Wrong type!

// Unsafe cast - undefined behavior if int != int32_t
iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, (int32_t *)vals);

// Another unsafe pattern
iio_parse_value(buf, IIO_VAL_INT_PLUS_MICRO,
                (int32_t *)&vals[0], (int32_t *)&vals[1]);
```

**Why it's dangerous:**
- Violates strict aliasing rules (C99/C11)
- Undefined behavior on platforms where `sizeof(int) != sizeof(int32_t)`
- Common on AVR (int=16bit), some DSP platforms
- May work on x86/ARM but fails elsewhere

---

### 2. Silent Integer Overflow on Narrowing Casts

**WRONG - No overflow protection:**
```c
// ❌ CRITICAL BUG - Silent wraparound
int32_t vals[2];
uint16_t value;

iio_parse_value(buf, IIO_VAL_INT_PLUS_MICRO, &vals[0], &vals[1]);
value = (uint16_t)(vals[0] * MILLI + vals[1] / MILLI);  // UNSAFE!

// If user inputs "70.0" volts:
//   vals[0] = 70, vals[1] = 0
//   Arithmetic: 70 * 1000 = 70000
//   Cast to uint16_t: 70000 % 65536 = 4464
//   Device receives: 4.464V instead of 70V
//   Result: HARDWARE DAMAGE from undervoltage
```

**Real-world impact:**
- LT8460 could output 4.6V instead of 70V (silent wraparound)
- Power regulators operating at wrong voltage
- No error reported to user
- Hardware damage or system failure

---

## Mandatory Safe Patterns ✅

### Pattern 1: IIO Format Value (Read Path)

**Correct implementation:**
```c
case DEVICE_IIO_ATTR_VOLTAGE: {
    int32_t vals[2];  // ✅ Correct type - matches iio_format_value signature
    uint16_t value;

    ret = device_get_voltage(dev, &value);
    if (ret)
        return ret;

    // Break down millivolts into integer and fractional parts
    vals[0] = (int32_t)value / MILLI;
    vals[1] = (int32_t)(value - vals[0] * MILLI) * MILLI;

    // ✅ No cast needed - types match
    return iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, vals);
}
```

**Key points:**
- Use `int32_t vals[2]` not `int vals[2]`
- No pointer casting needed
- Works correctly across all platforms

---

### Pattern 2: IIO Parse Value with Overflow Protection (Write Path)

**Correct implementation:**
```c
case DEVICE_IIO_ATTR_VOLTAGE: {
    uint16_t value;
    int32_t vals[2];
    int32_t temp_value;  // ✅ Intermediate variable for validation

    ret = iio_parse_value((char *)buf, IIO_VAL_INT_PLUS_MICRO,
                          &vals[0], &vals[1]);
    if (ret)
        return ret;

    // ✅ CRITICAL: Validate BEFORE casting
    temp_value = vals[0] * MILLI + vals[1] / MILLI;
    if (temp_value < 0 || temp_value > UINT16_MAX)
        return -EINVAL;  // Reject out-of-range values

    value = (uint16_t)temp_value;  // Safe cast after validation

    return device_set_voltage(dev, value);
}
```

**Key points:**
- Use intermediate `int32_t temp_value` for calculation
- Validate range BEFORE casting to smaller type
- Return `-EINVAL` for out-of-range values
- Prevents silent overflow and hardware damage

---

### Pattern 3: uint32_t Overflow Protection

**For larger ranges (e.g., resistance values):**
```c
case DEVICE_IIO_ATTR_RESISTANCE: {
    uint32_t res;
    int32_t vals[2];
    int64_t temp_res;  // ✅ Use int64_t to prevent overflow in calculation

    ret = iio_parse_value((char *)buf, IIO_VAL_INT_PLUS_MICRO,
                          &vals[0], &vals[1]);
    if (ret)
        return ret;

    // ✅ Calculate in wider type
    temp_res = (int64_t)vals[0] * MILLI + vals[1] / MILLI;
    if (temp_res < 0 || temp_res > UINT32_MAX)
        return -EINVAL;

    res = (uint32_t)temp_res;

    return device_set_resistance(dev, res);
}
```

---

### Pattern 4: Device-Specific Range Validation

**When device has explicit limits:**
```c
case DEVICE_IIO_GLOBAL_VOUT_ALL: {
    int32_t vals[2];
    int32_t temp_value;
    uint16_t value;

    ret = iio_parse_value(buf, IIO_VAL_INT_PLUS_MICRO, &vals[0], &vals[1]);
    if (ret)
        return ret;

    // ✅ Validate BEFORE casting (prevents overflow first)
    temp_value = vals[0] * MILLI + vals[1] / MILLI;

    // ✅ Check device-specific limits BEFORE type limits
    if (temp_value < DEVICE_MIN_VOUT || temp_value > DEVICE_MAX_VOUT)
        return -ERANGE;  // Use -ERANGE for device limits

    // ✅ Then check type overflow (belt-and-suspenders)
    if (temp_value > UINT16_MAX)
        return -EINVAL;  // Use -EINVAL for type overflow

    value = (uint16_t)temp_value;

    return device_set_vout_all(dev, value);
}
```

**Error code conventions:**
- `-ERANGE`: Value outside device-specific valid range
- `-EINVAL`: Value overflows data type or invalid format

---

## QA Quality Check Patterns

### Automated Detection Patterns

**Add these patterns to `.claude/tools/pre-commit/review-checker.py`:**

```python
# Pattern 1: Detect unsafe int vals[] declarations
{
    "pattern": r"int\s+vals\[2\].*iio_(format|parse)_value",
    "severity": "critical",
    "message": "Use 'int32_t vals[2]' not 'int vals[2]' to prevent type aliasing violations",
    "category": "data_safety"
}

# Pattern 2: Detect unsafe casts without overflow protection
{
    "pattern": r"\(uint(16|32)_t\)\(vals\[0\]\s*\*\s*MILLI",
    "severity": "critical",
    "message": "Direct cast to uint without overflow check - use intermediate variable + range validation",
    "category": "data_safety"
}

# Pattern 3: Detect unsafe pointer casts
{
    "pattern": r"\(int32_t\s*\*\)\s*&?vals\[",
    "severity": "high",
    "message": "Unsafe pointer cast - declare vals as int32_t[] instead",
    "category": "data_safety"
}
```

---

## Code Generation Guidelines

When generating IIO driver code, Claude MUST:

### ✅ DO:
1. **Always use `int32_t vals[2]`** for IIO value arrays
2. **Always validate range before narrowing casts** (uint16_t, uint32_t, uint8_t)
3. **Use intermediate variables** for calculations before casting
4. **Return proper error codes** (-EINVAL for type overflow, -ERANGE for device limits)
5. **Add comments** explaining overflow protection logic

### ❌ DON'T:
1. **Never use `int vals[2]`** with IIO functions
2. **Never cast directly** from calculation to smaller type without validation
3. **Never use `(int32_t *)` casts** on int arrays
4. **Never assume** arithmetic results fit in target type
5. **Never skip** range validation on user input

---

## Testing Requirements

All IIO write attributes with narrowing casts must be tested with:

### Boundary Value Tests:
```bash
# Test negative values
echo "-1.0" > attribute  # Expect: -EINVAL

# Test zero
echo "0.0" > attribute  # Expect: Success (if valid)

# Test maximum valid value
echo "65.535" > attribute  # Expect: Success (for uint16_t)

# Test overflow boundary
echo "65.536" > attribute  # Expect: -EINVAL (overflow)

# Test extreme overflow
echo "100.0" > attribute  # Expect: -EINVAL (overflow)
echo "1000.0" > attribute  # Expect: -EINVAL (overflow)
```

---

## Real-World Examples from LT8460 Fixes

### Example 1: VOUT Voltage Setting

**Before (UNSAFE):**
```c
case LT8460_IIO_VOUT_VOUT: {
    uint16_t value;
    int32_t vals[2];

    ret = iio_parse_value((char *)buf, IIO_VAL_INT_PLUS_MICRO,
                          &vals[0], &vals[1]);
    if (ret)
        return ret;

    value = (uint16_t)(vals[0] * MILLI + vals[1] / MILLI);  // ❌ UNSAFE!

    return lt8460_set_vout_channel_vout(lt8460, channel, value);
}
```

**After (SAFE):**
```c
case LT8460_IIO_VOUT_VOUT: {
    uint16_t value;
    int32_t vals[2];
    int32_t temp_value;  // ✅ Added

    ret = iio_parse_value((char *)buf, IIO_VAL_INT_PLUS_MICRO,
                          &vals[0], &vals[1]);
    if (ret)
        return ret;

    /* Validate range before casting to prevent silent overflow */
    temp_value = vals[0] * MILLI + vals[1] / MILLI;  // ✅ Calculate first
    if (temp_value < 0 || temp_value > UINT16_MAX)   // ✅ Validate
        return -EINVAL;

    value = (uint16_t)temp_value;  // ✅ Safe cast

    return lt8460_set_vout_channel_vout(lt8460, channel, value);
}
```

### Example 2: Temperature Reading

**Before (UNSAFE):**
```c
case LT8460_IIO_TEMP_TEMP: {
    int vals[2];  // ❌ Wrong type
    int32_t temp;

    ret = lt8460_get_temp_channel_temp(lt8460,
                                       (enum lt8460_temp_channel)ch_num,
                                       &temp);
    if (ret)
        return ret;

    vals[0] = temp / MILLI;
    vals[1] = (temp - vals[0] * MILLI) * MILLI;

    return iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2,
                           (int32_t *)vals);  // ❌ Unsafe cast
}
```

**After (SAFE):**
```c
case LT8460_IIO_TEMP_TEMP: {
    int32_t vals[2];  // ✅ Correct type
    int32_t temp;

    ret = lt8460_get_temp_channel_temp(lt8460,
                                       (enum lt8460_temp_channel)ch_num,
                                       &temp);
    if (ret)
        return ret;

    vals[0] = temp / MILLI;
    vals[1] = (temp - vals[0] * MILLI) * MILLI;

    return iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, vals);  // ✅ No cast
}
```

---

## Checklist for Code Review

When reviewing IIO driver code, verify:

- [ ] All `vals[]` arrays declared as `int32_t`, not `int`
- [ ] No `(int32_t *)` casts on value arrays
- [ ] All narrowing casts (to uint16_t/uint32_t/uint8_t) have overflow protection
- [ ] Intermediate variables used for calculations before casting
- [ ] Range validation returns `-EINVAL` or `-ERANGE` as appropriate
- [ ] Comments explain overflow protection logic
- [ ] Boundary value tests exist for all write attributes

---

## Impact Assessment

**Severity Levels:**

| Pattern | Severity | Impact | Detection |
|---------|----------|--------|-----------|
| Type aliasing (`int vals[]`) | High | Undefined behavior, portability issues | Static analysis |
| uint16_t overflow | **Critical** | Hardware damage, system failure | Runtime testing |
| uint32_t overflow | Medium-High | Data corruption | Runtime testing |
| Missing validation | **Critical** | Silent failures, no error reporting | Code review |

---

## References

- **Source Analysis:** LT8460 IIO driver bug fixes (2026-05-29)
- **Files Fixed:** `drivers/power/lt8460/iio_lt8460.c` (10 instances)
- **Standards:** C99/C11 strict aliasing rules, IIO subsystem conventions
- **Related:** `.claude/docs/reference/iio-scale-offset-requirement.md`

---

## Summary

**Golden Rules for IIO Data Safety:**

1. **Always use `int32_t vals[2]`** - Never `int vals[2]`
2. **Never cast directly** - Always validate range first
3. **Use intermediate variables** - Calculate, validate, then cast
4. **Return proper errors** - `-EINVAL` for overflow, `-ERANGE` for limits
5. **Test boundaries** - Negative, zero, max, overflow values

**Remember:** These aren't just style preferences - they prevent real hardware damage and system failures. Silent overflow can cause power regulators to output wrong voltages, potentially destroying expensive hardware.

**When in doubt:** Add an intermediate variable and validate the range. The extra 2 lines of code can save thousands in damaged hardware.
