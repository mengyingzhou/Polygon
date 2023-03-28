date > ~/start_experiment.sh.start_ts

tmux has-session -t main 2> /dev/null; if [[ $? == 0  ]]; then tmux kill-session -t main; fi
tmux new-session -ds main
for i in `seq 4`
do
    tmux new-window -t main:${i}
done

hostname=`hostname`
role=${hostname:`expr ${#hostname} - 6`:6}
bash ~/data/kill_server.sh
sleep 5
case $role in
    "router")
        tmux send-key -t main:0 'rm -f ~/balancer*.log && rm -rf ~/experiment_results && mkdir -p ~/experiment_results' Enter
        tmux send-key -t main:0 'sleep 5 && ~/data/start_dispatcher.sh' Enter
        tmux send-key -t main:1 'mysql -ujohnson -pjohnson serviceid_db' Enter
        tmux send-key -t main:2 '~/data/init_router_bw.sh' Enter
        tmux send-key -t main:3 'sudo ~/iptraf-ng-1.2.1/iptraf-ng -i all -L ~/traffic.log' Enter
        ;;
    "server")
        tmux send-key -t main:0 'rm -f ~/server*.log && rm -rf ~/experiment_results && mkdir -p ~/experiment_results && mkdir -p ~/experiment_results/deliver_info' Enter
        tmux send-key -t main:0 'sleep 5 && ~/data/start_server.sh' Enter
        tmux send-key -t main:1 '~/data/init_server_bw.sh' Enter
        tmux send-key -t main:3 'sudo ~/iptraf-ng-1.2.1/iptraf-ng -i all -L ~/traffic.log' Enter
        tmux send-key -t main:4 'sudo iftop -t > ~/iftop_log.txt' Enter
        ;;
esac

date > ~/start_experiment.sh.end_ts
