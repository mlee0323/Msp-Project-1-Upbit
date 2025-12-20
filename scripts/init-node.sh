#!/bin/bash
# 우분투 노트 초기화 스크립트

echo "시스템 업데이트 및 필수 패키지 설치"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git tailscale apt-transport-https open-ssh-server chrony

sudo systemctl enable --now chrony
sudo systemctl enable --now ssh
sudo ufw allow ssh

echo "도커 설치"
sudo apt instsall -y containered
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

echo "K8s 패키치 설치"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "커널 모듈 로드 및 네트워크 설정"
sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward

sudo sysctl --system

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Kubelet 네트워크 인터페이스 설정"
# kubelet이 Tailscale IP를 사용하도록 강제
echo 'KUBELET_EXTRA_ARGS="--node-ip='$(tailscale ip -4)'"' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo "--------------------------------------------------------"
echo "설치가 완료되었습니다."
echo "1) 'sudo tailscale up' 으로 로그인하세요."
echo "2) 마스터 노드에서 받은 'kubeadm join' 명령어를 실행하세요."
echo "--------------------------------------------------------"
