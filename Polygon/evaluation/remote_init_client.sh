root=${HOME}
data_path=${root}


# creat client data
cp ${root}/Polygon/examples/client ${data_path}/client_data
cp ${root}/server.json ${data_path}/client_data
cp ${root}/deploy/project_settings.json ${data_path}/client_data/client_settings.json


cd ${data_path}
rm client_data.zip
zip client_data.zip client_data -r
cd ${root}

# start init
lb_ip="`jq -r .LB_IP ${data_path}/client_data/client_settings.json`"
ip_primary=`python3 -c "import json
machines=json.load(open('client.json'))
for item in machines: print(item['hostname'])"`
echo "client ips:    "$ip_primary
array=(${ip_primary//,/ })
for(( i=0;i<${#array[@]};i++)) do
    {
        echo ${array[i]}
        # creat data
        sshpass scp -r -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${data_path}/client_data.zip ${array[i]}:~

        # transfer data
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "sudo apt update"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "sudo DEBIAN_FRONTEND=noninteractive apt install -yqq unzip"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "[ -e data ] && rm -r data"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "unzip ~/client_data.zip >> /dev/null"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "mv ~/client_data/ ~/data"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "rm ~/home -rf"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "cp -r ~/data/.ssh ~/"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "cp -r ~/data/websites ./"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "mkdir -p ~/experiment_results" 

        # envir
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "bash ~/data/envir.sh"
        start_port=`expr 4434 + ${i} \* 10`
        echo "start port: "${start_port}
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "echo export start_port=${start_port} >> ~/.bashrc"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "echo export lb_ip=${lb_ip} >> ~/.bashrc"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "echo export region=\"unknown\" >> ~/.bashrc"
        sshpass ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${array[i]} "source ~/.bashrc"

        echo ${array[i]} "Done!!"
    } &
done
