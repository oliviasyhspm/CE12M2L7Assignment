# Configure the AWS Provider (adjust region as needed)
provider "aws" {
  region = "ap-southeast-1"
}

# Data source to get the Availability Zone of the specified subnet
data "aws_subnet" "selected" {
  id = "subnet-048a1bb9312e319aa"
}

resource "aws_instance" "web_server" {
  ami                         = "ami-0be9cb9f67c8dabd6" # find the AMI ID of Amazon Linux 2023  instance_type               = "t2.micro"
  instance_type               = "t2.micro"
  subnet_id     = data.aws_subnet.selected.id
  # Ensure the instance is launched in the same AZ as the subnet
  availability_zone = data.aws_subnet.selected.availability_zone 
  associate_public_ip_address = true
  key_name                    = "olivia-keypair" #Change to your keyname, e.g. jazeel-key-pair
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
 
  tags = {
    Name = "olivia-ec2-M2L7EBSTF"    #Prefix your own name, e.g. jazeel-ec2
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "olivia-sg-M2L7EBSTF" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id      = "vpc-0a498991ea4dd5943"  #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Create a 1 GB EBS volume in the same AZ as the instance
resource "aws_ebs_volume" "example" {
  availability_zone = aws_instance.web_server.availability_zone
  size              = 1 # Size in GiBs
  type              = "gp2" # General Purpose SSD volume type

  tags = {
    Name = "olivia-volume-M2L7EBSTF"
  }
}

# Attach the EBS volume to the EC2 instance
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh" # A typical device name for a data volume in Linux instances
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.web_server.id
}

# Output the instance and volume IDs for verification
output "instance_id" {
  value = aws_instance.web_server.id
}

output "volume_id" {
  value = aws_ebs_volume.example.id
}
