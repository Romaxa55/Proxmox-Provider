output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value = [
    for i in range(3) : 
    "${local.network_base_ipv4}.${240 + i}"
  ]
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value = [
    for i in range(3) : 
    "${local.network_base_ipv4}.${243 + i}"
  ]
}

output "external_machine_ip" {
  description = "External machine IP address"
  value       = "${local.network_base_ipv4}.254"
}

output "k8s_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${local.network_base_ipv4}.250:6443"
}

output "ssh_commands" {
  description = "SSH commands to connect to nodes"
  value = {
    control_plane = [
      for i in range(3) : 
      "ssh ${var.vm_user}@${local.network_base_ipv4}.${240 + i}"
    ]
    workers = [
      for i in range(3) : 
      "ssh ${var.vm_user}@${local.network_base_ipv4}.${243 + i}"
    ]
    ingress = [
      "ssh ${var.vm_user}@${local.network_base_ipv4}.247",
      "ssh ${var.vm_user}@${local.network_base_ipv4}.248"
    ]
    gpu = "ssh ${var.vm_user}@${local.gpu_ip}"
    external = "ssh ${var.vm_user}@${local.network_base_ipv4}.254"
  }
}