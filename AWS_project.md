#  AWS 클라우드에서 고가용성 Wordpress 서비스 배포

> https://github.com/jeonjungseok/cloud-mini-project 에서도 확인할 수 있습니다.


>  EC2(Security Group ...), EBS, VPC, ELB, Autoscaling, S3, RDS, CloudFront 등 사용/적용할 수 있는 기술을 구현 가능한 영역까지 설계 및 구현

> Architecture
<img src="img/Mini_Project 1.png">

> 적용 기술
>- Amazon Elastic Compute Cloud(EC2)
>
>- Amazon Elastic Block Store(EBS)
>
>- Amazon Virtual Private Cloud(VPC)
>
>- Amazon Relational Database Service(RDS
>
>- AWS Elastic Load Balancer(ELB)
>
>- AWS Autoscaling
>
>- Wordpress httpd-2.4.6-97, php-7.4
>
>- MariaDB-server-10.2.43-1
>```
We recommend servers running version 7.4 or greater of PHP and mySQL version 5.7 OR MariaDB version 10.2 or greater.
We also recommend either Apache or Nginx as the most robust options or running WordPress, but neither is required.
>```

<br>


## 목차
* [정보](#정보)

* [적용 기술](#적용%20기술)

* [특징](#특징)

* [설정](#설정)
	* [1. VPC](#1.%20VPC)
			<br>1.1 VPC 생성
	* [2. 보안그룹](#2.%20보안그룹)
			<br>2.1 보안그룹 생성
			<br>2.2 public subnet 설정
			<br>2.3 private subnet 설정
			<br>2.4 rds private subnet 설정
	* [3. EC2 생성](#3.%20EC2%20생성)
		  <br>3.1 Bastion Host 생성
			<br>3.2 private EC2 생성
	* [4. private EC2 접속](#4.%20private%20EC2%20접속)
			<br>4.1 private EC2 접속
	* [5. Amazon RDS](#5.%20Amazon%20RDS)
			<br>5.1 RDS 생성
			<br>5.2 AWS EC2, RDS 연결
	* [6. AWS ELB](#6.%20AWS%20ELB)
			<br>6.1 AWS ELB 생성
			<br>6.2 AWS ELB 구동 확인
	* [7. Auto Scaling](#7.%20Auto%20Scaling)
			<br>7.1 Auto Scaling 설정


* [사용](#사용)

<br>

## 정보

- 프로젝트 기간: 2022년 4월 6일 ~ 4월 8일

- 목적: AWS 클라우드에서 고가용성 Wordpress 서비스 배포

<br>

## 적용 기술

- Amazon Elastic Compute Cloud(EC2)

- Amazon Elastic Block Store(EBS)

- Amazon Virtual Private Cloud(VPC)

- Amazon Relational Database Service(RDS)

- AWS Elastic Load Balancer(ELB)

- AWS Autoscaling

```
We recommend servers running version 7.4 or greater of PHP and mySQL version 5.7 OR MariaDB version 10.2 or greater.
We also recommend either Apache or Nginx as the most robust options or running WordPress, but neither is required.
```
- Wordpress httpd-2.4.6-97, php-7.4

- MariaDB-server-10.2.43-1

<br>

## 특징

- 서버와 네트워크, 프로그램 등의 정보 시스템이 오랜 기간 동안 지속적으로 정상 운영이 가능하도록 고가용성을 목표로 한다.

- 내부와 외부 네트워크 사이에서 게이트웨이 역할을 수행하는 베스천 호스트(Bastion Host)를 적용하여 내부 네트워크를 겨냥한 공격에 대해 방어하도록 구축하였다.

- Amazon RDS로, 자동으로 프라이머리 데이터베이스 DB 인스턴스를 생성하고 동시에 다른 AZ의 인스턴스에 데이터를 복제한다. 이로써 자동으로 대기 인스턴스로 장애 조치하도록 한다.

<br>

## 설정

### 1. VPC

Amazon VPC(Virtual Private Cloud)는 클라우드 내의 논리적인 가상공간이다. AWS에서 나만의 작업공간을 구축하기 위해서 처음으로 VPC를 생성해야 한다. 

#### 1. 1 VPC 생성

1. VPC 메뉴 검색
<img src="img/Pasted image 20220408141631.png">

2. VPC 마법사 시작
<img src="img/Pasted image 20220408141814.png">

3. VPC 설정
<br>
<img src="img/Pasted image 20220408142027.png">

> IPv4는 총 32비트의 숫자로 구성된다. 이 중 사용 가능한 공간은 3,706,452,992개로 충분하지 않다. 이의 해결책은 Private Network(사설망)이다. Private Network는 하나의 Public IP를 여러 기기들가 공유할 수 있는 방법이다. 하나의 망에는 Private IP를 부여받은 기기들과 Gateway로 구성된다.

> Classless Inter Domain Routing(CIDR)란, 여러개의 사설망을 구축하기 위해 망을 나누는 방법이다. IP는 주소의 영역을 여러 네트워크 영역으로 나누기 위해 IP를 묶는 방식이다. <br>VPC의 CIDR블록을 10.0.0.0/16 으로 설정하는 것을 추천한다.

> VPC 마법사로 VPC, 인터넷 게이트웨이, 서브넷, 라우팅테이블 생성 및 설정이 가능하다.

### 2. 보안그룹
보안그룹이란 인스턴스에 대한 인바운드 및 아웃바운드 트래픽을 제어하는 가상 방화벽 역할을 하는 장치이다. 보안그룹은 인스턴스 수준에서 작동하며 VPC에 있는 서브넷의 각 인스턴스를 서로 다른 보안그룹으로 지정할 수 있다. <br>
현재까지 VPC내의 3개분류(public, private, rds),  6개의 서브넷이 존재한다.  각각의 분류는 고가용성 및 로드밸런싱을 위해 2개씩 제작을 하였다.


#### 2.1 보안그룹 생성
보안그룹의 이름만 설정하여 비어있는 보안그룹을 생성한다.
1. 보안 그룹 생성

<img src="img/Pasted image 20220408144815.png">

2. 비어있는 보안그룹(public-sg, private-sg, rds-private-sg) 생성

<img src="img/Pasted image 20220408144943.png">
<img src="img/Pasted image 20220408145036.png">
<img src="img/Pasted image 20220408145123.png">
#### 2.2 public subnet 설정
public subnet은 외부인터넷의 연결이 되어있는 서브넷이다. 해당 서브넷 내에 인스턴스를 생성 할 것이고 인스턴스 접근을 위해서는 SSH 접속이 가능해야한다. 그리고 모든 TCP 통신에 대해서 private-sg와 rds-private-sg도 허용해야한다.

<img src="img/Pasted image 20220408145943.png]]																>

#### 2.3 private subnet 설정
private subnet의 경우 public-sg와 rds-private-sg에서 오는 트래픽에 대해서만 인바운드 규칙에 추가해주면 된다.

<img src="img/Pasted image 20220408150341.png">

#### 2.4 rds-private subnet 설정
rds private subnet은 DB포트에 대해서만 인바운드 규칙을 추가해주면 된다.

<img src="img/Pasted image 20220408150509.png">

이렇게 인바운드 규칙에 다른 보안그룹을 추가하게 되면 인바운드 규칙에 포함된 보안그룹의 서비스들 통과할 수 있게 된다. 이 경우의 이점은 Auto-Scailing시 인스턴스가 추가될 경우 별도로 보안그룹에 해당 인스턴스의 IP를 인바운드 규칙으로 등록할 필요가 없다.

### 3. EC2 생성
#### 3.1 Bastion Host 생성
Bastion Host란 내부와 외부를 연결하는 게이트웨이 역할을 하는 인스턴스로써 인가되지 않은 IP는 Private 망에 접속할 수 없을 뿐더러, 방화벽의 역할을동시에 수행하는 것이다. Bastion Host를 통해서만 시스템 담당자는 Private 망에 있는 서버와 DB등에 접근이 가능하다.

1. Bastion Host 생성

<img src="img/Pasted image 20220408152329.png">

<img src="img/Pasted image 20220408152354.png">

> 참고. 키 페어 생성 및 적용 <br>
_퍼블릭 키와 프라이빗 키로 구성되는 키 페어는 Amazon EC2 인스턴스에 연결할 때 자격 증명 입증에 사용하는 보안 자격 증명 집합이다. Amazon EC2는 퍼블릭 키를 인스턴스에 저장하며 프라이빗 키는 사용자가 저장한다. Windows 인스턴스의 경우 관리자 암호를 복호화하려면 프라이빗 키가 필요하다. 그런 다음 복호화된 암호를 사용하여 인스턴스에 연결한다. 프라이빗 키를 소유하는 사람은 누구나 인스턴스에 연결할 수 있으므로 보안된 위치에 프라이빗 키를 저장해 두는 것이 중요하다._
>
>1. 키 페어 가져오기
<img src="img/Pasted image 20220408152517.png">
> 2. 키 페어 가져오기 실행
<img src="img/Pasted image 20220408152601.png">
> 3. EC2 생성 시 키 페어 선택
<img src="img/Pasted image 20220408152646.png">


#### 3.2 private EC2 생성
private EC2 내에 httpd, Wordpress, mySQL 설치를 위해 기본 EC2를 생성 후 AMI 이미지를 생성하여 private EC2를 생성하겠다. 이후의 이 AMI는 Autoscaling에서도 사용될 예정이다.
* wget, wordpress 접속, mySQL 연결을 위해 임시로 포트를 개방
<img src="img/Pasted image 20220408154648.png">

<br>

설치과정은 [이전 프로젝트](https://github.com/jeonjungseok/linux-mini-project)를 참고하였다. 


```
PS C:\Users\jeonj> ssh ec2-user@34.207.236.149
[ec2-user@ip-172-31-22-50 ~]$ sudo -s
[root@ip-172-31-22-50 ec2-user]# yum -y install httpd

[root@ip-172-31-22-50 ec2-user]# amazon-linux-extras enable php7.4
[root@ip-172-31-22-50 ec2-user]# yum -y install php-cli php-common php-gd php-mbstring php-mysqlnd php-fpm php-xml php-opcache php-zip

[root@ip-172-31-22-50 ec2-user]# vim /etc/yum.repos.d/MariaDB.repo
[root@ip-172-31-22-50 ec2-user]# yum -y install MariaDB-server MariaDB-client

[root@ip-172-31-22-50 ec2-user]# wget https://wordpress.org/latest.tar.gz
[root@ip-172-31-22-50 ec2-user]# file latest.tar.gz
[root@ip-172-31-22-50 ec2-user]# tar -xvzf latest.tar.gz -C /var/www/html

[root@ip-172-31-22-50 ec2-user]# mkdir /var/www/html/wordpress/uploads

```

위 코드 실행 후 화면은 아래와 같다. 정상적으로 설치가 잘 되었으니, AMI 이미지를 생성 후 해당되는 EC2를 지우겠다.


<img src="img/Pasted image 20220408162837.png">

### 4. private EC2 접속
private EC2로 접속하기 위해 경유 서버를 이용한 목적서버를 연결해야 한다. SSH 프록시/터널링을 사용하는 이유는 아래와 같다.
1. 간이 VPN이 필요할 때
2. 여러 안전하지 않은 통신 프로토콜을 안전하게 연결하고 싶을때
3. 서버가 접근 IP 를 제한하거나 방화벽/공유기 뒤에 있어서 직접 연결이 불가능 할때
4. 사용하는 데스크탑/노트북이 Public IP를 가지고 있지 않을 때 임시로 서비스를 운용하고 싶을때.
5. 다른 서버를 이용해서 최종 서버에 ssh 연결하고 싶을때
6. 다른 프록시나 tor 망을 경유해서 접속하고 싶을때

보통 5번을 점프 호스트라 부른다. 접속을 위해서는 아래와 같이 사용한다.

<img src="img/Pasted image 20220409100459.png">

이는 내부 네트워크와 연결되어 있으나, 외부에서 접근하기 위해서는 내부 네트워크의 다른 서버를 경유해서 이용해야하는 경우에 사용한다. 

  
### 5. Amazon RDS
RDS란 Amazon Relational Database Service로 클라우드에서 관계형 데이터베이스를 간편하게 사용할 수 있도록 아마존에서 관리하는 서비스를 말한다. 하드웨어 프로비저닝, DB설정, 패치, 백업과 같은 관리를 아마존에서 자동으로 해주기 때문에 사용자는 Application 개발에 집중할 수 있게 해준다.<br>
RDS의 내부 구조는 EC2와 EBS로 구성되어있다. 따라서 RDS 생성시 EC2의 타입과 EBS의 용량을 설정할 수 있게 된다.

#### 5.1 RDS 생성
<img src="img/Pasted image 20220408162136.png">
<img src="img/Pasted image 20220408162216.png">
<img src="img/Pasted image 20220408162226.png">
<img src="img/Pasted image 20220408162253.png">

> RDS에서는 고가용성 구성이 가능하다. MULTI-AZ 기능은 DB의 이중화 구성을 하는 것으로 RDS 생성 시 RDS가 위치하게 될 서브넷 그룹을 설정 하게 된다. 이때 서브넷 그룹은 서로 다른 Availibily Zone에 위치하게끔 설정 하고 이렇게 설정한 서브넷 그룹에 RDS의 Primary와 Standby가 위치하게 된다.   
따라서 평상시에는 Primary가 db서비스를 제공하고 있으며 Primary와 Standby는 Sync형태로 동기화를 지속적으로 진행 한다. 그리고 장애가 발생하거나 DB문제가 생길 경우 Standby를 Primary로 변경키는 FAILOVER를 AWS에서 자동으로 진행 해주게 된다.   
RDS는 기본적으로 엔드포인트라는 DNS를 이용하기 때문에 FAILOVER시에도 Application에서의 작업은 필요하지 않다. 엔드포인트는 FAILOVER의 경우도 그대로 유지되기 때문이다. 그리고 유저가 Standby DB로는 접근이 불가능 하다.<br>
_* 위 프로젝트는 프리티어로, 이중화 구성을 따로 하지 않았음._

#### 5.2 AWS EC2, RDS 연결
엔드포인트 및 포트를 보면 아래와 같다.
<img src="img/Pasted image 20220409101301.png">

 Private EC2에 접속해서 아래 코드를 작성한다.
 - EC2에서 RDS 엔드포인트로 접속한 후, Wordpress에서 사용할 데이터베이스를 생성한다.
 ```
[ec2-user@ip-10-0-154-150 ~]$ mysql -u admin -p -h myproject-rds.chngbcqv7tcf.us-east-1.rds.amazonaws.com
Enter password:

MySQL [(none)]> CREATE DATABASE wordpress;
Query OK, 1 row affected (0.01 sec)

MySQL [(none)]>  CREATE USER adminuser@'%' IDENTIFIED BY 'dkagh1.';
Query OK, 0 rows affected (0.00 sec)

MySQL [(none)]> GRANT ALL PRIVILEGES ON wordpress.* TO adminuser@'%';
Query OK, 0 rows affected (0.01 sec)

MySQL [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MySQL [(none)]> exit
Bye
```
 
 - wp-config.php 내에 DB관련 정보를 설정한다. 이어서 [여기](https://api.wordpress.org/secret-key/1.1/salt/)에 접속 해서, the Authentication Unique Keys and Salts를 설정한다.
```
[root@ip-172-31-22-50 ec2-user]# cd /var/www/html/wordpress
[root@ip-172-31-22-50 wordpress]# cp wp-config-sample.php wp-config.php
[root@ip-172-31-22-50 wordpress]# chown -R apache:apache /var/www/html/wordpress


[root@ip-172-31-22-50 wordpress]# vim wp-config.php
	
  define( 'DB_NAME', 'wordpress' );
  /** Database username */
  define( 'DB_USER', 'adminuser' );
  /** Database password */
  define( 'DB_PASSWORD', 'dkagh1.' );
  /** Database hostname */
  define( 'DB_HOST', 'myproject-rds.chngbcqv7tcf.us-east-1.rds.amazonaws.com' );
	
	define('AUTH_KEY',         '');
	define('SECURE_AUTH_KEY',  '');
	define('LOGGED_IN_KEY',    '');
	define('NONCE_KEY',        '');
	define('AUTH_SALT',        '');
	define('SECURE_AUTH_SALT', '');
	define('LOGGED_IN_SALT',   '');
	define('NONCE_SALT',       '');
```

### 6. AWS ELB
#### 6.1 AWS ELB 생성
ELB(Elastic Load Balancer)란 트래픽의 분산을 통해 부하를 줄여주는 기능을 한다. AWS에서는 ELB를 통해 로드밸런싱을 하여 다량의 트래픽에도 서버가 죽지않도록 관리해주는 고가용성 역할을 하게된다. 

이번에는 ELB를 생성하여 아파치에 접속하고 실제 로드밸런싱이 제대로 이루어지고 있는지 확인해보자.

로드 밸런서 생성을 클릭한다.
<img src="img/Pasted image 20220409104128.png">

LoadBanlancing에는 3가지가 있다.

-   ALB(Application Load Balancer): HTTP 및 HTTPS 트래픽을 사용하는 웹 애플리케이션을 위한 유연한 기능이 필요한 경우 사용
-   NLB(Network Load Balancer): 애플리케이션에 초고성능, 대규모 TLS 오프로딩, 중앙 집중화된 인증서 배포, UDP에 대한 지원 및 고정 IP 주소가 필요한 경우 사용
-   GLB(Gateway Load Balancer): GENEVE를 지원하는 타사 가상 어플라이언스 플릿을 배포 및 관리해야 할 경우 사용

HTTP 통신을 해야하니 ALB로 선택한다.

<img src="img/Pasted image 20220409104238.png">

이름 입력
<img src="img/Pasted image 20220409105013.png">

VPC 선택 및 만들어 놓은 public 가용영역 선택한다. **가용영역은 반드시 public으로 설정한다.**
<img src="img/Pasted image 20220409105032.png">

새 보안 그룹 생성 및 라우팅 대상 생성은 다음 그림과 같다.
<img src="img/Pasted image 20220409105049.png">

public-sg, private-sg, 그리고 본인 IP를 작성하였다.<br>
_본인 IP로 접속을 위해 _
<img src="img/Pasted image 20220409114702.png">

<img src="img/Pasted image 20220409104720.png">
<img src="img/Pasted image 20220409104812.png">



#### 6.2 AWS ELB 구동 확인
> **대상그룹의 Health check 및 로드밸런싱 테스트**  
  	ELB 생성이 끝나게 되면 ELB는 대상그룹에 포함한 인스턴스가 정상적으로 작동 하고 있는지 Health check를 하게 된다. <br>모니터링 화면을 보면 unhealthy가 나오는 것을 확인할 수 있다. <br>
> 최초 elb를 생성할때 만들었던 alb-sg는 private-sg와 public-sg가 모두 인바운드 규칙에 포함되어 있어 통신이 가능하지만 ap가 있는 private-sg는 alb-sg를 인바운드에 추가하지 않았기 때문에 접근 자체가 불가능 하다.
> 따라서 private-sg의 인바운드 규칙에 alb-sg를 추가시켜줘야한다.

> Health check 내에서 [301에러](https://linuxtut.com/en/f799c0ad7d85b7d60f01/)는 페이지가 리디렉션 되었음을 의미한다. 따라서 이와 같이 대상그룹을 수정해준다.
> <img src="img/Pasted image 20220409110617.png">


AWS ELB를 구동하기 위해서 이전에 만든 alb-sg에 80번 포트에 대해서 본인의 IP를 인바운드 규칙에 추가해 주도록 한다.
<img src="img/Pasted image 20220409110524.png">

Health check을 하면 다음과 같다.
<img src="img/Pasted image 20220409113700.png">

### 7. Auto Scaling
AWS Auto Scaling은 애플리케이션을 모니터링하고 용량을 자동으로 조정하여, 최대한 저렴한 비용으로 안정적이고 예측 가능한 성능을 유지한다. 장점은 아래와 같다.
- 규모 조정을 신속하게 설정
- 규모 조정 의사 결정
- 자동으로 성능 유지
- 필요한 만큼만 지불

AWS Auto Scaling의 작동방식은 아래 그림과 같다.
<img src="img/Pasted image 20220409120542.png">

<br>

#### 7.1 Auto Scaling 설정
새 시작 템플릿에 시작 탬플릿 생성을 클릭한다.
<img src="img/Pasted image 20220409111016.png">

AMI는 [3.2 private EC2 생성](#3.2%20private%20EC2%20생성)에서 생성한 AMI를 선택한다.
<img src="img/Pasted image 20220409112110.png">

마지막 설정까지 끝내고 시작 탬플릿 생성을 한다.
<img src="img/Pasted image 20220409112524.png">
 
 생성한 탬플릿을 기준으로 Auto Scaling 그룹을 생성한다.
 <img src="img/Pasted image 20220409112634.png">
 
 다음
 <img src="img/Pasted image 20220409112710.png">
 
 EC2는 사설영역에 구성되기 때문에 Private 으로 선택한다.
 <img src="img/Pasted image 20220409112741.png">
 
 [6.1 AWS ELB 생성](#6.1%20AWS%20ELB%20생성)에서 생성한 로드 밸런서에 연결한다.
 <img src="img/Pasted image 20220409112828.png">
 
 조정 정책은 다음과 같이 설정하였다. 이후 CPU에 부하를 주어 그룹의 크기를 확인할 것이다.
 <img src="img/Pasted image 20220409113107.png">

## 사용
정상적으로 접속이 가능하다.

<img src="img/Pasted image 20220409115118.png">

<br>

CPU 부하로 AutoScaling을 확인하겠다. <br>
CPU 부하는 private ec2에 접속하여 `sha256sum /dev/zero` 으로 부하를 생성하겠다.

<img src="img/Pasted image 20220409115402.png">

<br>

부하를 생성하니, 이와 같이 Auto Scaling 그룹에서 인스턴스가 추가되었다.

<img src="img/Pasted image 20220409121424.png">
<img src="img/Pasted image 20220409120715.png">
<img src="img/Pasted image 20220409121227.png">

<br>

부하를 멈추고 일정시간 대기 후 이와 같이 인스턴스가 제거되었다.

<img src="img/Pasted image 20220409122856.png">
<img src="img/Pasted image 20220409122840.png">