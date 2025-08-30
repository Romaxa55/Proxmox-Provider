# Kubernetes Cluster on Proxmox

Автоматическое развертывание высокодоступного Kubernetes кластера в Proxmox с помощью Terraform и Ansible.

## Архитектура

- **3x Control Plane** (4 CPU, 8GB RAM, 100GB SSD)
- **2x Worker Nodes** (12 CPU, 24GB RAM, 200GB SSD + 1TB HDD)
- **1x Load Balancer** (2 CPU, 4GB RAM, 50GB SSD)
- **1x Backup Node** (4 CPU, 16GB RAM, 100GB SSD)

## Требования

### Proxmox
- Proxmox VE 7.0+
- Ubuntu 22.04 cloud-init template
- Настроенные storage pools: SSD и HDD
- Сетевой мост vmbr0

### Локальная машина
- Terraform >= 1.0
- Ansible >= 2.9
- SSH ключи

## Быстрый старт

### 1. Подготовка template в Proxmox

```bash
# Скачать Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Создать VM template
qm create 9000 --name ubuntu-22.04-cloudinit --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-ssd
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-ssd:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-ssd:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

### 2. Настройка конфигурации

```bash
# Клонировать репозиторий
git clone <repo-url>
cd Proxmox-Provider

# Настроить переменные
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

### 3. Развертывание

```bash
# Автоматическое развертывание
./scripts/deploy.sh

# Или пошагово:
terraform init
terraform plan
terraform apply
cd ansible
ansible-playbook -i inventory.ini k8s-cluster.yml
```

## Конфигурация

### terraform.tfvars

```hcl
proxmox_api_url     = "https://your-proxmox-ip:8006/api2/json"
proxmox_user        = "root@pam"
proxmox_password    = "your-password"
proxmox_node        = "pve"
backup_proxmox_node = "pve-backup"
ubuntu_template     = "ubuntu-22.04-cloudinit"
ssd_storage        = "local-ssd"
hdd_storage        = "local-hdd"
ssh_public_key     = "ssh-rsa AAAAB3... your-key"
```

## Сетевая схема

```
192.168.100.5   - Load Balancer (HAProxy)
192.168.100.10  - Control Plane 1
192.168.100.11  - Control Plane 2  
192.168.100.12  - Control Plane 3
192.168.100.20  - Worker Node 1
192.168.100.21  - Worker Node 2
192.168.100.30  - Backup Node
```

## Компоненты

- **Container Runtime**: containerd
- **CNI**: Flannel (10.244.0.0/16)
- **Ingress**: NGINX Ingress Controller
- **Load Balancer**: HAProxy
- **Service CIDR**: 10.96.0.0/12

## Управление

### Подключение к кластеру

```bash
# SSH к первой control plane ноде
ssh ubuntu@192.168.100.10

# Проверить статус кластера
kubectl get nodes
kubectl get pods -A
```

### Мониторинг

```bash
# Статус нод
kubectl get nodes -o wide

# Статус подов
kubectl get pods -A

# Логи
kubectl logs -n kube-system <pod-name>
```

### Масштабирование

Для добавления worker нод:

1. Увеличить `count` в `k8s_worker` ресурсе
2. Выполнить `terraform apply`
3. Добавить новые ноды в `ansible/inventory.ini`
4. Запустить playbook для новых нод

## Резервное копирование

Backup нода настроена для:
- Резервного копирования etcd
- Мониторинга кластера
- Аварийного восстановления

## Устранение неполадок

### Проверка статуса

```bash
# Статус kubelet
systemctl status kubelet

# Логи kubeadm
journalctl -xeu kubelet

# Сетевые проблемы
kubectl get pods -n kube-flannel
```

### Переустановка ноды

```bash
# На проблемной ноде
kubeadm reset
systemctl restart kubelet

# На control plane
kubectl delete node <node-name>

# Повторно присоединить ноду
kubeadm token create --print-join-command
```

## Удаление кластера

```bash
./scripts/destroy.sh
```

## Безопасность

- Все ноды используют SSH ключи
- Firewall настроен автоматически
- Сетевые политики Kubernetes
- RBAC включен по умолчанию

