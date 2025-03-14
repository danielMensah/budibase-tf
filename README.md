# Budibase Terraform
This project provides an automated deployment setup for Budibase using Terraform and Nginx. 
It simplifies infrastructure provisioning on DigitalOcean and ensures secure, scalable deployment using Cloudflare’s 
Origin SSL/TLS certificates.

This template is ideal for anyone looking to deploy Budibase on DigitalOcean with Cloudflare and Nginx for secure, production-ready hosting.

## Setup
### Prerequisites:
- Terraform is installed.
- Have a Digital Ocean account.
- Add Digital Ocean API key to the var.tfvars file.
- Ensure you are happy with the `ssh_allowed_ips` variable, and `http_allowed_ips` and `https_allowed_ips` locals.
  In this example, we are whitelisting cloudflare's IP ranges for the allowed IPs and have SSL/TLS certificates in the
  reverse proxy for extra protection. If you provide your own `ssh_allowed_ips`, ensure it is a static IP address.

To setup the project, follow the steps below:
- Run `terraform init` to initialize the project.
- Run `terraform apply -var-file=var.tfvars` to create the infrastructure.
- Once deployed, add the created droplet's IP to your DNS records (If using Cloudflare, ensure to enable Proxy on the DNS record). 
- You'll receive an email with the password to ssh into the server, take not of that and follow in instructions below.

### Setup Reverse Proxy
We need to setup a reverse proxy to route traffic to the Budibase application because Budibase is running on port `10000`
and we cannot set the port in the DNS record value. To do this, we will use Nginx as a reverse proxy.

This script automates the installation and configuration of Nginx with SSL support using an origin certificate and key. 
All configuration is loaded exclusively from a YAML file.

#### Overview
The `setup_nginx.sh` script performs the following tasks:
- Reads configuration from a YAML file (default: `config.yaml`, or via the `-c` option).
- Creates the necessary SSL directories and writes the origin certificate and key to:
    - `/etc/ssl/certs/origin_cert.pem`
    - `/etc/ssl/private/origin_key.pem`
- Installs Nginx and creates a configuration file for your specified site.
- Sets up Nginx to:
    - Redirect HTTP (port 80) traffic to HTTPS.
    - Serve HTTPS (port 443) with SSL.
    - Proxy requests to a local server running on `http://127.0.0.1:10000`.
- Updates the firewall rules (using `ufw`) to allow HTTP and HTTPS traffic.

#### Installation
- In your local machine, copy the `config.yaml.example` file to `config.yaml` and update the values as needed.
  If using Cloudflare, you can get/create the origin certificate and key from the SSL/TLS tab in the Cloudflare dashboard.
- Make any change to the nginx configuration in the `setup_nginx.sh` file if needed.
- SSH into the server using the IP address and password provided in the email using the command:
  ```shell
  ssh root@<ip_address>
  ```
- Create both the `config.yaml` and `setup_nginx.sh` files in the server.
- Make the bash script executable by running:
  ```shell
  chmod +x setup_nginx.sh
  ```
- Run the script:
  ```shell
    ./setup_nginx.sh
  ```
- The script will install Nginx and configure it to serve the Budibase application.
- Once the script is done, you can access the Budibase application by visiting the domain name you set in the `config.yaml` file.