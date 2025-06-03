import pyvisa
import time
import csv
from datetime import datetime

# VISA setup
rm = pyvisa.ResourceManager('@py')
dmm = rm.open_resource("USB0::10893::4865::MY53222530::0::INSTR")
dmm.timeout = 5000

print(f"Connected to: {dmm.query('*IDN?').strip()}", flush=True)

# DMM config
dmm.write("*CLS")
dmm.write("CONF:CURR:DC AUTO")
dmm.write("SENS:CURR:DC:NPLC 0.02")

def open_new_log_file():
    timestamp = datetime.now().strftime("%Y%m%d_%H00")
    filename = f"current_log_{timestamp}.csv"
    f = open(filename, "w", newline="")
    writer = csv.writer(f)
    writer.writerow(["timestamp", "current_mA"])
    print(f"Started new log file: {filename}", flush=True)
    return f, writer, timestamp

# Initialize logging
log_file, writer, current_hour_tag = open_new_log_file()
flush_tag = datetime.now().strftime("%Y%m%d_%H%M")  # Track last flushed minute

try:
    while True:
        # Rotate log file if hour changed
        new_hour_tag = datetime.now().strftime("%Y%m%d_%H00")
        if new_hour_tag != current_hour_tag:
            log_file.close()
            log_file, writer, current_hour_tag = open_new_log_file()
            flush_tag = datetime.now().strftime("%Y%m%d_%H%M")  # Reset flush tag too

        # Read and log data
        raw_current = dmm.query("READ?").strip()
        current_mA = float(raw_current) * 1000
        timestamp = datetime.now().isoformat()
        formatted = f"{current_mA:.6f}"

        writer.writerow([timestamp, formatted])

        # Flush once per minute
        new_flush_tag = datetime.now().strftime("%Y%m%d_%H%M")
        if new_flush_tag != flush_tag:
            log_file.flush()
            flush_tag = new_flush_tag

        print(f"{timestamp}, {formatted} mA", flush=True)
        time.sleep(1)

except KeyboardInterrupt:
    print("\nLogging stopped.", flush=True)
finally:
    log_file.close()
    dmm.close()
