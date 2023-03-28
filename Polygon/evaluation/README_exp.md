# 1. Outline
- [1. Outline](#1-outline)
- [2. Environmental checks before running experiments](#2-environmental-checks-before-running-experiments)
  - [2.1. gcloud firewall start port](#21-gcloud-firewall-start-port)
  - [2.2. Configure MySQL](#22-configure-mysql)
    - [2.2.1. Configure master-salve](#221-configure-master-salve)
    - [2.2.2. Check master-slave function](#222-check-master-slave-function)
    - [2.2.3. View database](#223-view-database)
    - [2.2.4. Database password](#224-database-password)
- [3. Conduct experiment](#3-conduct-experiment)
  - [3.1. Prepare data](#31-prepare-data)
    - [3.1.1. Preconditions](#311-preconditions)
    - [3.1.2. Build client, server, dispatcher (balancer) assembly](#312-build-client-server-dispatcher-balancer-assembly)
    - [3.1.3. Create Website data](#313-create-website-data)
  - [3.2. Single machine experiment testing](#32-single-machine-experiment-testing)
- [4. Large scale experiments](#4-large-scale-experiments)



# 2. Environmental checks before running experiments
## 2.1. gcloud firewall start port
1. Sidebar - VPC Network - Firewall
2. Add "allow-all-in" inbound Apply to all instances IP address range: 0.0.0.0/0 Protocols and ports:all allow 1000"
3. Add "allow-all-out" outbound apply to all instances IP address range: 0.0.0.0/0 Protocols and ports:all allow 1000"

## 2.2. Configure MySQL
### 2.2.1. Configure master-salve
```
sudo vim /etc/mysql/my.cnf
And add the following:
[mysqld]
log-bin=mysql-bin
server-id=2

Then
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf
1. Comment bind-address = 0.0.0.0 or bind-address = 127.0.0.1
2. Uncomment the lines where log_bin and server-id are located

sudo service mysql restart
sudo service mysql status
sudo mysql
After entering the MySQL interactive terminal:
GRANT replication slave ON *.* TO 'slave'@'%' IDENTIFIED BY '123456';
exit mysql

cd evaluation
Modify setting_path in init_mysql.sh
bash ./server_data/init_mysql.sh
```
### 2.2.2. Check master-slave function
sudo mysql -uroot -proot -e "show slave status\G"

if <Slave_IO_Running> and <Slave_SQL_Running> are both yes, it is successful

### 2.2.3. View database
mysql -h<administrator ip> -ujohnson -pjohnson serviceid_db -e "select * from measurements;"
mysql -ujohnson -pjohnson serviceid_db -e "select * from measurements;"
sudo mysql -uroot -proot serviceid_db -e "select * from measurements;"

### 2.2.4. Database password
- MySQL: 
  - user1: johnson
  - passwd1: johnson
  - user2: root
  - passwd2: root
- MongoDB: 
  - passwd: polygon123456
- Redis: 
  - passwd: polygon123456

# 3. Conduct experiment
## 3.1. Prepare data
### 3.1.1. Preconditions
1. VMs have been created
2. Get the server.json and client.json of python -m deploy.main
3. Polygon has been successfully compiled
4. Go to https://console.cloud.google.com/net-services/loadbalancing/details/proxy/load-balancer to get the IP of load-balancer, namely Anycast IP

### 3.1.2. Build client, server, dispatcher (balancer) assembly
1. client (**has been integrated into remote_init_client.sh. What you need to check is the path parameters.**)
```
cp Polygon/examples/client Polygon/evaluation/client_data
cp server.json Polygon/evaluation/client_data
Modify "mysql_ip="<administrator server IP>" to Administrator's IP in start_anycast.sh and start_polygon.sh

cp ${HOME}/openssl/libssl.so.1.1 ${data_path}/client_data/libssl.so.1.1
cp ${HOME}/openssl/libcrypto.so.1.1 ${data_path}/client_data/libcrypto.so.1.1
cp ${HOME}/.ssh ${data_path}/client_data/.ssh
cat ~/.ssh/id_rsa.pub >> ${data_path}/client_data/.ssh/authorized_keys
```

2. server and balancer (**has been integrated into remote_init_server.sh, What you need to check is the path parameters.**)
```
cp Polygon/examples/client Polygon/evaluation/server_data
cp Polygon/examples/server Polygon/evaluation/server_data
cp Polygon/examples/balancer Polygon/evaluation/server_data

cp server.json Polygon/evaluation/server_data
cp client.json Polygon/evaluation/server_data
cp Polygon/deploy/project_settings.json Polygon/evaluation/server_data/server_settings.json

cp ${HOME}/openssl/libssl.so.1.1 ${data_path}/server_data/libssl.so.1.1
cp ${HOME}/openssl/libcrypto.so.1.1 ${data_path}/server_data/libcrypto.so.1.1
cp ${HOME}/.ssh ${data_path}/server_data/.ssh
cat ~/.ssh/id_rsa.pub >> ${data_path}/server_data/.ssh/authorized_keys
```

1. Modify script
    1. cp server.json Polygon/evaluation
    2. cp client.json Polygon/evaluation
    3. remote_init_client.sh: modifies <lb_ip> to the Anycast IP in remote_init_client.sh 
    4. remote_init_client.sh: Modify data_path
    5. When change evaluated schemes between the Polygon and Anycast scheme, you need to modify the script that needs to be started in start_wrapper.sh


### 3.1.3. Create Website data
The website is the CDN content hosted by the server. For server_data, the data in the websites folder is not uploaded in the repo and needs to be manually constructed. The server side needs complete data, and the client side needs resource_list.txt.

There are four file types in total:
- cpu: The key is to pay attention to the scope and number of database queries in cpu.py
- normal_1: A total of 263 web pages
- video: a total of 50 video file streams


## 3.2. Single machine experiment testing
Suppose there are three machines, namely server, dispatcher, and client. Start the three terminals of tmux and start them in order


1. server
```
sudo LD_LIBRARY_PATH=~/data ~/data/server --interface=ens4 --unicast=${unicast} 0.0.0.0 ${port} server.key server.crt -q

parameter explanation:
  - ${unicast}: server's external unicast IP
  - 0.0.0.0: Sets that any host can connect to the server
  - ${port}: port
  - ens4: the monitored network interface
  - server.key, server.crt: SSL certificate
  - -q: silent mode
  - example: sudo LD_LIBRARY_PATH=~/data ~/data/server --interface=ens4 --unicast=34.87.220.111 0.0.0.0 4500 ~/data/server.key ~/data/server.crt -q
```


2. dispatcher
```
sudo LD_LIBRARY_PATH=~/data ~/data/balancer --datacenter ${zone} --user ${username} --password ${password} bridge 0.0.0.0 ${port} server.key server.crt -q

parameter explanation:
  - ${zone} is the abbreviation of the region, indicating the name of the zone belongs to the dispater
  - ${username}: database user name 
  - ${password}: database password  
  - 0.0.0.0: Sets that any host can connect to the server
  - ${port}: port
  - example: sudo LD_LIBRARY_PATH=~/data ~/data/balancer --datacenter asia-sot1 --user johnson --password johnson bridge 0.0.0.0 4500 ~/data/server.key ~/data/server.crt -q
```

3. client
```
sudo LD_LIBRARY_PATH=~/data ~/data/client ${target} ${port} -i -p ${request_type} -o ${require_www} -w ${website} --client_ip ${client_ip} --client_process ${p_id} --time_stamp ${time_stamp} -q 

parameter explanation:
  - {target}: is the ip of the dispatcher
  - ${port}: port
  - ${request_type}: The request type, including normal_1, video, and cpu
  - ${require_www}: Whether www prefix is required for the tested website
  - ${website}: the domain name of the specific web page
  - ${client_ip}: client's external ip
  - ${p_id}: the tag of differentclient processes
  - ${time_stamp}: timestamp
  - example: sudo LD_LIBRARY_PATH=~/data ~/data/client 35.189.7.58 4500 -i -p normal_1 -o 0 -w google.com --client_ip 34.97.121.148 --client_process 10 --time_stamp 12345678 -q 
```



# 4. Large scale experiments
1. init
   1. bash remote_init_server.sh
   2. bash remote_init_client.sh
2. run experiment
   1. bash remote_start_server.sh
   2. bash remote_start_client.sh
3. stop experiment 
   1. python3 remote_kill_all.py
4. download experiment results
   1. python3 remote_fetch_data.py



