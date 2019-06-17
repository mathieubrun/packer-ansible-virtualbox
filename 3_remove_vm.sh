#!/bin/bash

VM_HOSTNAME=$1

VBoxManage controlvm "$VM_HOSTNAME" poweroff
sleep 2
VBoxManage unregistervm "$VM_HOSTNAME" --delete