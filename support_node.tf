
resource "macaddress" "k3s-support" {}

locals {
  k3s-support     = merge(var.cluster.vm["support"], { network_device = { macaddr = upper(macaddress.k3s-support.address) } })
  support_node_ip = cidrhost(var.cluster.vm["support"].initialization.ip_config.ipv4.address, 0)
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
    private_key = file("${var.ssh_key_files.PRIV}")
  }

  //@todo  name        = join("-", [var.cluster_name, "support"])
  name        = "support"
  description = local.k3s-support.description

  node_name = local.k3s-support.node
  vm_id     = local.k3s-support.vm_id
  pool_id   = local.k3s-support.pool_id

  clone          = local.k3s-support.clone
  tags           = local.k3s-support.tags
  startup        = local.k3s-support.startup
  cpu            = local.k3s-support.cpu
  memory         = local.k3s-support.memory
  disk           = local.k3s-support.disk
  initialization = local.k3s-support.initialization
  network_device = local.k3s-support.network_device

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

      k3s_database = local.k3s-support.parameter.db_name
      k3s_user     = local.k3s-support.parameter.db_user
      k3s_password = random_password.k3s-master-db-password.result

      //@todo      http_proxy = var.http_proxy
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
    private_key = file("${var.ssh_key_files.PRIV}")
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
