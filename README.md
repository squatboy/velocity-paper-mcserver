### 🇰🇷 [한국어 보기](README.ko.md)

# Velocity-Paper Minecraft Server Infrastructure

This project aims to build and manage a **medium-to-large scale Minecraft server infrastructure** running on AWS, using **Velocity proxy server** and **Paper bucket servers** in **Docker containers**, automated and managed with **Terraform**.

### Architecture 
<img width="1747" height="1102" alt="image" src="https://github.com/user-attachments/assets/fc22c887-e991-468e-9afe-21a2307bcae7" />

### Main AWS Resources
- **Compute**: EC2 (Ubuntu 22.04 ARM64)
- **Network**: VPC, Public/Private Subnet, NAT Gateway, Security Groups, Elastic IP
- **Storage**: EBS GP3 Volume, S3 (VPC Flow Logs)
- **Monitoring**: CloudWatch (Metrics/Alarms), SNS, Lambda (Discord Notifications) + Prometheus/Grafana (Application Level)
- **Backup**: Data Lifecycle Manager (1-hour snapshots)
- **Security**: IAM Roles, SSM Session Manager, VPC Flow Logs

### Docker Images
- **Velocity Proxy**: [`itzg/mc-proxy`](https://github.com/itzg/docker-mc-proxy)
- **Paper Servers**: [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server)
- **Monitoring**: `prom/prometheus`, `grafana/grafana`
- **Management**: [`portainer/portainer-ce`](https://hub.docker.com/r/portainer/portainer-ce)

## Deployment Guide

### 1. Prerequisites

#### 1.1 Required Tools Installation
```bash
# Install Terraform (macOS)
brew install terraform

# Install and configure AWS CLI
brew install awscli
aws configure
```

#### 1.2 AWS Permissions Setup
Minimum IAM permissions required for deployment:
- EC2, VPC, EBS management
- CloudWatch, SNS, Lambda management
- IAM role creation/management
- S3 bucket creation/management

### 2. Environment Setup

#### 2.1 Repository Clone
```bash
git clone https://github.com/your-username/velocity-papermc-server.git
cd velocity-papermc-server
```

#### 2.2 Terraform Variables Setup
Create a `terraform.tfvars` file and enter the following content:

```hcl
# Project basic settings
project_name = "mcserver"
aws_region   = "ap-northeast-2"

# Network settings
vpc_cidr            = "10.0.0.0/16"
availability_zone   = "ap-northeast-2a"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 instance settings
velocity_instance_type = "t4g.small"    # ARM64 instance
paper_instance_type    = "r6g.medium"   # Memory optimized

# EBS volume sizes (GB)
velocity_ebs_size = 20
paper_ebs_size    = 50

# SSH key pair (must be created in AWS console beforehand)
key_name = "your-keypair-name"

# Discord notifications (optional)
discord_webhook_url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

# Monitoring & access control
admin_ip                   = "YOUR_PUBLIC_IP/32"  # Your public IP
grafana_admin_username     = "admin"
grafana_admin_password     = "your-secure-password"
prometheus_scrape_interval = "5s"
prometheus_retention       = "7d"
```

⚠️ **Security Notes**:
- Never commit the `terraform.tfvars` file to Git
- Set `grafana_admin_password` to a strong password
- Set `admin_ip` to allow only your own public IP

### 3. Infrastructure Deployment

#### 3.1 Terraform Initialization and Deployment
```bash
# Initialize Terraform
terraform init

# Check deployment plan
terraform plan

# Deploy infrastructure (takes about 10-15 minutes)
terraform apply
```

#### 3.2 Deployment Completion Verification
After deployment completes, the following information will be output:
```
Outputs:
velocity_ec2_public_ip = "XX.XX.XX.XX"
grafana_url = "http://XX.XX.XX.XX:3000"
paper_ec2_private_ip = "10.0.2.XXX"
```

### 4. Game Server Configuration

#### 4.1 Velocity Proxy Configuration

1. **Connect to Velocity EC2**:
```bash
# SSH connection
ssh -i ~/.ssh/your-keypair.pem ubuntu@[VELOCITY_PUBLIC_IP]

# Or use SSM Session Manager
aws ssm start-session --target [VELOCITY_INSTANCE_ID]
```

2. **velocity.toml configuration**:
```bash
# Navigate to config file location
cd /mcserver/velocity

# Edit velocity.toml
sudo nano velocity.toml
```

Main `velocity.toml` settings:
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

3. **forwarding-secret configuration**:
```bash
# Check forwarding.secret file
echo "your-secret-key-here" > /mcserver/velocity/forwarding.secret
```

#### 4.2 Paper Server Configuration

1. **Connect to Paper EC2** (via Velocity Jump Host):
```bash
# Connect to Paper EC2 through Velocity EC2 (Security Group permission required)
ssh -i ~/.ssh/your-keypair.pem -J ubuntu@[VELOCITY_PUBLIC_IP] ubuntu@[PAPER_PRIVATE_IP]

# Or use SSM Session Manager
aws ssm start-session --target [PAPER_INSTANCE_ID]
```

2. **Paper server config file (paper-global.yml)**:
```bash
# Edit common config file (paper-global.yml)
cd /mcserver/paper/lobby/config
sudo nano paper-global.yml
sudo cp paper-global.yml ../wild/config/paper-global.yml
sudo cp paper-global.yml ../village/config/paper-global.yml
```

`paper-global.yml` configuration:
```yaml
# paper-global.yml
proxies:
  velocity:
    enabled: true
    online-mode: true
    secret: "your-secret-key-here"  # velocity's forwarding.secret value

settings:
  velocity-support:
    enabled: true
    online-mode: true
    secret: "your-secret-key-here"

# Performance optimization settings
chunk-loading:
  autoconfig-send-distance: true
  enable-frustum-priority: true

timings:
  enabled: false

network:
  keep-alive: 30
```

3. **Individual server settings**:
```bash
# Edit server.properties in each server directory
sudo nano /mcserver/paper/lobby/server.properties
sudo nano /mcserver/paper/wild/server.properties
sudo nano /mcserver/paper/village/server.properties
```

Each server's `server.properties`:
```properties
# server.properties (individual server settings)
server-name=Lobby Server  # Set differently per server
online-mode=false         # Set to false when using Velocity
server-port=25565         # Internal container port
```

### 5. Service Start and Verification

#### 5.1 Container Status Check
```bash
# On Velocity EC2
cd /mcserver && docker-compose ps

# On Paper EC2
cd /mcserver && docker-compose ps
```

#### 5.2 Log Verification
```bash
# Check real-time logs
docker-compose logs -f velocity-proxy
docker-compose logs -f lobby-server
docker-compose logs -f wild-server
docker-compose logs -f village-server
```

### 6. Monitoring Setup

This project collects metrics using the [`bungeecord-prometheus-exporter`](https://github.com/weihao/bungeecord-prometheus-exporter) plugin.

#### 6.1 Grafana Access
1. Access `http://[VELOCITY_PUBLIC_IP]:3000` in browser
2. Login credentials:
   - Username: user_name set in `terraform.tfvars`
   - Password: password set in `terraform.tfvars`

#### 6.2 Add Prometheus Data Source
1. Grafana → Configuration → Data Sources
2. Add data source → Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

#### 6.3 Portainer Access (Paper Server Management)
```bash
# SSM port forwarding from local PC
aws ssm start-session \
    --target [PAPER_INSTANCE_ID] \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["9000"],"localPortNumber":["9000"]}'

# Access http://localhost:9000 in browser
```

### 7. Game Server Testing

#### 7.1 Connection Test
1. Connect to `[VELOCITY_PUBLIC_IP]:25565` from Minecraft client
2. Test server switching:
   ```
   /server lobby
   /server wild
   /server village
   ```

#### 7.2 Performance Monitoring
- **Grafana**: Check application-level server metrics (player count, JVM memory, etc.)
- **CloudWatch**: AWS resource monitoring
- **Discord**: SNS + Lambda alerts

### 8. Troubleshooting

**Issue**: "Can't connect to server"
```bash
# Solution: Check security groups and firewall
aws ec2 describe-security-groups --group-ids [SG_ID]
sudo ufw status
```

**Issue**: "Server failed to start"
```bash
# Solution: Check container logs
docker-compose logs [service-name]
sudo journalctl -u docker
```

**Issue**: "Permission denied" (monitoring)
```bash
# Solution: Reset permissions
sudo chown -R 65534:65534 /mcserver/monitoring/prometheus/data
sudo chown -R 472:472 /mcserver/monitoring/grafana
```

### 9. Infrastructure Cleanup

⚠️ **Warning**: The following commands will delete all AWS resources.

```bash
# Delete infrastructure
terraform destroy

# Type 'yes' in the confirmation prompt
```
