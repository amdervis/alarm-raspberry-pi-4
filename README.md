[![Build Status](https://realdigitalsignage.com/tmp/logos/images.png)](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4)
# AArch64 Installation

This provides an installation using the mainline kernel and U-Boot. Use this installation only if you have no dependencies on the closed source vendor libraries shipped in the ARMv7 release. This installation has near full support for the device, including the VC4 graphics.

Replace `sdX` in the following instructions with the device name for the SD card as it appears on your computer (`mmcblkX`).

1.  Start fdisk to partition the SD card:
```sh
fdisk /dev/mmcblk0
```
2.  At the fdisk prompt, delete old partitions and create a new one:
- Type `o`. This will clear out any partitions on the drive.
- Type `p` to list partitions. There should be no partitions left.
- Type `n`, then `p` for primary, `1` for the first partition on the drive, press `ENTER` to accept the default first sector, then type `+500M` for the last sector.
- Type `t`, then `c` to set the first partition to type W95 FAT32 (LBA).
- Type `n`, then `p` for primary, `2` for the second partition on the drive, and then press `ENTER` twice to accept the default first and last sector.
- Write the partition table and exit by typing `w`.

3. Create and mount the `FAT` filesystem:
```sh
mkfs.vfat /dev/mmcblk0p1
mkdir boot
mount /dev/mmcblk0p1 boot
```

4. Create and mount the `ext4`  filesystem:
```sh
mkfs.vfat /dev/mmcblk0p2
mkdir root
mount /dev/mmcblk0p2 root
```

5. Download and extract the root filesystem (as root, not via sudo):
```sh
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
tar -xpf ArchLinuxARM-rpi-armv7-latest.tar.gz -C root
```
6. Move boot files to the first partition:
```sh
mv root/boot/* boot
```

7. Download and extract the new bootloader (as root, not via sudo):
```sh
wget http://mirror.archlinuxarm.org/aarch64/alarm/uboot-raspberrypi-2024.07-3-aarch64.pkg.tar.xz
tar -xf uboot-raspberrypi-2024.07-3-aarch64.pkg.tar.xz -C /tmp
```
8. Before unmounting the partitions, update `/etc/fstab` for the different SD block device compared to the Raspberry Pi 3:
```sh
sed -i 's/mmcblk0/mmcblk1/g' root/etc/fstab
```
9. Replace the Das U-Boot bootloader with a newer version:
```sh
cp /tmp/boot/kernel8.img boot/
```

10. Syncronize and unmount the two partitions:
```sh
sync && umount boot root
```

# AArch64 Post-Installation
## Pacman setup and system update
1. Insert the SD card into the Raspberry Pi, connect ethernet, and apply 5V power.
2. Use the serial console or SSH to the IP address given to the board by your router.
-- Login as the default user alarm with the password alarm.
-- The default root password is root.
3. Initialize the pacman keyring and populate the Arch Linux ARM package signing keys and start full system update.
```sh
# Switch to root with default password for archlinuxarm
su root

# Pacman keyring init
pacman-key --init
pacman-key --populate archlinuxarm
# Full system update
pacman -Syu
```
## System, language and locale
Configure SSH to allow user root to ssh:
```sh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
```

Change the default hostname:
```sh
HOSTNAME="rpi4-wp" && echo $HOSTNAME > /etc/hostname
```

Set timezone:
```sh
TIMEZONE="Europe/Zagreb" && ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
```

Set locale:
```sh
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```
Set keyboard layout:
```sh
echo "KEYMAP=hr" > /etc/vconsole.conf
```

## Users and privilage escalation (sudo)
Rename the default username to `your-user`:
```sh
USER="your-user" && usermod -l $USER alarm
```
Change password for new user your-user
```sh
passwd $USER
```
Change the home directory name to match the new username
```sh
usermod -d /home/$USER -m $USER
```
Change the group name to match the new username
```sh    
groupmod -n $USER alarm
```
Install sudo package:
```sh
pacman -S sudo --noconfirm
```
Add `your-user` user to sudoers file:
```sh
echo "$USER ALL=(ALL) ALL" >> /etc/sudoers
```
## Kernel
For hardware acceleration, a requirement is the `linux-rpi` kernel (RPi Foundation fork), not vanilla kernel:
```sh
pacman -S linux-rpi --noconfirm
```

Reboot after the kernel and bootloader replacement:
```sh
sudo reboot
```
