data "aws_caller_identity" "me" {}

data "aws_region" "current" {}

# Ubuntu 24.04 arm64（Graviton なので Android の ARM アプリを変換なしで動かせる）
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# ---------- Security Group: インバウンドは全閉（接続は Tailscale 経由のみ） ----------
resource "aws_security_group" "waydroid" {
  name        = "waydroid-no-ingress"
  description = "No inbound. Access via Tailscale only."
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Waydroid image, Google Play, Tailscale DERP etc."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 用 IAM ロール ----------
resource "aws_iam_role" "ec2" {
  name = "waydroid-ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Tailscale の auth key（SSM Parameter Store / SecureString）だけ読める
resource "aws_iam_role_policy" "read_ts_key" {
  name = "read-tailscale-authkey"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.me.account_id}:parameter${var.ts_authkey_param}"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "waydroid-ec2"
  role = aws_iam_role.ec2.name
}

# ---------- EC2 ----------
resource "aws_instance" "waydroid" {
  ami           = data.aws_ami.ubuntu_arm.id
  instance_type = var.instance_type
  # ids の並びは保証されないので sort する。並びが変わるとインスタンスごと作り直しになる
  subnet_id              = var.subnet_id != "" ? var.subnet_id : sort(data.aws_subnets.default.ids)[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.waydroid.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    region   = data.aws_region.current.region
    ts_param = var.ts_authkey_param
  })

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2 強制
  }

  # 新しい AMI が出ても作り直さない（EBS 上の Android のデータ＝アプリのログイン状態を守る）
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = { Name = "waydroid" }
}
