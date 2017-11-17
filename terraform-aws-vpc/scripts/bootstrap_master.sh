apt-get install curl wget vim -y
apt-get install software-properties-common -y
add-apt-repository ppa:saltstack/salt -y
apt-get install salt-master salt-cloud salt-doc -y

MYIP=$(ip a|grep 'inet '|grep -v 'host lo' |grep scope|awk '{print $2}'|awk -F'/' '{print $1}')
#Pem file name
KEY="demo_bv"
KEYNAME="demo_BV"

#Simple Salt Master config
echo "
worker_threads: 5
timeout: 25
file_roots:
  base:
    - /opt/salt/
top_file_merging_strategy: same
default_top: base
fileserver_backend:
  - roots
  - git
pillar_roots:
  base:
    - /opt/salt/pillar
log_level_logfile: debug
yaml_utf8: True
" > /etc/salt/master


echo "-----BEGIN RSA PRIVATE KEY-----
This is your aws key
-----END RSA PRIVATE KEY-----" > /home/ubuntu/.ssh/$KEY

chmod 400 /home/ubuntu/.ssh/$KEY
chown ubuntu:ubuntu /home/ubuntu/.ssh/$KEY
cp /home/ubuntu/.ssh/$KEY /etc/salt/$KEY

echo "-----BEGIN RSA PRIVATE KEY-----
A ubuntu key is needed too, same for root...
-----END RSA PRIVATE KEY-----" > /home/ubuntu/.ssh/id_rsa

cp /home/ubuntu/.ssh/id_rsa /root/.ssh/id_rsa
chmod 400 /root/.ssh/id_rsa
chown root:root /root/.ssh/id_rsa


chmod 400 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
chown -R ubuntu:ubuntu /etc/salt


mkdir /opt/salt
cd /opt/
ssh-keyscan github.com >> /root/.ssh/known_hosts
cd /tmp
#for the sake of the simplicity I will copy only the folder needed
git clone git@github.com:bvcelari/test_bv.git
cp -r salt /opt

