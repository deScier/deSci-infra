# Data source to obtain available Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create a VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  # The IPv4 CIDR block for the VPC
  cidr_block           = var.vpc_cidr
  
  # Enable DNS hostnames in the VPC
  enable_dns_hostnames = true
  
  # Enable DNS support in the VPC
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  # The VPC ID to create the Internet Gateway in
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  # Create a subnet for each specified Availability Zone
  count             = length(var.availability_zones)
  
  # The VPC ID to create the subnet in
  vpc_id            = aws_vpc.main.id
  
  # Calculate a CIDR block for each subnet
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  
  # The AZ to create the subnet in
  availability_zone = var.availability_zones[count.index]

  # Specify that instances launched into the subnet should be assigned a public IP address
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Create a route table for public subnets
resource "aws_route_table" "public" {
  # The VPC ID to create the route table in
  vpc_id = aws_vpc.main.id

  # Add a route for internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a NAT Gateway (optional, for private subnets with internet access)
resource "aws_eip" "nat" {
  # Create only if NAT Gateway is enabled
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  # Create only if NAT Gateway is enabled
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# Create private subnets (optional)
resource "aws_subnet" "private" {
  # Create only if private subnets are enabled
  count             = var.create_private_subnets ? length(var.availability_zones) : 0
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Create a route table for private subnets (optional)
resource "aws_route_table" "private" {
  # Create only if private subnets and NAT Gateway are enabled
  count  = var.create_private_subnets && var.create_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  # Add a route for internet access through the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate private subnets with the private route table (optional)
resource "aws_route_table_association" "private" {
  # Create only if private subnets and NAT Gateway are enabled
  count          = var.create_private_subnets && var.create_nat_gateway ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
