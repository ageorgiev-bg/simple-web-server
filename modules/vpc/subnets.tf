resource "aws_subnet" "private" {
  for_each = var.private_subnets_config

  availability_zone_id = each.value["az"]
  cidr_block           = each.value["cidr"]
  vpc_id               = aws_vpc.main.id

  tags = {
    Name        = "${aws_vpc.main.id}-${each.key}",
    subnet_type = "private"
  }
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets_config

  availability_zone_id = each.value["az"]
  cidr_block           = each.value["cidr"]
  vpc_id               = aws_vpc.main.id

  tags = {
    Name        = "${aws_vpc.main.id}-${each.key}",
    subnet_type = "public"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = aws_vpc.main.id
  subnet_ids = values(aws_subnet.private)[*].id

  tags = {
    Name = aws_vpc.main.id
  }
}