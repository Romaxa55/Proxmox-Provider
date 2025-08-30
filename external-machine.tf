# External machine configuration for 10.0.0.254
# This machine is not managed by Terraform but can be added to the cluster

resource "null_resource" "external_machine_config" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "External machine 10.0.0.254 configuration:"
      echo "To add this machine to the cluster manually:"
      echo "1. SSH to 10.0.0.254"
      echo "2. Install Docker and Kubernetes (same as other nodes)"
      echo "3. Get join command from control plane:"
      echo "   ssh ubuntu@10.0.0.240 'sudo kubeadm token create --print-join-command'"
      echo "4. Run join command on 10.0.0.254"
    EOT
  }
}

# Add external machine to monitoring/backup scripts
locals {
  external_machine_ip = "10.0.0.254"
  all_cluster_ips = concat(
    [for i in range(3) : "10.0.0.${240 + i}"],  # Control planes
    [for i in range(2) : "10.0.0.${243 + i}"],  # Workers
    ["10.0.0.245"],                              # Backup
    ["10.0.0.246"],                              # Load balancer
    [local.external_machine_ip]                  # External machine
  )
}

