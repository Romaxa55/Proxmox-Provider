variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://10.0.0.253:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox username"
  type        = string
  default     = "terraform@pve!terraform"
}

variable "proxmox_password" {
  description = "Proxmox password (optional if using token)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  default     = ""
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_node" {
  description = "Main Proxmox node name"
  type        = string
  default     = "pve"
}

variable "backup_proxmox_node" {
  description = "Backup Proxmox node name"
  type        = string
  default     = "pve-backup"
}

variable "ubuntu_template" {
  description = "Debian cloud-init template name"
  type        = string
  default     = "debian-12-cloudinit"
}

variable "ubuntu_template_id" {
  description = "Debian cloud-init template VM ID"
  type        = number
  default     = 8000
}

variable "nvme_storage" {
  description = "NVMe storage pool name (fastest - for system)"
  type        = string
  default     = "local-zfs"
}

variable "ssd_storage" {
  description = "SSD storage pool name (medium speed - for other tasks)"
  type        = string
  default     = "SSDLVMStorage"
}

variable "hdd_storage" {
  description = "HDD storage pool name (slow - for video only)"
  type        = string
  default     = "HDDStorage"
}

variable "vm_user" {
  description = "Default VM user"
  type        = string
  default     = "romaxa55"
}

variable "vm_password" {
  description = "Default VM password"
  type        = string
  sensitive   = true
  default     = "romaxa55"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "k8s_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.33.4"
}

variable "pod_subnet" {
  description = "Pod network CIDR"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_subnet" {
  description = "Service network CIDR"
  type        = string
  default     = "10.96.0.0/12"
}

variable "gpu_pci_device" {
  description = "PCI device ID of NVIDIA GPU to passthrough (e.g., 0000:21:00.0)"
  type        = string
  default     = "0000:02:00.0"
}

variable "gpu_vendor_device_id" {
  description = "GPU vendor:device ID (e.g., 10de:2584) for hardware mapping"
  type        = string
  default     = "10de:2584"
}

variable "gpu_iommu_group" {
  description = "IOMMU group number for the GPU mapping"
  type        = number
  default     = 49
}

variable "gpu_subsystem_id" {
  description = "GPU subsystem vendor:device ID (e.g., 1462:174e). Use lspci -nns -vv 02:00.0 or /sys to obtain"
  type        = string
  default     = ""
}
