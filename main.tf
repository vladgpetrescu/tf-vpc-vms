################################################################################
# LOCALS
################################################################################

data "aws_availability_zones" "available" {}
locals {
  availability_zone = data.aws_availability_zones.available.names[0]
  ssh_key_name      = var.ssh_key_name != null ? var.ssh_key_name : var.name
  tags = merge(
    { "Name" = var.name },
    var.tags
  )
}

################################################################################
# VPC / General
################################################################################


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = local.tags
}

resource "aws_key_pair" "main" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key)

  tags = local.tags
}

################################################################################
# PUBLIC SUBNETS
################################################################################

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = local.availability_zone

  tags = merge(
    { "Type" = "public-subnet" },
    local.tags
  )
}

# Security Group for instances in the public subnet
# Ingress and egress rules are declared as separate resources below
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  vpc_id      = aws_vpc.main.id
  description = "Controls traffic for instances launched in the public subnets"
}

resource "aws_vpc_security_group_egress_rule" "public_sg_egress" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.public_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "public_sg_ingress" {
  from_port         = 22
  to_port           = 22
  ip_protocol       = "6"
  cidr_ipv4         = var.public_ingress_cidr
  security_group_id = aws_security_group.public_sg.id
}

################################################################################
# PRIVATE SUBNETS
################################################################################

resource "aws_subnet" "private" {
  count = var.create_private_resources ? 1 : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = local.availability_zone

  tags = merge(
    { "Type" = "private-subnet" },
    local.tags
  )
}

# Security Group for instances in the private subnet
# Ingress and egress rules are declared as separate resources below
resource "aws_security_group" "private_sg" {
  count = var.create_private_resources ? 1 : 0

  name        = "private-sg"
  vpc_id      = aws_vpc.main.id
  description = "Controls traffic for instances launched in the private subnets"
}

resource "aws_vpc_security_group_egress_rule" "private_sg_egress" {
  count = var.create_private_resources ? 1 : 0

  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.private_sg[0].id
}

resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress" {
  count = var.create_private_resources ? 1 : 0

  from_port         = 22
  to_port           = 22
  ip_protocol       = "6"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.private_sg[0].id
}

################################################################################
# Internet gateway
################################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    { "Type" = "main-igw" },
    local.tags
  )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    { "Type" = "public-rt" },
    local.tags
  )
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}


################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat_eip" {
  count = var.create_private_resources ? 1 : 0

  domain = "vpc"

  tags = merge(
    { "Type" = "nat-eip" },
    local.tags
  )
}

resource "aws_nat_gateway" "nat" {
  count = var.create_private_resources ? 1 : 0

  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_eip[0].id

  tags = merge(
    { "Type" = "main-nat" },
    local.tags
  )

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  count = var.create_private_resources ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(
    { "Type" = "private-rt" },
    local.tags
  )
}

resource "aws_route_table_association" "private_assoc" {
  count = var.create_private_resources ? 1 : 0

  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private_rt[0].id
}

################################################################################
# VMs
################################################################################

data "aws_ami" "linux" {
  count = var.instance_type == "linux" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
  filter {
    name   = "description"
    values = ["Amazon Linux 2023 AMI*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_ami" "windows" {
  count = var.instance_type == "windows" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "description"
    values = ["*Windows Server 2025*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#### Public VM

resource "aws_ebs_volume" "public" {
  availability_zone = local.availability_zone
  size              = 10

  tags = merge(
    { "Type" = "public-vm-ebs" },
    local.tags
  )
}

resource "aws_volume_attachment" "public_ebs_att" {
  device_name = var.instance_type == "linux" ? "/dev/sdh" : "H:"
  volume_id   = aws_ebs_volume.public.id
  instance_id = aws_instance.public.id
}

resource "aws_instance" "public" {
  ami                    = var.instance_type == "linux" ? data.aws_ami.linux[0].id : data.aws_ami.windows[0].id
  instance_type          = "t3.micro"
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = merge(
    { "Type" = "public-vm" },
    local.tags
  )
}

resource "aws_eip" "public_vm_eip" {
  domain   = "vpc"
  instance = aws_instance.public.id

  tags = merge(
    { "Type" = "public-vm-eip" },
    local.tags
  )
}

#### Private VM

resource "aws_ebs_volume" "private" {
  count = var.create_private_resources ? 1 : 0

  availability_zone = local.availability_zone
  size              = 10

  tags = merge(
    { "Type" = "private-vm-ebs" },
    local.tags
  )
}

resource "aws_volume_attachment" "private_ebs_att" {
  count = var.create_private_resources ? 1 : 0

  device_name = var.instance_type == "linux" ? "/dev/sdh" : "H:"
  volume_id   = aws_ebs_volume.private[0].id
  instance_id = aws_instance.private[0].id
}

resource "aws_instance" "private" {
  count = var.create_private_resources ? 1 : 0

  ami                    = var.instance_type == "linux" ? data.aws_ami.linux[0].id : data.aws_ami.windows[0].id
  instance_type          = "t3.micro"
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.private_sg[0].id]

  tags = merge(
    { "Type" = "private-vm" },
    local.tags
  )
}

