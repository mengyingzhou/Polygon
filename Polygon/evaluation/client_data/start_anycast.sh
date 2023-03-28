#!/usr/bin/env bash

BASEDIR=$(dirname "$0")

target=""
root=${HOME}/data
date > ${root}/start_anycast.sh.start_ts
mysql_ip="`jq -r .EXTERNAL_IP ${root}/client_settings.json`" # Administrator machine's ip

# Useful values
timestamp=$(($(date +%s%N)/1000000))
client_ip=$(curl -s https://api.ipify.org)

latency_min=1000000
# Init database
while read line
do
    dc=$(echo $line| cut -d' ' -f1)
    echo $line
    dc_ip=$(echo $line| cut -d' ' -f2)
    server_ip=$(echo $line| cut -d' ' -f3)
    latency=$(ping -i.2 -c5 ${dc_ip} | tail -1| awk '{print $4}' | cut -d '/' -f 2)
    cmp=$(awk 'BEGIN{ print "'$latency'"<"'$latency_min'"  }')
    if [[ $(bc <<< "$latency < $latency_min") -eq 1 ]];
    then
        latency_min=$latency
        target_server=$server_ip
        echo "min latency: $latency, from server: $server_ip, in region: $server_region"
    fi
    target_server=$server_ip
    server_region=`python3 -c "import os; print('-'.join([''.join((t[:2], t[-2:])) for t in '${dc}'.split('-')[:2]]))"`

    sql="insert into measurements (dc, client, latency, ts) values ('${server_region}', '${client_ip}', ${latency}, ${timestamp})"
    echo "sql: " $sql
    mysql -h${mysql_ip} -ujohnson -pjohnson -Dserviceid_db -e "${sql}"
done < ${root}/datacenters.txt

sleep 3

type_list_all=("normal_1" "normal_1" "normal_1" "normal_1" "video" "video" "video" "video" "cpu") ## 4:4:1

type_list=(${type_list_all[*]})
# start_port=4433
for i in `seq 30`
do
    {
        port=$(($start_port+$i))
        echo client_$port
        for round in `seq 20000`
        do
            # Anycast probing
            export router_region=`curl -s $lb_ip:9300`
            target=`python3 -c 'import os; import json; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["router_region"]]["external_ip1"])'`
            target_anycast=`python3 -c 'import os; import json; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(machines[os.environ["router_region"][:-7] + "-server"]["external_ip1"])'`
            echo "target_anycast: " $target_anycast

            # settings
            time_stamp=$(($(date +%s%N)/1000000))
            unique_identifier=${client_ip}'_'${port}'_'${time_stamp}

            echo port: $port
            echo round: $round
            total_normal_1=263
            total_video=50

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
         
            #Conduct experiment with Anycast
            echo sudo LD_LIBRARY_PATH=${root} ${root}/client ${target_anycast} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q
            sudo timeout 430 sudo LD_LIBRARY_PATH=${root} ${root}/client ${target_anycast} $port -i -p $data_type -o $opt -w $website --client_ip ${client_ip} --client_process ${port} --time_stamp ${time_stamp} -q 1>> ~/client_tmp_${port}.log 2>> ~/experiment_results/anycast_${unique_identifier}.log

            sleep 3
        done
    } &
done
# wait
date > ${root}/start_anycast.sh.end_ts
