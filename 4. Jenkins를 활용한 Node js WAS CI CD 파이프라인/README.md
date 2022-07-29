# Jenkins를 활용한 Node.js WAS CI/CD 파이프라인 및 ELK 모니터링 구축

#### https://github.com/ddung1203/CICD_Project << 코드

# 목차

1. **역할 분담**
2. **작업 환경**
3. **프로젝트 개요**
    1. Terraform(수정)
    2. Jenkins를 이용한 WAS CI/CD
    3. ELK 로그 모니터링
4. **프로젝트 진행 과정**
    1. Terraform을 활용한 리소스 생성
        1. 아키택처 
        2. Terraform 초기 설정
            1. Terraform 명령어 설치
            2. 사용자 생성
            3. AWS CLI 설치
            4. AWS S3 Bucket 생성
            5. Pem 키 생성
        3. AWS 환경 구축 
            1. AWS Provider
            2. IAM
            3. VPC
        4. 서버 생성
            1. Jenkins EC2 Instance
            2. Docker-Ansible EC2 Instance
        5. 서버 생성 후 동작
            1. Output 확인
            2. tfstate 파일 업데이트
            
    2. AWS EKS 배포
        1.  YAML 파일을 이용한 Amazon EKS 배포
        2. Amazon EKS의 네트워크 로드밸런싱
            1. AWS LoadBalancer Controller 추가 기능 설치
        3. Horizontal Pod AutoScaler 배포
            1. Kubernetes Metrics Server 설치
        4. Amazon EKS에서 Container Insigth 시작 설정
            1. CloudWatch Container Insight
        5. EKS Cluster Autoscaler
            1. Kubernetes Metrics Server 설치
        6. Horizontal Pod AutoScaler 배포
            1. Kubernetes Metrics Server 설치
            
    3. Jenkins를 사용한 NodeJS CI/CD 환경구성
        1. 플러그인 설치
        2. 플러그인 설정
        
    4. 관리형 데이터베이스 및 Amazon S3
        1. MongoDB Atlas 설정
        2. Amazon S3 설정
        
    5. 웹 애플리케이션 서버 구축
        1. NodeJS 웹 애플리케이션 서버
        2. 웹 애플리케이션 서버 구축
        
    6. Jenkins 이벤트 로그 모니터링
        1. Jenkins 설정
            1. 플러그인 설치 
            2. 플러그인 설정 
        2. Kubernetes에 ELK 스택 구성하기
            1. ELK 아키텍처 구성
        3. Elasticsearch 구축
            1. Namespace 생성
            2. Elasticsearch 마스터 노드 생성
            3. Elasticsearch 데이터 노드 생성
            4. Elasticsearch 클라이언트 노드 생성
        4. Logstash 생성
            1. Logstash 구축
        5. Kibana 구축
            1. Kibana 생성
            2. 인덱스 패턴 추가
    
    5. **프로젝트 최종 결과**
    
    1. 서비스 결과 확인
    2. 영상 확인
        1. Scale out
        2. Scale 
        3. 로그 적재 및 대시보드 확인
        

---

# 1. 역할 분담

| Name | Role |
| --- | --- |
| 도효주 | Terraform 리소스 생성(Ansible/Docker) |
| 선우지훈 | Jenkins 모니터링 ELK 클러스터 배포 |
| 오승우 | Terraform 리소스 생성 (Jenkins) |
| 전중석 | Jenkins EKS 배포 및 WAS 구축 |

# 2. Test 환경

### Test VM 설정

| Resource | Configuration |
|---|---|
| CPU | 2 |
| Memory | 2000MB |
| Disk | 20GB |
| OS | Ubuntu/focal |

### 구성 관리 / 배포 도구
| Name | Version |
|---|---|
| Terraform | v1.2.2 on linux_amd64
| | python v2.7.5 필요 |
| AWS CLI | v2.7.7|
| | python (Linux) 3.9.11 |

# 3. 프로젝트 개요

### a. Terraform

CICD를 위한 IaC를 구현하기 위해 Terraform을 사용합니다.

### b. Jenkins를 이용한 WAS CI/CD

![Architecture.png](img/Architecture.png)

CI/CD란 각각의 개발자들의 개발환경을 사용자가 사용 가능한 서비스로 코드를 빌드하고, 테스트하고 배포하는 활동으로 모든 과정을 지속 가능한 형태로 자동화해서 개발자와 사용자 사이의 격차를 없애준다.

## **시나리오**

BackEnd 개발자는 NodeJS를 활용하여 서버를 구축한다. 이때, 서버의 확장성을 고려하여 Docker를 활용하고 있다. 관리 도구로는 Github을 활용하고 있다. 그러나 개발자는 개발 과정에서 수정과 업데이트를 반복할 때마다 서버에도 동시에 Sync 기능을 수행해야만 하는 번거로움이 있었다. 이러한 문제점은 향후, 스케일처리를 위해 예비로 구성된 모든 확장 서버에 개발자가 직접 Sync 처리를 수행해야만한다.

따라서 이번 프로젝트에서는 이를 자동화할 수 있는 방법을 고려하며 Jenkins 사용을 택하기로 했다.

본 프로젝트에서는 이러한 과정들을 자동화 한다.

>💡 배포 테스트
>코드 컴파일 및 빌드
>도커 이미지 빌드
>쿠버네티스 오토 스케일링
>EKS 클러스터 오토 스케일링

</aside>

### c. ELK 로그 모니터링

![Untitled](img/Untitled.png)

Jenkins 모니터링을 위해 ELK 스택을 구축하고 플러그인으로 연동한다. 

Logstash에서 Jenkins에서 빌드 진행시 발생하는 이벤트 로그를 받아 Elasticsearch 데이터 노드에 전송하고, Kibana로 시각화한다.

**전체 프로젝트 구조**

![Untitled](img/Untitled%201.png)

# 5. 프로젝트 진행 과정

### a. **Terraform을 활용한 리소스 생성**

### 1. 아키텍쳐

![Untitled](img/Untitled%202.png)

### 2. Terraform 초기 설정

- **Terraform 명령어 설치**

```bash
$ curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
$ sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
$ sudo apt-get update && sudo apt-get install terraform
```

설치 확인

```bash
$ terraform --version

Terraform v1.1.9
on linux_amd64
```

- **사용자 생성**

AWS 콘솔에서 프로젝트에 사용할 사용자를 생성한다.

**AdministratorAccess** 권한을 부여하여 사용자가 제약 없이 원하는 리소스를 생성할 수 있도록 한다.

- 작업 경로 : EC2 > IAM > 사용자 > 사용자 추가

![스크린샷 2022-06-13 오후 8.48.46.png](img/스크린샷_2022-06-13_오후_8.48.46.png)

 사용자 이름을 지정하고 어떤 방식을 사용하여 AWS에 엑세스 할 것인지 선택한다.

AWS 자격 증명

- 엑세스 키 : AWS CLI에 접속하기 위한 키 (Acess Key, Secret Access Key)
- 암호 : AWS 콘솔에 접속하기 위한 패스워드

![스크린샷 2022-06-13 오후 8.49.49.png](img/스크린샷_2022-06-13_오후_8.49.49.png)

 

- **AWS CLI 설치 및 Profile 구성**

