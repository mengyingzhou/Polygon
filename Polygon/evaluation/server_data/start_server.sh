date > ~/start_server.sh.start_ts

unicast=`python3 -c 'import socket; import os; import json; machines=json.load(open("server.json")); print(machines[socket.gethostname()]["external_ip1"])'`

for i in `seq 100`
do 
    {
        port=$((4433+$i))
        echo server_$port
        echo sudo LD_LIBRARY_PATH=~/data ~/data/server --interface=ens4 --unicast=${unicast} 0.0.0.0 $port ~/data/server.key ~/data/server.crt -q
        sudo LD_LIBRARY_PATH=~/data ~/data/server --interface=ens4 --unicast=${unicast} 0.0.0.0 $port ~/data/server.key ~/data/server.crt -q 1>> ~/server_tmp_${port}.log 2>> ~/server_${port}.log
    } &
done

date > ~/start_server.sh.end_ts
