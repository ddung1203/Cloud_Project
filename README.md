# 리눅스 미니 프로젝트 - Wordpress 게시판

## 개요

>분리된 WEB, DB, DNS(Master, Slave) 서버를 통해 Wordpress 게시판 구현
>https 프로토콜로 암호화하여 보안성 강화

## 요구사항 
>We recommend servers running version 7.4 or greater of PHP and ySQL version 5.7 OR MariaDB version 10.2 or greater.
>We also recommend either Apache or Nginx as the most robust options or running WordPress, but neither is required.

## 서버 구축 설정
>기본값: SELinux 설정 off
>```
>[root@server ~]# setenforce 0
>[root@server ~]# getenforce 0
>Permissive
>```

## DB 서버
>
>#### 기존 MariaDB 삭제 및 MariaDB 10.2이상 설치
>```
>[root@db ~]# yum remove mariadb
>[root@db ~]# yum -y install MariaDB-server MariaDB-client
>Complete!
>```
>```
>[root@db ~]# vim /etc/yum.repos.d/MariaDB.repo
>	[mariadb]
>	name = MariaDB
>	baseurl = https://mirror.yongbok.net/mariadb/yum/10.2/centos7-amd64
>	gpgkey=https://mirror.yongbok.net/mariadb/yum/RPM-GPG-KEY-MariaDB
>	gpgcheck=1
>```
>
>#### MariaDB 포트 허용 및 방화벽 설정
>```
>[root@db ~]# systemctl start mariadb.service
>[root@db ~]# systemctl enable mariadb.service
>[root@db ~]# /usr/bin/mysql_secure_installation
>
>Enter current password for root (enter for none):
>OK, successfully used password, moving on...
>
>Set root password? [Y/n] y
>New password:
>Re-enter new password:
>Remove anonymous users? [Y/n] y
>Disallow root login remotely? [Y/n] n
>Remove test database and access to it? [Y/n] y
>Reload privilege tables now? [Y/n] y
>```
>
>```
>[root@db ~]# firewall-cmd --permanent --zone=public --add-port=3306/tcp
>success
>[root@db ~]# firewall-cmd --reload
>success
>[root@db ~]# firewall-cmd --list-all
>public (active)
>  target: default
>  icmp-block-inversion: no
>  interfaces: enp0s3 enp0s8
>  sources:
>  services: dhcpv6-client ssh
>  ports: 3306/tcp
>  protocols:
>  masquerade: no
>  forward-ports:
>  source-ports:
>  icmp-blocks:
>  rich rules:
>```
>
>#### Wordpress 사용할 데이터베이스 설정
>```
>[root@db ~]# mysql -u root -p 1
>
>MariaDB [(none)]> CREATE DATABASE wordpress;
>MariaDB [(none)]> CREATE USER adminuser@'%' IDENTIFIED BY 'dkagh1.';
>MariaDB [(none)]> GRANT ALL PRIVILEGES ON wordpress.* TO adminuser@'%' IDENTIFIED BY 'dkagh1.';
>MariaDB [(none)]> FLUSH PRIVILEGES;
>MariaDB [(none)]> exit
>```


