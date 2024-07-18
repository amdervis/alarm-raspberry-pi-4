#!/bin/bash

# Find the SD card device that starts with mmc
SD_CARD=$(lsblk -dpno NAME | grep -E '^/dev/mmcblk[0-9]$')

DOWNLOAD_URL64="http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
DOWNLOAD_FILE=$(echo "$DOWNLOAD_URL64" | grep -oE '[^/]+$')

# Check if an mmc device was found
if [ -z "$SD_CARD" ]; then
    echo "No mmc device found. Exiting."
    exit 1
fi

# Unmount partitions if they are already mounted
umount ${SD_CARD}* || true

# Delete all partitions from the SD card
echo "Deleting all partitions from the SD card..."
wipefs -a ${SD_CARD}

# Start fdisk to partition the SD card
echo "Starting fdisk to partition the SD card..."
fdisk ${SD_CARD} <<EOF
o
p
n
p
1

+500M
t
c
n
p
2


w
EOF

# Create and mount the FAT filesystem
echo "Creating and mounting the FAT filesystem..."
mkfs.vfat ${SD_CARD}p1
mkdir -p boot
mount ${SD_CARD}p1 boot

# Create and mount the ext4 filesystem
echo "Creating and mounting the ext4 filesystem..."
mkfs.ext4 ${SD_CARD}p2
mkdir -p root
mount ${SD_CARD}p2 root

# Download and extract the root filesystem
echo "Downloading and extracting the root filesystem..."
wget $DOWNLOAD_URL64
tar -xpf $DOWNLOAD_FILE -C root


# Move boot files to the first partition
echo "Moving boot files to the first partition..."
mv root/boot/* boot

# Before unmounting the partitions, update /etc/fstab for the different SD block device compared to the Raspberry Pi 3
sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab

echo "Copying bootloader..."
cp $HOME/download/boot/kernel8.img $HOME/boot

# Unmount partitions
sync && umount boot root

echo "SD card setup complete!"
