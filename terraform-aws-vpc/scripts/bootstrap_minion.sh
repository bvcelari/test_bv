MASTER_IP=$1
HOST_NAME=$2

curl -L https://bootstrap.saltstack.com -o install_salt.sh
sudo sh install_salt.sh -P

pip install boto
locale-gen 'en_EN.UTF-8'
dpkg-reconfigure locales

#HOST_NAME="$HOST_NAME-`hostname`"
#hostname $HOST_NAME

#in case the is a key there.... not sure why was ther in first instance..
rm /etc/salt/pki/minion/minion_master.pub


echo "id: $HOST_NAME
master: $MASTER_IP
mine_functions:
  network.ip_addrs: []
startup_states: 'deployment'
" > /etc/salt/minion

service salt-minion restart

#COuld be used the module saltify, but it's gonna need more time, I had done it before and I like it

