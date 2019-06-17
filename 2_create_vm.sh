#!/bin/bash

set -e

VM_HOSTNAME=$1
OVA_FILE="packer/arch/output-virtualbox-iso/arch_base.ovf"
MACHINES_ROOT="$PWD/machines"
MACHINE_ROOT="$MACHINES_ROOT/$VM_HOSTNAME"

mkdir -p "$MACHINE_ROOT/share"

VBoxManage import $OVA_FILE --vsys 0 --memory 2048 --vsys 0 --vmname "$VM_HOSTNAME" --vsys 0 --basefolder "$MACHINES_ROOT" --vsys 0 --unit 11 --disk "$MACHINE_ROOT/$VM_HOSTNAME.vmdk" --vsys 0 --settingsfile "$MACHINE_ROOT/$VM_HOSTNAME.vbox"
VBoxManage modifyvm "$VM_HOSTNAME" --accelerate3d on --vram 64

VBoxManage modifyvm "$VM_HOSTNAME" --nic1 natnetwork --nat-network1 "nat-int-network"
## this is temporary, to connect to the machine without knowing its hostname
VBoxManage modifyvm "$VM_HOSTNAME" --nic2 nat
VBoxManage modifyvm "$VM_HOSTNAME" --natpf2 "guestssh,tcp,,2222,,22"

VBoxManage sharedfolder add "$VM_HOSTNAME" --name share --hostpath "$MACHINE_ROOT/share" --automount

VBoxManage startvm "$VM_HOSTNAME"

pushd ansible
ansible-playbook bootstrap.yaml -i localhost:2222, --extra-vars "host_fqdn=$VM_HOSTNAME.local"
popd

## now the interface is back as host-only as the machine can be accessed
## using $VM_HOSTNAME.local
VBoxManage controlvm "$VM_HOSTNAME" natpf2 delete "guestssh"
VBoxManage controlvm "$VM_HOSTNAME" nic2 hostonly vboxnet0
