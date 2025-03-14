terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.49.1"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  # Define the IP ranges that are allowed to access the droplet via HTTP and HTTPS
  http_allowed_ips = ["0.0.0.0/0", "::/0"]
  https_allowed_ips = ["0.0.0.0/0", "::/0"]
}