## 웹 서버
>
>#### 웹 서버 설치
>```
>[root@server ~]# yum -y install httpd
>```
>
>#### 방화벽 정책 추가
>```
>[root@server ~]# firewall-cmd --add-service=http
>success
>[root@server ~]# firewall-cmd --add-service=http --permanent
>success
>[root@server ~]# firewall-cmd --list-all
>public (active)
>  target: default
>  icmp-block-inversion: no
>  interfaces: enp0s3 enp0s8
>  sources:
>  services: dhcpv6-client http ssh
>  ports:
>  protocols:
>  masquerade: no
>  forward-ports:
>  source-ports:
>  icmp-blocks:
>  rich rules:
>```
>
>#### php7.4 이상 설치 및 기존 php5.4 종료
>```
>[root@server ~]# yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
>Complete!
>[root@server ~]# yum-config-manager --disable remi-php54
>[root@server ~]# yum-config-manager --enable remi-php74
>[root@server ~]# yum -y install php74-php php-cli php74-scldevel php php-mysql
>Complete!
>```
>
>#### Wordpress 게시판 다운로드
>```
>[root@server ~]# yum -y install wget
>[root@server ~]# wget https://wordpress.org/latest.tar.gz
>[root@server ~]# file latest.tar.gz
>[root@server ~]# tar -xvzf latest.tar.gz -C /var/www/html
>[root@server ~]# mkdir /var/www/html/wordpress/uploads
>```
>
>#### Wordpress 구성
>```
>[root@server ~]# cd /var/www/html/wordpress
>[root@server wordpress]# cp wp-config-sample.php wp-config.php
>[root@server wordpress]# chown -R apache:apache /var/www/html/wordpress
>[root@server wordpress]# vim  wp-config.php
>	define( 'DB_NAME', 'wordpress' );
>	/** Database username */
>	define( 'DB_USER', 'adminuser' );
>	/** Database password */
>	define( 'DB_PASSWORD', '1' );
>	/** Database hostname */
>	define( 'DB_HOST', '192.168.56.118' );
>```

## DNS 서버
>
>#### DNS 서버 구성
>```
>[root@master ~]# yum -y install bind bind-utils
>[root@master ~]# nmcli con add con-name static ifname enp0s3 type ethernet ip4 10.0.2.10/24 gw4 10.0.2.1 ipv4.dns 10.0.2.10
>연결 'static' (d7cb0ec5-d0c9-42aa-92e2-380b89d4dd3f)이 성공적으로 추가되었습니다.
>[root@master ~]# nmcli con reload
>[root@master ~]# nmcli con up static
>연결이 성공적으로 활성화되었습니다 (D-Bus 활성 경로: /org/freedesktop/NetworkManager/ActiveConnection/5)
>```
>
>#### 정방향 조회 구성
>```
>[root@master ~]# vim /etc/named.conf
>	options {
>        listen-on port 53 { any; };
>        listen-on-v6 port 53 { none; };
>				...	
>        allow-query     { any; };
>	...
>	zone "jeonj.exam.com" IN {
>        type master;
>        file "jeonj.exam.com.zone";
>	};
>[root@master ~]# cd /var/named
>[root@master named]# cp named.empty jeonj.exam.com.zone
>[root@master named]# vim jeonj.exam.com.zone
>	$TTL 3H
>	@       IN SOA  jeonj.exam.com. root.jeonj.exam.com. (
>                                        0       ; serial
>                                        1D      ; refresh
>                                        1H      ; retry
>                                        1W      ; expire
>                                        3H )    ; minimum
>        	NS      dns.jeonj.exam.com.
>        	A       10.0.2.2
>	dns     A       10.0.2.10
>	db      A       192.168.56.118
>	server  A       10.0.2.2
>
>[root@master named]# chmod 660 jeonj.exam.com.zone
>[root@master named]# chown :named jeonj.exam.com.zone
>```
>
>#### 정방향 조회 구성 확인
>```
>[root@master named]# systemctl enable named --now
>Created symlink from /etc/systemd/system/multi-user.target.wants/named.service to /usr/lib/systemd/system/named.service.
>[root@master named]# firewall-cmd --add-service=dns --permanent
>success
>[root@master named]# firewall-cmd --reload
>
>[root@master named]# host db.jeonj.exam.com
>db.jeonj.exam.com has address 192.168.56.118
>```
>
>#### 역방향 조회 구성
>```
>[root@master named]# vim /etc/named.conf
>	zone "56.168.192.in-addr.arpa" IN {
>        	type master;
>        	file "192.168.56.0.zone";
>	};
>	...
>	/*
>	zone "2.0.10.in-addr.arpa" IN {
>        	type master;
>        	file "10.0.2.0.zone;
>	};
>	*/
>[root@master named]# vim /etc/named.conf
>[root@master named]# cp jeonj.exam.com.zone 192.168.56.0.zone
>[root@master named]# vim 192.168.56.0.zone
>	$TTL 3H
>	@       IN SOA  jeonj.exam.com. root.jeonj.exam.com. (
>                                        	0       ; serial
>                                        	1D      ; refresh
>                                        	1H      ; retry
>                                        	1W      ; expire
>                                        	3H )    ; minimum
>	        NS      dns.jeonj.exam.com.
>        	A       192.168.56.2
>	118     PTR     db.jeonj.exam.com.
>	117     PTR     server.jeonj.exam.com.
>
>[root@master named]# chmod 660 192.168.56.0.zone
>[root@master named]# chown :named 192.168.56.0.zone
>```
>#### 역방향 조회 구성 확인
>```
>[root@master named]# systemctl restart named
>[root@master named]# systemctl enable named
>[root@master named]# host 192.168.56.118
>118.56.168.192.in-addr.arpa domain name pointer db.jeonj.exam.com.
>```

