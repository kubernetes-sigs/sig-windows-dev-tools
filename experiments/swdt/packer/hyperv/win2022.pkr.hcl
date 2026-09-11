packer {
  required_plugins {
    hyperv = {
      version = "~> 1"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "switch_name" {
  type        = string
  default     = ""
  description = "Hyper-V virtual switch to attach to. Empty lets Packer auto-detect an external switch."
}

source "hyperv-iso" "windows" {
  vm_name = "win2k22"

  # Generation 1 is required: the existing unattended installation uses
  # floppy_files, and Hyper-V Generation 2 does not support floppy drives.
  generation = 1

  iso_url      = "kvm/isos/windows.iso"
  iso_checksum = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"

  cpus      = 4
  memory    = 4096
  disk_size = 15360

  switch_name = var.switch_name

  floppy_files = ["kvm/floppy/autounattend.xml", "kvm/floppy/openssh.ps1"]

  output_directory = "output/hyperv"

  communicator = "ssh"
  ssh_username = "Administrator"
  ssh_password = "S3cr3t0!"
  ssh_timeout  = "1h"

  boot_wait        = "10s"
  shutdown_command = "shutdown /s /t 30 /f"
  shutdown_timeout = "15m"
}

build {
  name    = "win2022"
  sources = ["source.hyperv-iso.windows"]
}
