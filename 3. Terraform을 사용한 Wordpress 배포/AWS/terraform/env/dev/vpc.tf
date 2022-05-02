# NAT 게이트 용 EIP
resource "aws_eip" "nat" {
  count = 1
  vpc   = true
}

module "app_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  #  version = "~> 3.0"

  name = "app_vpc"
  cidr = "10.0.0.0/16"

  azs              = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # 하나의 가용 영역에 한 개의 nat 게이트웨이 설정
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = false
  external_nat_ip_ids    = aws_eip.nat.*.id

  create_database_subnet_group = true
}