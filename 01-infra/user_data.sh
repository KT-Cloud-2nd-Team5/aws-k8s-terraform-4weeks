#!/bin/bash

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
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token | jq -r .token)
  
if [ "$REG_TOKEN" == "null" ] || [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to get Org registration token. Check 'admin:org' permission."
    exit 1
fi


REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token | jq -r .token)

# Runner 설치 (버전 다운로드 로직 동일)
mkdir -p /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
curl -o actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v$${LATEST_VERSION}/actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner
sudo -u ubuntu ./config.sh \
  --url "https://github.com/$GITHUB_ORG" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --unattended \
  --labels "bastion,org-runner" \
  --replace

# 서비스 실행
./svc.sh install
./svc.sh start