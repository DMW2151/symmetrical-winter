#! bin/bash
set -xev

#
# This userdata runs on an auto-scaling (or spot) instance. Need to do an unattended registration of
# a new node. The below registers the node, replicating what `knife bootstrap` does but from the 
# node -> server; not server -> node
#
# See Reference: https://docs.chef.io/install_bootstrap/#unattended-installs
#

# Update Apt for Chef Install && Node registration
sudo apt update &&\
    sudo apt -y upgrade &&\
    sudo apt install -y jq awscli


# Get Params for the Installation && Registration!
export AWS__REGION=`(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)`
export CHEF__INFRA_SERVER_IP=`(aws ssm get-parameter --name chef_server_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`
export CHEF__INFRA_SERVER_DNS=`(aws ssm get-parameter --name chef_server_dns --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`

echo `(aws ssm get-parameters --names chef_server_config --region=${AWS__REGION} | jq -r '.Parameters | first | .Value' | base64 -d)` > chef_config.json
export CHEF__ORG_NAME=`cat chef_config.json | jq -r '.organization'`

# Generate a random node name in the format `node-XXXXXXXX`
export NODE_NAME=node-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

# Create logging locations etc...
sudo mkdir -p /etc/chef &&\
    sudo mkdir -p /var/lib/chef &&\
    sudo mkdir -p /var/log/chef 

sudo chown ubuntu /etc/chef/

# Setup /etc/hosts file with the IP of the Infra Server, can now refer to infra server 
# with `infra-server`
echo """
$CHEF__INFRA_SERVER_IP    infra-server infra-server.automate.com
""" >> /etc/hosts

# Install Chef Client
sudo wget https://omnitruck.chef.io/install.sh -O /etc/chef/install.sh &&\
sudo bash /etc/chef/install.sh

# Copy Certs from S3 -> Local Trusted Certs, analagous to checking 
# `knife ssl check -s https://infra-server/` and `knife ssl fetch ...`
sudo aws s3 cp s3://dmw2151-chef/nginx/ /etc/chef/trusted_certs/ --recursive &&\
sudo rm /etc/chef/trusted_certs/dhparams.pem

# [TODO][NOTE]: Per suggestion on Chef blog, try to rely on custom keys rather than org 
# level validator - Use custom keys for each node if time permits...

# In lieu of doing something like the below, use aws s3 cp to pull down keys!
# `scp ubuntu@$CHEF__INFRA_SERVER_IP:~/.chef/*.pem /home/ubuntu/.chef/`
sudo aws s3 cp s3://dmw2151-chef/pem/ /home/ubuntu/.ssh/ --recursive

# Create Config w. Validation Client and Validator from S3...
sudo touch /etc/chef/client.rb &&\
    sudo chmod 777 /etc/chef/client.rb

cat > '/etc/chef/client.rb' << EOF
log_level                :debug
log_location             STDOUT
node_name                "${NODE_NAME}"
validation_client_name   "${CHEF__ORG_NAME}-validator"
validation_key           "/home/ubuntu/.ssh/${CHEF__ORG_NAME}.pem"
chef_server_url          "https://${CHEF__INFRA_SERVER_DNS}/organizations/${CHEF__ORG_NAME}"
EOF

# Assumes there is a role named base - depends on when the ASG instance launches; assume
# launch is AFTER the server!!!
sudo cat > "/etc/chef/first-boot.json" << EOF
{
   "run_list" :[ "role[server]" ]
}
EOF

# Register Node...
sudo chef-client -j /etc/chef/first-boot.json \
    --chef-license=accept \
    --config /etc/chef/client.rb