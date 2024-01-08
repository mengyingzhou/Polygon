# 1. Outline
- [1. Outline](#1-outline)
- [2. Environment Configuration \& Compilation](#2-environment-configuration--compilation)
  - [2.1. Install environment packages required](#21-install-environment-packages-required)
  - [2.2. install pip](#22-install-pip)
  - [2.3. Install the packages required by openssl and ngtcp2](#23-install-the-packages-required-by-openssl-and-ngtcp2)
  - [2.4. openssl](#24-openssl)
  - [2.5. mysql dev](#25-mysql-dev)
    - [2.5.1. Install lexbor](#251-install-lexbor)
  - [2.6. Install redis](#26-install-redis)
    - [2.6.1. Install hiredis](#261-install-hiredis)
    - [2.6.2. Install redis-server](#262-install-redis-server)
  - [2.7. Compile ngtcp2](#27-compile-ngtcp2)
  - [2.8. Test the ngtcp2 communication between client and server](#28-test-the-ngtcp2-communication-between-client-and-server)
    - [2.8.1. Create SSL certificate](#281-create-ssl-certificate)
    - [2.8.2. Create test CDN data](#282-create-test-cdn-data)
    - [2.8.3. Running tests](#283-running-tests)
    - [2.8.4. Test with scripts](#284-test-with-scripts)


# 2. Environment Configuration & Compilation
## 2.1. Install environment packages required 
```
sudo apt install -y git tmux jq zip unzip sshpass mysql-client mysql-server
```

## 2.2. install pip
```
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo apt install -y python3-distutils
sudo python3 get-pip.py
sudo pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```


## 2.3. Install the packages required by openssl and ngtcp2
```
sudo apt install -y pkg-config autoconf automake autotools-dev libtool libev-dev gdb libcunit1 libcunit1-doc libcunit1-dev gcc g++
```

Polygon is based on the ngtcp2. The libngtcp2 C library itself does not depend on any external libraries.  The example client, and server are written in C++14, and should compile with the modern C++ compilers (e.g., clang >= 4.0, or gcc >= 5.0).

The following packages are required to configure the build system:

* pkg-config >= 0.20
* autoconf
* automake
* autotools-dev
* libtool

libngtcp2 uses cunit for its unit test frame work:

* cunit >= 2.1

To build sources under the examples directory, libev is required:

* libev


## 2.4. openssl
The client and server under examples directory require OpenSSL (master branch) as crypto backend

```
git clone --depth 1 -b quic https://github.com/tatsuhiro-t/openssl
cd openssl
./config enable-tls1_3 --prefix=$PWD/build
make -j$(nproc)
make install_sw
```


## 2.5. mysql dev
* When the error "/usr/lib/gcc/x86_64-linux-gnu/7/../../../x86_64-linux-gnu/libmysqlclient.so: undefined reference to `SSL_CTX_set_ciphersuites@OPENSSL_1_1_1'" appears, you can run the following command to solve it. The purpose is to downgrade the version of libmysqlclient-dev.
```
sudo apt install libmysql++3v5 -y
cd ~
wget http://launchpadlibrarian.net/355857431/libmysqlclient20_5.7.21-1ubuntu1_amd64.deb
sudo apt install -yqq --allow-downgrades ./libmysqlclient20_5.7.21-1ubuntu1_amd64.deb
sudo apt-mark hold libmysqlclient20
wget http://launchpadlibrarian.net/355857415/libmysqlclient-dev_5.7.21-1ubuntu1_amd64.deb
sudo apt install -yqq --allow-downgrades ./libmysqlclient-dev_5.7.21-1ubuntu1_amd64.deb
sudo apt-mark hold libmysqlclient-dev
```


### 2.5.1. Install lexbor
Lexbor is a third-party library for HTML parsing
```
cd ~
curl -O https://lexbor.com/keys/lexbor_signing.key
sudo apt-key add lexbor_signing.key
sudo sh -c "echo 'deb https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo sh -c "echo 'deb-src https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo apt update
sudo apt install liblexbor liblexbor-dev -y
```

## 2.6. Install redis
### 2.6.1. Install hiredis
```
cd ~
git clone https://github.com/redis/hiredis
cd hiredis
make
sudo make install
sudo cp -r ~/hiredis /usr/local/lib
sudo ldconfig /usr/local/lib
```

### 2.6.2. Install redis-server
```
sudo apt -y install redis-server
sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
sudo sed -i 's/# requirepass foobared/requirepass polygon123456/g' /etc/redis/redis.conf
sudo service redis-server restart
```

## 2.7. Compile ngtcp2
```
cd Polygon
autoreconf -i
* For Mac users who have installed libev with MacPorts, append',-L/opt/local/lib' to LDFLAGS, and also pass
* CPPFLAGS="-I/opt/local/include" to ./configure.
./configure.sh && make
```

## 2.8. Test the ngtcp2 communication between client and server
### 2.8.1. Create SSL certificate
```
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.crt -days 3650
```

### 2.8.2. Create test CDN data
```
cd Polygon
mkdir websites
cd websites
mkdir video
cp <Repo Path>/server_data/websites/video/downloading <Repo Path>Polygon/websites
```

### 2.8.3. Running tests
1. terminal 1: server 
```
sudo ./examples/server --interface=ens4 --unicast=${unicast} 0.0.0.0 ${port} server.key server.crt -q

parameter explanation:
  - ${unicast}: server's external unicast IP
  - 0.0.0.0: Sets that any host can connect to the server
  - ${port}: port
  - ens4: the monitored network interface
  - server.key, server.crt: SSL certificate
  - -q: silent mode
  - example: sudo LD_LIBRARY_PATH=~/data ~/data/server --interface=ens4 --unicast=34.87.220.111 0.0.0.0 4500 ~/data/server.key ~/data/server.crt -q
```

2. terminal 2: client
```
./examples/client ${target} ${port} -i -p ${request_type} -o ${require_www} -w ${website} --client_ip ${client_ip} --client_process ${p_id} --time_stamp ${time_stamp} -q 

parameter explanation:
  - {target}: is the ip of the dispatcher
  - ${port}: port
  - ${request_type}: The request type, including normal_1, video, and cpu
  - ${require_www}: Whether www prefix is required for the tested website
  - ${website}: the domain name of the specific web page
  - ${client_ip}: client's external ip
  - ${p_id}: the tag of different client processes
  - ${time_stamp}: timestamp
  - example: sudo LD_LIBRARY_PATH=~/data ~/data/client 35.189.7.58 4500 -i -p normal_1 -o 0 -w google.com --client_ip 34.97.121.148 --client_process 10 --time_stamp 12345678 -q 
```


3. results: client output
```
127.0.0.1
website: downloading
website_root_path: video
website_www_opt: 1
bind fd_ with 127.0.0.1
time before decrypt 0.01
time after decrypt 0.05
1208
b
t
migrate server's address to 35.238.144.79
bind fd2_ with 35.238.144.79
final time 0.53
time before decrypt 0.00
time after decrypt 0.02
final time 0.48
t=0.018543 QUIC handshake has completed
handshake time: 16697
==== downloading resources =====
req: GET /websites/video/downloading/www.downloading/big.mp4 HTTP/1.1


last_plt_time: 0
PLT: 30630 microseconds
last_plt_cost: 30630
last_plt_time: 30630
PLT: 9388838 microseconds
last_plt_cost: 9358208
```

### 2.8.4. Test with scripts
- start_dispatcher.sh # Single dispatcher run script sample, need to modify IP
- start_client.sh # Single client running script sample, need to modify IP
- start_server.sh # Single server running script sample, need to modify IP

