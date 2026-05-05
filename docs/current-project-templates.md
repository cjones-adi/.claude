# Current Project Templates (Updated May 2026)

This document provides the **current** project templates based on the latest framework changes. These templates reflect the patterns used in the LTM4700 project after the "Align project example with new framework" commit.

## 🚨 CRITICAL: Template Standards Update

**Issue Resolved**: Previous templates were outdated, causing Claude to generate incorrect project files.
**Reference Implementation**: LTM4700 project files (commit e13b47e23)
**Status**: ✅ Updated to current framework patterns

---

## Project Structure Template

```
projects/<device>/
├── Makefile              # Platform build selection
├── builds.json           # CI build matrix (NEW FORMAT)
├── src.mk               # Source dependencies (INDIVIDUAL INCLUDES)
├── README.rst            # Complete project documentation
└── src/
    ├── common/
    │   ├── common_data.h
    │   └── common_data.c
    ├── examples/
    │   ├── basic/
    │   │   └── basic_example.c    # NO header file needed
    │   └── iio_example/
    │       ├── iio_example.c
    │       └── iio_example.mk     # Example-specific configuration
    └── platform/<target>/
        ├── main.c                # Simplified main (calls example_main())
        ├── parameters.c
        ├── parameters.h
        └── platform_src.mk       # Individual includes only
```

---

## Makefile Template

**✅ CURRENT FORMAT:**
```makefile
EXAMPLE ?= iio_example

include ../../tools/scripts/generic_variables.mk

include ../../tools/scripts/examples.mk

include src.mk

include ../../tools/scripts/generic.mk
```

**❌ OLD FORMAT (DO NOT USE):**
```makefile
# Select the example you want to enable by choosing y for enabling and n for disabling
BASIC_EXAMPLE = n
IIO_EXAMPLE = y

include ../../tools/scripts/generic_variables.mk

include src.mk

include ../../tools/scripts/generic.mk
```

---

## builds.json Template

**✅ CURRENT FORMAT:**
```json
{
	"maxim": {
		"basic_example_max32665": {
			"flags": "EXAMPLE=basic TARGET=max32665"
		},
		"iio_example_max32665": {
			"flags": "EXAMPLE=iio_example TARGET=max32665"
		}
	}
}
```

**Key Requirements:**
- **Indentation**: Use TABS (not spaces)
- **Target Platform**: `max32665` (not `max32655`)
- **Example Format**: `EXAMPLE=basic` (not `BASIC_EXAMPLE=y`)
- **Build Keys**: Include target in name (`basic_example_max32665`)
- **Flag Format**: Space-separated flags string

**❌ OLD FORMAT (DO NOT USE):**
```json
{
    "maxim": {
        "basic_example": {
            "flags": "BASIC_EXAMPLE=y TARGET=max32655"
        }
    }
}
```

---

## src.mk Template

**✅ CURRENT FORMAT:**
```makefile
INCS += $(INCLUDE)/no_os_delay.h	\
	$(INCLUDE)/no_os_error.h	\
	$(INCLUDE)/no_os_list.h		\
	$(INCLUDE)/no_os_gpio.h		\
	$(INCLUDE)/no_os_dma.h		\
	$(INCLUDE)/no_os_print_log.h	\
	$(INCLUDE)/no_os_i2c.h		\
	$(INCLUDE)/no_os_irq.h		\
	$(INCLUDE)/no_os_pwm.h		\
	$(INCLUDE)/no_os_rtc.h		\
	$(INCLUDE)/no_os_uart.h		\
	$(INCLUDE)/no_os_lf256fifo.h	\
	$(INCLUDE)/no_os_util.h		\
	$(INCLUDE)/no_os_units.h	\
	$(INCLUDE)/no_os_alloc.h	\
	$(INCLUDE)/no_os_mutex.h	\
	$(INCLUDE)/no_os_crc8.h

SRCS += $(NO-OS)/util/no_os_lf256fifo.c	\
	$(DRIVERS)/api/no_os_i2c.c	\
	$(DRIVERS)/api/no_os_dma.c	\
	$(DRIVERS)/api/no_os_uart.c	\
	$(DRIVERS)/api/no_os_irq.c	\
	$(DRIVERS)/api/no_os_gpio.c	\
	$(DRIVERS)/api/no_os_pwm.c	\
	$(NO-OS)/util/no_os_util.c	\
	$(NO-OS)/util/no_os_list.c	\
	$(NO-OS)/util/no_os_alloc.c	\
	$(NO-OS)/util/no_os_mutex.c	\
	$(NO-OS)/util/no_os_crc8.c

INCS += $(DRIVERS)/power/<device>/<device>.h
SRCS += $(DRIVERS)/power/<device>/<device>.c
```

