#!/bin/bash
set -eu

echo "==== create partitions"
parted --script /dev/sda \
    mklabel msdos \
    mkpart primary linux-swap 1MiB 2049MiB \
    mkpart primary ext4 2049MiB 100% \
    set 2 boot on

mkswap /dev/sda1
swapon /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt

echo "==== install base packages"
pacstrap /mnt base grub
genfstab -U /mnt > /mnt/etc/fstab

echo "==== setup grub"
sed -i 's/#GRUB_HIDDEN_TIMEOUT=5/GRUB_HIDDEN_TIMEOUT=0/' /mnt/etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg   



 