#! /bin/bash
set -xev

# Install Utils
sudo apt update &&\
    sudo apt -y upgrade &&\
    sudo apt install -y jq awscli

# Create Repo && Default cookbooks
cd /home/ubuntu &&\
    chef generate repo chef-repo

# Create cookook in repo && grant ownership to ubuntu
cd /home/ubuntu/chef-repo/cookbooks &&\
    chef generate cookbook jupyter &&\
    sudo chown -R ubuntu /home/ubuntu/chef-repo/

mkdir -p /home/ubuntu/.chef &&\
    chmod 777 /home/ubuntu/.chef

export AWS__REGION=`(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)`
export CHEF__INFRA_SERVER_IP=`(aws ssm get-parameter --name chef_server_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`
export CHEF__INFRA_SERVER_DNS=`(aws ssm get-parameter --name chef_server_dns --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`

echo `(aws ssm get-parameters --names chef_server_config --region=${AWS__REGION} | jq -r '.Parameters | first | .Value' | base64 -d)` > chef_config.json
export CHEF__ORG_NAME=`cat chef_config.json | jq -r '.organization'`
export CHEF__USER_NAME=`cat chef_config.json | jq -r '.username'`

sudo cat > '/home/ubuntu/.chef/knife.rb' << EOF
log_level                :debug
log_location             STDOUT
validation_client_name   "${CHEF__ORG_NAME}-validator"
validation_key           "/home/ubuntu/.ssh/${CHEF__ORG_NAME}.pem"
client_key               "/home/ubuntu/.ssh/${CHEF__USER_NAME}.pem"
chef_server_url          "https://${CHEF__INFRA_SERVER_DNS}/organizations/${CHEF__ORG_NAME}"
cookbook_path            ['/home/ubuntu/chef-repo/cookbooks']
EOF

# [TODO]: Clean up this bucket s.t. multiple keys don't stay here between 
# runs => should only contain a *.crt and *.key
sudo aws s3 cp s3://${CHEF__USER_NAME}-chef/pem/ /home/ubuntu/.ssh/ --recursive

# Init Roles for Worker Nodes - SSL validate
knife ssl fetch &&\
    knife ssl check

knife role create --disable-editing worker \
    --key /home/ubuntu/.chef/$CHEF__USER_NAME.pem \
    --verbose \
    --user ${CHEF__USER_NAME} \
    --key /home/ubuntu/.ssh/${CHEF__USER_NAME}.pem \
    --config /home/ubuntu/.chef/knife.rb

knife role create --disable-editing server\
    --key /home/ubuntu/.chef/$CHEF__USER_NAME.pem \
    --verbose \
    --user ${CHEF__USER_NAME} \
    --key /home/ubuntu/.ssh/${CHEF__USER_NAME}.pem \
    --config /home/ubuntu/.chef/knife.rb


