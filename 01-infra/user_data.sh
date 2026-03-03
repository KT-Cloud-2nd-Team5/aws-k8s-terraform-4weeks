#!/bin/bash
set -ex

# Squid Proxy 설치
apt update -y
apt install squid jq -y              
sed -i 's/http_access deny all/http_access allow all/g' /etc/squid/squid.conf
systemctl restart squid

# 변수 설정 (Terraform에서 주입됨)
GITHUB_ORG="${github_org}"
GITHUB_PAT="${github_pat}"
RUNNER_NAME="bastion-org-runner-$(hostname)"

# GITHUB API를 통해 조직 레벨 등록 토큰 가져오기
REG_TOKEN=$(curl -s -X POST -H "Authorization: token ${github_pat}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${github_org}/actions/runners/registration-token | jq -r .token)

if [ "$REG_TOKEN" == "null" ] || [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to get Org registration token."
    exit 1
fi

# Runner 설치 (한 줄로 정리 및 의존성 추가)
mkdir -p /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')

# 다운로드 주소 한 줄로 처리
curl -o actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz -L "https://github.com/actions/runner/releases/download/v$${LATEST_VERSION}/actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz"

tar xzf ./actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz

# 필수 의존성 설치 추가 (이게 없으면 config.sh가 실패할 수 있음)
./bin/installdependencies.sh

chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

# 6. Runner 설정 (ubuntu 유저로 실행)
sudo -u ubuntu ./config.sh \
  --url "https://github.com/$GITHUB_ORG" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --unattended \
  --labels "bastion,org-runner" \
  --replace

# 7. 서비스 등록 및 시작 (sudo 권한 필요)
./svc.sh install ubuntu
./svc.sh start