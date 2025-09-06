# Third worker without HDD (insufficient HDDStorage space)
resource "proxmox_virtual_environment_vm" "k8s_worker_extra" {
  name      = "k8s-worker-3"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_worker_extra


  cpu {
    cores = 12
    type  = "host"
  }

  memory {
    dedicated = 32768
  }

  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }

  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }

  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 200
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "${local.worker_ips[2]}/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }

  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true

  ssh {
    username    = "romaxa55"
    agent       = false
    private_key = file("~/.ssh/id_rsa")
  }
}

# Hardware mapping for NVIDIA GPU (requires root on Proxmox)
resource "proxmox_virtual_environment_hardware_mapping_pci" "gpu0" {
  name = "gpu0"
  map = [{
    id    = var.gpu_vendor_device_id
    node  = var.proxmox_node
    path  = var.gpu_pci_device
    iommu_group = var.gpu_iommu_group
    subsystem_id = var.gpu_subsystem_id != "" ? var.gpu_subsystem_id : null
  }]
}

resource "proxmox_virtual_environment_file" "cloudinit_user_data" {
  node_name    = var.proxmox_node
  datastore_id = "local"
  content_type = "snippets"

  source_raw {
    file_name = "k8s-user-data.yaml"
    data = templatefile("${path.module}/cloud-init/user-data.yaml", {
      ssh_public_key = local.ssh_public_key
      k8s_version    = var.k8s_version
    })
  }
}

# Control Plane Nodes
resource "proxmox_virtual_environment_vm" "k8s_control_plane" {
  count     = 3
  name      = "k8s-control-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_control_base + count.index


  # VM Configuration
  cpu {
    cores = 4
    type  = "host"
  }
  
  memory {
    dedicated = 24576
  }
  
  # Boot from cloud-init template
  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }
  
  # Network
  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }
  
  # System disk (NVMe - fastest)
  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 100
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }
  
  # Cloud-init
  operating_system {
    type = "l26"
  }
  
  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id
    
    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }
    
    ip_config {
      ipv4 {
        address = "${local.network_base_ipv4}.${240 + count.index}/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}

# Worker Nodes
resource "proxmox_virtual_environment_vm" "k8s_worker" {
  count     = 2
  name      = "k8s-worker-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_worker_base + count.index


  # VM Configuration
  cpu {
    cores = 12
    type  = "host"
  }
  
  memory {
    dedicated = 32768
  }
  
  # Boot from cloud-init template
  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }
  
  # Network
  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }
  
  # System disk (NVMe - fastest)
  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 200
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # Workers now SSD-only (no additional HDD)
  
  # Cloud-init
  operating_system {
    type = "l26"
  }
  
  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id
    
    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }
    
    ip_config {
      ipv4 {
        address = "${local.worker_ips[count.index]}/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}


# Ingress Node (dedicated)
resource "proxmox_virtual_environment_vm" "k8s_ingress" {
  name      = "k8s-ingress-1"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_ingress_1


  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }

  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }

  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 100
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "${local.network_base_ipv4}.247/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }

  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}

# Ingress Node 2 (dedicated)
resource "proxmox_virtual_environment_vm" "k8s_ingress_2" {
  name      = "k8s-ingress-2"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_ingress_2


  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }

  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }

  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 100
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "${local.network_base_ipv4}.248/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }

  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}

# GPU Node (dedicated with HDD for Longhorn and NVIDIA PCI passthrough)
resource "proxmox_virtual_environment_vm" "k8s_gpu" {
  name      = "k8s-gpu-1"
  node_name = var.proxmox_node
  vm_id     = local.vm_id_gpu_node
  machine   = "q35"

  cpu {
    cores = 16
    type  = "host"
  }

  memory {
    dedicated = 65536
  }

  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }

  network_device {
    bridge   = local.network_bridge
    model    = local.network_model
    vlan_id  = local.network_vlan_tag
    firewall = local.network_firewall
  }

  # System disk on SSD
  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 200
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # Additional HDD for Longhorn storage
  disk {
    datastore_id = var.hdd_storage
    interface    = "scsi1"
    size         = 3700
    file_format  = "raw"
    ssd          = false
    discard      = "on"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id

    user_account {
      username = var.vm_user
      password = var.vm_password
      keys     = [local.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "${local.gpu_ip}/${local.network_ipv4_prefix}"
        gateway = local.network_gateway_ipv4
      }
    }
  }

  # NVIDIA GPU passthrough
  hostpci {
    device  = "hostpci0"
    mapping = proxmox_virtual_environment_hardware_mapping_pci.gpu0.name
    pcie    = true
    rombar  = false
    xvga    = false
  }

  agent {
    enabled = true
    type    = "virtio"
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys
    ]
  }
}

# Install qemu-guest-agent on first control-plane via SSH to avoid provider hangs
// removed SSH provisioner; GA installed via cloud-init snippet