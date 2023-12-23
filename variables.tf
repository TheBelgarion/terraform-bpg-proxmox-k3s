// key is the name of the vm
variable "cluster_vm" {
  type = map(object({
    count   = optional(number, 1)
    vm_id   = number
    node    = string
    pool_id = optional(string)
    reboot  = optional(bool, false)
    on_boot = optional(bool, true)
    //qemu agent
    agent_enabled   = optional(bool, false)
    keyboard_layout = optional(string, "en-us")
    description     = optional(string)
    tags            = optional(list(string), ["k3s-cluster"])
    clone = object({
      datastore_id = optional(string)
      node_name    = optional(string)
      vm_id        = number
      full         = optional(bool, true)
    })
    cpu = object({
      cores   = optional(number, 1)
      sockets = optional(number)
      units   = optional(number, 100)
    })
    startup = object({
      order      = optional(string, "1")
      up_delay   = optional(string, "60")
      down_delay = optional(string, "60")
    })
    disk = object({
      datastore_id = string
      interface    = string
      file_format  = optional(string, "qcow2")
      size         = optional(number, 8)
    })
    memory = object({
      dedicated = optional(number, 512)
    })
    initialization = object({
      ip_config = object({
        ipv4 = object({
          address = string
          gateway = optional(string)
        })
      })
      user_account = object({
        keys     = list(string)
        password = string
        username = string
      })
      user_data_file_id = string
    })
    network_device = object({
      bridge      = string
      enabled     = optional(bool, true)
      firewall    = optional(bool, false)
      vlan_id     = optional(string)
      mac_address = optional(string)
    })
    operating_system = object({
      type = optional(string, "126") // default: Linux Kernel 2.6 - 5.X.
    })
    tpm_state = optional(object({
      version = optional(string)
    }))
    parameters = map(string)
  }))

  validation {
    condition = alltrue(
      flatten([for _, vm in var.cluster_vm : 100 <= vm.vm_id && vm.vm_id <= 9999])
    )
    error_message = "All vm_id values must be in the range of 100 to 9999."
  }
  validation {
    condition = alltrue(
      flatten([for _, vm in var.cluster_vm : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", vm.initialization.ip_config.ipv4.address))])
    )
    error_message = "The control_plane_subnet value must be a valid cidr range."
  }
}

variable "ssh_key_files" {
  description = "full filename of key files"
  type = object({
    PUBL = string,
    PRIV = string
  })
}
