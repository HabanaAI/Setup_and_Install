#!/bin/bash
PORT_ID=4022
COMMON_PATH=/root/common
# Append public keys from all nodes to authorized_keys
cat "${COMMON_PATH}/public_keys" >> ~/.ssh/authorized_keys
service ssh restart
while read node; do
    ssh-keyscan -p ${PORT_ID} -H ${node} >> ~/.ssh/known_hosts
done < "${COMMON_PATH}/nodes.txt"
#service ssh restart
echo "Added shared public_keys to authorized_keys and IPs to known_hosts ..."
echo "Checking Port status by running command 'lsof -i' ..."
lsof -i
echo "Exiting ..."