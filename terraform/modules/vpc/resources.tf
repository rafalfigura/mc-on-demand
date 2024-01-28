resource "aws_internet_gateway" "internet-gateway" {
  count  = local.provisioned_vpc_enabled ? 0 : 1
  vpc_id = aws_vpc.vpc[0].id

  tags = {
    Name = random_id.internet-gateway-name.dec
  }
}

resource "aws_vpc" "vpc" {
  count      = local.provisioned_vpc_enabled ? 0 : 1
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = random_id.vpc-name.dec
  }
}

resource "aws_route_table" "isolated" {
  count  = local.provisioned_vpc_enabled ? 0 : length(local.isolated_subnet_cidr_blocks_per_az)
  vpc_id = aws_vpc.vpc[0].id

  route {
    cidr_block = aws_vpc.vpc[0].cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = random_id.isolated-route-table-name[count.index].dec
  }
}

resource "aws_route_table" "public" {
  count  = local.provisioned_vpc_enabled ? 0 : length(local.public_subnet_cidr_blocks_per_az)
  vpc_id = aws_vpc.vpc[0].id

  route {
    cidr_block = aws_vpc.vpc[0].cidr_block
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway[0].id
  }

  tags = {
    Name = random_id.public-route-table-name[count.index].dec
  }
}

resource "aws_route_table_association" "isolated" {
  count          = local.provisioned_vpc_enabled ? 0 : length(local.isolated_subnet_cidr_blocks_per_az)
  route_table_id = aws_route_table.isolated[count.index].id
  subnet_id      = aws_subnet.isolated[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = local.provisioned_vpc_enabled ? 0 : length(local.public_subnet_cidr_blocks_per_az)
  route_table_id = aws_route_table.public[count.index].id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_subnet" "public" {
  availability_zone       = element(keys(local.public_subnet_cidr_blocks_per_az), count.index)
  cidr_block              = element(values(local.public_subnet_cidr_blocks_per_az), count.index)
  count                   = local.provisioned_vpc_enabled ? 0 : length(local.public_subnet_cidr_blocks_per_az)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc[0].id

  tags = {
    Name                                = random_id.public-subnet-name[count.index].dec
    "${var.vpc_public_subnet_tag_name}" = "${var.vpc_public_subnet_tag_value}"
  }
}

resource "aws_subnet" "isolated" {
  count      = local.provisioned_vpc_enabled ? 0 : length(local.isolated_subnet_cidr_blocks_per_az)
  cidr_block = element(values(local.isolated_subnet_cidr_blocks_per_az), count.index)
  vpc_id     = aws_vpc.vpc[0].id

  map_public_ip_on_launch = false
  availability_zone       = element(keys(local.isolated_subnet_cidr_blocks_per_az), count.index)

  tags = {
    Name                                  = random_id.isolated-subnet-name[count.index].dec
    "${var.vpc_isolated_subnet_tag_name}" = "${var.vpc_isolated_subnet_tag_value}"
  }
}

resource "random_id" "internet-gateway-name" {
  byte_length = 5
  prefix      = "mod-igw-"
}

resource "random_id" "isolated-route-table-name" {
  byte_length = 5
  count       = 3
  prefix      = "mod-isolated-route-table-"
}

resource "random_id" "isolated-subnet-name" {
  byte_length = 5
  count       = 3
  prefix      = "mod-isolated-subnet-"
}

resource "random_id" "public-route-table-name" {
  byte_length = 5
  count       = 3
  prefix      = "mod-public-route-table-"
}

resource "random_id" "public-subnet-name" {
  byte_length = 5
  count       = 3
  prefix      = "mod-public-subnet-"
}

resource "random_id" "vpc-name" {
  byte_length = 5
  prefix      = "mod-vpc-"
}
