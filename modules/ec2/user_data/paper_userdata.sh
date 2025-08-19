#!/bin/bash

# 로그 설정
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Velocity Proxy EC2 User Data Script Started at $(date) ==="

# 시스템 업데이트
apt-get update
apt-get upgrade -y
echo "System updated successfully."

# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
echo "Docker installed successfully."
sudo usermod -aG docker ubuntu
echo "User 'ubuntu' added to 'docker' group."

# Docker Compose 설치
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Docker 서비스 시작
systemctl start docker
systemctl enable docker

# SSM Agent 설치 및 시작
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# CloudWatch Agent 설치
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
echo "CloudWatch Agent installed."

# CloudWatch Agent 설정 및 시작
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c ssm:/mcserver/cloudwatch-agent/config

echo "CloudWatch Agent configured and started."

# EBS 볼륨 마운트 설정 
echo "=== EBS Volume Setup ==="
MOUNT_POINT="/mcserver"
DEVICE_PATH=""

# EBS 볼륨 마운트 Race Condition 방지용
MAX_RETRIES=60
RETRY_COUNT=0

# 부팅 시점의 블록 디바이스 상태를 로그로 기록
echo "Initial block device state:"
lsblk

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # 루트 파티션('/')이 있는 디바이스를 찾아서 제외
  ROOT_DEVICE=$(lsblk -no pkname $(findmnt -n -o SOURCE /))
  
  # /dev/sd* 또는 /dev/xvd* 또는 /dev/nvme* 형태의 모든 블록 디바이스를 순회
  for device in $(ls /dev/{sd,xvd,nvme}*n* 2>/dev/null | grep -vE 'p[0-9]+$'); do
    # 디바이스가 루트 디바이스인지 확인
    if [[ "$device" == "/dev/$ROOT_DEVICE" ]]; then
      echo "Skipping root device: $device"
      continue
    fi

    # 파티션이 없는 순수 디스크인지 확인
    if [ -b "$device" ] && ! lsblk -n "$device" | grep -q "part"; then
      DEVICE_PATH="$device"
      echo "Found attached EBS volume: $DEVICE_PATH"
      break 2
    fi
  done

  if [ -n "$DEVICE_PATH" ]; then
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Waiting for EBS volume to attach... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 5
done

# 최종 블록 디바이스 상태를 로그로 기록
echo "Final block device state:"
lsblk

# 디바이스를 여전히 찾지 못한 경우 에러
if [ -z "$DEVICE_PATH" ]; then
  echo "ERROR: EBS volume device not found after $MAX_RETRIES attempts."
  exit 1
fi

# 파일시스템 확인 및 생성 (ext4)
# blkid가 0이 아닌 종료 코드를 반환하면 파일시스템이 없는 것
if ! blkid -o value -s TYPE ${DEVICE_PATH}; then
  echo "Creating ext4 filesystem on ${DEVICE_PATH}"
  mkfs.ext4 ${DEVICE_PATH}
fi

# 마운트 포인트 생성
mkdir -p ${MOUNT_POINT}
echo "Mount point ${MOUNT_POINT} created."

# 마운트
mount ${DEVICE_PATH} ${MOUNT_POINT}
chown -R ubuntu:ubuntu ${MOUNT_POINT}
echo "EBS volume ${DEVICE_PATH} mounted to ${MOUNT_POINT} and ownership set."

# fstab에 추가 (재부팅 시 자동 마운트)
UUID=$(blkid -s UUID -o value ${DEVICE_PATH})
if [ -n "$UUID" ] && ! grep -q "UUID=$UUID" /etc/fstab; then
  echo "Adding entry to /etc/fstab for UUID=$UUID."
  echo "UUID=$UUID ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
fi

echo "EBS volume mounted successfully on ${MOUNT_POINT}"

# Paper 서버별 데이터 디렉토리 및 Portainer 데이터 디렉토리 생성
mkdir -p ${MOUNT_POINT}/{lobby,wild,village,portainer}
chown -R ubuntu:ubuntu ${MOUNT_POINT}

# Docker Compose 파일 생성
cat > /mcserver/docker-compose.yml <<EOF
version: '3.8'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${MOUNT_POINT}/portainer:/data

  lobby-server:
    image: itzg/minecraft-server
    ports:
      - "25501:25565"
    environment:
      - EULA=TRUE
      - TYPE=PAPER
      - VERSION=1.20.4
      - ONLINE_MODE=FALSE
      - SERVER_NAME=Lobby Server
      - MEMORY=1G
    volumes:
      - ${MOUNT_POINT}/lobby:/data
    restart: unless-stopped
    stdin_open: true
    tty: true

  wild-server:
    image: itzg/minecraft-server
    ports:
      - "25502:25565"
    environment:
      - EULA=TRUE
      - TYPE=PAPER
      - VERSION=1.20.4
      - ONLINE_MODE=FALSE
      - SERVER_NAME=Wild Server
      - MEMORY=1G
    volumes:
      - ${MOUNT_POINT}/wild:/data
    restart: unless-stopped
    stdin_open: true
    tty: true

  village-server:
    image: itzg/minecraft-server
    ports:
      - "25503:25565"
    environment:
      - EULA=TRUE
      - TYPE=PAPER
      - VERSION=1.20.4
      - ONLINE_MODE=FALSE
      - SERVER_NAME=Village Server
      - MEMORY=1G
    volumes:
      - ${MOUNT_POINT}/village:/data
    restart: unless-stopped
    stdin_open: true
    tty: true
EOF

# 권한 설정
chown ubuntu:ubuntu /mcserver/docker-compose.yml

# Paper 서버들 시작
cd /mcserver
docker-compose up -d

echo "=== Paper Server EC2 Setup Completed at $(date) ==="