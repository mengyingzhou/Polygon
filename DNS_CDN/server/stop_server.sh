ps -ef | grep "server.crt" | grep -v grep | awk '{print $2}' | sudo xargs sudo kill -9
sudo wondershaper clear ens4
ps -ef | grep "top" | grep -v grep | awk '{print $2}' | sudo xargs sudo kill -9
ps -ef | grep "iptraf" | grep -v grep | awk '{print $2}' | sudo xargs sudo kill -9
ps -ef | grep cpu/cpu/www.cpu/src/cpu.py |grep -v grep|cut -c 8-14|sudo xargs kill -9