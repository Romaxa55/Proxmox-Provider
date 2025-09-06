# External machine configuration for ${local.network_base_ipv4}.254
# This machine is not managed by Terraform but can be added to the cluster

resource "null_resource" "external_machine_config" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "External machine ${local.network_base_ipv4}.254 configuration:"
      echo "To add this machine to the cluster manually:"
      echo "1. SSH to ${local.network_base_ipv4}.254"
      echo "2. Install Docker and Kubernetes (same as other nodes)"
      echo "3. Get join command from control plane:"
      echo "   ssh ubuntu@${local.network_base_ipv4}.240 'sudo kubeadm token create --print-join-command'"
      echo "4. Run join command on ${local.network_base_ipv4}.254"
    EOT
  }
}

# Add external machine to monitoring/backup scripts
locals {
  external_machine_ip = "${local.network_base_ipv4}.254"
  all_cluster_ips = concat(
    [for i in range(3) : "${local.network_base_ipv4}.${240 + i}"],  # Control planes
    [for i in range(2) : "${local.network_base_ipv4}.${243 + i}"],  # Workers
    ["${local.network_base_ipv4}.247"],                              # Ingress-1
    ["${local.network_base_ipv4}.248"],                              # Ingress-2
    [local.external_machine_ip]                  # External machine
  )
}