## DNS 서버 Master/Slave 구성
>
>#### Master 구성
>```
>[root@master named]# vim /etc/named.conf
>	zone "jeonj.exam.com" IN {
>        	type master;
>        	file "jeonj.exam.com.zone";
>        	allow-transfer { 10.0.2.101; };
>	};
>
>	zone "56.168.192.in-addr.arpa" IN {
>        	type master;
>        	file "192.168.56.0.zone";
>        	allow-transfer {10.0.2.101; };
>	};
>
>[root@master named]# vim /var/named/jeonj.exam.com.zone
>	$TTL 3H
>	@       IN SOA  jeonj.exam.com. root.jeonj.exam.com. (
>                                        	0       ; serial
>                                        	1D      ; refresh
>                                        	1H      ; retry
>                                        	1W      ; expire
>                                        	3H )    ; minimum
>        	NS      dns.jeonj.exam.com.
>        	NS      slave.jeonj.exam.com.
>        	A       10.0.2.2
>	dns     A       10.0.2.10
>	db      A       192.168.56.118
>	server  A       192.168.56.117
>	slave   A       10.0.2.101
>
>[root@master named]# vim 192.168.56.0.zone
>	$TTL 3H
>	@       IN SOA  jeonj.exam.com. root.jeonj.exam.com. (
>                                        	0       ; serial
>                                        	1D      ; refresh
>                                        	1H      ; retry
>                                        	1W      ; expire
>                                        	3H )    ; minimum
>        	NS      dns.jeonj.exam.com.
>        	NS      slave.jeonj.exam.com.
>        	A       192.168.56.2
>	118     PTR     db.jeonj.exam.com.
>	117     PTR     server.jeonj.exam.com.
>```
>
>#### Slave 구성
>```
>[root@slave ~]# yum -y install bind bind-utils
>Complete!
>[root@slave ~]# nmcli con add con-name static ifname enp0s3 type ethernet ip4 10.0.2.101/24 ipv4.dns 10.0.2.10
>연결 'static' (730f987d-717a-40ff-9f3f-c579562fdd3c)이 성공적으로 추가되었습니다.
>[root@slave ~]# nmcli con reload
>[root@slave ~]# nmcli con up static
>연결이 성공적으로 활성화되었습니다 (D-Bus 활성 경로: /org/freedesktop/NetworkManager/ActiveConnection/5)
>[root@slave ~]# vim /etc/named.conf
>	options {
>        	listen-on port 53 { any; };
>        	listen-on-v6 port 53 { none; };
>	...
>        	allow-query     { any; };
>	...
>
>	zone "jeonj.exam.com" IN {
>        	type slave;
>        	masters { 10.0.2.10; };
>        	file "slaves/jeonj.exam.com.zone";
>        	notify no;
>	};
>
>	zone "2.0.10.in-addr.arpa" IN {
>        	type slave;
>        	masters { 10.0.2.10; };
>        	file "slaves/10.0.2.0.zone";
>        	notify no;
>	};
>```
>
>#### Master/Slave 구성 조회
>```
>[root@slave ~]# systemctl enable named --now
>[root@slave ~]# firewall-cmd --add-service=dns --permanent
>	success
>[root@slave ~]# firewall-cmd --reload
>	success
>
>[root@slave ~]# ls /var/named/slaves/
>	jeonj.exam.com.zone
>```
>##### 혹은
>```
>[root@slave ~]# more /var/log/messages
>...
>Mar 17 16:26:49 localhost named[4804]: transfer of 'jeonj.exam.com/IN' from 10.0.2.10#53: connected using 10.0.2.101#45448
>Mar 17 16:26:49 localhost named[4804]: zone jeonj.exam.com/IN: transferred serial 0
>Mar 17 16:26:49 localhost named[4804]: transfer of 'jeonj.exam.com/IN' from 10.0.2.10#53: Transfer status: success
>Mar 17 16:26:49 localhost named[4804]: transfer of 'jeonj.exam.com/IN' from 10.0.2.10#53: Transfer completed: 1 messages, 7
>records, 201 bytes, 0.004 secs (50250 bytes/sec)
>...
>```
>
>#### Client 구성
>```
>[root@server ~]# nmcli con add con-name static ifname enp0s3 type ethernet ip4 10.0.2.20/24 gw4 10.0.2.2 ipv4.dns 10.0.2.10
>연결 'static' (431c562f-b00b-4a2b-8323-aabd959c2dd2)이 성공적으로 추가되었습니다.
>[root@server ~]# nmcli con mod static +ipv4.dns 10.0.2.101
>[root@server ~]# nmcli con reload
>[root@server ~]# nmcli con up static
>연결이 성공적으로 활성화되었습니다 (D-Bus 활성 경로: /org/freedesktop/NetworkManager/ActiveConnection/5)
>```
>
>#### Client 조회
>```
>[root@server ~]# host dns.jeonj.exam.com
>dns.jeonj.exam.com has address 10.0.2.10
>```

