import argparse
import nmap
from nmap import PortScanner, convert_nmap_output_to_encoding, nmap
import subprocess
import re
from scapy.all import ARP, Ether, srp

# Function to scan for open ports on a local network
def scan_local_network():
    # Step 1: Perform an ARP scan to discover devices in the local network
    target_ip = "192.168.86.0/24"  # Modify this to match your local network
    arp = ARP(pdst=target_ip)
    ether = Ether(dst="ff:ff:ff:ff:ff:ff")
    packet = ether/arp
    result = srp(packet, timeout=3, verbose=0)[0]

    # Extract hostnames and MAC addresses
    devices = []
    for sent, received in result:
        devices.append({'ip': received.psrc, 'mac': received.hwsrc})

    # Step 2: Perform a port scan on discovered devices to find open ports
    open_ports = []
    for device in devices:
        nm = nmap.PortScanner()
        nm.scan(device['ip'], arguments='-p 80,443,22,8080')  # Add more ports if needed
        if device['ip'] in nm.all_hosts() and nm[device['ip']].all_tcp():
            open_ports.append({'ip': device['ip'], 'hostname': '', 'mac': device['mac'],
                               'open_ports': list(nm[device['ip']].all_tcp())})

    # Step 3: Classify devices likely to be developer laptops based on open ports
    developer_laptops = []
    for device in open_ports:
        if 22 in device['open_ports']:
            developer_laptops.append(device)

    # Print the results
    print("Devices in the local network:")
    for device in devices:
        print(f"IP: {device['ip']}, MAC: {device['mac']}")

    print("\nDevices with open ports:")
    for device in open_ports:
        print(f"IP: {device['ip']}, Hostname: {device['hostname']}, MAC: {device['mac']}, Open Ports: {device['open_ports']}")

    print("\nLikely Developer Laptops:")
    for device in developer_laptops:
        print(f"IP: {device['ip']}, Hostname: {device['hostname']}, MAC: {device['mac']}, Open Ports: {device['open_ports']}")

# Function to run the CLI menu
def main():
    parser = argparse.ArgumentParser(description="Network Scanner Menu")
    parser.add_argument( "--option", default=1, type=int, help="Select an option: 1 for Scan Local Network")
    args = parser.parse_args()

    if args.option == 1:
        scan_local_network()
    else:
        print("Invalid option. Please select a valid option from the menu.")

if __name__ == "__main__":
    main()