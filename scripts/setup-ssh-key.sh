#!/bin/bash

# Script to use existing id_rsa.pub key and update terraform.tfvars automatically

set -e

SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
TFVARS_FILE="terraform.tfvars"

echo "🔑 Using existing SSH key for Proxmox K8s cluster..."

# Check if id_rsa.pub exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH public key not found at $SSH_KEY_PATH"
    echo "Please generate SSH key first: ssh-keygen -t rsa -b 4096"
    exit 1
fi

echo "🔍 Found SSH public key at $SSH_KEY_PATH"

# Read public key
PUBLIC_KEY=$(cat "$SSH_KEY_PATH")
echo "📋 Public key: $PUBLIC_KEY"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "$TFVARS_FILE" ]; then
    echo "📄 Creating $TFVARS_FILE from example..."
    cp terraform.tfvars.example "$TFVARS_FILE"
fi

# Update SSH key in terraform.tfvars
echo "🔧 Updating SSH key in $TFVARS_FILE..."
if grep -q "ssh_public_key" "$TFVARS_FILE"; then
    # Replace existing SSH key
    sed -i.bak "s|ssh_public_key.*|ssh_public_key = \"$PUBLIC_KEY\"|" "$TFVARS_FILE"
else
    # Add SSH key if not present
    echo "" >> "$TFVARS_FILE"
    echo "# SSH Configuration" >> "$TFVARS_FILE"
    echo "ssh_public_key = \"$PUBLIC_KEY\"" >> "$TFVARS_FILE"
fi

echo "✅ SSH key configuration completed!"
echo ""
echo "📁 Public key: $SSH_KEY_PATH"
echo "📄 Updated: $TFVARS_FILE"
echo ""
echo "🔐 To use this key for SSH connections:"
echo "ssh ubuntu@<vm-ip>"
echo ""
echo "💡 SSH config already uses default ~/.ssh/id_rsa key"