## https 설정
>#### ssl 패키지 설치
>```
>[root@server ~]# yum -y install mod_ssl
>[root@server ~]# openssl genrsa -out private.key 2048
>Generating RSA private key, 2048 bit long modulus
>..................................................................+++
>.............................................................+++
>e is 65537 (0x10001)
>[root@server ~]# openssl req -new -key private.key -out cert.csr
>	Country Name (2 letter code) [XX]:kr
>	State or Province Name (full name) []:seoul
>	Locality Name (eg, city) [Default City]:city
>	Organization Name (eg, company) [Default Company Ltd]:jeonj
>	Organizational Unit Name (eg, section) []:computer
>	Common Name (eg, your name or your server's hostname) []:jeonj
>	Email Address []:jeonj@jeonj
>
>[root@server ~]# openssl x509 -req -signkey private.key -in cert.csr -out cert.crt
>	Signature ok
>	subject=/C=kr/ST=seoul/L=city/O=jeonj/OU=computer/CN=joenj/emailAddress=jeonj@jeonj
>	Getting Private key
>
>[root@server ~]# chmod 600 private.key cert.crt
>
>[root@server ~]# mv private.key /etc/pki/tls/private/
>[root@server ~]# mv cert.* /etc/pki/tls/certs/
>```
>
>#### .conf 변경
>```
>[root@server ~]# vim /etc/httpd/conf.d/ssl.conf
>	...
>	DocumentRoot "/var/www/html"
>	ServerName server.jeonj.exam.com:443
>	...
>	SSLCertificateFile /etc/pki/tls/certs/cert.crt
>	SSLCertificateKeyFile /etc/pki/tls/private/private.key
>	...
>[root@server ~]# vim /etc/httpd/conf/httpd.conf
>	<VirtualHost *:80>
>    	DocumentRoot /var/www/html
>    	ServerName jeonj.exam.com
>    	RewriteEngine On
>    	RewriteCond %{HTTPS} off
>    	RewriteRule ^(.*)$https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
>	</VirtualHost>
>
>[root@server ~]# systemctl restart httpd
>
>[root@server ~]# firewall-cmd --add-service=https --permanent
>success
>[root@server ~]# firewall-cmd --reload
>success
>```

# 프로젝트 결과

## DB 데이터베이스 및 테이블 조회
><img src=/img/db_1.png>
><img src=/img/db_2.png>
## 웹 서버 구동
><img src=/img/server_1.png>

### HTTPS 확인
><img src=/img/https_1.png>

## DNS 서버 구동
><img src=/img/dns_1.png>

### Master/Slave 구동
><img src=/img/ms_1.png>
><img src=/img/ms_2.png>
