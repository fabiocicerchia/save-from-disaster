variable "scw_accesskey" {}
variable "scw_secretkey" {}
variable "local_public_ip" {}

terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  access_key = var.scw_accesskey
  secret_key = var.scw_secretkey
  zone       = "fr-par-1"
  region     = "fr-par"
}

provider "scaleway" {
  alias      = "nl-ams"
  access_key = var.scw_accesskey
  secret_key = var.scw_secretkey
  zone       = "nl-ams-1"
  region     = "nl-ams"
}

resource "scaleway_account_ssh_key" "default" {
  name       = "My Key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "scaleway_instance_ip" "public_ip" {}

# Create a web server
resource "scaleway_instance_server" "web3" {
  image = "ubuntu_focal"
  name  = "web-3"
  type  = "STARDUST1-S"

  user_data = {
    cloud-init = file("./cloud-init")
  }

  ip_id = scaleway_instance_ip.public_ip.id

  depends_on = [
    scaleway_account_ssh_key.default,
  ]
}

# Create a web server
resource "scaleway_instance_server" "web4" {
  provider = "nl-ams"
  image = "ubuntu_focal"
  name  = "web-4"
  type  = "STARDUST1-S"

  user_data = {
    cloud-init = file("./cloud-init")
  }

  ip_id = scaleway_instance_ip.public_ip.id

  depends_on = [
    scaleway_account_ssh_key.default,
  ]
}

resource "scaleway_instance_security_group" "sg-paris" {
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action = "accept"
    port   = "22"
    ip     = var.local_public_ip
  }

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 3306
      ip     = inbound_rule.value
    }
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }

  # TCP port 2377 for cluster management communications
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 2377
      ip     = inbound_rule.value
    }
  }

  # TCP and UDP port 7946 for communication among nodes
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 7946
      ip     = inbound_rule.value
    }
  }

  # UDP port 4789 for overlay network traffic
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 4789
      ip     = inbound_rule.value
    }
  }
}

resource "scaleway_instance_security_group" "sg-amsterdam" {
  provider = "nl-ams"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action = "accept"
    port   = "22"
    ip     = var.local_public_ip
  }

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 3306
      ip     = inbound_rule.value
    }
  }

  inbound_rule {
    action = "accept"
    port   = "80"
  }

  inbound_rule {
    action = "accept"
    port   = "443"
  }

  # TCP port 2377 for cluster management communications
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 2377
      ip     = inbound_rule.value
    }
  }

  # TCP and UDP port 7946 for communication among nodes
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 7946
      ip     = inbound_rule.value
    }
  }

  # UDP port 4789 for overlay network traffic
  dynamic "inbound_rule" {
    for_each = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]

    content {
      action = "accept"
      port   = 4789
      ip     = inbound_rule.value
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/scaleway"
  content  = join("\n", formatlist("%s ansible_host=%s\n%s ansible_host=%s", scaleway_instance_server.web3.name, scaleway_instance_server.web3.public_ip, scaleway_instance_server.web4.name, scaleway_instance_server.web4.public_ip))
}
