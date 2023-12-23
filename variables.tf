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
    tags            = optional(string, "k3s-cluster")
    clone = map(object({
      datastore_id = optional(string)
      node_name    = optional(string)
      vm_id        = number
      full         = optional(bool, true)
    }))
    cpu = map(object({
      cores = optional(number, 1)
      units = optional(number, 100)
    }))
    startup = map(object({
      order      = optional(string, "1")
      up_delay   = optional(string, "60")
      down_delay = optional(string, "60")
    }))
    disk = map(object({
      datastore_id = string
      interface    = string
      file_format  = optional(string, "qcow2")
      size         = optional(number, 8)
    }))
    memory = map(object({
      dedicated = optional(number, 512)
    }))
    initialization = map(object({
      ip_config = map(object({
        ipv4 = map(object({
          address = string
          gateway = optiona(string)
        }))
      }))
      user_account = map(object({
        keys     = string
        password = string
        username = string
      }))
      user_data_file_id = string
    }))
    network_device = map(object({
      bridge      = string
      enabled     = optional(bool, true)
      firewall    = optional(bool, false)
      vlan_id     = optional(string)
      mac_address = optional(string)
    }))
    operating_system = map(object({
      type = string
    }))
    tpm_state = map(object({
      version = optional(string)
    }))
    parameters = map(string({
    }))
  }))

  validation {
    condition = all(
      flatten([for _, vm in var.cluster_vm : can(100, 9999, vm.vm_id)])
    )
    error_message = "All vm_id values must be in the range of 100 to 9999."
  }
  validation {
    condition = all(
      flatten([for _, vm in var.cluster_vm : can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/[0-9]{1,2}$", var.ipv4.adress))])
    )
    error_message = "The control_plane_subnet value must be a valid cidr range."
  }
}
