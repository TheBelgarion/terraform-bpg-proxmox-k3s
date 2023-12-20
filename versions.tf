terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # https://registry.terraform.io/providers/bpg/proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.41.0"
    }

    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.0"
    }
  }
}

locals {
  authorized_keyfile = "authorized_keys"
}
