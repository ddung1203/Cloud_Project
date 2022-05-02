module "rds_allow" {
  source = "terraform-aws-modules/security-group/aws"
  #  version = "~> 4.0"

  name            = "rds_allow_sg"
  description     = "rds"
  vpc_id          = module.app_vpc.vpc_id
  use_name_prefix = false

  # ssh_allow 인바운드 규칙에 추가
  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = aws_security_group.node_sg.id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

# 템플릿(프리티어), 디비 인스턴스 이름
# 디비 마스터 사용자 이름, 비밀번호
# 스토리지
# 가용성 및 내구성(다중 AZ)
# vpc 세팅 및 서브넷 설정, 퍼블릭 액세스 설정, VPC 보안 그룹 세팅
# 데이터 베이스 인증 옵션(암호인증)
# 초기 데이터베이스 이름 설정, 백업, 스냅샷, 디비 인스턴스 암호화 옵션 등
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "wordpress"

  engine               = "mysql"
  engine_version       = "8.0.20"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name                = "wordpress"
  username               = "admin"
  password               = "dkagh1."
  create_random_password = false
  port                   = "3306"

  # 내가 지정한 VPC 에 데이터베이스가 만들어지지 않음..
  # DB subnet group
  # create_db_subnet_group = true
  # multi_az             = true
  subnet_ids             = module.app_vpc.database_subnets
  vpc_security_group_ids = [module.rds_allow.security_group_id]
  create_db_subnet_group = false
  db_subnet_group_name   = module.app_vpc.database_subnet_group_name

  # 삭제 시 스냅샷을 생성할지에 대한 여부, true 로 설정하여 스냅샷 생성 안 함
  skip_final_snapshot = true

  #   maintenance_window              = "Mon:00:00-Mon:03:00"
  #   backup_window                   = "03:00-06:00"
  #   enabled_cloudwatch_logs_exports = ["general"]
  #   create_cloudwatch_log_group     = true

  #   backup_retention_period = 0
  #   skip_final_snapshot     = true
  #   deletion_protection     = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  depends_on = [
    module.app_vpc
  ]
}

resource "null_resource" "rds_endpoint_info" {
  provisioner "local-exec" {
    command = "echo database_host: ${module.db.db_instance_endpoint} > /home/vagrant/220429/vars/rds_endpoint_info.yml"
  }
}