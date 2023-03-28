date > ~/start_experiment.sh.start_ts

tmux has-session -t dnscdn 2> /dev/null; if [[ $? == 0  ]]; then tmux kill-session -t dnscdn; fi
tmux new-session -ds dnscdn

hostname=`hostname`

result=$(echo $hostname | grep "server")
if [[ "$result" != "" ]]; then
    tmux send-key -t dnscdn:0 'rm -f ~/server*.log && rm -rf ~/experiment_results && mkdir -p ~/experiment_results && mkdir -p ~/experiment_results/deliver_info' Enter
    tmux send-key -t dnscdn:0 'cd ~ && bash ~/DNS_CDN/server/DNSCDN_server.sh' Enter
    sleep 3
    tmux new-window -t dnscdn:1
    tmux send-key -t dnscdn:1 "top -b -d 0.1 | grep -a '%Cpu' >> ~/DNS_CDN/server/top.log" Enter
    tmux new-window -t dnscdn:2
    tmux send-key -t dnscdn:2 "sudo ~/iptraf-ng-1.2.1/iptraf-ng -i all -L ~/DNS_CDN/server/traffic.log" Enter
fi

result=$(echo $hostname | grep "client")
if [[ "$result" != "" ]]; then
    tmux send-key -t dnscdn:0 'rm -rf ~/DNS_CDN/client/experiment_results && mkdir -p ~/DNS_CDN/client/experiment_results' Enter
    tmux send-key -t dnscdn:0 'bash ~/DNS_CDN/client/DNSCDN_client.sh' Enter
fi

date > ~/start_experiment.sh.end_ts