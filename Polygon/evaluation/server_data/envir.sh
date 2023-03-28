# init variables
export hostname=`hostname`
root=${HOME}/data

# ==================== set time zone ==================== 
cd ${HOME}
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


# ==================== copy data ==================== 
cp -r data/.ssh ~/
cp -r data/server.json ~/
cp -r data/websites ~/
# cp -r data/server_measures ~/


# ==================== install basic packages ==================== 
sudo apt update
sudo apt --fix-broken install -y -qq
sudo apt install unzip zip make gcc libncurses5-dev wondershaper jq net-tools openssh-server git vim tmux iputils-ping libev-dev expect python-netifaces -y


# ==================== init LB ==================== 
# GCP health checks will expect a HTTP(s) 200 response, make sure that your backend server is listening on that port and the URL match the Health check's URL path.
# You can check if your instance is listening on port 9300 with the following commands (only for linux): netstat -an | grep -w 9300 | grep -i listen
sudo apt install apache2 -y
sudo sed -i '/Listen 80/c\Listen 9300' /etc/apache2/ports.conf
sudo service apache2 restart
echo `hostname` | sudo tee /var/www/html/index.html


# ==================== init GRE ==================== 
date > init_gre.sh.start_ts
# install openvswitch
sudo apt install -y openvswitch-switch python-openvswitch

iface_primary='ens4'
iface_secondary='ens5'

var=$(ifconfig ${iface_secondary}|grep ether); vars=( $var  ); mac_secondary=${vars[1]}
ip_primary=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["hostname"]]["internal_ip1"])'`
ip_secondary=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["hostname"]]["internal_ip2"])'`

sudo iptables -I OUTPUT -p icmp --icmp-type destination-unreachable -j DROP
for bridge in `sudo ovs-vsctl show| grep Bridge| sed -E 's/ +Bridge //'| sed -E 's/"//g'`;
    do sudo ovs-vsctl del-br $bridge;
done

region=${hostname:0:`expr ${#hostname} - 7`}
other_routers=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); machines.pop(os.environ["hostname"], None); print(",".join(machines.keys()))'`

