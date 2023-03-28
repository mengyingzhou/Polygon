ip_primary=`python3 -c "import json
machines=json.load(open('client.json'))
for item in machines: print(item['hostname'])"`
echo "client ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "bash ~/data/start_wrapper.sh"
        echo ${i} ${array[i]} "Done!!"
    } &
done;