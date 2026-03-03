#!/bin/bash

# ... (Squid Proxy 설치 등 앞부분은 동일) ...
apt update -y && apt install -y jq curl git libicu-dev build-essential

# 변수 설정 (Terraform에서 주입됨)
GITHUB_ORG="${github_org}"
GITHUB_PAT="${github_pat}"
RUNNER_NAME="bastion-org-runner-$(hostname)"

# -----------------------------------------------------------------------------
# [핵심 변경 1] API 엔드포인트가 /repos -> /orgs 로 변경됨
# -----------------------------------------------------------------------------
REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token | jq -r .token)

if [ "$REG_TOKEN" == "null" ] || [ -z "$REG_TOKEN" ]; then
    echo "Error: Failed to get Org registration token. Check 'admin:org' permission."
    exit 1
fi

# Runner 설치 (버전 다운로드 로직 동일)
mkdir -p /home/ubuntu/actions-runner && cd /home/ubuntu/actions-runner
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
curl -o actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v$${LATEST_VERSION}/actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

# -----------------------------------------------------------------------------
# [핵심 변경 2] 설정 URL도 리포지토리 경로가 아닌 조직 경로로 지정
# -----------------------------------------------------------------------------
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