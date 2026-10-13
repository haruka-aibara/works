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

# ---------- ネットワーク ----------
# 専用の VPC にパブリックサブネットを1つ。NAT ゲートウェイ（月 $45 前後）を置かず、
# インスタンスにパブリック IP を付けて外へ出る。インバウンドは SG で全閉
data "aws_ec2_instance_type_offerings" "az" {
  location_type = "availability-zone-id"
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

resource "aws_vpc" "waydroid" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "waydroid" }
}

resource "aws_internet_gateway" "waydroid" {
  vpc_id = aws_vpc.waydroid.id
  tags   = { Name = "waydroid" }
}

resource "aws_subnet" "waydroid" {
  vpc_id     = aws_vpc.waydroid.id
  cidr_block = "10.40.0.0/24"
  # instance_type を置ける AZ から選ぶ。あとで instance_type を変えて候補が変わっても
  # サブネット（とインスタンス・EBS）が作り直されないよう、作ったあとは AZ を見ない
  availability_zone_id = sort(data.aws_ec2_instance_type_offerings.az.locations)[0]
  tags                 = { Name = "waydroid" }

  lifecycle {
    ignore_changes = [availability_zone_id]
  }
}

resource "aws_route_table" "waydroid" {
  vpc_id = aws_vpc.waydroid.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.waydroid.id
  }
  tags = { Name = "waydroid" }
}

resource "aws_route_table_association" "waydroid" {
  subnet_id      = aws_subnet.waydroid.id
  route_table_id = aws_route_table.waydroid.id
}

# ---------- Security Group: インバウンドは全閉（接続は Tailscale 経由のみ） ----------
resource "aws_security_group" "waydroid" {
  name        = "waydroid-no-ingress"
  description = "No inbound. Access via Tailscale only."
  vpc_id      = aws_vpc.waydroid.id

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

# Tailscale の auth key の置き場所。中身はダミーで作り、本物はコンソールか CLI で上書きする。
# Terraform が値を持つと state に残るので、value の変更は見ない
resource "aws_ssm_parameter" "ts_authkey" {
  name        = var.ts_authkey_param
  description = "Tailscale auth key for waydroid-ec2. Overwrite the placeholder by hand."
  type        = "SecureString"
  value       = "placeholder"

  lifecycle {
    ignore_changes = [value]
  }
}

# Tailscale の auth key だけ読める
resource "aws_iam_role_policy" "read_ts_key" {
  name = "read-tailscale-authkey"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = aws_ssm_parameter.ts_authkey.arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "waydroid-ec2"
  role = aws_iam_role.ec2.name
}

# ---------- EC2 ----------
resource "aws_instance" "waydroid" {
  ami                         = data.aws_ami.ubuntu_arm.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.waydroid.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids      = [aws_security_group.waydroid.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    region   = data.aws_region.current.region
    ts_param = aws_ssm_parameter.ts_authkey.name
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

# 起動・停止も Terraform で持つ。CLI で起動しても、running = false のまま
# 次に works が apply されると止まる（止め忘れの保険にもなる）
resource "aws_ec2_instance_state" "waydroid" {
  instance_id = aws_instance.waydroid.id
  state       = var.running ? "running" : "stopped"
}
