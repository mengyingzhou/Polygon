start_time=$(date "+%Y%m%d%H%M%S")
echo "start_time: ${start_time}" >> ~/FastRoute/server/top.log
top -b -d 0.1 | grep -a '%Cpu' >> ~/FastRoute/server/top.log