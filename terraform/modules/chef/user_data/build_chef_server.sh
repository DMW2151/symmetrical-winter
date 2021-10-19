#! /bin/bash

# Configures Chef Infrastucture Server - Should see Chef on 
# `https://ec2-xxx-xxx-xxx-xxx.compute-1.amazonaws.com/login`, DNS left as exercise!
# If user data has run properly...

# Basic apt-get update; install aws utils + jq for parsing misc. data
sudo apt update &&\
    sudo apt -y upgrade &&\
    sudo apt install -y jq awscli

# Installing && Configuring the Chef Server, this does a lot of the heavy 
# lifting but takes a while! See note on waiting on cloud init!
#
# Reference: https://www.linode.com/docs/guides/install-a-chef-server-workstation-on-ubuntu-18-04/
#
wget https://packages.chef.io/files/stable/chef-server/13.1.13/ubuntu/18.04/chef-server-core_13.1.13-1_amd64.deb

sudo dpkg -i chef-server-core_13.1.13-1_amd64.deb &&\
    sudo chef-server-ctl reconfigure --chef-license=accept

# Init Chef Infrastructure frontend && Reconfigure
sudo chef-server-ctl install chef-manage &&\
    sudo chef-server-ctl reconfigure &&\
    sudo chef-manage-ctl reconfigure 

# Configure Default User and Organization - Setting params from SSM
export AWS__REGION="us-east-1"
echo `(aws ssm get-parameters --names chef_server_config --region=${AWS__REGION} | jq -r '.Parameters | first | .Value' | base64 -d)` > chef_config.json

# Start Server User + Org Creation...
export CHEF__USER_NAME=`cat chef_config.json | jq -r '.username'`
export CHEF__FIRST_NAME=`cat chef_config.json | jq -r '.firstname'`
export CHEF__LAST_NAME=`cat chef_config.json | jq -r '.lastname'`
export CHEF__EMAIL=`cat chef_config.json | jq -r '.email'`
export CHEF__PWD=`cat chef_config.json | jq -r '.password'`
export CHEF__ORG_NAME=`cat chef_config.json | jq -r '.organization'`

# Init Chef Directory && Create Default Org and "Admin" user...
mkdir -p /home/ubuntu/.chef &&\
    chmod 777 /home/ubuntu/.chef

sudo chef-server-ctl user-create $CHEF__USER_NAME $CHEF__FIRST_NAME $CHEF__LAST_NAME $CHEF__EMAIL $CHEF__PWD \
    --filename /home/ubuntu/.chef/$CHEF__USER_NAME.pem

sudo chef-server-ctl org-create $CHEF__ORG_NAME "$CHEF__ORG_NAME" \
    --association_user $CHEF__USER_NAME \
    --filename /home/ubuntu/.chef/$CHEF__ORG_NAME.pem

# Move Org and User Certs to S3 locked down bucket! [NOTE]: Consider a Secure Parameter!
sudo aws s3 cp /var/opt/opscode/nginx/ca/ s3://$CHEF__USER_NAME-chef/nginx/ --recursive
sudo aws s3 cp /home/ubuntu/.chef/ s3://$CHEF__USER_NAME-chef/pem/ --recursive


