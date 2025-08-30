#!/bin/bash

# Script to setup external machine 10.0.0.254 for Kubernetes cluster

set -e

EXTERNAL_IP="10.0.0.254"
CONTROL_PLANE_IP="10.0.0.240"

echo "🔧 Setting up external machine $EXTERNAL_IP for Kubernetes cluster..."

# Check if we can reach the external machine
if ! ping -c 1 $EXTERNAL_IP > /dev/null 2>&1; then
    echo "❌ Cannot reach external machine at $EXTERNAL_IP"
    echo "Please ensure the machine is accessible and has SSH configured"
    exit 1
fi

# Install Docker and Kubernetes on external machine
echo "📦 Installing Docker and Kubernetes on external machine..."
ssh ubuntu@$EXTERNAL_IP << 'EOF'
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet=1.28.0-00 kubeadm=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
echo 'overlay' | sudo tee /etc/modules-load.d/k8s.conf
echo 'br_netfilter' | sudo tee -a /etc/modules-load.d/k8s.conf
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
echo 'net.bridge.bridge-nf-call-iptables  = 1' | sudo tee /etc/sysctl.d/k8s.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.d/k8s.conf
echo 'net.ipv4.ip_forward                 = 1' | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system

echo "✅ External machine setup completed!"
EOF

# Get join command from control plane
echo "🔗 Getting join command from control plane..."
JOIN_COMMAND=$(ssh ubuntu@$CONTROL_PLANE_IP 'sudo kubeadm token create --print-join-command')

if [ -z "$JOIN_COMMAND" ]; then
    echo "❌ Failed to get join command from control plane"
    echo "Make sure the Kubernetes cluster is initialized first"
    exit 1
fi

# Join external machine to cluster
echo "🚀 Joining external machine to cluster..."
ssh ubuntu@$EXTERNAL_IP "sudo $JOIN_COMMAND"

echo "✅ External machine successfully joined to Kubernetes cluster!"
echo ""
echo "📊 Verify the node:"
echo "ssh ubuntu@$CONTROL_PLANE_IP 'kubectl get nodes'"

