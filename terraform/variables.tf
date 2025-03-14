variable "do_token" {
  sensitive = true
}

variable "ssh_allowed_ips" {
  type = list(string)
  sensitive = true
  # by default, allow all ipv4 and ipv6
  default = ["0.0.0.0/0", "::/0"]
}