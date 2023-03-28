hostname=`hostname`
server="server"
dns="dns"

cd ${HOME}
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

sudo apt update
sudo apt install unzip zip bind9 bind9utils bind9-doc resolvconf make gcc libncurses5-dev make gcc wondershaper -y

curl -O https://lexbor.com/keys/lexbor_signing.key
sudo apt-key add lexbor_signing.key
sudo sh -c "echo 'deb https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo sh -c "echo 'deb-src https://packages.lexbor.com/ubuntu/ bionic liblexbor' >> /etc/apt/sources.list.d/lexbor.list"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -yqq liblexbor liblexbor-dev jq libev-dev iftop

if [ ! -f "${HOME}/get-pip.py" ]; then
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo apt install -y python3-distutils
    sudo python3 get-pip.py
    pip install flask scrapy beautifulsoup4 dnspython gunicorn supervisor
fi

if [ ! -d "${HOME}/iptraf-ng-1.2.1" ]; then
    wget https://github.com/iptraf-ng/iptraf-ng/archive/refs/tags/v1.2.1.zip
    unzip v1.2.1.zip
    cd iptraf-ng-1.2.1
    make install
fi