Shell에서도 AWS 명령어를 사용하여 AWS 서비스와 상호 작용하기 위해 AWS 관리 통합 도구인 AWS CLI를 설치한다.

```bash
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$ unzip awscliv2.zip
$ sudo ./aws/install
```

**$ aws configure** 명령어를 사용하여 사용자의 서버에 앞서 생성한 AWS 사용자의 Profile을 등록한다.

```bash
$ aws configure 

AWS Access Key ID [****************]: **[AWS Access Key ID]**
AWS Secret Access Key [****************]: **[AWS Seret Access Key]**
Default region name [us-east-1]: **ap-northeast-2**
Default output format [None]:

$ aws sts get-caller-identity
{
    "UserId": "@@@@@@@@@@@@@@@",
    "Account": "@@@@@@@@@@@@@@@",
    "Arn": "arn:aws:iam::@@@@@@@@@@:user/mursh"
}
```

- **AWS S3 Bucket 생성**

terraform apply 실행 시 생성되는 tfstate 파일을 저장하기 위한 버킷을 생성한다.

원하는 리전을 선택하여 S3 버킷 생성한다.

현재 서울 리전(ap-northeast-2)를 선택하였다.

*주의 : 버킷 이름은 고유해야한다.*

![스크린샷 2022-06-13 오후 8.54.10.png](img/스크린샷_2022-06-13_오후_8.54.10.png)

Terraform에서 구현할 리소스에서 S3에 접근할 수 있도록 퍼블릭 엑세스를 허용한다. 

그 외 설정은 기본 설정을 유지한다.

![스크린샷 2022-06-13 오후 8.54.37.png](img/스크린샷_2022-06-13_오후_8.54.37.png)

생성 완료 한 S3 버킷

![스크린샷 2022-06-13 오후 8.41.26.png](img/스크린샷_2022-06-13_오후_8.41.26.png)

- **pem 키 생성**

Terraform apply를 통해 AWS 리소스를 생성하고자하는 디렉토리에

config 디렉토리를 생성한 후, 해당 디렉토리로 이동한다.

- 현재 진행 중인 프로젝트에서는 *****jenkins-ci* ****디렉토리에서 terraform apply를 실행한다.
- **aws 명령어**를 사용하여 config 디렉토리 아래에  *jenkins.pem* 키를 생성한다.
    - 이 때, 리소스를 생성하고자 하는 리전을 환경변수 **AWS_DEFAULT_REGION**로 지정한다.

```bash
# pem키 생성 + aws에 다운로드 
> cd terraform/jenkins-ci/config
> AWS_DEFAULT_REGION=ap-northeast-2 aws ec2 create-key-pair --key-name jenkins --query 'KeyMaterial' --output text > jenkins.pem
```

### 3. AWS 환경 구축

- **AWS Provider**

사용자가 리소스를 생성할 리전을 지정하고

원하는 버전의 aws 프로바이더를 사용할 수 있도록 설정한다.

`provider.tf`

```bash
 provider "aws" {
  region = "ap-northeast-2"
}

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

}
```

- **IAM**

**Jenkins**

**1 ) Jenkins IAM 정책 생성**

Jenkins 서버에 할당할 **s3 버킷 정책** 생성

앞서 생성한 AWS s3가 s3, ec2, route53 리소스에 대한 정보를 받아올 수 있도록 정책을 할당한다.

`iam-policy.tf`

```bash
resource "aws_iam_policy" "s3_policy" {
  name        = "s3_policy"
  path        = "/"
  description = "s3 policy for Instance "

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "route53:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
```

**2) Jenkins IAM 역할 생성 후 버킷 정책 연결**

‘ec2_role’이라는 역할을 생성한다.

`iam-role.tf`

```bash
resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ec2-role"
  }
}
```

Jenkins IAM 역할과 버킷 정책을 연결한다.

`iam-policy.tf`

```bash
resource "aws_iam_role_policy_attachment" "s3-pol-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}
```

**3) Jenkins IAM 인스턴스 프로파일 생성**

*참고 : 하나의 role 또는 roles를 지정*

```bash
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}
```

**Ansible**

**1 ) Ansible IAM 정책 생성**

앞에서 생성한 Jenkins 서버의 s3 버킷 정책 설정과 동일하게 구성한다.

`iam-policy.tf`

```bash
resource "aws_iam_policy" "docker_jenkins_s3_policy" {
  name        = "docker_jenkins_s3_policy"
  path        = "/"
  description = "s3 policy for Instance "

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "route53:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
```

**2) Ansible IAM 역할 생성 후 버킷 정책 연결**

‘docker_jenkins_ec2_role’이라는 역할을 생성한다.

`iam-role.tf`

```bash
resource "aws_iam_role" "docker_jenkins_ec2_role" {
  name = "docker_jenkins_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ec2-role"
  }
}
```

Ansible IAM 역할과 버킷 정책을 연결한다.

`iam-policy.tf`

```bash
resource "aws_iam_role_policy_attachment" "docker-s3-pol-attach" {
  role       = aws_iam_role.docker_jenkins_ec2_role.name
  policy_arn = aws_iam_policy.docker_jenkins_s3_policy.arn
}
```

**3) Ansible IAM 인스턴스 프로파일 생성**

```bash
resource "aws_iam_instance_profile" "docker_jenkins_ec2_profile" {
  name = "docker_jenkins_ec2_profile"
  role = aws_iam_role.docker_jenkins_ec2_role.name
}
```

- **VPC**

AWS VPC 모듈을 사용하여 public subnet을 생성한다.

현재 프로젝트에서는 10.0.0.0/16 대역에 VPC를 생성했고

가용영역 3개(ap-northeast-2a,b,c) 중 하나의 public subnet에 리소스가 배치될 수 있도록 설정했다.

`vpc.tf`

```bash
module "app_vpc" {

  source = "terraform-aws-modules/vpc/aws"
  name   = "cicd_vpc"
  cidr   = "10.0.0.0/16"

  create_igw = true

  azs = [
    "ap-northeast-2a",
    "ap-northeast-2b",
    "ap-northeast-2c"
  ]

  public_subnets = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

}
```

- **보안그룹**

PORT **22** (SSH) / PORT **8080** (Jenkins) / PORT **80** (HTTP)에 대해 트래픽 인바운드를 개방하고

모든 포트에 대해 아웃바운드를 개방한다.

`security_group.tf`

```bash
resource "aws_security_group" "allow_login" {
  description = "Allow inbound traffic"
  vpc_id      = module.app_vpc.vpc_id

  ingress {
    description = "allow ssh to system"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow ssh to system"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # add the webhook ips and whitelist them
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 4. 서버 생성

인스턴스 구축 시 AWS에서 지원하는 **userdata**를 활용해서 모든 환경이 구축되고 EC2 인스턴스가 시작되는 방식이다.

- 변수 설정

`variable.tf`

```bash
#========================================
# JENKINS SERVER
#========================================

variable "os" { default = "ubuntu" }
variable "ami" { default = "ami-058165de3b7202099" }
variable "instance_type" { default = "t3.small" }
variable "key_name" { default = "jenkins" }
variable "region" { default = "ap-northeast-2" }
variable "project" { default = "jenkins" }
variable "bucketname" { default = "murshibucket1" }
variable "mysystem" { default = "192.168.59.22/32" }

