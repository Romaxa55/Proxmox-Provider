#!/bin/bash

set -e

echo "🚀 Deploying Kubernetes cluster on Proxmox..."

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Copy terraform.tfvars.example and configure it."
    exit 1
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan

# Apply configuration
echo "🔨 Applying Terraform configuration..."
terraform apply -auto-approve

# Wait for VMs to be ready
echo "⏳ Waiting for VMs to boot up..."
sleep 60

# Run Ansible playbook
echo "🎭 Running Ansible playbook..."
cd ansible
ansible-playbook -i inventory.ini k8s-cluster.yml

echo "✅ Kubernetes cluster deployed successfully!"
echo ""
echo "📊 Cluster Information:"
echo "API Endpoint: https://10.0.0.246:6443"
echo "Control Plane Nodes: 10.0.0.240-242"
echo "Worker Nodes: 10.0.0.243-244"
echo "Backup Node: 10.0.0.245"
echo "Load Balancer: 10.0.0.246"
echo "External Machine: 10.0.0.254 (manual setup required)"
echo ""
echo "🔑 To access the cluster:"
echo "ssh ubuntu@10.0.0.240"
echo "kubectl get nodes"
echo ""
echo "🔧 To add external machine 10.0.0.254:"
echo "./scripts/setup-external-machine.sh"
