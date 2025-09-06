# Local values for automation
locals {
  # Automatically read SSH public key if not provided
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : file("~/.ssh/id_rsa.pub")
  
  # Common network settings
  network_bridge   = "vmbr0"
  network_model    = "virtio"
  network_vlan_tag = 100
  network_firewall = false
  
  # L3 defaults
  # Base network
  network_base_ipv4    = "172.16.100"
  network_gateway_ipv4 = "172.16.100.1"
  network_ipv4_prefix  = 24
  
  # Static VM IDs (start from 500)
  vm_id_base             = 500
  vm_id_control_base     = 500                 # 500..502 (3 control planes)
  vm_id_worker_base      = 503                 # 503..504 (2 workers)
  vm_id_worker_extra     = 505                 # 505 (worker-3)
  vm_id_ingress_1        = 506                 # 506 (ingress-1)
  vm_id_ingress_2        = 507                 # 507 (ingress-2)
  vm_id_gpu_node         = 508                 # 508 (gpu node)
  
  # Control plane IPs
  control_plane_ips = [
    for i in range(3) : "${local.network_base_ipv4}.${240 + i}"
  ]
  
  # Worker IPs  
  worker_ips = [
    for i in range(3) : "${local.network_base_ipv4}.${230 + i}"
  ]

  # GPU node IP
  gpu_ip = "${local.network_base_ipv4}.249"
}
