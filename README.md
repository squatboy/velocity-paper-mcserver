
<img width="1681" height="987" alt="mcserver-arch" src="https://github.com/user-attachments/assets/0b1a2865-39a0-49bd-be7c-99e0649eda0e" />

> This project aims to build Medium-High Scale Minecraft Server infrastructure on AWS using **Velocity proxy server** and **Paper Minecraft servers** running inside **Docker containers** 24/7, automated and managed with **Terraform**.

# Key Features

- **`Single Public Endpoint`**  
  External access via a fixed Elastic IP assigned to the Proxy Server EC2 (Route 53: Optional)

- **`Subnet Segmentation Architecture`**  
  - Proxy Server EC2 deployed in a public subnet  
  - Paper Minecraft servers deployed in a private subnet for enhanced security

- **`Containerized Service Deployment`**  
  - Velocity Server(Proxy Server) using [itzg/docker-mc-proxy](https://github.com/itzg/docker-mc-proxy)
  - Paper Server(Minecraft Servers) using [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)

- **`Multi-Server Integration`**  
  A single Paper Server EC2 runs 3 server instances (Lobby, Wild, Village) concurrently via Docker Compose

- **`Container Management`** <br>
  Provides a user-friendly container management environment using [Portainer](https://hub.docker.com/r/portainer/portainer-ce)

- **`Enhances security`** <br>
  Deploys the original game server within a private subnet to enhance security and isolate internal resources

- **`High-Performance Shared Storage`** <br>
  Amazon EBS GP3 volume mounted at `/data` for data sharing and durability

- **`Monitoring and Alerting System`**  
  Resource monitoring with AWS CloudWatch Agent and Container Insights  
  Real-time alert notifications integrated via Discord webhook

- **`Enhanced Security Logging`**  
  VPC Flow Logs enabled for network traffic monitoring and security auditing

- **`Automated Backup and Recovery`**  
  AWS Data Lifecycle Manager configured to create EBS snapshots every hour

