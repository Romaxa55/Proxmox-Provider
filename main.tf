# Third worker without HDD (insufficient HDDStorage space)
resource "proxmox_virtual_environment_vm" "k8s_worker_extra" {
  name      = "k8s-worker-3"
  node_name = var.proxmox_node


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
    bridge = "vmbr0"
    model  = "virtio"
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
        address = "${local.worker_ips[2]}/16"
        gateway = "10.0.0.1"
      }
    }
  }

  agent {
    enabled = true
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


  # VM Configuration
  cpu {
    cores = 4
    type  = "host"
  }
  
  memory {
    dedicated = 8192
  }
  
  # Boot from cloud-init template
  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }
  
  # Network
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # System disk (NVMe - fastest)
  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 30
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
        address = "10.0.0.${240 + count.index}/16"
        gateway = "10.0.0.1"
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
  }
}

# Worker Nodes
resource "proxmox_virtual_environment_vm" "k8s_worker" {
  count     = 2
  name      = "k8s-worker-${count.index + 1}"
  node_name = var.proxmox_node


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
    bridge = "vmbr0"
    model  = "virtio"
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

  # Add 1.5TB HDD for video (Frigate/Longhorn)
  disk {
    datastore_id = var.hdd_storage
    interface    = "scsi1"
    size         = count.index == 0 ? 2000 : 1500
    file_format  = "raw"
    ssd          = false
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
        address = "${local.worker_ips[count.index]}/16"
        gateway = "10.0.0.1"
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
  }
}

# Backup Node
resource "proxmox_virtual_environment_vm" "k8s_backup" {
  name      = "k8s-backup"
  node_name = var.backup_proxmox_node


  # VM Configuration
  cpu {
    cores = 4
    type  = "host"
  }
  
  memory {
    dedicated = 16384
  }
  
  # Boot from cloud-init template
  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }
  
  # Network
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # System disk (NVMe - fastest)
  disk {
    datastore_id = var.nvme_storage
    interface    = "scsi0"
    size         = 30
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
        address = "10.0.0.245/16"
        gateway = "10.0.0.1"
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
  }
}

# Load Balancer for K8s API
resource "proxmox_virtual_environment_vm" "k8s_lb" {
  name      = "k8s-lb"
  node_name = var.proxmox_node


  # VM Configuration
  cpu {
    cores = 2
    type  = "host"
  }
  
  memory {
    dedicated = 4096
  }
  
  # Boot from cloud-init template
  clone {
    vm_id = var.ubuntu_template_id
    full  = true
  }
  
  # Network
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # System disk (NVMe - fastest)
  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 50
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
        address = "10.0.0.250/16"
        gateway = "10.0.0.1"
      }
    }
  }
  
  # Wait for cloud-init
  agent {
    enabled = true
  }
}

# Ingress Node (dedicated)
resource "proxmox_virtual_environment_vm" "k8s_ingress" {
  name      = "k8s-ingress-1"
  node_name = var.proxmox_node


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
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    datastore_id = var.ssd_storage
    interface    = "scsi0"
    size         = 50
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
        address = "10.0.0.247/16"
        gateway = "10.0.0.1"
      }
    }
  }

  agent {
    enabled = true
  }
}

# Install qemu-guest-agent on first control-plane via SSH to avoid provider hangs
// removed SSH provisioner; GA installed via cloud-init snippet