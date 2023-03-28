#!/bin/bash
# 开启iperf3测量端口
iperf3 -s -p 5200 -D >/dev/null 2>&1
iperf3 -s -p 5201 -D >/dev/null 2>&1
iperf3 -s -p 5202 -D >/dev/null 2>&1
iperf3 -s -p 5203 -D >/dev/null 2>&1
iperf3 -s -p 5204 -D >/dev/null 2>&1
iperf3 -s -p 5205 -D >/dev/null 2>&1
iperf3 -s -p 5206 -D >/dev/null 2>&1
iperf3 -s -p 5207 -D >/dev/null 2>&1
iperf3 -s -p 5208 -D >/dev/null 2>&1
iperf3 -s -p 5209 -D >/dev/null 2>&1


# 通过传输小文件来测量实际带宽
export hostname=`hostname`
root=${HOME}/data
main_test_ip="`jq -r .EXTERNAL_IP ${root}/server_settings.json`"
main_hostname=`jq -r .HOSTNAME ${root}/server_settings.json`

router_ips=(`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(" ".join([machines[x]["internal_ip1"] for x in machines if "router" in x]));'`)
server_ips=(`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(" ".join([machines[x]["external_ip1"] for x in machines if "server" in x]));'`)
server_hostnames=(`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(" ".join([x for x in machines if "server" in x]));'`)
router_hostnames=(`python3 -c 'import json; import os; machines=json.load(open(os.environ["HOME"]+"/data/server.json")); print(" ".join([x for x in machines if "router" in x]));'`)

router_num=-1
for i in `seq 0 $((${#router_hostnames[*]} - 1))`
do
    echo ${server_ips[$i]}
    if [[ ${router_hostnames[$i]} == $hostname ]] 
    then
        router_num=$i
    fi
done

sleep 20
time_stamp=$(($(date +%s%N)/1000000))
for i in `seq 0 $((${#router_hostnames[*]} - 1))`
do
    server_num=$(($i+$router_num))
    # echo "server_num: " $server_num
    server_num=$(($server_num%5))
    echo "server_num: " $server_num
    server_ip=${server_ips[$server_num]}

    if [[ $i == $router_num ]]
    then
        website=downloading
    else
        website=downloadingcross
    fi

    rm ${HOME}/speed_router_$server_num.txt
    echo sudo LD_LIBRARY_PATH=${root} ${root}/client ${server_ip} 4433 -i -p video -o 1 -w $website --client_ip 123.123.123.123 --client_process 4433 --time_stamp $time_stamp -q
    sudo LD_LIBRARY_PATH=${root} ${root}/client ${server_ip} 4433 -i -p video -o 1 -w $website --client_ip 123.123.123.123 --client_process 4433 --time_stamp $time_stamp -q 1>> /dev/null 2>> ${HOME}/speed_router_$server_num.txt
    # sudo 
    PLT_num=`sudo tac ${HOME}/speed_router_$server_num.txt | grep -c "PLT"`
    time_spend=`sudo tac ${HOME}/speed_router_$server_num.txt | grep -a "PLT" |head -n 1| awk '{print $2}'`
    while [[ $time_spend == 0 || $PLT_num -ne 2 ]] 
    do
        sleep 10
        rm ${HOME}/speed_router_$server_num.txt
        sudo LD_LIBRARY_PATH=${root} ${root}/client ${server_ip} 4443 -i -p video -o 1 -w $website --client_ip 123.123.123.123 --client_process 4433 --time_stamp $time_stamp -q 1>> /dev/null 2>> ${HOME}/speed_router_$server_num.txt
    done
    echo "time_spend: " $time_spend

    if [[ $website == "downloading" ]]
    then
        size=5000
    else
        size=942
    fi
    rate=`awk 'BEGIN{print "'$size'" / "'$time_spend'"  * "1000000"}'`
    # echo rate > ${HOME}/initial_${router_num}_${server_num}.txt

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${server_ip} "echo $rate > ~/initial_${router_num}.txt"
    # sleep
done

echo "router_num: " $router_num
echo "initial done"