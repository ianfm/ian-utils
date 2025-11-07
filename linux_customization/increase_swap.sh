#!/bin/bash
# Check the middle of this thread for more details https://chatgpt.com/share/690e4f6e-5dd4-8008-8140-68027e3ad2fa
# Assumes you have a swapfile at /swap.img
# Could also be at /swapfile

SWAPFILE=""

echo "Current swapfile status:"
if [[ -f "/swap.img" ]]; then
    SWAPFILE="/swap.img"
elif [[ -f "/swapfile" ]]; then
    SWAPFILE="/swapfile"
else
    echo "Swapfile does not exist"
    exit 1
fi

echo "Swapfile exists at $SWAPFILE"
OG_SWAPSIZE=$(free -h | grep Swap | awk '{print $2}')
echo "Current swap size: $OG_SWAPSIZE"

echo "This is a potentially dangerous operation. Make sure you know what you're doing."
read -p "Are you sure you want to continue? [y/n] " ans
if [[ $ans != y && $ans != Y ]]; then
    echo "Exiting"
    exit 1
fi

read -p "Enter new swap size in GB (e.g. 32): " SWAPSIZE

sudo swapoff $SWAPFILE
sudo fallocate -l ${SWAPSIZE}G $SWAPFILE
sudo chmod 600 $SWAPFILE
sudo mkswap $SWAPFILE
sudo swapon $SWAPFILE
echo "Swap size increased to ${SWAPSIZE}GB"
swapon --show

# Not sure if this is required (original purpose was allowing hibernate-resume)
# check, then update fstab if needed
if grep -q "$SWAPFILE" /etc/fstab; then
    echo "Swapfile already in fstab"
else
    echo "Adding swapfile to fstab"
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "Summary of changes:"
echo "Swapfile: $SWAPFILE"
echo "Swap size: $(free -h | grep Swap | awk '{print $2}')"
echo "fstab entry: $(grep $SWAPFILE /etc/fstab)"