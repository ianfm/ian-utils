# Manage flashing with a makefile
# This is a basic but powerful setup for programming and debugging MCUs
# See the accompanying README for more details.
# Author: Ian McMurray

# TODO: Create executable at $(pwd)/$(IMAGEBASE).elf
IMAGEBASE=build/my_firmware_image

GDB=gdb-multiarch
OPENOCD=openocd

GDB_STARTUP_SCRIPT = connect.gdb
OPENOCD_TARGET_SCRIPT = target.cfg	# TODO: Edit to match your processor and programmer
OPENOCD_FLASH_SCRIPT = flash.cfg
OPENOCD_DEBUG_SCRIPT = debug.cfg


# Erase the flash and write the new image
flash:
	$(OPENOCD) -c "set IMAGE $(IMAGEBASE).elf" \
			   -f $(OPENOCD_TARGET_SCRIPT)
			   -f $(OPENOCD_FLASH_SCRIPT)

# Start embedded gdb server
debug:
	$(OPENOCD) -f $(OPENOCD_TARGET_SCRIPT) \
			   -f $(OPENOCD_DEBUG_SCRIPT)

# Attach to embedded gdb server
attach:
	$(GDB) "$(IMAGEBASE).elf" -x $(GDB_STARTUP_SCRIPT)

# JLink Control Interface
control:
	telnet localhost 4444

# View SWO data -- requires code changes
inspect:
	telnet localhost 2332

# TODO: Add project-specific build target
build:
	@echo "Build target not defined"

.PHONY: flash debug
