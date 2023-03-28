ip_primary=`python3 -c "import json
machines=json.load(open('machine_server.json'))
for key in machines.keys(): 
	if '-server' in key:
		print(machines[key]['internal_ip1'])"`
host_primary=`python3 -c "import json
machines=json.load(open('machine_server.json'))
for key in machines.keys(): 
	if '-server' in key:
		print(key)"`
echo "server ips:	"$ip_primary
echo "server hostnames:	"$host_primary
array=(${ip_primary//,/ })  
array_host=(${host_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
	echo ${array[i]};
	echo ${array_host[i]};

	if [[ ${array_host[i]}  == "polygon-northamerica-northeast1-c-server" ]]
	then
		second_max=17920
	elif [[ ${array_host[i]}  == "polygon-asia-southeast1-c-server" ]]
	then
		second_max=1628
	elif [[ ${array_host[i]}  == "polygon-southamerica-east1-b-server" ]]
	then
		second_max=1198
	elif [[ ${array_host[i]}  == "polygon-europe-west2-b-server" ]]
	then
		second_max=31129
	elif [[ ${array_host[i]}  == "polygon-australia-southeast1-c-server" ]]
	then
		second_max=20172
	fi

	echo "sudo wondershaper ens4 $second_max $second_max"
	sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo wondershaper clear ens4"
	sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gtc@${array[i]} "sudo wondershaper ens4 $second_max $second_max"
done;
