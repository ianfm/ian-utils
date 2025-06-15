import pyvisa
import time
import csv
from datetime import datetime

# Connect to VISA backend
rm = pyvisa.ResourceManager('@py')

# Replace with your actual VISA resource strings
PSU_ADDR = "USB0::65535::37376::802243020747510043::0::INSTR"
DMM_VOLT_ADDR = "USB0::10893::257::MY60077870::0::INSTR"  # Voltage
DMM_CURR_ADDR = "USB0::10893::4865::MY53222530::0::INSTR"  # Current

# Open instruments
psu = rm.open_resource(PSU_ADDR)
dmm_v = rm.open_resource(DMM_VOLT_ADDR)
dmm_c = rm.open_resource(DMM_CURR_ADDR)

# Set timeouts
for inst in (psu, dmm_v, dmm_c):
    inst.timeout = 5000

print(f"Connected to PSU: {psu.query('*IDN?').strip()}")
print(f"Connected to DMM-V: {dmm_v.query('*IDN?').strip()}")
print(f"Connected to DMM-C: {dmm_c.query('*IDN?').strip()}")

# Configure instruments
dmm_c.write("*CLS")
dmm_c.write("CONF:CURR:DC 0.1")  # for 100 mA range
#dmm_c.write("SENS:CURR:DC:NPLC 0.02")

dmm_v.write("*CLS")
dmm_v.write("CONF:VOLT:DC AUTO")
dmm_v.write("SENS:VOLT:DC:NPLC 0.2")

psu.write("CURR 0.2 A")
psu.write("VOLT 4.8 V")
psu.write("OUTP ON")
print("PSU Output is ON")

# Logging state
last_hour = None
last_flush = time.time()
logfile = None
writer = None

def open_log_file():
    now = datetime.now()
    fname = now.strftime("log_%Y%m%d_%H00.csv")
    f = open(fname, 'a', newline='')
    w = csv.writer(f)
    if f.tell() == 0:
        w.writerow([
            "timestamp",
            "v_solar_mV", "i_solar_mA", "p_solar_mW",
            "v_batt_mV", "i_batt_mA", "p_batt_mW",
            "p_device_mW"
        ])
    return f, w

try:
    while True:
        now = datetime.now()
        if now.hour != last_hour:
            if logfile:
                logfile.flush()
                logfile.close()
            logfile, writer = open_log_file()
            last_hour = now.hour

        # Measurements
        timestamp = now.isoformat()
        v_solar = float(psu.query("MEAS:VOLT?").strip()) * 1000  # mV
        i_solar = float(psu.query("MEAS:CURR?").strip()) * 1000  # mA
        p_solar = v_solar * i_solar / 1000  # mW

        v_batt = float(dmm_v.query("MEAS:VOLT?").strip()) * 1000  # mV
        i_batt = float(dmm_c.query("MEAS:CURR? 0.1").strip()) * 1000  # set range 100 mA, mA out
        p_batt = v_batt * i_batt / 1000  # mW

        # p consumed = p_draw - p_charge
        p_device = p_batt - p_solar  # mW

        writer.writerow([
            timestamp,
            f"{v_solar:.2f}", f"{i_solar:.2f}", f"{p_solar:.2f}",
            f"{v_batt:.2f}", f"{i_batt:.2f}", f"{p_batt:.2f}",
            f"{p_device:.2f}"
        ])

        print(f"{timestamp} | PSU: {v_solar:.1f} mV, {i_solar:.1f} mA, {p_solar:.1f} mW "
              f"| DMM: {v_batt:.1f} mV, {i_batt:.1f} mA, {p_batt:.1f} mW "
              f"| Device: {p_device:.1f} mW", flush=True)

        # Flush to disk every minute
        if time.time() - last_flush >= 60:
            logfile.flush()
            last_flush = time.time()

        time.sleep(0.2)

except KeyboardInterrupt:
    print("\nLogging stopped.")

finally:
    psu.write("OUTP OFF")
    print("PSU Output is OFF")
    for inst in (psu, dmm_v, dmm_c):
        inst.close()
    if logfile:
        logfile.flush()
        logfile.close()
