# README

## Identification commands
Find your devices like this. First make sure the usb device is present. You may need to change a setting on the equipment to enable usb comms.
Then see if the usbmtc device is present.
Then see if python's pyvisa library can see it.

1. `lsusb`
2. `ls /dev/usbnmtc*`
3. `python3`
then 
```python
import pyvisa
rm = pyvisa.ResourceManager('@py')
print(rm.list_resources())
```

If all but the last work, you need to unbind the device from usbmtc.


## Measuring