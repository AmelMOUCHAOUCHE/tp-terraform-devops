# ── Data sources ───────────────────────────────────
data "aws_availability_zones" "available" {
  state = "available"
}

# ── VPC ────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

# ── Internet Gateway ───────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ── Subnet public ──────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public-subnet" }
}

# ── Route Table ────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# ── Security Group ─────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security Group pour le serveur web"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH depuis ma machine"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Tout le trafic sortant"
  }
  tags = { Name = "${var.project_name}-web-sg" }
}

# ── Clé SSH ────────────────────────────────────────
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/tp_terraform.pub")
}

# ── AMI Ubuntu ─────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "image-id"
    values = ["ami-0adb8ca49015e0901"]
  }
}

# ── Instance EC2 ───────────────────────────────────
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type[terraform.workspace] 
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  tags = { Name = "${var.project_name}-web" }
}

# ── S3 Bucket ──────────────────────────────────────
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-${random_id.suffix.hex}"
  tags   = { Name = "${var.project_name}-assets" }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── Subnet privé ───────────────────────────────────
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-private-subnet" }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = { Name = "${var.project_name}-private-subnet-2" }
}

# ── DB Subnet Group ────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]
  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# ── Security Group RDS ─────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security Group pour RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "PostgreSQL depuis EC2 uniquement"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# ── RDS PostgreSQL ─────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "appdb"
  username = "dbadmin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = { Name = "${var.project_name}-db" }
}

# ── Subnet public 2 (obligatoire pour ALB) ─────────
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project_name}-public-subnet-2" }
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group ALB ─────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group pour ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# ── Application Load Balancer ──────────────────────
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
  tags = { Name = "${var.project_name}-alb" }
}

# ── Target Group ───────────────────────────────────
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = { Name = "${var.project_name}-tg" }
}

# ── Listener ───────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ── Attachment EC2 → Target Group ─────────────────
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}