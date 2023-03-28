root=${HOME}
data_path=${root}


# creat server data
cp ${root}/Polygon/examples/server ${data_path}/server_data
cp ${root}/ngtPolygoncp2/examples/balancer ${data_path}/server_data
cp ${root}/server.json ${data_path}/server_data
cp ${root}/client.json ${data_path}/server_data
cp ${root}/deploy/project_settings.json ${data_path}/server_data/server_settings.json

cd ${data_path}
rm server_data.zip
zip server_data.zip server_data -r
cd ${root}

# start init
ip_primary=`python3 -c "import json
machines=json.load(open('server.json'))
for key in machines.keys(): 
    print(machines[key]['external_ip1'])"`
echo "server ips:    "$ip_primary
array=(${ip_primary//,/ })  
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]};
        # transfer data
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${data_path}/server_data.zip ${array[i]}:~
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "sudo apt update"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "sudo apt install -yqq unzip"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "[ -e data ] && rm -r data"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "unzip ~/server_data.zip >> /dev/null"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "mv ~/server_data/ ~/data"

        # envir
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "bash ~/data/envir.sh"

        echo ${array[i]} "Done!!"
    } &
done;
