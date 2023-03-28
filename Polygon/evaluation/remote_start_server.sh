# server first 
ip_primary=`python3 -c "import json
machines=json.load(open('server.json'))
for key in machines.keys(): 
    if '-server' in key:
        print(machines[key]['external_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "bash ~/data/start_experiment.sh"
        echo ${array[i]} "Done!!"
    } &
done;

# router later 
ip_primary=`python3 -c "import json
machines=json.load(open('server.json'))
for key in machines.keys(): 
    if '-router' in key:
        print(machines[key]['external_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "bash ~/data/start_experiment.sh"
        echo ${array[i]} "Done!!"
    } &
done;
