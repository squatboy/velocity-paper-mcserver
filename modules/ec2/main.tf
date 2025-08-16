# 최신 Ubuntu 22.04 LTS AMI 조회 (ARM64)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  tags = {
    Name = "${var.project_name}-velocity"
  }
}


# Velocity EC2용 Elastic IP
# resource "aws_eip" "velocity_eip" {
#   domain   = "vpc"
#   instance = aws_instance.velocity_ec2.id

#   depends_on = [aws_instance.velocity_ec2]
#   tags = {
#     Name = "${var.project_name}-velocity-eip"
#   }
# }

# Velocity Server EC2 
resource "aws_instance" "velocity_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.velocity_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.velocity_security_group_id]
  iam_instance_profile   = var.iam_instance_profile_name
  key_name               = var.key_name
  user_data              = base64encode(file("${path.module}/user_data/velocity_userdata.sh"))
  tags = {
    Name = "${var.project_name}-velocity-ec2"
  }
}

# Paper Server EC2
resource "aws_instance" "paper_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.paper_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.paper_security_group_id]
  iam_instance_profile   = var.iam_instance_profile_name
  key_name               = var.key_name
  user_data              = base64encode(file("${path.module}/user_data/paper_userdata.sh"))
  tags = {
    Name = "${var.project_name}-paper-ec2"
  }
}

# EBS 볼륨을 Paper EC2에 연결
resource "aws_volume_attachment" "paper_ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = var.paper_ebs_volume_id
  instance_id = aws_instance.paper_ec2.id
}

# EBS 볼륨을 Velocity EC2에 연결
resource "aws_volume_attachment" "velocity_ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = var.velocity_ebs_volume_id
  instance_id = aws_instance.velocity_ec2.id
}