#========================================
# DOCKER SERVER
#========================================

variable "docker_project" { default = "docker" }
```

- **Jenkins EC2 Instance**

앞서 생성했던 엑세스키, 보안그룹, 서브넷 등을 사용하여 EC2 인스턴스를 생성한다.

사용자는 생성된 인스턴스의 public ip를 사용하여 서버에 접속할 수 있다.

`jenkins-ec2.tf` 

```bash
resource "aws_instance" "jenkins" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.allow_login.id]
  subnet_id              = module.app_vpc.public_subnets[0]
  tags = {
    Name = var.project
    OS   = var.os
  }
  user_data = file("jenkins_userdata.sh")
  depends_on = [
    module.app_vpc
  ]
}
```

Jenkins를 사용하는데 필요한 기본 명령어를 설치하여 환경을  CI/CD 환경을 구축한다.

Jenkins와 AWS를 연동하여 사용하기 위해 AWS CLI를 설치하고

git에서 clone 해 온 코드를 war 파일로 패키징할 수 있게 JAVA 및 Maven을 설치한다.

Tomcat에 웹페이지를 올리는 경우 Tomcat system도 설치한다.

`jenkins_userdata.tf`

```bash
#!/bin/bash -xe

# JENKINS 설치
sudo su -
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FCEF32E745F2C3D5
apt-get update

# 임의로 수정한 코드
apt install openssh-server
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get upgrade -yq

# JAVA 설치
apt install openjdk-8-jdk openjdk-8-jre -y
apt-get update
java -version
cat >>~/.bashrc <<EOL

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export PATH="${JAVA_HOME}/bin:${PATH}"
EOL
source ~/.bashrc

# JENKINS 설치 후 방화벽 8080 포트 설정
apt-get install jenkins -y
/bin/systemctl start jenkins
/bin/systemctl status jenkins
/usr/sbin/ufw allow 8080
/usr/sbin/ufw status

# 깃 명령어 설치
apt install git -y
git --version

# pip3 설치
apt install python3-pip -yq

# AWS CLI 설치
pip3 install awscli

# terraform 명령어  설치
apt install unzip
wget -q https://releases.hashicorp.com/terraform/0.11.6/terraform_0.11.6_linux_amd64.zip
unzip terraform_0.11.6_linux_amd64.zip
mv terraform /usr/local/bin/terraform
terraform version

# MAVEN 명령어 설치
apt update
apt install maven -y
mvn -version
cat >>/etc/profile.d/maven.sh <<EOL

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export M2_HOME=/usr/share/maven
export M2=/usr/share/maven/bin
export MAVEN_HOME=/usr/share/maven
export PATH="${M2}:${M2_HOME}:${PATH}"
EOL
chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
mvn -version

# UBUNTU 서울 시간 동기화
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# 혹시 몰라 JENKINS 서비스 재시작
service jenkins restart

# TOMCAT 명령어 설치 및 설정
apt install -y tomcat9 tomcat9-admin
cat >>/etc/tomcat9/tomcat-users.xml <<EOL
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
        <role rolename="manager-gui"/>
        <role rolename="manager-script"/>
        <role rolename="manager-jmx"/>
        <role rolename="manager-status"/>
        <user username="admin" password="P@ssw0rd" roles="manager-gui, manager-script, manager-jmx, manager-status"/>
</tomcat-users>
EOL
service tomcat9 start
systemctl enable tomcat9.service
systemctl restart tomcat9
echo "—— End of Updates ——"
```

- **Docker-Ansible EC2 Instance**

앞서 생성했던 Jenkins EC2 Instance와 동일한 방식으로 생성된다.

두 인스턴스의 차이점 : 생성 시 실행되는 **userdata**의 내용이 다르다.

`jenkins-ec2.tf`

```bash
resource "aws_instance" "docker" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.docker_jenkins_ec2_profile.name
  vpc_security_group_ids = [aws_security_group.allow_login.id]
  subnet_id = module.app_vpc.public_subnets[1]

  tags = {
    Name = var.docker_project
    OS   = var.os
  }

  user_data = file("docker_userdata.sh")

  connection {
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file("/home/vagrant/cicd_terraform/jenkins-ci/config/jenkins.pem")
    timeout     = "1m"
  }

  depends_on = [
    module.app_vpc
  ]
}
```

Jenkins를 사용하여 빌드한 정보를 바탕으로 배포를 진행하기 때문에 Jenkins_userdata와 비슷한 명령어가 설치된다.

하지만 Ansible ec2에는 DockerHub에 이미지 Build / Push / Pull을 하기 위한 docker 명령어, 

EKS를 사용하기 위한 kubernetes-helm, eksctl 명령어를 설치한다.

`docker_userdata.sh`

```bash
#!/bin/bash -xe

sudo su -

# UBUNTU 한국 시간 동기화
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# HOST NAME 설정
hostname docker-host

apt update -y

# 임의로 넣어본 코드
apt install openssh-server -y
DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get upgrade -yq

# JAVA 설치
apt install openjdk-8-jdk openjdk-8-jre -y
apt-get Updates
# 확인
java -version

sudo su - 

cat >>~/.bashrc <<EOL

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
export PATH="${JAVA_HOME}/bin:${PATH}"
EOL

source ~/.bashrc

# 방화벽 열기
/usr/sbin/ufw allow 8080
/usr/sbin/ufw allow 80
/usr/sbin/ufw allow 22
/usr/sbin/ufw status

# 깃 명령어 설치
apt-get update
apt install git -y
git --version

# 파이썬, pip 명령어 설치
apt-get update
apt install python3 -y
apt install python3-pip -y

# AWS CLI 설치
apt-get update
apt install awscli -y

## aws configure access 설정 -> 여기서 AWS 세계여행이 시작됐다,,, 다들 조심해,,
aws configure set default.region 'ap-northeast-2'
aws configure set aws_access_key_id 'AKIA4L67ANECMSPTQIVK' # 사용자 ACCESS KEY
aws configure set aws_secret_access_key 'iMOStydHqtgSssiU5sVPHz+wvt5BQ+XPlXGrVkpP'  # 사용자 SECRET ACCESS KEY

apt-get update

# SSH password 접속 허용으로 변경
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# ANSIBLE 명령어 설치
apt install ansible -y
ansible --version
mkdir /etc/ansible

apt-get update

# DOCKER 명령어 설치
sudo apt install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

service docker start
service docker status

# sudo 없이 docker 명령어 사용
sudo su -
usermod -aG docker ubuntu
systemctl daemon-reload
systemctl restart docker

# kubectl 명령어 설치
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-cache madison kubectl | grep 1.22.8
apt-get install kubectl=1.22.8-00 -y
apt-mark hold kubectl

apt-get update

# OPENSHIFT 명령어 설치
wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar -zvxf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
cd openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit
sudo cp oc /usr/local/bin/
oc version

# kubernetes-helm 설치
wget https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz
tar -zxvf helm-v3.8.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# eksctl 설치
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# aws-iam-authenticator 설치
curl -o aws-iam-authenticator https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
curl -o aws-iam-authenticator.sha256 https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator.sha256
openssl sha1 -sha256 aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
aws-iam-authenticator help

