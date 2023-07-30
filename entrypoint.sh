#!/bin/sh

cat /tmp/ssh/*.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo 'GatewayPorts yes' >> /etc/ssh/sshd_config
mkdir /run/sshd
/usr/sbin/sshd &
python3 -m http.server --bind 127.0.0.1 ${PORT} &
sleep infinity
