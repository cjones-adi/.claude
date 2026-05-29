# IIO Data Type Safety - Quick Reference

**🚨 CRITICAL: Hardware Damage Risk - Always Follow These Patterns**

---

## ❌ NEVER Do This:

```c
// ❌ WRONG - Type aliasing violation
int vals[2];
iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, (int32_t *)vals);

// ❌ CRITICAL BUG - Silent overflow (can cause hardware damage!)
value = (uint16_t)(vals[0] * MILLI + vals[1] / MILLI);
```

**Impact:** User sets 70V → Device outputs 4.6V → Hardware damage

---

## ✅ Always Do This:

### Read Path (IIO Format Value):
```c
case DEVICE_IIO_VOLTAGE: {
    int32_t vals[2];  // ✅ Correct type
    uint16_t value;

    ret = device_get_voltage(dev, &value);
    if (ret)
        return ret;

    vals[0] = (int32_t)value / MILLI;
    vals[1] = (int32_t)(value - vals[0] * MILLI) * MILLI;

    return iio_format_value(buf, len, IIO_VAL_INT_PLUS_MICRO, 2, vals);  // ✅ No cast
}
```

### Write Path (IIO Parse Value):
```c
case DEVICE_IIO_VOLTAGE: {
    uint16_t value;
    int32_t vals[2];
    int32_t temp_value;  // ✅ Intermediate variable

    ret = iio_parse_value(buf, IIO_VAL_INT_PLUS_MICRO, &vals[0], &vals[1]);
    if (ret)
        return ret;

    /* ✅ Validate BEFORE casting */
    temp_value = vals[0] * MILLI + vals[1] / MILLI;
    if (temp_value < 0 || temp_value > UINT16_MAX)
        return -EINVAL;

    value = (uint16_t)temp_value;  // ✅ Safe cast

    return device_set_voltage(dev, value);
}
```

---

## 🔍 Quick Checklist:

- [ ] Use `int32_t vals[2]` - NEVER `int vals[2]`
- [ ] Add intermediate variable for calculations
- [ ] Validate range BEFORE casting
- [ ] Return `-EINVAL` for overflow errors
- [ ] No pointer casts on vals[] arrays

---

**Full Documentation:** `.claude/docs/reference/iio-data-type-safety.md`
