#!/bin/bash

pushd packer/arch
packer build -var "vm_name=temppacker" -var "keymap=fr_CH" -var "ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" arch_template_bios_mbr.json
popd