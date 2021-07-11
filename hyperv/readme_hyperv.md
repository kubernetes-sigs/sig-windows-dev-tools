## Prerequisites
Start PowerShell as admin. Vagrant needs a couple of plugins that can be installed via `vagrant plugin install vagrant-reload winrm winrm-elevated`. 
To provide synced directories Hyper-V uses SMB which needs your username and password. To prevent entering it over and over you can enter `$env:SMB_USERNAME="your_username"` and `$env:SMB_PASSWORD="your_password"` before starting the provisioning.

## Starting it
`vagrant up` starts the actual provisioning.

# Useful for Hyper-V
`get-vm` lists all existing VMs
`stop-vm [name]` stops a VM (`*` for all)
`remove-vm [name]` deletes a VM (`*` for all). Only works with stopped VMs!
