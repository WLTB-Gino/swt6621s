# swt6621s — Seekwave SWT6621S (SV6160LITE) USB wifi driver

GPL-2.0 kernel driver for the Seekwave SWT6621S wifi/BT combo chip
(reported by hardware as `SV6160LITE`/`SV6160`; SV6316 also supported).
USB transport (`0x3607:0x6621` and friends). Used in IP cameras such as
the Jooan W3-U.

This is a verbatim vendor drop (`SWT6621S_H25.34.7.1_F25.34.6.1`), minus
Android/Allwinner/Rockchip board patches and the USB firmware blobs, which
are packaged with the firmware image instead (see below). The only tree
change is `0001-load-swt6621s-wifi-core-on-pdev-register.patch`.

## Layout

```
drivers/
  seekwaveplatform_lite/   BSP: USB boot + firmware download + power
                           (module: skw_usb_lite, Kconfig: SKW_USB)
  swt6621s_wifi/           cfg80211 full-MAC core
                           (module: swt6621s_wifi, Kconfig: WLAN_VENDOR_SWT6621S)
firmware/                  USB firmware blobs (IRAM/DRAM/NV + RF calib)
include/linux/platform_data/skw_platform_data.h
```

## Module architecture

Two modules with **no shared symbols** (depmod cannot order them):

1. `skw_usb_lite` (BSP) claims the USB device, downloads firmware
   (`SWT6621S_IRAM_USB.bin`, `SWT6621S_DRAM_USB.bin`, `SWT6621S_NV_USB.bin`
   via `request_firmware`), then registers the `sv6621s_wireless1`
   platform device.
2. `swt6621s_wifi` (core) probes on that platform device and creates wlan0.

Because the core only ever loads on demand after the BSP registers the
platform device, load order does not matter in practice — but the BSP is
the module you probe first (S36wireless-style init scripts).

## Load-order fix (integrated)

Right before the BSP registers the wifi platform device it calls
`request_module("swt6621s_wifi")`, so the core is guaranteed present when
the device appears regardless of modprobe ordering. The two modules share
no symbols (all coupling is via the platform device name and platform_data
function pointers), so depmod cannot order them — this request removes the
ordering dependency entirely.

## Building standalone against a kernel tree

```
make -C <kernel-src> M=$PWD \
  CONFIG_SEEKWAVE_BSP_DRIVERS=m \
  CONFIG_SKW_USB=m \
  CONFIG_WLAN_VENDOR_SWT6621S=m \
  modules
```

The root Makefile exports `skw_extra_flags`/`skw_extra_symbols` consumed
by both leaf Makefiles. Compat guards cover kernels 3.1 through 6.4.

## Provenance

- Source: vendor SDK `SWT6621S_H25.34.7.1_F25.34.6.1` (Seekwave tech LTD,
  2020-2021 copyright headers, GPL-2.0 `MODULE_LICENSE`).
- Integrated for [thingino](https://github.com/themactep/thingino-firmware)
  (package: `package/wifi-swt6621s`), which builds both modules from this
  repo and installs the USB firmware set.
