output "ec2_instances_info" {
  description = "EC2 인스턴스들의 상세 정보"
  value = {
    velocity = {
      id         = aws_instance.velocity_ec2.id
      private_ip = aws_instance.velocity_ec2.private_ip
      public_ip  = aws_instance.velocity_ec2.public_ip
      type       = var.velocity_instance_type
    }
    paper = {
      id         = aws_instance.paper_ec2.id
      private_ip = aws_instance.paper_ec2.private_ip
      type       = var.paper_instance_type
    }
  }
}
