#! /bin/bash

# Basic Apt Updates
sudo apt update &&\
    sudo apt -y upgrade &&\
    sudo apt install -y jq awscli

# Fetch Instance Identity Document
# See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)

# Configure default user and organization, ssetting env vars from params fetched vis SSM
aws ssm get-parameters \
    --names chef_server_config \
    --region=${AWS__REGION} | jq -r '.Parameters | first | .Value' | base64 -d > chef_config.json

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


