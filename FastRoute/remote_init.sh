cp ~/hosts.json ./machine_client.json
cp ~/polygon/machine.json ./machine_server.json
# cp ~/deploy.json ./machine_server.json
python3 create_ipconfig.py

ip_primary=`python3 -c "import json
machines=json.load(open('machine_server.json'))
for key in machines.keys(): 
    if '-server' in key:
        print(machines[key]['internal_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })
cd ~
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo rm ~/FastRoute -r"
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no FastRoute gtc@${array[i]}:/home/gtc
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/FastRoute/envir_FastRoute.sh"
    } &
done;


cd ~/FastRoute
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
        
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo rm ~/FastRoute -r"
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no FastRoute gtc@${array[i]}:/home/gtc
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "bash ~/FastRoute/envir_FastRoute.sh"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "echo export start_port=${start_port} >> ~/.bashrc && source ~/.bashrc"
        # sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo sh -c \"echo 'nameserver 10.128.0.2' >> /etc/resolvconf/resolv.conf.d/head\""
        # sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo resolvconf -u"
    } &
done;


dns="35.232.57.157"
echo ${dns};
sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${dns} "sudo rm ~/FastRoute -r"
sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no FastRoute gtc@${dns}:/home/gtc
# sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${dns} "bash ~/FastRoute/envir_FastRoute.sh"
sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${dns} "bash ~/FastRoute/start_experiment.sh"