**Key Requirements:**
- **Individual Includes**: Each header listed separately
- **Proper Alignment**: Use tabs for alignment
- **No Wildcards**: Never use `$(INCLUDE)` or `**` patterns
- **No Conditionals**: No `ifeq` blocks for example selection

**❌ OLD FORMAT (DO NOT USE):**
```makefile
include $(PROJECT)/src/platform/$(PLATFORM)/platform_src.mk
include $(PROJECT)/src/examples/examples_src.mk

NO_OS_INC_DIRS += \
	$(INCLUDE) \
	$(PROJECT)/src/ \
	$(DRIVERS)/api/ \
	$(DRIVERS)/power/<device>/

ifeq (y,$(strip $(IIO_EXAMPLE)))
IIOD=y
SRCS += $(DRIVERS)/power/<device>/iio_<device>.c
INCS += $(DRIVERS)/power/<device>/iio_<device>.h
endif
```

---

## Example Files Template

### basic_example.c

**✅ CURRENT FORMAT:**
```c
#include "common_data.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"
#include "<device>.h"
#include <stdlib.h>

int example_main()  // NOT basic_example_main()
{
    struct <device>_dev *dev;
    int ret = 0;

    // Implementation here

    return ret;
}
```

**Key Requirements:**
- **Function Name**: `example_main()` (not `<example>_example_main()`)
- **No Header File**: Do not create `basic_example.h`
- **Direct Includes**: Include headers directly, not via `platform_includes.h`

### iio_example.c

**✅ CURRENT FORMAT:**
```c
#include "common_data.h"
#include "no_os_delay.h"
#include "no_os_print_log.h"
#include "iio_app.h"

int example_main()  // NOT iio_example_main()
{
    int ret;

    // IIO implementation here

    return ret;
}
```

### iio_example.mk

**✅ NEW FILE REQUIRED:**
```makefile
IIOD=y
INCS += $(DRIVERS)/power/<device>/iio_<device>.h
SRCS += $(DRIVERS)/power/<device>/iio_<device>.c
```

**Key Requirements:**
- **Example-Specific**: Each complex example gets its own `.mk` file
- **IIO Configuration**: Set `IIOD=y` and include IIO-specific sources
- **Individual Includes**: List headers and sources individually

---

## Platform Files Template

### main.c

**✅ CURRENT FORMAT:**
```c
#include "parameters.h"
#include "common_data.h"
#include "no_os_error.h"

int main()
{
    return example_main();
}
```

**Key Requirements:**
- **Simplified**: Just calls `example_main()`
- **No Conditionals**: No `#ifdef` blocks for different examples
- **Direct Includes**: Include `parameters.h` directly
- **No AI Attribution**: Use configured git user for copyright

**❌ OLD FORMAT (DO NOT USE):**
```c
#include "platform_includes.h"
#include "common_data.h"

#ifdef BASIC_EXAMPLE
#include "basic_example.h"
#endif

#ifdef IIO_EXAMPLE
#include "iio_example.h"
#endif

int main()
{
    int ret = 0;

#ifdef BASIC_EXAMPLE
    ret = basic_example_main();
#endif

#ifdef IIO_EXAMPLE
    ret = iio_example_main();
#endif

    return ret;
}
```

### platform_src.mk

