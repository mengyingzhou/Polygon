date > ~/start_dispatcher.sh.start_ts

hostname=`hostname`
zone=${hostname:0:`expr ${#hostname} - 7`}
export zone=${zone:7}
zone=`python3 -c "import os; print('-'.join([''.join((t[:2], t[-2:])) for t in '${zone}'.split('-')[:2]]))"`

for i in `seq 100`
do
	{
		port=$((4433+${i}))
		echo balancer_$port
		while true
		do
			ps -ef | grep "$port ${HOME}/data" | grep -v "grep"
			if [ "$?" -eq 1 ]
			then
				#启动应用，修改成自己的启动应用脚本或命令
				echo sudo LD_LIBRARY_PATH=~/data ~/data/balancer --datacenter ${zone} --user johnson --password johnson bridge 0.0.0.0 $port ~/data/server.key ~/data/server.crt -q
				sudo LD_LIBRARY_PATH=~/data ~/data/balancer --datacenter ${zone} --user johnson --password johnson bridge 0.0.0.0 $port ~/data/server.key ~/data/server.crt -q 1>> ${HOME}/balancer_tmp_${port}.log 2>> ${HOME}/balancer_${port}.log 

				# echo "process has been restarted!"
			else
				echo "process already started!"
			fi
			sleep 10
		done
	} &
done

date > ~/start_dispatcher.sh.end_ts

