provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainInternetGateway"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "MainRouteTable"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MainSubnet"
  }
}

resource "aws_security_group" "web_server_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_server_sg"
  }
}


resource "tls_private_key" "web_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "web_server_key" {
  key_name   = "otowok"
  public_key = tls_private_key.web_server_key.public_key_openssh
}

resource "aws_instance" "web_server" {
  ami                    = "ami-029fb5f3f8aa2663c" 
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]
  key_name               = aws_key_pair.web_server_key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "web_server"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.public_ip
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo add-apt-repository ppa:ansible/ansible -y",
      "sudo apt update",
      "sudo apt install ansible -y"
    ]
  }

provisioner "file" {
  source      = "ansible_files/monitoring.yml"
  destination = "/tmp/monitoring.yml"
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_server_key.private_key_pem
    host        = self.public_ip
  }
}

provisioner "file" {
  source      = "ansible_files/service.yml"
  destination = "/tmp/service.yml"
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_server_key.private_key_pem
    host        = self.public_ip
  }
}

provisioner "file" {
  source      = "ansible_files/config.yml"
  destination = "/tmp/network.yml"
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_server_key.private_key_pem
    host        = self.public_ip
  }
}

provisioner "file" {
  source      = "ansible_files/dashboard.yml"
  destination = "/tmp/dashboard.yml"
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.web_server_key.private_key_pem
    host        = self.public_ip
  }
}

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.web_server_key.private_key_pem
      host        = self.public_ip
    }

    inline = [
      "echo \"[web_servers]\" > /tmp/inventory.ini",
      "echo \"${self.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file='/tmp/private_key.pem'\" >> /tmp/inventory.ini",
      "echo '${tls_private_key.web_server_key.private_key_pem}' > /tmp/private_key.pem",
      "chmod 600 /tmp/private_key.pem",
      "ansible-playbook -i /tmp/inventory.ini /tmp/config.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/monitoring.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/service.yml -vvv",
      "ansible-playbook -i /tmp/inventory.ini /tmp/dashboard.yml -vvv"
    ]
  }


  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 20
    volume_type = "gp2"
  }

  depends_on = [
    aws_security_group.web_server_sg,
    aws_subnet.main
  ]
}