# 혹시 몰라서 시간 한 번 더 동기화
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
echo "----- End of Updates -----"
```

### 5. 생성 정보 확인

- **Output 확인**

terraform apply 후 생성 된 리소스의 data를 기반으로 output을 출력한다.

생성되는 EC2에 접속하기 위해 **생성 된 인스턴스의 ip**를 중점으로 추출한다.

`output.tf`

```bash
#========================================
# JENKINS SERVER
#========================================

# JENKINS ec2 ID
output "jenkins_instance_id" {
  description = " Instance ID of the instance"
  value       = aws_instance.jenkins.id
}

# JENKINS ec2 IP
output "jenkins_instance_ip" {
  description = " Public IP of the instance"
  value       = aws_instance.jenkins.public_ip
}

# JENKINS ec2 sg ID
output "allow_login_id" {
  description = "output allow login security group id"
  value       = ["${aws_security_group.allow_login.id}"]
  # sensitive = true
}

# JENKINS VPC ID
output "jenkins_vpc_id" {
  description = "jenkins_vpc_id"
  value       = module.app_vpc.vpc_id
}

#========================================
# DOCKER SERVER
#========================================

# DOCKER & ANSIBLE & EKS ec2 ID
output "docker_instance_id" {
  description = "docker server instance ID"
  value       = aws_instance.docker.id
}

# DOCKER & ANSIBLE & EKS ec2 IP
output "docker_instance_ip" {
  description = "docker server public IP"
  value       = aws_instance.docker.public_ip
}
```

- **tfstate 파일 업로드**

`$ terraform apply` 시 AWS s3에 tfstate 파일 업로드

서로 다른 디렉토리에 인스턴스가 분포할 때, 글로벌 서비스인 s3를 사용하여 리소스의 정보를 얻어오기 위해 상태 파일을 s3에 업로드한다.

`terraform_state.ft`

```bash
# Apply 시 AWS s3에 tfstate 파일 업로드
terraform {
  backend "s3" {
    encrypt = true
    bucket  = "murshibucket1"
    key     = "deploy-jenkins/terraform.tfstate"
    region  = "ap-northeast-2"
  }
}
```

---

## b. AWS EKS 배포

### **1. YAML 파일을 이용한 Amazon EKS 배포**

Amazon EC2를 Worker 노드로 사용하는 Amazon EKS 클러스터를 생성하기 위한 YAML 파일을 작성하였다. `ap-northeast-2` 지역 내에 `a, b, c`의 가용영역을 사용하며 EC2 인스턴스는 `t3.medium`을 사용한다.

또한 Kubernetes는 OpenID Connet(OIDC) 를 지원하기 때문에, Service Account와 OIDC를 매핑하여 인증절차로 사용할 수 있으며 `iam.withAddonPolicies`를 통해 add-on 정책 또한 정의할 수 있다.

1. 아래의 명령어를 통해, 클러스터를 배포한다.

```bash
eksctl create cluster -f myeks.yaml
```

`myeks.yaml`

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig 

metadata:
  name: myeks
  region: ap-northeast-2
  version: "1.22"

# AZ
availabilityZones: ["ap-northeast-2a", "ap-northeast-2b",  "ap-northeast-2c"]

# IAM OIDC & Service Account
iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: kube-system
      wellKnownPolicies:
        awsLoadBalancerController: true
    - metadata:
        name: ebs-csi-controller-sa
        namespace: kube-system
      wellKnownPolicies:
        ebsCSIController: true
    - metadata:
        name: cluster-autoscaler
        namespace: kube-system
      wellKnownPolicies:
        autoScaler: true

# Managed Node Groups
managedNodeGroups:
  # On-Demand Instance
  - name: myeks-ng1
    instanceType: t3.medium
    minSize: 2
    desiredCapacity: 3
    maxSize: 4
    privateNetworking: true
    ssh:
      allow: true
      publicKeyPath: ./keypair/myeks.pub
    availabilityZones: ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
    iam:
      withAddonPolicies:
        autoScaler: true
        albIngress: true
        cloudWatch: true
        ebs: true

# Fargate Profiles
fargateProfiles:
  - name: fg-1
    selectors:
    - namespace: dev
      labels:
        env: fargate
        
        
# CloudWatch Logging
cloudWatch:
  clusterLogging:
    enableTypes: ["*"]
```

### **2. Amazon EKS의 네트워크 로드 밸런싱**

AWS 로드 밸런서 컨트롤러는 Kubernetes 클러스터의 AWS Elastic Load Balancer를 관리한다. 이 컨트롤러는 리소스를 프로비저닝한다.

- **AWS Load Balancer Controller 추가 기능설치**

아래의 AWS 로드 밸런서 컨트롤러가 Kubernetes용 AWS ALB 수신 컨트롤러의 기능을 대신한다. 따라서 컨트롤러가 현재 설치되어 있는지 추가로 확인해야 한다.

`Helm V3` 이상을 사용하거나 Kubernetes 메니페스트를 적용하여 AWS Load Balancer Controller를 설치한다.

1. `eks-charts` 레포지토리를 추가

```bash
helm repo add eks https://aws.github.io/eks-charts
```

1. 레포지토리 업데이트

```bash
helm repo update
```

1. `cluster-name`과 `image.repository`를 본인의 클러스터 이름과 지역으로 수정하여 실행

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=myeks \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller
```

### **3. Horizontal Pod AutoScaler 배포**

- **Kubernetes Metrics Server 설치**

Kubernets Vertial Pod Autoscaler는 Pod에 대한 CPU 및 메모리 예약을 자동으로 조정하여 애플리케이션의 크기를 적절히 조정할 수 있게 지원한다. 이러한 조정을 통해 클러스터 리소스 사용량을 개선하고 다른 Pod를 위한 CPU 및 메모리를 확보할 수 있다.

>💡 hpa를 사용하기 위해선 Kubernetes Metrics Server 설치가 필수이다.

Kubernets Metrics Server는 클러스터에서 리소스 사용량을 집계하며, 기본적으로 EKS 클러스터에 배포되어 있지 않다.

</aside>

1. Metrics Server 배포

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### **4. Amazon EKS에서 Container Insight 시작 설정**

- **CloudWatch Container Insight**

Amazon CloudWatch는 몇 분 내에 시작할 수 있는 안정적이고 확장 가능하며 유연한 모니터링 솔루션을 제공한다. 따라서 더 이상 자체 모니터링 시스템 및 인프라를 설치, 관리, 확장할 필요가 없다.

```bash
ClusterName=myeks
RegionName=ap-northeast-2
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f -
```

### **5. EKS Cluster Autoscaler**

- **Kubernetes Metrics Server 설치**

자동 크기 조정은 변화하는 요구 사항에 맞게 리소스를 자동으로 확장하거나 축소하는 기능이다. 이는 Kubernetes의 주요 기능이며 Autoscaler를 사용하지 않고 수동으로 수행한다면 많은 인적 자원을 필요로 할 것이다.

1. Cluster Autoscaler YAML 파일 다운

```bash
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

1. YAML 파일 수정

```bash
163: - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/myeks
```

1. YAML 파일 적용

```bash
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```

1. `cluster-autoscaler.kubernetes.io/safe-to-evict` 주석을 Cluster Autoscaler Pod에 추가

