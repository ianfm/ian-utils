import pyvisa
rm = pyvisa.ResourceManager('@py')
print(rm.list_resources())
print()

# ASRL1::INSTR                                      # bogus serial port - ignore
# USB0::10893::4865::MY53222530::0::INSTR           # Keysight 3446 (5A?)  
# USB0::10893::257::MY60077870::0::INSTR            # Keysight 3446 (1A?)  
# USB0::65535::37376::802243020747510043::0::INSTR  # BK Precision 9120       

for res in rm.list_resources():
    try:
        inst = rm.open_resource(res)
        idn = inst.query("*IDN?")
        print()
        print(f"{res} -> {idn.strip()}")
    except Exception:
        pass
