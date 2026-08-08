#!/bin/bash
PORT_ID=4022
COMMON_PATH=/root/common
sed -i "s/#Port 22/Port ${PORT_ID}/g" /etc/ssh/sshd_config
sed -i "s/#   Port 22/    Port ${PORT_ID}/g" /etc/ssh/ssh_config
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
service ssh restart

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    mkdir -p ~/.ssh
    cd ~/.ssh
    ssh-keygen -t rsa -b 4096 -f id_rsa -q -N ""
fi

# Append public key and make it accessible to all nodes
cat ~/.ssh/id_rsa.pub >> "${COMMON_PATH}/public_keys"
echo "Public key appended to ${COMMON_PATH}/public_keys ..."
echo "Exiting ..."