# Manage flash programming and debugging with a makefile project

The combination of `openocd`, `gdb`, and `make` form a powerful setup for programming and debugging MCUs. The Makefile contains rules to flash, debug, and inspect MCU output, so all you need to do is call `make <target>` to orchestrate the workflow!

This example targets the STM32L431 microcontroller with a JLink debugger. Details are provided in the readme and scripts for adapting the tools to a new project.

Note: This setup is intended to run on a Linux host. Doing it on Windows is possible, but it sucks, and I don't recommend it. Try using WSL and USBIP to share your hardware with the WSL instance if you don't want to run Linux natively. Otherwise, use vendor-provided tools like CubeIDE or SEGGER Embedded Studio to program and debug your hardware.


## Usage

1. `make flash` to erase the chip and flash the firmware image
2. `make debug` to start the debug server on the JLink
3. `make attach` to connect to the debug server with GDB and start debugging
4. `make control` to connect to the JLink's telnet port where you can send it commands
5. `make inspect` to view SWO data the JLink streams from the processor **(requires source code modifications)**
6. `make build` ... Add your own build rules to the makefile!

## Prerequisites

### Install software dependencies

At the minimum you need `openocd`, `make`, and `gdb`. Note that `gdb-multiarch` replaces `arm-none-eabi-gdb`, which is no longer in the apt source list.

```Bash
sudo apt install openocd make gdb-multiarch
```

Naturally you'll also want build tools. The typical toolchain is `arm-none-eabi-gcc` which you can download with 

```Bash
sudo apt install gcc-arm-none-eabi
```

### Set your target processor, debugger, and interface

This project uses `STM32L4x`, `JLink`, and `SWD`, which are set in `target_cpu.cfg`. Modify this file to match your target hardware. For example, if you have a raspberry pi pico, you might have something like this:

```Tcl
source [find interface/jlink.cfg]
source [find target/rp2040.cfg]
```

*Note: if you read target/rp2040.cfg, you'll see it already specifies `transport select swd` and explains that it is required. Consider reading your target file to learn more about your processor!*

You can change the target processor, debugger, and interface by editing `flash.cfg`. To see what options are included with openocd, find the key openocd paths with `whereis openocd` and look in the scripts directory. For example, I can list available processor targets provided by openocd with

```Bash
ls /usr/share/openocd/scripts/target/
```

### Prepare a firmware image to flash

Have an executable to run on your MCU. This is project dependent so bring your own build tools. I've provided a dummy rule in the makefile for adding a new build target, but you'll have to update it to set the correct path and build recipe.

## Advanced Topics

- Flash write location when using binaries (as opposed to .elf which contains location information)
  - bootloader location
  - firmware location
  - reserved memory for e.g. nonvolatile storage
- Serial Wire Output (SWO) and Embedded Trace Macrocell (ETM) for debugging
  - see debug.cfg for the tpiu config line
  - these powerful tools require source code modifications

...to be continued?
