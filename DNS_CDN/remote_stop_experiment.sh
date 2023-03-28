ip_primary=`python3 -c "import json
machines=json.load(open('machine_server.json'))
for key in machines.keys(): 
    if '-server' in key:
        print(machines[key]['internal_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    echo ${array[i]};
    echo "bash ~/DNS_CDN/server/stop_server.sh"
    sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/DNS_CDN/server/stop_server.sh"
done;


ip_primary=`python3 -c "import json
machines=json.load(open('machine_client.json'))
for item in machines: print(item['hostname'])"`
echo "client ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    echo ${array[i]};
    echo "bash ~/DNS_CDN/client/stop_client.sh"
    sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/DNS_CDN/client/stop_client.sh"
done;
