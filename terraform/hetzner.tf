# Set the variable value in *.tfvars file
# or using -var="hcloud_token=..." CLI option
variable "hcloud_token" {}
variable "local_public_ip" {}
variable "mysql_nodes" { type = map(string) }
variable "docker_nodes" { type = map(string) }

# Configure the Hetzner Provider
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "My Key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Create a web server
resource "hcloud_server" "web1" {
  image       = "ubuntu-20.04"
  name        = "web-1"
  location    = "hel1"
  server_type = "cx11"
  user_data   = file("./cloud-init")

  ssh_keys = [hcloud_ssh_key.default.fingerprint]

  firewall_ids = [hcloud_firewall.ssh.id, hcloud_firewall.web.id, hcloud_firewall.mysql.id, hcloud_firewall.docker.id]

  depends_on = [
    digitalocean_ssh_key.default,
  ]
}
resource "hcloud_server" "web2" {
  image       = "ubuntu-20.04"
  name        = "web-2"
  location    = "nbg1"
  server_type = "cx11"
  user_data   = file("./cloud-init")

  ssh_keys = [hcloud_ssh_key.default.fingerprint]

  firewall_ids = [hcloud_firewall.ssh.id, hcloud_firewall.web.id, hcloud_firewall.mysql.id, hcloud_firewall.docker.id]

  depends_on = [
    digitalocean_ssh_key.default,
  ]
}

resource "hcloud_firewall" "ssh" {
  name = "firewall-ssh"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.local_public_ip]
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "mysql" {
  name = "firewall-mysql"

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "3306"
    source_ips = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }
}

resource "hcloud_firewall" "kubernetes" {
  name = "firewall-kubernetes"

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8443"
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "10520"
    source_ips = [
      var.local_public_ip,
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [
      var.local_public_ip,
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }
}

resource "hcloud_firewall" "web" {
  name = "firewall-web"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_firewall" "docker" {
  name = "firewall-docker"

  depends_on = [
    digitalocean_droplet.web0,
    hcloud_server.web1,
    hcloud_server.web2,
    scaleway_instance_server.web3,
    scaleway_instance_server.web4,
  ]

  # TCP port 2377 for cluster management communications
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "2377"
    source_ips = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  # TCP and UDP port 7946 for communication among nodes
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "7946"
    source_ips = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "7946"
    source_ips = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }

  # UDP port 4789 for overlay network traffic
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "4789"
    source_ips = [
      digitalocean_droplet.web0.ipv4_address,
      hcloud_server.web1.ipv4_address,
      hcloud_server.web2.ipv4_address,
      scaleway_instance_server.web3.public_ip,
      scaleway_instance_server.web4.public_ip,
    ]
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/hetzner"
  content  = join("\n", formatlist("%s ansible_host=%s\n%s ansible_host=%s", hcloud_server.web1.name, hcloud_server.web1.ipv4_address, hcloud_server.web2.name, hcloud_server.web2.ipv4_address))
}
