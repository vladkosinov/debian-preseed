 #!/bin/sh
exec >>/root/bootstrap.out 2>&1
set -x

mkdir --mode=700 /root/.ssh;
wget --output-document=/root/.ssh/authorized_keys http://192.168.2.1/authorized_keys;
chmod 644 /root/.ssh/authorized_keys;

mkdir --mode=700 /home/user/.ssh;
cp /root/.ssh/authorized_keys /home/user/.ssh/authorized_keys
chown -R user:user /home/user/.ssh;
chmod 644 /home/user/.ssh/authorized_keys;

modprobe -r iwlwifi;
modprobe iwlwifi;
