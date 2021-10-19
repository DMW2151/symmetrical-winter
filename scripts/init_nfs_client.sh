#!/bin/bash

sudo apt update &&\


sudo apt install -y \
    nfs-common

export AWS__REGION="us-east-1"
export MOUNT_IP=`(aws ssm get-parameter --name chef_server_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`

mkdir -p efs

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${MOUNT_IP}:/ efs