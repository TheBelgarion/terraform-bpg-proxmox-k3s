
resource "macaddress" "k3s-support" {}

locals {
  k3s-support = merge(var.cluster_vm["support"], {
    network_device = merge(
      var.cluster_vm["support"].network_device,
      { mac_address = upper(macaddress.k3s-support.address) }
    )
  })
  support_node_ip = cidrhost(var.cluster_vm["support"].initialization.ip_config.ipv4.address, 0)
}


resource "proxmox_virtual_environment_vm" "k3s_cluster_support_vm" {

  lifecycle {
    ignore_changes = [
    ]
  }

  connection {
    type        = "ssh"
    user        = local.k3s-support.initialization.user_account.username
    host        = local.support_node_ip
    private_key = file("${var.ssh_key_files["PRIV"]}")
  }

  //@todo  name        = join("-", [var.cluster_name, "support"])
  name        = "support"
  description = local.k3s-support.description

  node_name = local.k3s-support.node
  vm_id     = local.k3s-support.vm_id
  pool_id   = local.k3s-support.pool_id

  tags = local.k3s-support.tags
  clone {
    datastore_id = local.k3s-support.clone.datastore_id
    node_name    = local.k3s-support.clone.node_name
    vm_id        = local.k3s-support.clone.vm_id
    full         = local.k3s-support.clone.full
  }
  startup {
    order      = local.k3s-support.startup.order
    up_delay   = local.k3s-support.startup.up_delay
    down_delay = local.k3s-support.startup.down_delay
  }

  cpu {
    cores   = local.k3s-support.cpu.cores
    sockets = local.k3s-support.cpu.sockets
    units   = local.k3s-support.cpu.units
  }
  memory {
    dedicated = local.k3s-support.memory.dedicated
  }
  disk {
    datastore_id = local.k3s-support.disk.datastore_id
    interface    = local.k3s-support.disk.interface
    file_format  = local.k3s-support.disk.file_format
    size         = local.k3s-support.disk.size
  }
  network_device {
    bridge      = local.k3s-support.network_device.bridge
    enabled     = local.k3s-support.network_device.enabled
    firewall    = local.k3s-support.network_device.firewall
    vlan_id     = local.k3s-support.network_device.vlan_id
    mac_address = local.k3s-support.network_device.mac_address
  }
  initialization {
    ip_config {
      ipv4 {
        address = local.k3s-support.initialization.ip_config.ipv4.address
        gateway = local.k3s-support.initialization.ip_config.ipv4.gateway
      }
    }
    user_account {
      keys     = local.k3s-support.initialization.user_account.keys
      password = local.k3s-support.initialization.user_account.password
      username = local.k3s-support.initialization.user_account.username
    }
    user_data_file_id = local.k3s-support.initialization.user_data_file_id
  }
  agent {
    enabled = local.k3s-support.agent_enabled
  }

  /* @todo
  scsihw = var.scsihw
  os_type = "cloud-init"
  nameserver = var.nameserver
 */

  provisioner "file" {
    destination = "/tmp/install.sh"
    content = templatefile("${path.module}/scripts/install-support-apps.sh.tftpl", {
      root_password = random_password.support-db-password.result

      k3s_database = local.k3s-support["parameter"].db_name
      k3s_user     = local.k3s-support["parameter"].db_user
      k3s_password = random_password.k3s-master-db-password.result

      // @todo ????
      http_proxy = "hhtps"

    })
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/install.sh",
      "/tmp/install.sh",
      "rm -r /tmp/install.sh",
    ]
  }


}

resource "random_password" "support-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "random_password" "k3s-master-db-password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

resource "null_resource" "k3s_nginx_config" {

  depends_on = [
    proxmox_virtual_environment_vm.k3s_cluster_support_vm
  ]

  triggers = {
    config_change = filemd5("${path.module}/config/nginx.conf.tftpl")
  }

  connection {
    type        = "ssh"
    user        = local.k3s-support.initialization.user_account.username
    host        = local.support_node_ip
    private_key = file("${var.ssh_key_files["PRIV"]}")
  }

  /*  @todo
  provisioner "file" {
    destination = "/tmp/nginx.conf"
    content = templatefile("${path.module}/config/nginx.conf.tftpl", {
      k3s_server_hosts = [for ip in local.master_node_ips :
        "${ip}:6443"
      ]
      k3s_nodes = concat(local.master_node_ips, [
        for node in local.listed_worker_nodes :
        node.ip
      ])
    })
  }
 */
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo systemctl restart nginx.service",
    ]
  }
}