```bash
kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
```

1. Cluster Autoscaler 배포 편집

```bash
kubectl -n kube-system edit deployment.apps/cluster-autoscaler
```

```bash
...
- command:
- ./cluster-autoscaler
- --v=4
- --stderrthreshold=info
- --cloud-provider=aws
- --skip-nodes-with-local-storage=false
- --expander=least-waste
- --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/myeks
- --balance-similar-node-groups
- --skip-nodes-with-system-pods=false
image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.22.6
...
```

1. Cluster Autoscaler 이미지 태그를 이전 단계에서 적어 둔 버전으로 설정

```bash
kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.22.2
```

## c. Jenkins를 사용한 NodeJS CI/CD 환경 구성

### **1. 플러그인 설치**

### **Jenkins관리 -> 플러그인 관리**

플러그인 매니저에서 NodeJS Plugin, Publish Over SSH 플러그인을 수동으로 설치해준다.

![2.png](img/2.png)

![3.png](img/3.png)

### 2. 플러그인 설정

### **Jenkins관리 -> 시스템 설정**

Publish over SSH는 jenkins에서 빌드를 마치고, 특정 서버로 배포할 때 사용되는 플러그인이다. SSH 접속을 위해서는 User ID와 비밀번호 또는 개인키/공개키가 필요하다.

![5.png](img/5.png)

### **Jenkins관리 -> Global Tool Configuration**

NodeJS 탭에서 프로젝트에 사용되는 Node Version을 선택한다.

Node Version은 `node -v` 명령어로 확인이 가능하다.

![4.png](img/4.png)

### **새로운 Item -> Freestyle project**

4개의 Password Parameter를 설정하였다.

- PASS(Docker HUB의 Password에 해당)
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- S3_BUCKET
- 

![6.png](img/6.png)

소스 코드 관리 탭에서 GitHub 주소와 브랜치를 입력한다.

![8.png](img/8.png)

GitHub hook trigger for GITScm polling에 체크한다.

빌드 환경에서 Provide & npm bin/ folder to PATH 체크한 뒤에 Global Tool Configuration에서 생성했던 Node 버전 설정을 선택한다.

Poll SCM은 Jenkins에서 도메인을 등록하여 Push 상태 시 자동 배포가 아닌 특정 시간마다 깃 변경 사항을 확인하는 방법이다. 테스트를 위해 매 분마다 변경사항을 확인하도록 하였다.

![9.png](img/9.png)

![10.png](img/10.png)

시스템 설정에서 설정한 Publish over SSH를 선택한다.

첫번째 Transfers의 경우 nodejs의 폴더 내의 파일들을 원격 전송한다.

두번째 Transfers의 경우 docker build와 kubernetes deploy가 적용된 YAML파일을 실행한다.

![11.png](img/11.png)

## d. 관리형 데이터베이스 및 Amazon S3

### **1. MongoDB Atlas 설정**

MongoDB Atlas는 MongoDB를 설계한 사람들이 만든 모든 것을 관리하는 클라우드 데이터베이스이다. AWS, Azure, GCP를 통해 배포에 관한 모든 것을 통합해 주는 시스템이다.

주요 특징으로는 클러스터가 자동으로 Scale-out하고, 자동 회복 기능이 있어서 fault-tolerant하다.

1. 원하는 클라우드의 사양과 리전을 선택한다.

![12.png](img/12.png)

2. Connect 버튼을 누르고 NodeJS와의 연결을 위해 `Connection your application`을 선택한다.

![13.png](img/13.png)

3. 코드 복사 후 `<username>:<password>`를 본인의 정보로 교체 후 사용한다.

![14.png](img/14.png)

### **2. Amazon S3 설정**

Amazon S3는 데이터를 버킷 내의 객체로 저장하는 스토리지 서비스이다. 버킷 내에는 이미지가 저장이 된다.

버킷 정책은 아래와 같다.

```json
{
		"Version": "2012-10-17",
		"Id": "Policy1655074292789",
		"Statement": [
		{
				"Sid": "Stmt1655074284421",
				"Effect": "Allow",
				"Principal": {
						"AWS": "arn:aws:iam::385722565672:user/realmytrip"
				},
				"Action": "s3:GetBucketPolicy",
				"Resource": "arn:aws:s3:::realmytrip"
				}
		]
}
```

### e. WAS(**웹 애플리케이션 서버) 구축**

### **1. NodeJS 웹 애플리케이션 서버**

