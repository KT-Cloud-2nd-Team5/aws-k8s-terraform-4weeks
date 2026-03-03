#!/bin/bash

# 1. 로그 설정 (디버깅을 위해 로그를 파일로 남깁니다)
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Start user_data script..."

# 2. 기본 패키지 업데이트 및 필요 도구 설치
# jq: Github API 응답 파싱용
# squid: 프록시 서버
apt-get update -y
apt-get install -y jq squid curl tar libdigest-sha-perl

# ------------------------------------------------------------------
# 3. Squid 설정 (기본 설정)
# ------------------------------------------------------------------
# 기본적으로 Squid는 localhost만 허용하므로, VPC 내부에서 접근하려면
# 허용 범위를 추가해야 할 수 있습니다. 일단 서비스 활성화만 진행합니다.
systemctl enable squid
systemctl start squid

echo "Squid installation completed."

# ------------------------------------------------------------------
# 4. GitHub Actions Runner 설치
# ------------------------------------------------------------------

# 변수 설정 (Terraform에서 주입됨)
GITHUB_ORG="${github_org}"
GITHUB_PAT="${github_pat}"
RUNNER_VERSION="2.313.0" # 최신 버전을 확인하여 변경 권장
RUNNER_DIR="/home/ubuntu/actions-runner"
RUNNER_NAME="bastion-runner-$(hostname)"

# GitHub API를 통해 Runner 등록 토큰(Registration Token) 발급
# 주의: PAT는 'admin:org' (조직 러너) 권한이 있어야 토큰 발급이 가능합니다.
REG_TOKEN=$(curl -s -X POST -H "Authorization: token ${GITHUB_PAT}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token | jq .token --raw-output)

if [ "$REG_TOKEN" == "null" ]; then
    echo "Error: Failed to get registration token. Check PAT permissions."
    exit 1
fi

# ubuntu 사용자로 Runner 디렉토리 생성
mkdir -p $RUNNER_DIR
chown ubuntu:ubuntu $RUNNER_DIR

# ubuntu 사용자 권한으로 Runner 다운로드 및 설치 진행
sudo -u ubuntu bash << EOF
cd $RUNNER_DIR

# Runner 다운로드
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# 압축 해제
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# 의존성 설치 (루트 권한 필요하므로 sudo 사용)
EOF

# 의존성 설치 스크립트 실행 (루트 권한으로 실행)
$RUNNER_DIR/bin/installdependencies.sh

# ubuntu 사용자 권한으로 Runner 설정 및 서비스 등록
sudo -u ubuntu bash << EOF
cd $RUNNER_DIR

# Runner 설정 (--unattended 모드로 비대화형 설치)
./config.sh --url https://github.com/${GITHUB_ORG} --token $REG_TOKEN --unattended --name "$RUNNER_NAME" --work _work --labels "bastion,ubuntu"

# 서비스 설치 및 시작 (sudo 필요)
sudo ./svc.sh install
sudo ./svc.sh start
EOF

echo "GitHub Action Runner installation completed."