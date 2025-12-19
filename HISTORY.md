# 프로젝트 진행 이력 (Project History)

## 2025-12-19

### 인프라 기초 및 마스터 노드 구축

- **OS 최적화**: 기존 실습용 Ubuntu 24.04.3 LTS 초기화 및 Hostname 변경 (`k8s-m` -> `master`)
- **네트워크**: Tailscale 설치 및 가상 메시 네트워크 구성
- **런타임**: `containerd` 설치 및 SystemdCgroup 설정 완료
- **K8s 마스터**: `kubeadm init` 성공 (Tailscale IP 기반 Control Plane 구성)
- **네트워크 플러그인**: Flannel CNI 적용 및 노드 `Ready` 상태 확인
- **보안**: GitHub Personal Access Token(PAT) 연동 및 첫 인프라 코드 커밋
