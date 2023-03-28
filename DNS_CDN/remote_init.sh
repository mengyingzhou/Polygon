cp ~/hosts.json ./machine_client.json
cp ~/machine.json ./machine_server.json

ip_primary=`python3 -c "import json
machines=json.load(open('machine_server.json'))
for key in machines.keys(): 
    if '-server' in key:
        print(machines[key]['internal_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })
cd ..
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo rm ~/DNS_CDN -r"
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no DNS_CDN gtc@${array[i]}:/home/gtc
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/DNS_CDN/envir.sh"
    } &
done;


cd DNS_CDN
ip_primary=`python3 -c "import json
machines=json.load(open('machine_client.json'))
for item in machines: print(item['hostname'])"`
echo "client ips:    "$ip_primary
array=(${ip_primary//,/ })
cd ..
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        start_port=`expr 4434 + ${i} \* 10`
        echo "start port: "${start_port}
        
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo rm ~/DNS_CDN -r"
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no DNS_CDN gtc@${array[i]}:/home/gtc
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/DNS_CDN/envir.sh"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "echo export start_port=${start_port} >> ~/.bashrc && source ~/.bashrc"
    } &
done;
