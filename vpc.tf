data "aws_availability_zones" "available" {
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = var.aws_vpc_cidr
  # instance_tenancy = default
  enable_dns_support   = true
  enable_dns_hostnames = true
  # enable_classiclink = false
  # enable_classiclink_dns_support = false
  # assign_generated_ipv6_cidr_block = false

  # Tagging
  tags = {
    Name                                                = var.aws_vpc_name
    Namespace                                           = var.namespace
    BoundedContext                                      = var.bounded_context
    Environment                                         = var.environment
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  # Tagging
  tags = {
    Name           = var.aws_internet_gateway_name
    Namespace      = var.namespace
    BoundedContext = var.bounded_context
    Environment    = var.environment
  }
}

# Route Table - Gateway
resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    # ipv6_cidr_block
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name           = var.aws_route_table_gateway_name
    Namespace      = var.namespace
    BoundedContext = var.bounded_context
    Environment    = var.environment
    Network        = "public"
  }

  # propagating_vgws
}

# Route Table - Application
resource "aws_route_table" "application" {
  count  = var.subnet_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    # ipv6_cidr_block 
    nat_gateway_id = aws_nat_gateway.this.*.id[count.index] # Use this if using NAT Gateway
  }

  tags = {
    Name           = var.aws_route_table_application_name
    Namespace      = var.namespace
    BoundedContext = var.bounded_context
    Environment    = var.environment
    Network        = "private"
  }

  # propagating_vgws  
}

# Elastic IP
resource "aws_eip" "nat_gateway" {
  count = var.subnet_count
  vpc   = true

  tags = {
    Name = var.aws_eip_name
    Namespace      = var.namespace
    BoundedContext = var.bounded_context
    Environment    = var.environment
  }  
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  count         = var.subnet_count
  allocation_id = aws_eip.nat_gateway.*.id[count.index]
  subnet_id     = aws_subnet.gateway.*.id[count.index]

  tags = {
    Name = var.aws_nat_gateway_name
    Namespace      = var.namespace
    BoundedContext = var.bounded_context
    Environment    = var.environment
  }

  depends_on = [aws_internet_gateway.this]
}

# Subnet - Gateway
resource "aws_subnet" "gateway" {
  count             = var.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.1${count.index}.0/24"
  vpc_id            = aws_vpc.this.id

  tags = {
    Name                                                = var.aws_subnet_gateway_name
    Namespace                                           = var.namespace
    BoundedContext                                      = var.bounded_context
    Environment                                         = var.environment
    "kubernetes.io/role/elb"                            = "1"
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared"
  }
}

# Subnet - Application
resource "aws_subnet" "application" {
  count             = var.subnet_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.2${count.index}.0/24"
  vpc_id            = aws_vpc.this.id

  tags = {
    Name                                                = var.aws_subnet_application_name
    Namespace                                           = var.namespace
    BoundedContext                                      = var.bounded_context
    Environment                                         = var.environment
    "kubernetes.io/cluster/${var.aws_eks_cluster_name}" = "shared"
  }
}

# Route Table Association - Gateway
resource "aws_route_table_association" "gateway" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.gateway.*.id[count.index]
  route_table_id = aws_route_table.gateway.id
}

# Route Table Association - Application
resource "aws_route_table_association" "application" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.application.*.id[count.index]
  route_table_id = aws_route_table.application.*.id[count.index]
}