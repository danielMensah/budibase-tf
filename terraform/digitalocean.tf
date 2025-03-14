data "digitalocean_vpc" "default" {
  name   = "london-vpc"
}

resource "digitalocean_project" "budibase" {
  name        = ""
  description = ""
  environment = ""
  purpose     = "Just trying out DigitalOcean"
  resources = [digitalocean_droplet.budibase.urn]
}

resource "digitalocean_droplet" "budibase" {
  image      = "budibase-20-04"
  name       = ""

  region     = data.digitalocean_vpc.default.region
  graceful_shutdown = true

  monitoring = true
  size       = "s-2vcpu-4gb"

  vpc_uuid   = data.digitalocean_vpc.default.id

  backups    = "true"
  backup_policy {
    plan = "weekly"
    weekday = "MON"
    hour = 0
  }
}

resource "digitalocean_firewall" "budibase" {
  name = ""

  droplet_ids = [digitalocean_droplet.budibase.id]

  inbound_rule {
    port_range = "22"
    protocol   = "tcp"
    source_addresses = var.ssh_allowed_ips
  }

  inbound_rule {
    port_range = "443"
    protocol   = "tcp"
    source_addresses = local.https_allowed_ips
  }

  inbound_rule {
    port_range = "80"
    protocol   = "tcp"
    source_addresses = local.http_allowed_ips
  }

  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    port_range = "all"
    protocol   = "tcp"
  }

  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    port_range = "all"
    protocol   = "udp"
  }

  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    protocol = "icmp"
  }
}