setup_server() {
    # Setup the GRE tunnel from server -> router
    export router=${hostname:0:`expr ${#hostname} - 6`}router
    router_primary_ip_inner=`python3 -c 'import os; import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["router"]]["internal_ip1"])'`
    router_secondary_ip_inner=`python3 -c 'import os; import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["router"]]["internal_ip2"])'`
    router_bridge_name=router
    router_port_name=tunnel-router
    router_ip=$router_primary_ip_inner
    router_anycast_ip=$router_secondary_ip_inner
    sudo ovs-vsctl add-br $router_bridge_name

    sudo ovs-vsctl add-port $router_bridge_name $router_port_name -- set interface $router_port_name type=vxlan, options:remote_ip=$router_ip
    router_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $router_port_name| tail -n1| egrep -o "[0-9]+"`
    sudo ifconfig $router_bridge_name $router_anycast_ip/32 up
    var=`ifconfig ${router_bridge_name}| grep ether`
    vars=( $var )
    router_mac=${vars[1]}
    sudo ovs-ofctl del-flows $router_bridge_name
    sudo ovs-ofctl add-flow $router_bridge_name in_port=$router_port,actions=mod_dl_dst:${router_mac},mod_nw_dst:${router_anycast_ip},local
    sudo ovs-ofctl add-flow $router_bridge_name in_port=local,actions=$router_port
    sudo arp -s $router_primary_ip_inner 00:00:00:00:00:00 -i $router_bridge_name
    sudo ip route flush table 2 > /dev/null 2>&1
    sudo ip rule delete table 2 > /dev/null 2>&1
    sudo ip route add default via $router_anycast_ip dev $router_bridge_name tab 2 > /dev/null 2>&1
    sudo ip rule add from $router_anycast_ip/32 tab 2 priority 600 > /dev/null 2>&1
}

setup_router() {
    bridge_name=bridge
    sudo ovs-vsctl add-br $bridge_name
    var=$(ifconfig ${bridge_name}|grep ether); vars=( $var  ); mac_bridge=${vars[1]}
    sudo ovs-vsctl add-port $bridge_name $iface_secondary
    sudo ovs-ofctl del-flows $bridge_name
    sudo ifconfig $bridge_name $ip_secondary/24 up
    anycast_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $iface_secondary| tail -n1| egrep -o "[0-9]+"`
    sudo ovs-ofctl add-flow $bridge_name in_port=local,actions=$anycast_port
    sudo ovs-ofctl add-flow $bridge_name in_port=$anycast_port,actions=mod_dl_dst=${mac_bridge},local
    # sudo ifconfig $iface_secondary down

    # Setup the gre tunnel from router -> server
    echo "setup router->server"
    export server=${hostname:0:`expr ${#hostname} - 6`}server
    server_ip=`python3 -c 'import os; import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["server"]]["internal_ip1"])'`
    server_local_port_name=server
    server_gre_port_name=tunnel-server
    echo sudo ovs-vsctl add-port $bridge_name $server_local_port_name -- set interface $server_local_port_name type=internal
    sudo ovs-vsctl add-port $bridge_name $server_local_port_name -- set interface $server_local_port_name type=internal
    echo sudo ovs-vsctl add-port $bridge_name $server_gre_port_name -- set interface $server_gre_port_name type=vxlan options:remote_ip=$server_ip
    sudo ovs-vsctl add-port $bridge_name $server_gre_port_name -- set interface $server_gre_port_name type=vxlan options:remote_ip=$server_ip
    echo sudo ifconfig $server_local_port_name 123.123.123.123/32 up
    sudo ifconfig $server_local_port_name 123.123.123.123/32 up
    server_gre_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $server_gre_port_name| tail -n1| egrep -o "[0-9]+"`
    server_local_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $server_local_port_name| tail -n1| egrep -o "[0-9]+"`
    echo sudo ovs-ofctl add-flow $bridge_name in_port=$server_gre_port,actions=mod_dl_src:${mac_secondary},$iface_secondary
    sudo ovs-ofctl add-flow $bridge_name in_port=$server_gre_port,actions=mod_dl_src:${mac_secondary},$iface_secondary
    echo sudo ovs-ofctl add-flow $bridge_name in_port=$server_local_port,actions=$server_gre_port
    sudo ovs-ofctl add-flow $bridge_name in_port=$server_local_port,actions=$server_gre_port
    echo sudo arp -s $ip_primary 00:00:00:00:00:00 -i $server_local_port_name
    sudo arp -s $ip_primary 00:00:00:00:00:00 -i $server_local_port_name
    echo sudo arp -s $ip_secondary 00:00:00:00:00:00 -i $server_local_port_name
    sudo arp -s $ip_secondary 00:00:00:00:00:00 -i $server_local_port_name

    # Setup the gre tunnel among routers
    while IFS=',' read -ra ADDR
    do
        echo "setup router->router"
        for remote_host in "${ADDR[@]}"
        do
            echo ${remote_host}
            dc_region=${remote_host:0:`expr ${#remote_host} - 7`}
            type=${remote_host:`expr ${#remote_host}` - 6:6}
            if [[ ${type} == router ]] && [[ ${dc_region} != ${region} ]]
            then
                export remote_host
                remote_ip=`python3 -c 'import os; import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["remote_host"]]["external_ip1"])'`
                #dc_region_short=${dc_region//-/}
                export dc_region_short=${dc_region:7}
                dc_region_short=`python3 -c "import os; print('-'.join([''.join((t[:2], t[-2:])) for t in '${dc_region_short}'.split('-')[:2]]))"`
                local_port_name=$dc_region_short
                remote_port_name=tunnel-${dc_region_short}
                echo sudo ovs-vsctl add-port $bridge_name ${local_port_name} -- set interface ${local_port_name} type=internal
                sudo ovs-vsctl add-port $bridge_name ${local_port_name} -- set interface ${local_port_name} type=internal
                echo sudo ovs-vsctl add-port $bridge_name ${remote_port_name} -- set interface ${remote_port_name} type=vxlan options:remote_ip=${remote_ip}
                sudo ovs-vsctl add-port $bridge_name ${remote_port_name} -- set interface ${remote_port_name} type=vxlan options:remote_ip=${remote_ip}
                local_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $local_port_name| tail -n1| egrep -o "[0-9]+"`
                remote_port=`sudo ovs-vsctl -- --columns=name,ofport list Interface $remote_port_name| tail -n1| egrep -o "[0-9]+"`
                echo sudo ifconfig ${local_port_name} 123.123.123.123/32 up
                sudo ifconfig ${local_port_name} 123.123.123.123/32 up
                echo sudo ovs-ofctl add-flow ${bridge_name} in_port=${local_port},actions=${remote_port}
                sudo ovs-ofctl add-flow ${bridge_name} in_port=${local_port},actions=${remote_port}
                echo sudo ovs-ofctl add-flow ${bridge_name} in_port=${local_port},actions=${remote_port}
                sudo ovs-ofctl add-flow ${bridge_name} in_port=${remote_port},actions=${server_gre_port}
                echo sudo arp -s $ip_primary 00:00:00:00:00:00 -i ${local_port_name}
                sudo arp -s $ip_primary 00:00:00:00:00:00 -i ${local_port_name}
                echo sudo arp -s $ip_secondary 00:00:00:00:00:00 -i ${local_port_name}
                sudo arp -s $ip_secondary 00:00:00:00:00:00 -i ${local_port_name}
            fi
        done
    done <<< $other_routers
}

for bridge in `sudo ovs-vsctl show| grep Bridge| sed -E 's/ +Bridge //'| sed -E 's/"//g'`
do
    sudo ovs-vsctl del-br $bridge
done

if [[ $hostname == *server ]]
then
    setup_server
fi
if [[ $hostname == *router ]]
then
    setup_router
fi

date > init_gre.sh.end_ts



# ==================== init mysql ====================
date > ~/init_mysql.sh.start_ts

# install mysql
sudo apt install -y mysql-server

iname="$(ip -o link show | sed -rn '/^[0-9]+: en/{s/.: ([^:]*):.*/\1/p}')"
echo 'sudo ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers
sudo su ubuntu -c "echo 'export PATH=$PATH:/sbin' >> ${HOME}/.bashrc"
echo "export interface=$iname" | sudo tee -a /etc/environment

# install mysql-lib: libmysqlclient20=5.7.21-1ubuntu1 libmysqlclient-dev=5.7.21-1ubuntu1
cd ~
wget http://launchpadlibrarian.net/355857431/libmysqlclient20_5.7.21-1ubuntu1_amd64.deb
sudo apt install -yqq --allow-downgrades ./libmysqlclient20_5.7.21-1ubuntu1_amd64.deb
sudo apt-mark hold libmysqlclient20
wget http://launchpadlibrarian.net/355857415/libmysqlclient-dev_5.7.21-1ubuntu1_amd64.deb
sudo apt install -yqq --allow-downgrades ./libmysqlclient-dev_5.7.21-1ubuntu1_amd64.deb
sudo apt-mark hold libmysqlclient-dev


# init mysql database
main_server_ip="`jq -r .EXTERNAL_IP ${root}/server_settings.json`"
main_hostname=`jq -r .HOSTNAME ${root}/server_settings.json`

if [[ $hostname == $main_hostname ]]
then
    sudo mysql -e "create database if not exists serviceid_db"
    sudo mysql -e "create user if not exists 'johnson' identified by 'johnson'"
    sudo mysql -e "GRANT USAGE ON *.* TO 'johnson'@'%' IDENTIFIED BY 'johnson'"
    sudo mysql -e "GRANT ALL privileges ON \`serviceid_db\`.* TO 'johnson'"
    sudo mysql -e "FLUSH PRIVILEGES"
    auth='-ujohnson -pjohnson'
elif [[ $hostname == *router  ]]
then
    echo root | unbuffer -p mysql_config_editor set --login-path=local --host=localhost --user=root --password --warn=false
    sudo mysql --login-path=local -e "create database if not exists serviceid_db"
    sudo mysql --login-path=local -e "create user if not exists 'johnson' identified by 'johnson'"
    sudo mysql --login-path=local -e "GRANT USAGE ON *.* TO 'johnson'@'%' IDENTIFIED BY 'johnson'"
    sudo mysql --login-path=local -e "GRANT ALL privileges ON \`serviceid_db\`.* TO 'johnson'"
    sudo mysql --login-path=local -e "FLUSH PRIVILEGES"
    auth='--login-path=local'
    echo johnson | unbuffer -p mysql_config_editor set --login-path=local --host=localhost --user=johnson --password --warn=false
fi

if [[ $hostname == $main_hostname ]]
then
    mysql ${auth} -D serviceid_db -e "drop table if exists measurements" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "drop table if exists deployment" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "drop table if exists intra" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "drop table if exists clients" 2> /dev/null
    # mysql ${auth} -D serviceid_db -e "drop table if exists transfer_time" 2> /dev/null

    mysql ${auth} -D serviceid_db -e "create table measurements (
        id int NOT NULL AUTO_INCREMENT,
        dc varchar(32),
        client varchar(32),
        latency FLOAT,
        ts BIGINT,
        primary key (id)
    )" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "create table deployment (
        id int NOT NULL AUTO_INCREMENT,
        datacenter varchar(32),
        domain varchar(32),
        loadbalancer varchar(32),
        primary key (id),
        unique key (domain, datacenter)
    )" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "create table intra (
        id int NOT NULL AUTO_INCREMENT,
        domain varchar(32),
        server varchar(32),
        datacenter varchar(32),
        sid varchar(32),
        weight int,
        primary key (id)
    )" 2> /dev/null
    mysql ${auth} -D serviceid_db -e "create table clients (
        id int NOT NULL AUTO_INCREMENT,
        ip varchar(32),
        primary key (id),
        unique key (ip)
    )" 2> /dev/null
    # mysql ${auth} -D serviceid_db -e "create table transfer_time (
    #     id int NOT NULL AUTO_INCREMENT,
    #     client_ip varchar(32),
    #     router_ip varchar(32),
    #     server_ip varchar(32),
    #     hostname varchar(1024),
    #     client_region varchar(1024),
    #     router_region varchar(1024),
    #     server_region varchar(1024),
    #     service_id_handshake_time integer,
    #     dns_query_time integer,
    #     dns_handshake_time integer,
    #     anycast_handshake_time integer,
    #     service_plt_time integer,
    #     dns_plt_time integer,
    #     anycast_plt_time integer,
    #     bind_server_ip varchar(32),
    #     website varchar(32),
    #     timestamp bigint,
    #     primary key (id)
    # )" 2> /dev/null

    declare -a arr=("usus-eat1" "usus-eat4" "usus-cel1" "usus-wet1" "usus-wet2" "usus-wet3" "eupe-wet1" "eupe-wet2" "eupe-wet3" "eupe-wet4" "eupe-wet6" "eupe-noh1" "asia-eat1" "asia-eat2" "asia-sot1" "asia-not1" "asia-not2" "asia-not3" "asia-soh1" "auia-sot1" "soca-eat1" "noca-not1")
    for zone in "${arr[@]}"
    do
        mysql ${auth} -D serviceid_db -e "insert into intra (domain, server, datacenter, sid, weight) values ('serviceid.polygon.msn', 'server', '${zone}', '11.11.11.11', 1)" 2> /dev/null
        mysql ${auth} -D serviceid_db -e "insert into deployment (datacenter, domain, loadbalancer) values ('${zone}', 'serviceid.polygon.msn', '${zone}')" 2> /dev/null
    done
    #mysql ${auth} -D serviceid_db -e "insert into deployment (datacenter, domain, loadbalancer) values ('uscentral1c', 'serviceid.polygon.msn', 'uscentral1c')" 2> /dev/null
fi

date > ~/init_mysql.sh.end_ts


# ==================== init master-slave ==================== 
date > ~/init_master_slave.sh.start_ts

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root';
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root';

if [[ $hostname == *router ]]
then
    server_id=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); split_ip=machines[os.environ["hostname"]]["internal_ip1"].split("."); print(split_ip[3])'`

    grep -q "mysqld" /etc/mysql/my.cnf
    if [ $? -ne 0 ]
    then
        sudo sh -c 'echo "\n[mysqld]\nlog-bin=mysql-bin\nserver-id=\c" >> /etc/mysql/my.cnf'
        sudo sh -c "echo $server_id >> /etc/mysql/my.cnf"
    else
        sudo sed -i "/server-id=/c\server-id=${server_id}" /etc/mysql/my.cnf
    fi

    position=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json"));pos=machines["position"]; print(pos)'`
    fl=`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json"));f=machines["file"]; print(f)'`
    fl="'"$fl"'"

    sudo service mysql restart
    test_ip=`jq -r .EXTERNAL_IP ${HOME}/data/server_settings.json`
    echo $test_ip
    sudo mysql -uroot -proot -e "stop slave;"
    sudo mysql -uroot -proot -e "change master to \
        master_host='$test_ip', \
        master_user='slave', \
        master_password='123456', \
        master_log_file=$fl, \
        master_log_pos=$position;"
    sudo mysql -uroot -proot -e "start slave;"
fi
date > ~/init_master_slave.sh.end_ts


# ==================== init mongodb ==================== 
date > ~/init_mongodb.sh.start_ts

if [[ $hostname == *server ]]
then
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B
    echo "deb [ arch=amd64 ] https://mirrors.tuna.tsinghua.edu.cn/mongodb/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
    sudo apt update
    sudo apt install -y mongodb-org
    sudo systemctl enable mongod
    sudo service mongod restart
    sudo apt install -y python3-pymongo
    sudo mongorestore --db shuffle_index --drop ${root}/shuffle_index
fi
date > ~/init_mongodb.sh.end_ts


# ==================== install redis ==================== 
date > ~/init_redis.sh.start_ts
if [ ! -d "${HOME}/hiredis" ]; then
    cd ~/ && wget https://github.com/redis/hiredis/archive/refs/heads/master.zip
    unzip master.zip
    mv hiredis-master hiredis && cd hiredis
    sudo make install && cd ~/
    sudo cp -r ~/hiredis /usr/local/lib
    sudo ldconfig /usr/local/lib

    # init redis database
    if [[ $hostname == *router  ]]
    then
        sudo apt -y install redis-server
        sudo sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
        sudo sed -i 's/# requirepass foobared/requirepass polygon123456/g' /etc/redis/redis.conf
        sudo service redis-server restart
    elif [[ $hostname == *server  ]]
    then
        sudo apt -y install redis-server
    fi
fi
date > ~/init_redis.sh.end_ts


# ==================== install lexbor ==================== 
if [ ! -d "${HOME}/lexbor_signing.key" ]; then
    curl -O https://lexbor.com/keys/lexbor_signing.key
    sudo apt-key add lexbor_signing.key > /dev/null 2>&1
    sudo sh -c "echo 'deb https://packages.lexbor.com/ubuntu/ bionic liblexbor' > /etc/apt/sources.list.d/lexbor.list"
    sudo sh -c "echo 'deb-src https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
    sudo apt update
    sudo apt install -yqq liblexbor liblexbor-dev jq libev-dev iftop sshpass tmux
fi

# ==================== install iperf3 ==================== 
if [ ! -d "${HOME}/libiperf0_3.7-3_amd64.deb" ]; then
    sudo apt -y remove iperf3 libiperf0 
    sudo apt -y install libsctp1 
    wget https://iperf.fr/download/ubuntu/libiperf0_3.7-3_amd64.deb 
    wget https://iperf.fr/download/ubuntu/iperf3_3.7-3_amd64.deb 
    sudo dpkg -i libiperf0_3.7-3_amd64.deb iperf3_3.7-3_amd64.deb 
fi

# ==================== install iptraf ==================== 
if [ ! -d "${HOME}/iptraf-ng-1.2.1" ]; then
    wget https://github.com/iptraf-ng/iptraf-ng/archive/refs/tags/v1.2.1.zip
    unzip v1.2.1.zip
    cd iptraf-ng-1.2.1
    make install
fi
