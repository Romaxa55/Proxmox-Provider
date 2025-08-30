output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value = [
    for i in range(3) : 
    "10.0.0.${240 + i}"
  ]
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value = [
    for i in range(3) : 
    "10.0.0.${243 + i}"
  ]
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = "10.0.0.250"
}

output "backup_node_ip" {
  description = "Backup node IP address"
  value       = "10.0.0.245"
}

output "external_machine_ip" {
  description = "External machine IP address"
  value       = "10.0.0.254"
}

output "k8s_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://10.0.0.250:6443"
}

output "ssh_commands" {
  description = "SSH commands to connect to nodes"
  value = {
    control_plane = [
      for i in range(3) : 
      "ssh ${var.vm_user}@10.0.0.${240 + i}"
    ]
    workers = [
      for i in range(3) : 
      "ssh ${var.vm_user}@10.0.0.${243 + i}"
    ]
    load_balancer = "ssh ${var.vm_user}@10.0.0.250"
    ingress = [
      "ssh ${var.vm_user}@10.0.0.247",
      "ssh ${var.vm_user}@10.0.0.254"
    ]
    backup = "ssh ${var.vm_user}@10.0.0.245"
    external = "ssh ${var.vm_user}@10.0.0.254"
  }
}