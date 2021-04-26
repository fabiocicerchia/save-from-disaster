# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "local_public_ip" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "My Key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a web server
resource "digitalocean_droplet" "web0" {
  image      = "ubuntu-20-04-x64"
  name       = "web-1"
  region     = "fra1"
  size       = "s-1vcpu-1gb"
  monitoring = "true"
  ssh_keys   = [digitalocean_ssh_key.default.fingerprint]
  user_data  = file("./cloud-init")

  depends_on = [
    digitalocean_ssh_key.default,
  ]
}

resource "digitalocean_firewall" "ssh" {
  name = "firewall-ssh"

  droplet_ids = [digitalocean_droplet.web0.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.local_public_ip]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "mysql" {
  name = "firewall-mysql"

  droplet_ids = [digitalocean_droplet.web0.id]

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "3306"
    source_addresses = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]
}

resource "digitalocean_firewall" "web" {
  name = "firewall-web"

  droplet_ids = [digitalocean_droplet.web0.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "docker" {
  name = "firewall-docker"

  droplet_ids = [digitalocean_droplet.web0.id]

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  # TCP port 2377 for cluster management communications
  inbound_rule {
    protocol         = "tcp"
    port_range       = "2377"
    source_addresses = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  # TCP and UDP port 7946 for communication among nodes
  inbound_rule {
    protocol         = "tcp"
    port_range       = "7946"
    source_addresses = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "7946"
    source_addresses = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  # UDP port 4789 for overlay network traffic
  inbound_rule {
    protocol         = "udp"
    port_range       = "4789"
    source_addresses = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/digitalocean"
  content  = join("\n", formatlist("%s ansible_host=%s", digitalocean_droplet.web0.name, digitalocean_droplet.web0.ipv4_address))
}
