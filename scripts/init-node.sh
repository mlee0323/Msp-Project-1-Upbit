#!/bin/bash
# Ubuntu 24.04.3 LTS 노드 초기화 스크립트 (수정본)

set -e

echo ">>> 1. APT 잠금 대기 및 필수 패키지 설치"
sudo apt update
sudo apt install -y curl git apt-transport-https openssh-server chrony software-properties-common

# SSH 서비스 활성화
sudo systemctl enable --now ssh
sudo ufw allow ssh

echo ">>> 2. Tailscale 설치 (공식 스크립트 사용)"
curl -fsSL https://tailscale.com/install.sh | sh

echo ">>> 3. 커널 모듈 로드 및 네트워크 설정"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo ">>> 4. Docker(containerd) 설치"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

echo ">>> 5. K8s 패키지 설치"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo ">>> 6. 스왑 비활성화"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "--------------------------------------------------------"
echo "설치가 완료되었습니다."
echo "1) 'sudo tailscale up' 명령어로 로그인하세요."
echo "2) Tailscale IP가 할당되면, 마스터 노드에서 'kubeadm join'을 실행하세요."
echo "--------------------------------------------------------"
