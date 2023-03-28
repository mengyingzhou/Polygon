cd ${HOME}
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

sudo apt update
sudo apt install unzip zip make gcc libncurses5-dev -y

curl -O https://lexbor.com/keys/lexbor_signing.key
sudo apt-key add lexbor_signing.key
sudo sh -c "echo 'deb https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo sh -c "echo 'deb-src https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq liblexbor liblexbor-dev jq libev-dev iftop

if [ ! -d "${HOME}/iptraf-ng-1.2.1" ]; then
    wget https://github.com/iptraf-ng/iptraf-ng/archive/refs/tags/v1.2.1.zip
    unzip v1.2.1.zip
    cd iptraf-ng-1.2.1
    make install
fi
