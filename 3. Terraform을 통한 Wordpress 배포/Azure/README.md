


**1. 프로젝트 개요**
**2. 프로젝트 과정**
**3. 결과** 

---
### 1. 프로젝트 개요
---

1.1 프로젝트 목적
Ansible과 Terraform을 이용해 Azure에 Wordrpress 자동화 배포를 위한 아키텍처 설계와 구성까지 진행함으로써 다양한 서비스를 경험하며 이해하는것을 목표로 함

1.2. 프로젝트 환경

| 사용 도구 | 설명 | 
|:----------:|:----------:|
| Ansible | wordpress환경 자동화를 위한 playbook 작성 | 
| Terraform | 인프라 관리 |
| MariaDB | Database |

-----------------------
| 패키지 | 버전 | 
|:-------:|:-----:|
| Ubuntu | 18.04 - LTS |
| python | 	version 2.7.5	|
| MariaDB |	version 10.3	|
| Wordpress | version 5.9.3	|
| php		|version 7.4 이상|
<br>
<br>



1.3 아키텍처 설계

![](https://velog.velcdn.com/images/luna_0917/post/16e0acc2-f6ba-486f-80a6-e0b031862449/image.png)



## 2. 프로젝트 과정


### 2.1 Terraform 작성

### `provider.tf`

- azurerm : 프로바이더 이름
- source : 프로바이더 종류
```bash
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"  # 3.0.2버전 이상을 의미
    }
  }

  required_version = ">= 1.1.0" # 최소 요구 버전
}
```
**_provider block 필수 작성 부분_**
```
provider "azurerm" {
  features {}
}
```


### `main.tf`
- network와 security 부분은 따로 분류하여 작성함
- random_pet : 임의로 이름 생성
- random_id : 고유 식별자로 사용하기 위한 난수 생성
```bash
resource "random_pet" "rg-name" {  
  prefix    = var.resource_group_name_prefix # 이름에 붙일 문자열
}

resource "azurerm_resource_group" "rg" {
  name      = random_pet.rg-name.id       # 리소스에 사용히는 이름
  location  = var.resource_group_location # 리소스 그룹이 존재해야하는 Azure지역
}
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8  #생성할 임의의 바이트 수
}
```

#### Azure 스토리지 계정 관리
- name : Azure 서비스 전체에서 유일해야함
- account_tier : 스토리지 계정에 사용할 계층
- account_replication_type : 스토리지 계정에 사용할 복제 유형 정의
``` bash
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

### `network.tf`

- address_space : 가상 네트워크에서 사용되는 주소 공간
- address_prefix : 서브넷에 사용할 주소 접두사

```bash
# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create public subnet
resource "azurerm_subnet" "pubsubnet" {  # bastion을 위한 public 서브넷
  name                 = "pubsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"] # 사용할 주소 접두사
}
# Create private1 Subnet
resource "azurerm_subnet" "private1_subnet" { # wordpress를 위한 private 서브넷
  name                 = "prisubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.Sql"] # 서브넷과 연결할 서비스 앤드포인트
}

# Create public IPs : 기존 공용 IP주소들에 대한 정보에 접근
resource "azurerm_public_ip" "pub_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"   # 공용 IP 주소 할당 유형
  }

# Create private1 IPs
resource "azurerm_public_ip" "private1_ip" {
  name                = "myPrivateIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create network interface : 네트워크 인터페이스 관리
resource "azurerm_network_interface" "pubnic" {
  name                = "pubNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     =azurerm_subnet.pubsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          =azurerm_public_ip.pub_ip.id
  }
}

# Create network interface  private1
resource "azurerm_network_interface" "private1nic" {
  name                = "private1NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "priv1_ipconfig"
    subnet_id                     = azurerm_subnet.private1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.private1_ip.id
  }
}
```
### `vm.tf`
- bastion과 wordpress를 위한 virtual machine 생성

```bash
# create VM for bastion
resource "azurerm_linux_virtual_machine" "bastionmvm" { #리눅스 VM
  name                  = "bastionVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids =[azurerm_network_interface.pubnic.id]
  size                  = "Standard_DS1_v2"
  os_disk {		#os_disk 구성
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"  #버전 20.04는 에러 발생
    version   = "latest"
  }
  computer_name                   = "bastion"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # ssh key 경로 지정
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
# 부팅 진단을 저장하는데 사용해야하는 Azure Storage 계정의 기본 엔드포인트
}
}

# Create VM for Wordpress : wordpress를 위해 사용할 vm 생성
resource "azurerm_linux_virtual_machine" "wp" {
  name                  = "wpVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.private1nic.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "mywpDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  computer_name                   = "wp"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # 접속을 위한 ssh key 경로 설정
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
```
#### MariaDB 서버
```bash
#Create Mariadb_serever 
resource "azurerm_mariadb_server" "maria" {
  name                         = "jeonj-mariadb-server-7" # 유일해야 한다
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  administrator_login          = "adminuser" # MariaDB 서버에 대한 관리자 로그인
  administrator_login_password = "dkagh1234."
  version                      = "10.3" # 사용중인 MariaDB 버전
  ssl_enforcement_enabled      = false # SSL 인증 해제
  sku_name = "GP_Gen5_2"	# mariadb 서버의 SKU 이름
}

# wordpress-config.php파일과 동일한 데이터로 작성해야 함
resource "azurerm_mariadb_database" "myDatabase-7" {
  name                = "wordpress"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}
resource "azurerm_mariadb_virtual_network_rule" "mariaVnetRule" {
  name                = "mariadb-vnet-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  subnet_id           = azurerm_subnet.private1_subnet.id
}
# security_ruel 대신 방화벽으로 보안
resource "azurerm_mariadb_firewall_rule" "mariaFwRule" {
  name                = "mriadb-fw-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
```



### `security_group.tf`
- 네트워크 인터페이스와 네트워크 보안그룹 간의 연결 관리
```bash
# Connect the security group to the network interface_bastion
resource "azurerm_network_interface_security_group_association" "pub_sg" {
  network_interface_id      = azurerm_network_interface.pubnic.id
  network_security_group_id = azurerm_network_security_group.pub1.id
}

# Connect the security group to the network interface_wp
resource "azurerm_network_interface_security_group_association" "private1_sg" {
  network_interface_id      = azurerm_network_interface.private1nic.id
  network_security_group_id = azurerm_network_security_group.private1.id
}

# Create Network Security Group and rule Bastion
# Bastion의 인바운드 규칙 편집
# 22번 포트 접속 허용
resource "azurerm_network_security_group" "pub1" {
  name                = "public1SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Network Security Group and rule wp
# wordpress 인바운드 규칙 편집
# 80포트와 22번 포트 허용
resource "azurerm_network_security_group" "private1" {
  name                = "private1SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

	security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
```




### `output.tf`
- 원하는 값을 쉽게 도출하기 위하여 사용
- apply 후에 output 값 확인 가능
```
# output
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.bastionmvm.public_ip_address
}

```

### `variables.tf`
```bash
# Variable
variable "resource_group_name_prefix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}
variable "resource_group_location" {
  default = "korea central"
  description   = "Location of the resource group."
}
```