> [https://github.com/ddung1203/CICD_Project/tree/jeonj/nodejs](https://github.com/ddung1203/CICD_Project/tree/jeonj/nodejs)


'자유여행 가이드 투어 서비스'라는 목표로 진행되었던 프로젝트이다. 메인 페이지, 로그인/회원가입, 사용자 관리페이지, 투어 등록 및 확인, 예약 확인 등의 기능을 가진다.

NodeJS, Express.js를 사용하여 최신 브라우저에서 사용이 가능하다.

### **2. 웹 애플리케이션 서버 구축**

이미지는 node를 위한 컨테이너로 `node:14`을 선택하고, `package.json`의 의존성 설치를 완료한 뒤 COPY하고 실행될 수 있도록 구성한다.

`Dockerfile`

```yaml
FROM node:14

WORKDIR / 

COPY package.json .
RUN npm install
COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]
```

이미지를 생성하고 Docker Hub에 이미지를 저장한다. 형상관리를 위해 도커 이미지 뒤에 태그를 `BUILD_NUMBER`로 설정하였다.

`docker_build_and_push.yaml`

```yaml
- hosts: ansible_host
  gather_facts: no

  tasks:
    - name: Login to Docker Hub
      docker_login:
        username: ddung1203
        password: "{{ lookup('env', 'PASS') }}"
        reauthorize: yes

    - name: Build and Push Image
      docker_image:
        build:
          path: /home/ubuntu/nodejs/
        name: ddung1203/node-js
        tag: "{{ lookup('env', 'BUILD_NUMBER') }}"
        push: yes
        source: build
```

Container를 생성한다. Docker Hub 내에 저장된 이미지를 불러들인 후 Deployment를 생성한다. `containers.resources`는 추후 hpa의 Autoscaling에 사용될 예정이다.

여기서 `state: absent`는 CI/CD 구현 과정에서 orphan된 `replica.set`을 지워주는 역할을 한다.

`kube_deploy.yaml`

```yaml
- hosts: ansible_host
  gather_facts: no
 
  tasks:
    - name: Destroy Deployment
      k8s:
        state: absent
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: node-js
            namespace: default
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: node-js
            template:
              metadata:
                labels:
                  app: node-js
              spec:
                containers:
                  - name: node-js
                    image: "ddung1203/node-js:{{ lookup('env', 'BUILD_NUMBER') }}"
                    imagePullPolicy: Always
                    ports:
                      - containerPort: 3000
                    resources:
                      requests:
                        cpu: 500m
                        memory: 500M
                      limits:
                        cpu: 800m
                        memory: 800M

    - name: Create Deployment
      k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: node-js
            namespace: default
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: node-js
            template:
              metadata:
                labels:
                  app: node-js
              spec:
                containers:
                  - name: node-js
                    image: "ddung1203/node-js:{{ lookup('env', 'BUILD_NUMBER') }}"
                    imagePullPolicy: Always
                    ports:
                      - containerPort: 3000
                    resources:
                      requests:
                        cpu: 500m
                        memory: 500M
                      limits:
                        cpu: 800m
                        memory: 800M
```

일반 LoadBalancer와 다르게 3줄의 annotations이 추가로 작성되어있다.

**service.beta.kubernetes.io/aws-load-balancer-type**

- external: AWS 로드 밸런서 컨트롤러가 Network Load Balancer를 생성하도록 하는 원인

**service.beta.kubernetes.io/aws-load-balancer-nlb-target-type** 

- instance: EC2 타겟
- ip: Pod 타겟(Fargate)

**service.beta.kubernetes.io/aws-load-balancer-scheme**

- internal: 내부
- internet-facing: 외부

`kube_deploy.yaml`

```yaml
- name: Create Service
      k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: node-js-lb
            namespace: default
            annotations:
             service.beta.kubernetes.io/aws-load-balancer-type: "external"
             service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
             service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          spec:
            type: LoadBalancer
            selector:
              app: node-js
            ports:
              - port: 80
                targetPort: 3000

    - command: kubectl apply -f /home/ubuntu/nodejs/hpa.yaml
```

`hpa.yaml`

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
	name: node-js
spec:
	scaleTargetRef:
		apiVersion: apps/v1
		kind: Deployment
		name: node-js
			minReplicas: 1
			maxReplicas: 20
			targetCPUUtilizationPercentage: 50
```

### e. Jenkins 이벤트 로그 모니터링

### **1.** Jenkins 설정

- **플러그인 설치**

Jenkins에서 빌드 진행시 발생하는 로그를 보내기 위해 먼저 플러그인을 설치한다. 

Jenkins에서 발생하는 이벤트 로그는 다음과 같다.

- 프로젝트 생성 ( job이 생성, 삭제, 수정되었을 때 )
- Job 실행 (build가 시작되거나 끝났을 경우)
- Job step execution ( job에서 각 스탭이 시작, 끝날 경우)
- SCM Checkout (job이 소스 관리 툴에서 부터 파일을 체크아웃 받을 때)

이번 프로젝트에서는 Job이 실행됐을 때 즉 빌드 이벤트만 받아서 적재하기로 했다.

먼저 플러그인 매니저에서 Static Gatherer 플러그인을 수동으로 설치해준다.

![Untitled](img/Untitled%203.png)

- **플러그인 설정**

플러그인 설치가 완료되면, Jenkins 관리 > 환경 설정에서 다음과 같이 설정할 수 있는 창을 볼 수 있다.

![Untitled](img/Untitled%204.png)

위 캡쳐 화면에 보이는 설정은 Statistics Gatherer Plugin이 Logstash HTTP 입력 플러그인으로 HTTP 메세지를 보낼 수 있도록 설정 한 것이다.

Logstash 주소는 앞서 설정한 Logstash Service의 로드밸런서 주소를 입력한다.  주소 마지막에 /jenkins-build/ 를 입력해 어떤 이벤트 타입 정보가 Logstash 필터로 전송되게 하는지 추가적인 정보를 제공한다.

HTTP 메세지를 전송하기 위해서는 Addvanced Settings에서 “Enable HTTP publishing?” 옵션을 반드시 체크해야 한다. 

![Untitled](img/Untitled%205.png)

다음과 같이 설정하고 저장하면 빌드를 실행할 때 마다 로그를 받을 수 있게 된다.

### 2. Kubernetes에 ELK 스택 구성하기

- **ELK 아키텍처 구성**

![elk.svg](img/elk.svg)

1. Namespace

EKS 클러스터 내에서 ELK 리소스들을 효율적으로 관리하기 위해 논리적 분리 단위인 `elk` 네임 스페이스를 생성했다.  이후 생성되는 모든 리소스들은 `namespace` 단위로 구분된다.

1. Elasticsearch

저장은 `ElasticSearch`가 담당한다. ElasticSearch는 Lucene 기반의 검색 엔진이며, HTTP 웹 인터페이스와 schema에서 자유로운 JSON 문서와 함께 분산 multi-tenent 지원 전문 검색 엔진을 제공한다.

Elasticsearch 클러스터에는 `마스터 노드` 1개와 `데이터 노드` 2개 , `클라이언트 노드` 1개로 총 4개의 노드로 구성되어 있다. 

`마스터노드`와 `클라이언트 노드`는 `Deployment` 방식으로 배포하여 `Pod`들을 관리하고,  데이터의 저장을 담당하는 `데이터 노드는` `Statefulset` 방식으로 생성하여 클러스터가 삭제되어도 데이터를 영구 보존할 수 있도록 설계했다.

마지막으로 Service는 `ClusterIP` 형태의 서비스로 구성하여 노드 간 통신은 가능하도록 구성했다..

1. Kibana

Kibana를 통해 저장된 데이터를 `분석`하고 `시각화`한다. ElasticSearch에 저장된 `로그 데이터`에 대한 `Index 패턴`을 생성하고 `대시보드`를 통해 실시간 모니터링 서비스를 구성한다. 로드밸런서 타입의 서비스를 생성하여 외부에서 접근이 가능했고, 로드밸런서 주소의 80번 포트로 접근하면 Kibana 클러스터에 접근할 수 있도록 구성했다.

1. Logstash

`Deployment` 방식으로 `Logstash Pod`를 배포하고 `Jenkins Statistic gaterer` 플러그인의 사용을 위해 로드밸런서 타입의 서비스로 배포하였다. 

Jenkins 이벤트 로그를 Logstash로 수집하고, 로그에 대한 ETL 로직은 Logstash의 `파이프 라인`을 이용한다.

Logstash 파이프 라인 중 Filter 플러그인을 사용하여 정제하도록 구성했다.. Logstash의 로그는 `Message`라는 필드안에 한번에 들어오게 된다. 메세지 필드만 저장해도 되지만 추후 원활한 Kibana를 이용한 시각화를 위해 로그를 구분하여 각각의 `필드를 재생성`하는 필터를 추가한다.

이후 정제된 로그를 Elasticsearch `데이터 노드`에 저장한다.

### 3. Elasticsearch 구축

- **Namespace 생성**

 > `namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
    name: elk
```

- **elasticsearch 마스터 노드 생성**
1. ConfigMap 생성

> `elasticsearch-master-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elk
  name: elasticsearch-master-config
  labels:
    app: elasticsearch
    role: master
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}
    network.host: 0.0.0.0
    node:
      master: true
      data: false
      ingest: false
    xpack.security.enabled: false
    xpack.monitoring.collection.enabled: false
```

Elasticsearch 설정 값을 가진 `ConfigMap`을 생성한다. 클러스터의 이름과 노드의 이름과 노드의 리스트를 통해 host를 찾도록 설정하고 `master: true` 옵션을 통해 마스터 노드로 생성한다.

1. Service 생성

> `elasticsearch-master-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  namespace: elk
  name: elasticsearch-master
  labels:
    app: elasticsearch
    role: master
