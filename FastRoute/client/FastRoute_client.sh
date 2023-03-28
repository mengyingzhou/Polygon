#!/usr/bin/env bash
root=${HOME}"/FastRoute"
date > ${root}/start_FastRoute.sh.start_ts

client_ip=$(curl -s https://api.ipify.org)
dns_ip=`python3 -c "import os
import configparser
config = configparser.ConfigParser()
config.read('/home/gtc/FastRoute/ip.conf')
dns_ip = config.get('DNS', 'inter')
print(dns_ip)"`
echo "dns_ip: " $dns_ip
server_domain=`python3 -c "import os
myhost = os.uname()[1]
domain_id = myhost[-3]
if domain_id != '1':
    domain_id = '2'
print('server' + str(domain_id) + '.example.com')"`
echo "server_domain: " $server_domain
export server_domain=${server_domain}

total_normal_1=263
total_video=50
type_list=("normal_1" "normal_1" "normal_1" "normal_1" "video" "video" "video" "video" "cpu")

for i in `seq 10`
do
    {
        port=`expr "${start_port}" + ${i}`
        echo client_$port
        for round in `seq 20000`
        do
            server_ip=`python3 -c "import dns.resolver;import os;dns_ip = '10.128.0.2';my_resolver = dns.resolver.Resolver();my_resolver.nameservers = [dns_ip];DNS_resolving = my_resolver.query(os.environ['server_domain']);print(DNS_resolving[0].to_text().split(' ')[0]);"`
            echo $server_ip
            # settings
            time_stamp=$(($(date +%s%N)/1000000))

            rand_seed=$((${RANDOM=$port} % 9))
            data_type=${type_list[$rand_seed]}
            opt=1

            temp=$((${RANDOM=$round} % ${total_normal_1} + 1))
            if [[ $data_type == "normal_1" ]]; then
                temp=$((${RANDOM=$round} % ${total_normal_1} + 1))
                website=`sed -n ${temp}p ${root}/websites/$data_type/resource_list.txt`

            elif [[ $data_type == "video" ]]; then
                temp=$((${RANDOM=$round} % ${total_video} + 1))
                website=`sed -n ${temp}p ${root}/websites/$data_type/resource_list.txt`

            elif [[ $data_type == "cpu" ]]; then 
                website="cpu"
            fi

            echo data_type: $data_type
            echo website: $website
            echo opt: $opt
            
            #Conduct experiment 
            unique_identifier=${client_ip}'_'${port}'_'${server_ip}'_'${data_type}'_'${time_stamp}
            echo sudo LD_LIBRARY_PATH=${root} ${root}/client/client ${server_ip} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q
            sudo timeout 430 sudo LD_LIBRARY_PATH=${root} ${root}/client/client ${server_ip} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q 1>> ${root}/client/client_tmp_${port}.log 2>> ${root}/client/experiment_results/fastroute_${unique_identifier}.log

            sleep 3
        done
    } &
done
# wait
date > ${root}/start_FastRoute.sh.end_ts