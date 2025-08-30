#!/bin/bash

set -e

echo "🗑️  Destroying Kubernetes cluster..."

# Confirm destruction
read -p "Are you sure you want to destroy the cluster? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled."
    exit 0
fi

# Destroy Terraform resources
echo "💥 Destroying Terraform resources..."
terraform destroy -auto-approve

echo "✅ Cluster destroyed successfully!"

