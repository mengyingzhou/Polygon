date > ~/start_experiment.sh.start_ts

tmux has-session -t fastroute 2> /dev/null; if [[ $? == 0  ]]; then tmux kill-session -t fastroute; fi
tmux new-session -ds fastroute

hostname=`hostname`

result=$(echo $hostname | grep "test")
if [[ "$result" != "" ]]; then
    tmux send-key -t fastroute:0 'cd ~/FastRoute/DNS && sudo python3 dns.py' Enter
fi

result=$(echo $hostname | grep "server")
if [[ "$result" != "" ]]; then
    tmux send-key -t fastroute:0 'rm -f ~/server*.log && rm -rf ~/experiment_results && mkdir -p ~/experiment_results && mkdir -p ~/experiment_results/deliver_info' Enter
    tmux send-key -t fastroute:0 'cd ~ && bash ~/FastRoute/server/FastRoute_server.sh' Enter
    sleep 3
    tmux send-key -t fastroute:0 'cd ~/FastRoute/server && python3 LoadMonitor.py' Enter
    sleep 3
    tmux new-window -t fastroute:1
    tmux send-key -t fastroute:1 "top -b -d 0.1 | grep -a '%Cpu' >> ~/FastRoute/server/top.log" Enter
    tmux new-window -t fastroute:2
    tmux send-key -t fastroute:2 "sudo ~/iptraf-ng-1.2.1/iptraf-ng -i all -L ~/FastRoute/server/traffic.log" Enter
fi

result=$(echo $hostname | grep "client")
if [[ "$result" != "" ]]; then
    tmux send-key -t fastroute:0 'rm -rf ~/FastRoute/client/experiment_results && mkdir -p ~/FastRoute/client/experiment_results' Enter
    tmux send-key -t fastroute:0 'bash ~/FastRoute/client/FastRoute_client.sh' Enter
fi
date > ~/start_experiment.sh.end_ts