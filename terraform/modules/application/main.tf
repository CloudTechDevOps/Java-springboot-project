data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "instance" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "read_db_parameters" {
  name = "read-db-parameters"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameter"]
      Resource = [var.db_username_param_arn, var.db_password_param_arn]
    }]
  })
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "main" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.main.name
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail

    dnf update -y
    dnf install -y docker git curl awscli
    systemctl enable --now docker

    curl -fsSL "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    DB_USERNAME=$(aws ssm get-parameter --region ${var.region} --name '${var.db_username_param}' --query 'Parameter.Value' --output text)
    DB_PASSWORD=$(aws ssm get-parameter --region ${var.region} --name '${var.db_password_param}' --with-decryption --query 'Parameter.Value' --output text)

    cd /home/ec2-user
    git clone --depth 1 https://github.com/pavan-mudiraj22/Java-springboot-project.git app
    cd /home/ec2-user/app/compose

    cat > .env <<EOF
    API_URL=http://backend:8084
    FRONTEND_PORT=8501
    BACKEND_PORT=8084
    SPRING_DATASOURCE_URL=jdbc:mysql://${var.db_address}:3306/${var.db_name}?useSSL=false&allowPublicKeyRetrieval=true
    SPRING_DATASOURCE_USERNAME=$DB_USERNAME
    SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD
    EOF
    chmod 600 .env
    unset DB_PASSWORD

    /usr/local/bin/docker-compose --env-file .env -f docker-compose-rds.yaml up -d --build
  USERDATA

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-application"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_iam_role_policy_attachment.ssm_core, aws_iam_role_policy.read_db_parameters]
}
