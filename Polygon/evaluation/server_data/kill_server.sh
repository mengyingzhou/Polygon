ps -ef | grep "data/server.crt" | grep -v grep | awk '{print $3}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "data/server.crt" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "data/server.crt" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "sleep" | grep -v grep | awk '{print $3}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "sleep" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "top -b -d 0.1" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "iftop" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
ps -ef | grep "iptraf" | grep -v grep | awk '{print $2}' | xargs sudo kill -9 > /dev/null 2>&1
sudo wondershaper clear ens4