spec:
  ports:
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: master
```

마스터 노드에 대한 svc를 생성한다. 9300번 포트로 각 노드들과 통신할 수 있도록 설정했다.

1. Deployment 생성

> `elasticsearch-master-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elk
  name: elasticsearch-master
  labels:
    app: elasticsearch
    role: master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
      role: master
  template:
    metadata:
      labels:
        app: elasticsearch
        role: master
    spec:
      nodeSelector:
        Master: Node 
      containers:
      - name: elasticsearch-master
        image: docker.elastic.co/elasticsearch/elasticsearch:7.10.2
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-master
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: "ES_JAVA_OPTS"
          value: "-Xms500m -Xmx500m"
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: storage
          mountPath: /data
      volumes:
      - name: config
        configMap:
          name: elasticsearch-master-config
      - name: "storage"
        emptyDir:
          medium: ""
      initContainers:
      - name: increase-vm-max-map
        image: busybox
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
```

Deployment로 Pod를 배포한다. Elasticsearch 7.10.2 버전을 사용하고, ES_JAVA_OPTS 를 500m로 설정했다. 

EKS의 es-master 노드 그룹에 배치하도록 `nodeSelector` 옵션을 추가하여 스케줄링 한다.

- **elasticsearch 데이터 노드 생성**
1. ConfigMap 생성

> `elasticsearch-data-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elk
  name: elasticsearch-data-config
  labels:
    app: elasticsearch
    role: data
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}
    network.host: 0.0.0.0
    node:
      master: false
      data: true
      ingest: false
    xpack.security.enabled: false
    xpack.monitoring.collection.enabled: false
```

`data: true` 옵션을 통해 데이터를 저장하는 노드로 설정한다.

1. Service 생성

> `elasticsearch-data-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  namespace: elk
  name: elasticsearch-data
  labels:
    app: elasticsearch
    role: data
spec:
  ports:
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: data
```

1. Statefulset생성

> `elasticsearch-data-statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  namespace: elk
  name: elasticsearch-data
  labels:
    app: elasticsearch
    role: data
spec:
  serviceName: "elasticsearch-data"
  selector:
    matchLabels:
      app: elasticsearch-data
      role: data
  replicas: 2
  template:
    metadata:
      labels:
        app: elasticsearch-data
        role: data
    spec:
      nodeSelector:
        Data: Node 
      containers:
      - name: elasticsearch-data
        image: docker.elastic.co/elasticsearch/elasticsearch:7.10.2
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-data
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: "ES_JAVA_OPTS"
          value: "-Xms500m -Xmx500m"
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: elasticsearch-data-persistent-storage
          mountPath: /data/db
        imagePullPolicy: Always
      volumes:
      - name: config
        configMap:
          name: elasticsearch-data-config
      initContainers:
      - name: increase-vm-max-map
        image: busybox
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
  volumeClaimTemplates:
  - kind: PersistentVolumeClaim
    metadata:
      name: elasticsearch-data-persistent-storage
      annotations:
        volume.beta.kubernetes.io/storage-class: "gp2"
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

`Statefulset`으로 `Pod`를 배포한다. PVC 템플릿을 이용해서 elasticsearch-data-persistent-storage라는 이름의 pvc를 생성한다.

- **elasticsearch 클라이언트 노드 생성**
1. ConfigMap 생성

> `elasticsearch-data-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elk
  name: elasticsearch-client-config
  labels:
    app: elasticsearch
    role: client
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}
    network.host: 0.0.0.0
    node:
      master: false
      data: false
      ingest: true
    xpack.security.enabled: false
    xpack.monitoring.collection.enabled: false
```

`ingest: true` 옵션을 사용해 클라이언트 노드로 설정한다.

1. Service 생성

> `elasticsearch-data-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  namespace: elk
  name: elasticsearch-client
  labels:
    app: elasticsearch
    role: client
spec:
  ports:
  - port: 9200
    name: client
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: client
```

1. Deployment 생성

> `elasticsearch-client-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elk
  name: elasticsearch-client
  labels:
    app: elasticsearch
    role: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
      role: client
  template:
    metadata:
      labels:
        app: elasticsearch
        role: client
    spec:
      nodeSelector:
        Client: Node
      containers:
      - name: elasticsearch-client
        image: docker.elastic.co/elasticsearch/elasticsearch:7.10.2
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-client
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: "ES_JAVA_OPTS"
          value: "-Xms500m -Xmx500m"
        ports:
        - containerPort: 9200
          name: client
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: storage
          mountPath: /data
      volumes:
      - name: config
        configMap:
          name: elasticsearch-client-config
      - name: "storage"
        emptyDir:
          medium: ""
      initContainers:
      - name: increase-vm-max-map
        image: busybox
        command: ["sysctl", "-w", "vm.max_map_count=262144"]
        securityContext:
          privileged: true
```

### 4. Logstash 생성

- **logstash 구축**
1. ConfigMap 생성

> `logstash-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
  namespace: elk
data:
  # logstash conf
  logstash.yml: |
    http.host: "0.0.0.0"
    path.config: /usr/share/logstash/pipeline
    config.reload.automatic: true
# logstash pipeline
  logstash.conf: |
    input {
      tcp {
        port => 5000
      }
    }
    filter {
      if [message] =~ "ciUrl" {
        mutate {
          gsub => ["message", "[\"/{}]", ""]
        }
        kv {
          field_split => ","
          value_split => ":"
        }
        mutate {
          remove_field => [ "port","@version","host","message" ]
        } # mutate end
      }
      else {
        drop{}
      }
        mutate {
          convert => {
            "duration" => "integer"
            "executor" => "integer"
            "queueTime" => "integer"
            "startTime" => "integer"
            "number" => "integer"
            "endTime" => "integer"
          }
         }
    }
    output {
      stdout {
        codec => rubydebug
      }
      elasticsearch {
          hosts => "http://elasticsearch-client.elk.svc.cluster.local:9200"
          index => "jenkins_log-%{+YYYY.MM.dd}"
          codec => "json"
          timeout => 120    
      }
    }
```

Logstash 설정 값을 가진 `ConfigMap`을 생성한다. `logstash.yml` 설정파일에 `config.reload.automatic: true` 옵션으로 만약 설정 파일이 변경되면 자동으로 Logstash를 재시작 하도록 설정했다.

`logstash.conf`는 로그 데이터의 파이프 라인 설정 파일이다. 

> `Input`

```yaml
    input {
      tcp {
        port => 5000
      }
    }
```

먼저 Input 설정을 통해 TCP 5000번 포트로 로그를 받아오도록 설정한다.

> `filter`

```yaml
filter {
      if [message] =~ "ciUrl" {
        mutate {
          gsub => ["message", "[\"/{}]", ""]
        }
        kv {
          field_split => ","
          value_split => ":"
        }
        mutate {
          remove_field => [ "port","@version","host","message" ]
        } # mutate end
      }
      else {
        drop{}
      }
        mutate {
          convert => {
            "duration" => "integer"
            "executor" => "integer"
            "queueTime" => "integer"
            "startTime" => "integer"
            "number" => "integer"
            "endTime" => "integer"
          }
         }
    }
```

`Filter` 설정을 통해 로그 데이터를 정제할 수 있다. 

Jenkins로부터 오는 로그 중 빌드 관련 로그 만을 받기 위해 if / else 문으로 메세지 필드에 ciUrl 이 존재하지 않는 필드는 버리도록 설정했다.

