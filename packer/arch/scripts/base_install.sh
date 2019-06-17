#!/bin/bash
set -eu

echo "==== install packages"
pacstrap /mnt sudo openssh python

echo "==== create chroot script"
cat << CHROOT_DELIMITER > /mnt/usr/local/bin/arch-config.sh
#!/bin/bash
set -eu

echo "==== setup timezone"
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc

echo "==== setup locales"
echo "KEYMAP=$PACKER_KEYMAP" > /etc/vconsole.conf
echo "LANG=$PACKER_KEYMAP.UTF-8" > /etc/locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
sed -i "/\($PACKER_KEYMAP.UTF-8 UTF-8\)/s/^#//g" /etc/locale.gen
sed -i "/\(en_US.UTF-8 UTF-8\)/s/^#//g" /etc/locale.gen
locale-gen

echo "==== setup firstboot"

rm /etc/machine-id
rm /var/lib/dbus/machine-id

cat << EOF > /usr/lib/systemd/system/systemd-firstboot.service
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=First Boot Wizard
Documentation=man:systemd-firstboot(1)
DefaultDependencies=no
Conflicts=shutdown.target
After=systemd-remount-fs.service
Before=systemd-sysusers.service sysinit.target shutdown.target
ConditionPathIsReadWrite=/etc
ConditionFirstBoot=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/systemd-firstboot --setup-machine-id
StandardOutput=tty
StandardInput=tty
StandardError=tty

[Install]
WantedBy=sysinit.target
EOF

echo "==== setup network"
echo "$PACKER_HOSTNAME" > /etc/hostname

sed -i '/\(MulticastDNS=yes\)/s/^#//g' /etc/systemd/resolved.conf

cat << EOF > /etc/hosts
127.0.0.1	localhost
::1		    localhost
EOF

cat << EOF > /etc/systemd/network/20-wired.network
[Match]
Name=en*

[Network]
DHCP=ipv4
MulticastDNS=true

[DHCP]
UseDomains=true
EOF

echo "==== setup services"
systemctl enable sshd
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable systemd-firstboot.service

mkdir -p /root/.ssh
echo $PACKER_AUTHORIZED_KEY > /root/.ssh/authorized_keys

CHROOT_DELIMITER

chmod u+x /mnt/usr/local/bin/arch-config.sh

echo "==== run config in chroot"
arch-chroot /mnt /usr/local/bin/arch-config.sh