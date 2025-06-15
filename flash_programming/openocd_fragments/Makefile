# Manage flashing with a makefile
# This is experimental based on the cfg fragments in this dir

# executable is at $(pwd)/$(IMAGEBASE).elf
IMAGEBASE=original_source/images/pelagic_vms

GDB=gdb-multiarch
JLINK=JLinkCommander
OPENOCD=openocd

GDB_INIT_SCRIPT = connect.gdb
# GDB_UTILS_SCRIPT = adc_definitions.gdb

# Not ready for deployment
flash_experimental:
	$(OPENOCD) \
		-c "set IMAGE $(IMAGEBASE).elf" \
		-f "flashtools/setup_image.cfg" \
		-f "flashtools/setup_chip.cfg" \
		-f "flashtools/begin.cfg" \
		-f "flashtools/do_erase.cfg" \
		-f "flashtools/do_flash_verify.cfg" \
		-c "exit"

# Not ready for deployment
debug_experimental:
	$(OPENOCD) \
		-c "set IMAGE $(IMAGEBASE).elf" \
		-f "flashtools/setup_image.cfg" \
		-f "flashtools/setup_chip.cfg" \
		-f "flashtools/begin.cfg" \
		-f "flashtools/do_erase.cfg" \
		-f "flashtools/do_flash_verify.cfg" \
		-f "flashtools/setup_swd.cfg" \
		-f "flashtools/setup_ports.cfg" \
		-c "halt"


flash:
	$(OPENOCD) -c "set IMAGE $(IMAGEBASE).elf" -f "full_flash_example.cfg"

debug:
	$(OPENOCD) -f "full_debug_example.cfg"

attach:
	$(GDB) "$(IMAGEBASE).elf" -x $(GDB_INIT_SCRIPT)

inspect:
	telnet localhost 2332

control:
	telnet localhost 4444


.PHONY: flash debug