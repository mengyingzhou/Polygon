cd ${HOME}
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

sudo apt update
sudo apt install unzip zip make gcc libncurses5-dev -y

curl -O https://lexbor.com/keys/lexbor_signing.key > /dev/null 2>&1
sudo apt-key add lexbor_signing.key > /dev/null 2>&1
sudo sh -c "echo 'deb https://packages.lexbor.com/ubuntu/ bionic liblexbor' > /etc/apt/sources.list.d/lexbor.list"
sudo sh -c "echo 'deb-src https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"

# Install softwares
sudo apt update
sudo apt install -yqq liblexbor liblexbor-dev jq libev-dev iftop sshpass

sudo apt update
sudo apt install -yqq -qq dnsutils bc mysql-client libmysqlclient-dev libmariadbclient18