빌드 로그에서 필요 없는 특수 문자를 제거하고 콤마(,)를 기준으로 값을 나누어 각각의 필드로 저장하고 Key:value 의 형태로 데이터를 변환하도록  설정했다.  이후 Kibana 에서 원활한 분석 및 시각화를 위해 `Convert` 플러그인으로 일부 필드의 `데이터 타입`을 `Integer` 형태로 변환하였다.

> `output`

```yaml
output {
      stdout {
        codec => rubydebug
      }
      elasticsearch {
          hosts => "http://elasticsearch-client.elk.svc.cluster.local:9200"
          index => "jenkins_log-%{+YYYY.MM.dd}"
          codec => "json"
          timeout => 120    
      }
    }
```

이후 Elasticsearch에 Json 형태로 저장되도록 output을 설정했다.

1. Service 생성

> `log-svc-loadbalancer.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: logstash
  namespace: elk
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: logstash
```

Jenkins 플러그인에서 Logstash의 http 주소가 필요하기 때문에 로드밸런서 타입으로 서비스를 배포하고 80번 포트로 요청이 들어오면 Logstash의 5000 포트로 요청이 전송되도록 설정했다.

1. Deployment 생성

> `logstash-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  namespace: elk
spec:
  replicas: 1
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash

    spec:
      nodeSelector:
        Name: logstash
      volumes:
        - name: logstash-config-volume
          configMap:
            name: logstash-config
            items:
              - key: logstash.yml
                path: logstash.yml
        - name: logstash-pipeline-volume
          configMap:
            name: logstash-config
            items:
              - key: logstash.conf
                path: logstash.conf
      containers:
        - name: logstash
          image: docker.elastic.co/logstash/logstash:7.10.2
          imagePullPolicy: Always
          resources:
            limits:
              cpu: 2000m
              memory: 2Gi
            requests:
              cpu: 1500m
              memory: 1.5G
          env:
            - name: LS_JAVA_OPTS
              value: '-Xmx512m -Xms512m'
          ports:
            - name: tcp
              containerPort: 5000
              protocol: TCP
          volumeMounts:
            - name: logstash-config-volume
              mountPath: /usr/share/logstash/config

            - name: logstash-pipeline-volume
              mountPath: /usr/share/logstash/pipeline
```

nodeSelector 옵션으로 EKS logstash 노드 그룹으로 스케줄링 되도록 설정한다. 이후 Pod의 리소스를 설정하고 Logstash 컨테이너 포트를 5000번으로 변경한다. 마지막으로 앞서 설정했던 파이프라인 파일을 volumeMounts 옵션을 통해 마운트 한다.

### 5. Kibana 구축

- **kibana 생성**
1. ConfigMap 생성

> `kibana-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elk
  name: kibana-config
  labels:
    app: kibana
data:
  kibana.yml: |-
    server.host: 0.0.0.0
    elasticsearch:
      hosts: ${ELASTICSEARCH_HOSTS}
```

1. Service 생성

> `kibana-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  namespace: elk
  name: kibana
  labels:
    app: kibana
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: webinterface
    targetPort: 5601
  selector:
    app: kibana
```

1. Deployment 생성

> `kibana-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elk
  name: kibana
  labels:
    app: kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      nodeSelector:
        Name: Kibana
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.10.2
        ports:
        - containerPort: 5601
          name: webinterface
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch-client.elk.svc.cluster.local:9200"
        volumeMounts:
        - name: config
          mountPath: /usr/share/kibana/config/kibana.yml
          readOnly: true
          subPath: kibana.yml
      volumes:
      - name: config
        configMap:
          name: kibana-config
```

- **인덱스 패턴 추가**

데이터 처리 및 분석을 위한 시각화를 만들기 전에 Kibana에 `인덱스 패턴`을 설정해야 한다. 인덱스 패턴은 검색 및 분석을 실행하는 `Elasticsearch Index`를 식별하거나 필드를 설정하는데 사용한다. 인덱스 패턴은 여러 인덱스에 대응할 수 있는 선택적 `와일드 카드`를 포함한 문자열이다.

![Untitled](img/Untitled%206.png)

Kibana에 접속해서 `Discover` 탭에 들어가면 새로운 인덱스 패턴을 추가할 수 있다. 

![Untitled](img/Untitled%207.png)

인덱스 패턴을 `jenkins_log-*`로 설정한다.

![Untitled](img/Untitled%208.png)

# 6. 프로젝트 최종 결과

## 1. 서비스 확인

- Horizontal Pod AutoScaling, EKS Cluster AutoScaling, WAS

CloudWatch Insight의 사용으로 설정이나 유지 관리가 필요 없이 클라우드 규모에서 상호작용적인 쿼리 및 시각화를 제공하게 된다.

![18.png](img/18.png)

초기 kubectl get all, kubectl get nodes 상태

![21.png](img/21.png)

부하 생성

```bash
while true;do curl http://k8s-default-nodejslb-503c341ca4-ae8bf41485a9c468.elb.ap-northeast-2.amazonaws.com; done
```

시간이 지남에 따라 Pod의 개수가 증가하고, EKS Cluster의 개수 또한 증가했다.

hpa는 `TARGETS=50%/50%`을 넘지 않기 위해 Pod를 생성한다. 따라서 Pod 중간에 `Pending` 상태의 Pod가 존재하는 것이다. 이 Pod는 EKS Cluster가 추가되면 Scale-up이 될 예정이다.

![22.png](img/22.png)

부하 종료 후  Pod의 개수가 `MINPODS=1`로 설정되었기 때문에 1로 줄었다. 일정시간이 지나면 EKS Cluster의 개수도 Pod와 마찬가지로 감소가 되었음을 확인할 수 있다.

![24.png](img/24.png)

또한 웹 애플리케이션 서버 또한 정상적으로 접속이 가능하다.

![20.png](img/20.png)

- Logstash Pipeline

![Untitled](img/Untitled%209.png)

Jenkins에서 Build with Parameters를 클릭하여 빌드를 진행한다.

![Untitled](img/Untitled%2010.png)

빌드 이벤트 로그가 성공적으로 적재된 것을 알 수 있다.

- Kibana 대시보드

![Untitled](img/Untitled%2011.png)

time field를 timestamp로 설정하고 생성 버튼을 누르면 성공적으로 인덱스 패턴이 생성된다.

![Untitled](img/Untitled%2012.png)

인덱스 패턴이 생성되면 Kibana의 Discovery 탭에서 실시간으로 들어오는 로그들을 확인 할 수 있다.

![Untitled](img/Untitled%2013.png)

Elasticsearch에 인덱싱 되어있는 데이터들은 기본으로 제공되는 REST API를 통해서 조회할 수 있고 JSON 형태로 결과가 나오기 때문에 이를 가지고 다양하게 시각화를 할 수도 있다. 

# AS IS, TO BE

AS IS 

- Terraform을 활용한 IaC 구현
- Node.js를 활용한 WAS 배포
- ELK 스택 구축
    - Logstash로 이벤트 로그 받아 Kibana로 시각화

TO BE

- Open Distro 플러그인을 활용하여 현재 시간부터 2분 이내에 들어본 빌드 로그의 result에 따라 Slack에 알람 전송
- GitHub Repository를 private으로 설정하여 배포 코드 보안 강화
