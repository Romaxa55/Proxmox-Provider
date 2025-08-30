# Local values for automation
locals {
  # Automatically read SSH public key if not provided
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
  
  # Control plane IPs
  control_plane_ips = [
    for i in range(3) : "10.0.0.${240 + i}"
  ]
  
  # Worker IPs  
  worker_ips = [
    "10.0.0.243",
    "10.0.0.244",
    "10.0.0.248",
  ]
}
