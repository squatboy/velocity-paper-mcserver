# Velocity-Paper Minecraft Server Infrastructure

이 프로젝트에서는 **Velocity 프록시 서버**와 **Paper 버킷 서버**를 **Docker 컨테이너**로 띄워 AWS환경에서 운영되는 **중-대규모 마인크래프트 서버 인프라**를 구축하고, **Terraform**으로 자동화 및 관리하는 것을 목표로 합니다.

## 인프라 개요

### 아키텍쳐
<img width="1747" height="1102" alt="image" src="https://github.com/user-attachments/assets/bac0eabd-4f3e-4d57-a374-598974bdab43" />


### 주요 AWS 리소스
- **컴퓨팅**: EC2 (Ubuntu 22.04 ARM64)
- **네트워크**: VPC, Public/Private Subnet, NAT Gateway, Security Groups, Elastic IP
- **스토리지**: EBS GP3 볼륨, S3 (VPC Flow Logs)
- **모니터링**: CloudWatch (메트릭/알람), SNS, Lambda (Discord 알림) + Prometheus/Grafana(어플리케이션 레벨)
- **백업**: Data Lifecycle Manager (1시간 스냅샷)
- **보안**: IAM 역할, SSM Session Manager, VPC Flow Logs

### Docker 이미지
- **Velocity Proxy**: [`itzg/mc-proxy`](https://github.com/itzg/docker-mc-proxy)
- **Paper Servers**: [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server)
- **Monitoring**: `prom/prometheus`, `grafana/grafana`
- **Management**: [`portainer/portainer-ce`](https://hub.docker.com/r/portainer/portainer-ce)

## 배포 가이드

### 1. 사전 준비

#### 1.1 필수 도구 설치
```bash
# Terraform 설치 (macOS)
brew install terraform

# AWS CLI 설치 및 설정
brew install awscli
aws configure
```

#### 1.2 AWS 권한 설정
배포에 필요한 최소 IAM 권한:
- EC2, VPC, EBS 관리
- CloudWatch, SNS, Lambda 관리
- IAM 역할 생성/관리
- S3 버킷 생성/관리

### 2. 환경 설정

#### 2.1 저장소 클론
```bash
git clone https://github.com/your-username/velocity-papermc-server.git
cd velocity-papermc-server
```

#### 2.2 Terraform 변수 설정
`terraform.tfvars` 파일을 생성하고 다음 내용을 입력:

```hcl
# 프로젝트 기본 설정
project_name = "mcserver"
aws_region   = "ap-northeast-2"

# 네트워크 설정
vpc_cidr            = "10.0.0.0/16"
availability_zone   = "ap-northeast-2a"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 인스턴스 설정
velocity_instance_type = "t4g.small"    # ARM64 인스턴스
paper_instance_type    = "r6g.medium"   # 메모리 최적화

# EBS 볼륨 크기 (GB)
velocity_ebs_size = 20
paper_ebs_size    = 50

# SSH 키페어 (사전에 AWS 콘솔에서 생성 필요)
key_name = "your-keypair-name"

# Discord 알림 (선택사항)
discord_webhook_url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

# 모니터링 & 접근 제어
admin_ip                   = "YOUR_PUBLIC_IP/32"  # 본인 공인 IP
grafana_admin_username     = "admin"
grafana_admin_password     = "your-secure-password"
prometheus_scrape_interval = "5s"
prometheus_retention       = "7d"
```

⚠️ **보안 주의사항**: 
- `terraform.tfvars` 파일은 절대 Git에 커밋하지 마세요
- `grafana_admin_password`는 강력한 비밀번호로 설정하세요
- `admin_ip`는 본인의 공인 IP만 허용하도록 설정하세요

### 3. 인프라 배포

#### 3.1 Terraform 초기화 및 배포
```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan

# 인프라 배포 (약 10-15분 소요)
terraform apply
```

#### 3.2 배포 완료 확인
배포가 완료되면 다음 정보가 출력됩니다:
```
Outputs:
velocity_ec2_public_ip = "XX.XX.XX.XX"
grafana_url = "http://XX.XX.XX.XX:3000"
paper_ec2_private_ip = "10.0.2.XXX"
```

### 4. 게임 서버 설정

#### 4.1 Velocity 프록시 설정

1. **Velocity EC2에 접속**:
```bash
# SSH 접속
ssh -i ~/.ssh/your-keypair.pem ubuntu@[VELOCITY_PUBLIC_IP]

# 또는 SSM Session Manager 사용
aws ssm start-session --target [VELOCITY_INSTANCE_ID]
```

2. **velocity.toml 설정**:
```bash
# 설정 파일 위치로 이동
cd /mcserver/velocity

# velocity.toml 편집
sudo nano velocity.toml
```

`velocity.toml` 주요 설정:
```toml
# velocity.toml
config-version = "2.6"
bind = "0.0.0.0:25577"
motd = ""
show-max-players = 100
online-mode = true
force-key-authentication = true

[servers]
lobby = "PAPER_PRIVATE_IP:25501"
wild = "PAPER_PRIVATE_IP:25502"  
village = "PAPER_PRIVATE_IP:25503"

try = ["lobby"]

[forced-hosts]
"lobby.yourserver.com" = ["lobby"]
"wild.yourserver.com" = ["wild"]
"village.yourserver.com" = ["village"]
```

3. **forwarding-secret 설정**:
```bash
# forwarding.secret 파일 확인
echo "your-secret-key-here" > /mcserver/velocity/forwarding.secret
```

#### 4.2 Paper 서버 설정

1. **Paper EC2에 접속** (Velocity를 통한 Jump Host):
```bash
# Velocity EC2를 거쳐 Paper EC2 접속 (Security Group 허용 필요)
ssh -i ~/.ssh/your-keypair.pem -J ubuntu@[VELOCITY_PUBLIC_IP] ubuntu@[PAPER_PRIVATE_IP]

# 또는 SSM Session Manager 사용
aws ssm start-session --target [PAPER_INSTANCE_ID]
```

2. **Paper 서버 설정 파일 (paper-global.yml)**:
```bash
# 공통 설정 파일(paper-global.yml) 편집
cd /mcserver/paper/lobby/config
sudo nano paper-global.yml
sudo cp paper-global.yml ../wild/config/paper-global.yml
sudo cp paper-global.yml ../village/config/paper-global.yml
```

`paper-global.yml` 설정:
```yaml
# paper-global.yml
proxies:
  velocity:
    enabled: true
    online-mode: true
    secret: "your-secret-key-here"  # velocity의 forwarding.secret 값

settings:
  velocity-support:
    enabled: true
    online-mode: true
    secret: "your-secret-key-here"

# 성능 최적화 설정
chunk-loading:
  autoconfig-send-distance: true
  enable-frustum-priority: true

timings:
  enabled: false
  
network:
  keep-alive: 30
```

3. **각 서버별 개별 설정**:
```bash
# 각 서버 디렉토리에서 server.properties 편집
sudo nano /mcserver/paper/lobby/server.properties
sudo nano /mcserver/paper/wild/server.properties  
sudo nano /mcserver/paper/village/server.properties
```

각 서버의 `server.properties`:
```properties
# server.properties (각 서버 개별 설정)
server-name=Lobby Server  # 서버별로 다르게 설정
online-mode=false         # Velocity 사용 시 false
server-port=25565         # 컨테이너 내부 포트
```

### 5. 서비스 시작 및 확인

#### 5.1 컨테이너 상태 확인
```bash
# Velocity EC2에서
cd /mcserver && docker-compose ps

# Paper EC2에서  
cd /mcserver && docker-compose ps
```

#### 5.2 로그 확인
```bash
# 실시간 로그 확인
docker-compose logs -f velocity-proxy
docker-compose logs -f lobby-server
docker-compose logs -f wild-server
docker-compose logs -f village-server
```

### 6. 모니터링 설정

해당 프로젝트에서는 [`bungeecord-prometheus-exporter`](https://github.com/weihao/bungeecord-prometheus-exporter) 플러그인을 사용하여 메트릭을 수집합니다.

#### 6.1 Grafana 접속
1. 브라우저에서 `http://[VELOCITY_PUBLIC_IP]:3000` 접속
2. 로그인 정보:
   - Username: `terraform.tfvars`에서 설정한 user_name
   - Password: `terraform.tfvars`에서 설정한 password

#### 6.2 Prometheus 데이터 소스 추가
1. Grafana → Configuration → Data Sources
2. Add data source → Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

#### 6.3 Portainer 접속 (Paper 서버 관리)
```bash
# 로컬 PC에서 SSM 포트 포워딩
aws ssm start-session \
    --target [PAPER_INSTANCE_ID] \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["9000"],"localPortNumber":["9000"]}'

# 브라우저에서 http://localhost:9000 접속
```

### 7. 게임 서버 테스트

#### 7.1 연결 테스트
1. Minecraft 클라이언트에서 `[VELOCITY_PUBLIC_IP]:25565`로 접속
2. 각 서버 간 이동 테스트:
   ```
   /server lobby
   /server wild  
   /server village
   ```

#### 7.2 성능 모니터링
- **Grafana**: 어플리케이션 레벨의 서버 메트릭(플레이어 수, JVM memory 등) 확인
- **CloudWatch**: AWS 리소스 모니터링
- **Discord**: SNS + Lambda 경보

### 8. 트러블슈팅

**문제**: "Can't connect to server"
```bash
# 해결: 보안 그룹 및 방화벽 확인
aws ec2 describe-security-groups --group-ids [SG_ID]
sudo ufw status
```

**문제**: "Server failed to start"
```bash
# 해결: 컨테이너 로그 확인
docker-compose logs [service-name]
sudo journalctl -u docker
```

**문제**: "Permission denied" (모니터링)
```bash
# 해결: 권한 재설정
sudo chown -R 65534:65534 /mcserver/monitoring/prometheus/data
sudo chown -R 472:472 /mcserver/monitoring/grafana
```

### 9. 인프라 정리

⚠️ **주의**: 아래 명령어는 모든 AWS 리소스를 삭제합니다.

```bash
# 인프라 삭제
terraform destroy

# 확인 메시지에서 'yes' 입력
```
