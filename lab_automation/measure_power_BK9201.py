import pyvisa
import time
from datetime import datetime

# VISA setup
rm = pyvisa.ResourceManager('@py')

# Connect to BK Precision PSU
psu = rm.open_resource("USB0::65535::37376::802243020747510043::0::INSTR")  # Replace with your actual string
psu.timeout = 5000
print(f"Connected to PSU: {psu.query('*IDN?').strip()}", flush=True)

psu.write("OUTP ON")
print(f"Output is ON", flush=True)

try:
    while True:
        # Read from PSU
        psu_voltage = float(psu.query("MEAS:VOLT?").strip())
        psu_current = float(psu.query("MEAS:CURR?").strip())
        formatted_v = f"{psu_voltage:.3f}"
        formatted_c = f"{psu_current:.3f}"

        # Timestamp and write
        timestamp = datetime.now().isoformat()

        print(f"{timestamp}, {formatted_v} V, {formatted_c} A", flush=True)
        time.sleep(1)

except KeyboardInterrupt:
    print("\nLogging stopped.", flush=True)
finally:
    psu.close()



# >>> psu.query("CURR?")
# '0.25\n'
# >>> psu.write("CURR 0.45")
# 11
# >>> psu.write("VOLT 4.75")
# 11
