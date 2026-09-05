skw_extra_symbols := $(src)/drivers/seekwaveplatform_lite/Module.symvers
skw_extra_flags := -I$(src)/include/linux/platform_data

skw_extra_flags += -DCONFIG_SEEKWAVE_BSP_DRIVERS
skw_extra_flags += -DCONFIG_SWT6621S_LOG_DEBUG

export skw_extra_flags
export skw_extra_symbols

obj-m += drivers/
