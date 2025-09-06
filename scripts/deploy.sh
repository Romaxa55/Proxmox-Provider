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
API_ENDPOINT=$(terraform output -raw k8s_api_endpoint 2>/dev/null || echo "https://172.16.100.246:6443")
BASE_IP_PREFIX=${API_ENDPOINT#https://}
BASE_IP_PREFIX=${BASE_IP_PREFIX%:*}
BASE_IP_PREFIX=${BASE_IP_PREFIX%.*}
echo "API Endpoint: ${API_ENDPOINT}"
echo "Control Plane Nodes: ${BASE_IP_PREFIX}.240-242"
echo "Worker Nodes: ${BASE_IP_PREFIX}.243-244"
echo "Ingress Nodes: ${BASE_IP_PREFIX}.247, ${BASE_IP_PREFIX}.248"
echo "External Machine: ${BASE_IP_PREFIX}.254 (manual setup required)"
echo ""
echo "🔑 To access the cluster:"
echo "ssh ubuntu@${BASE_IP_PREFIX}.240"
echo "kubectl get nodes"
echo ""
echo "🔧 To add external machine ${BASE_IP_PREFIX}.254:"
echo "./scripts/setup-external-machine.sh"
