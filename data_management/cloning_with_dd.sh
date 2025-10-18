# Cloning command iterations
## Basic clone w/ 64MB block size, no caching, and progress display by dd
sudo dd if=/dev/sda of=/dev/sdb bs=64M iflag=direct oflag=direct status=progress
## Prevent the system from sleeping during the clone! Fucker.
systemd-inhibit --what=idle:sleep --why="Cloning SSD" dd if=/dev/sda of=/dev/sdb bs=64M iflag=direct oflag=direct status=progress
## Command below won't work b/c multiple commands after systemd-inhibit
sudo pv /dev/sda | systemd-inhibit --what=idle:sleep --why="Cloning SSD" dd of=/dev/sdb bs=64M iflag=direct oflag=direct status=progress 
## Wrap pv|dd in a bash -c to fix above
systemd-inhibit --what=idle:sleep --why="Cloning SSD" bash -c 'pv /dev/sda | dd of=/dev/sdb bs=64M iflag=direct oflag=direct'
## Add buffer to pv to match dd block size
sudo systemd-inhibit --what=idle:sleep --why="Cloning SSD" bash -c 'pv -B 64M /dev/sda | dd of=/dev/sdb bs=64M iflag=direct oflag=direct'
## dd complained about non-filled buffer something and said to add iflag=fullblock --> wait for buffer to fill (64MB) before writing
sudo systemd-inhibit --what=idle:sleep --why="Cloning SSD" bash -c 'pv -B 64M /dev/sda | dd of=/dev/sdb bs=64M iflag=fullblock,direct oflag=direct'

# Results from final command, cloning a 256GB SSD to a 2TB SSD
# Alienware M15-R7 running Ubuntu 22.04 (KDE)
# sda on external usb hub (10G) with thunderbolt cables from chassis to hub and hub to NVME adapter
# sdb on chassis usb-a with an A-to-C cable marked "SS" to NVME adapter
$ sudo systemd-inhibit --what=idle:sleep --why="Cloning SSD" bash -c 'pv -B 64M /dev/sda | dd of=/dev/sdb bs=64M iflag=fullblock,direct oflag=direct'
 238GiB 0:19:27 [ 209MiB/s] [======================================================================================================>] 100%            
3815+1 records in
3815+1 records out
256060514304 bytes (256 GB, 238 GiB) copied, 1170.71 s, 219 MB/s