**✅ CURRENT FORMAT:**
```makefile
INCS += \
	$(PLATFORM_DRIVERS)/maxim_gpio.h	\
	$(PLATFORM_DRIVERS)/maxim_gpio_irq.h	\
	$(PLATFORM_DRIVERS)/maxim_irq.h		\
	$(PLATFORM_DRIVERS)/../common/maxim_dma.h	\
	$(PLATFORM_DRIVERS)/maxim_i2c.h		\
	$(PLATFORM_DRIVERS)/maxim_uart.h	\
	$(PLATFORM_DRIVERS)/maxim_uart_stdio.h

SRCS += $(PLATFORM_DRIVERS)/maxim_delay.c \
	$(PLATFORM_DRIVERS)/maxim_gpio.c \
	$(PLATFORM_DRIVERS)/maxim_gpio_irq.c \
	$(PLATFORM_DRIVERS)/maxim_irq.c \
	$(PLATFORM_DRIVERS)/../common/maxim_dma.c \
	$(PLATFORM_DRIVERS)/maxim_i2c.c \
	$(PLATFORM_DRIVERS)/maxim_uart.c \
	$(PLATFORM_DRIVERS)/maxim_uart_stdio.c
```

**Key Requirements:**
- **Individual Headers**: List each header separately
- **No Directory Includes**: No `NO_OS_INC_DIRS += $(PLATFORM_DRIVERS)`
- **Platform-Specific**: Adapt header names for target platform

### common_data.h

**✅ CURRENT FORMAT:**
```c
#ifndef __COMMON_DATA_H__
#define __COMMON_DATA_H__

#include "no_os_uart.h"
#include "no_os_i2c.h"
#include "<device>.h"
#include "parameters.h"

// Device-specific definitions

extern struct no_os_uart_init_param <device>_uart_ip;
extern struct no_os_i2c_init_param <device>_i2c_ip;
extern struct <device>_init_param <device>_init_ip;

#endif /* __COMMON_DATA_H__ */
```

**Key Requirements:**
- **Direct Includes**: Include `parameters.h` directly
- **No Platform Wrapper**: No `platform_includes.h`

---

## Framework Integration Checklist

When using these templates, verify:

### ✅ Makefile Integration
- [ ] `EXAMPLE ?= iio_example` format used
- [ ] Includes `examples.mk` script
- [ ] No conditional example selection

### ✅ builds.json Standards
- [ ] Tab indentation (not spaces)
- [ ] Target is `max32665` (not `max32655`)
- [ ] `EXAMPLE=basic` format (not `BASIC_EXAMPLE=y`)
- [ ] Target-specific build keys

### ✅ src.mk Individual Includes
- [ ] All headers listed individually in `INCS +=`
- [ ] All sources listed individually in `SRCS +=`
- [ ] Proper tab alignment
- [ ] No wildcard directories

### ✅ Example Structure
- [ ] Functions named `example_main()`
- [ ] No example header files
- [ ] IIO example has `.mk` file
- [ ] Direct includes (no platform wrapper)

### ✅ Platform Integration
- [ ] Simplified `main.c` calling `example_main()`
- [ ] Individual platform headers in `platform_src.mk`
- [ ] `parameters.h` included directly
- [ ] No `platform_includes.h` file

---

## Claude Usage Guidelines

**🚨 MANDATORY: Claude must use ONLY these current templates**

1. **Reference Implementation**: Always refer to LTM4700 project structure
2. **No Old Patterns**: Never use conditional example selection or bulk includes
3. **Individual Files**: Always list headers and sources individually
4. **Current Targets**: Use `max32665` and current build flag formats
5. **Simplified Structure**: Use the new streamlined file organization

**Common Mistakes to Avoid:**
- ❌ Using `BASIC_EXAMPLE=y` format
- ❌ Including `$(INCLUDE)` bulk directories
- ❌ Creating `platform_includes.h` wrapper
- ❌ Using `max32655` instead of `max32665`
- ❌ Space indentation in `builds.json`
- ❌ Creating example header files

**Template Validation:**
Before implementation, Claude should verify these templates match current LTM4700 patterns and framework requirements.

---

**Reference Commit**: e13b47e23 "Align project example with new framework"
**Last Updated**: May 5, 2026
**Status**: ✅ Production-ready templates validated against current framework