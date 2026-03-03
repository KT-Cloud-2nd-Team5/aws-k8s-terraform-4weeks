#!/bin/bash

# debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Start user_data script..."
apt-get update -y
apt-get install -y jq squid curl tar libdigest-sha-perl

# proxy setting (all allow)
cat <<EOT > /etc/squid/squid.conf
# ACL 정의: 모든 IP 대역(0.0.0.0/0)을 'all'이라는 이름으로 정의
acl all src 0.0.0.0/0
http_port 3128
http_access allow all
EOT

systemctl stop squid
systemctl enable squid
systemctl start squid

echo "Squid installation completed."

# ------------------------------------------------------------------
# GitHub Actions Runner 설치
# ------------------------------------------------------------------

# 변수 설정 (Terraform에서 주입됨)
GITHUB_ORG="${github_org}"
GITHUB_PAT="${github_pat}"
RUNNER_VERSION="2.313.0" # 최신 버전을 확인하여 변경 권장
RUNNER_DIR="/home/ubuntu/actions-runner"
RUNNER_NAME="bastion-runner-$(hostname)"

REG_TOKEN=$(curl -s -X POST -H "Authorization: token $GITHUB_PAT" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/$GITHUB_ORG/actions/runners/registration-token | jq .token --raw-output)

if [ "$REG_TOKEN" == "null" ]; then
    echo "Error: Failed to get registration token. Check PAT permissions."
    exit 1
fi

mkdir -p $RUNNER_DIR
chown ubuntu:ubuntu $RUNNER_DIR
sudo -u ubuntu bash << EOF
cd $RUNNER_DIR
# Runner 다운로드
curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
# 압축 해제
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
# 의존성 설치 (루트 권한 필요하므로 sudo 사용)
EOF
$RUNNER_DIR/bin/installdependencies.sh
sudo -u ubuntu bash << EOF
cd $RUNNER_DIR
# Runner 설정 (--unattended 모드로 비대화형 설치)
./config.sh --url https://github.com/$GITHUB_ORG --token $REG_TOKEN --unattended --name "$RUNNER_NAME" --work _work --labels "bastion,ubuntu"
# 서비스 설치 및 시작 (sudo 필요)
sudo ./svc.sh install
sudo ./svc.sh start
EOF

echo "GitHub Action Runner installation completed."