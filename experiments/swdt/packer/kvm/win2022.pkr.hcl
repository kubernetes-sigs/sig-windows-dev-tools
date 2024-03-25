packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "windows" {
  vm_name     = "win2k22"
  format      = "qcow2"
  accelerator = "kvm"

  iso_url      = "kvm/isos/windows.iso"
  iso_checksum = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"

  cpus   = 4
  memory = 4096

  efi_boot       = false
  disk_size      = "15G"
  disk_interface = "virtio"

  floppy_files = ["kvm/floppy/autounattend.xml", "kvm/floppy/openssh.ps1"]
  qemuargs     = [["-cdrom", "./kvm/isos/virtio-win.iso"]]

  output_directory = "output"

  communicator   = "ssh"
  ssh_username = "Administrator"
  ssh_password = "S3cr3t0!"
  ssh_timeout = "1h"

  boot_wait        = "10s"
  shutdown_command = "shutdown /s /t 30 /f"
  shutdown_timeout = "15m"
}

build {
  name    = "win2022"
  sources = ["source.qemu.windows"]
}

