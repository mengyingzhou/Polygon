#!/usr/bin/env bash
root=${HOME}"/DNS_CDN"
date > ${root}/start_DNSCDN.sh.start_ts

client_ip=$(curl -s https://api.ipify.org)
server_ip=`python3 -c "import os 
import json
myhost = os.uname()[1]
region = myhost.split('-')[1]
if region == 'us':
    region = 'northamerica'
server_machines = json.load(open('${root}/machine_server.json'))
for key in server_machines.keys(): 
    if region in key and '-server' in key:
        server_ip = server_machines[key]['external_ip1']
        print(server_ip)
        break"`
echo "server_ip: " $server_ip

total_normal_1=263
total_video=50
type_list=("normal_1" "normal_1" "normal_1" "normal_1" "video" "video" "video" "video" "cpu")

# start_port=4433
for i in `seq 10`
do
    {
        port=`expr "${start_port}" + ${i}`
        echo client_$port
        for round in `seq 20000`
        do
            # settings
            time_stamp=$(($(date +%s%N)/1000000))
            unique_identifier=${client_ip}'_'${port}'_'${time_stamp}

            rand_seed=$((${RANDOM=$port} % 9))
            data_type=${type_list[$rand_seed]}
            opt=1

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
            echo sudo LD_LIBRARY_PATH=${root} ${root}/client/client ${server_ip} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q
            sudo timeout 430 sudo LD_LIBRARY_PATH=${root} ${root}/client/client ${server_ip} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q 1>> ${root}/client/client_tmp_${port}.log 2>> ${root}/client/experiment_results/dnscdn_${unique_identifier}.log

            sleep 3
        done
    } &
done
# wait
date > ${root}/start_DNSCDN.sh.end_ts