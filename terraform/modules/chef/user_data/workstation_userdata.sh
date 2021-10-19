#! /bin/bash
set -xev


# Install Workstation && use dpkg to install...
wget https://packages.chef.io/files/stable/chef-workstation/0.2.43/ubuntu/18.04/chef-workstation_0.2.43-1_amd64.deb &&\
sudo dpkg -i chef-workstation_0.2.43-1_amd64.deb &&\
rm chef-workstation_0.2.43-1_amd64.deb

# Create Repo
chef generate repo chef-repo

mkdir -p /home/ubuntu/.chef &&\
    chmod 777 /home/ubuntu/.chef

# Copy Keys
sudo aws s3 cp s3://dmw2151-chef/pem/ /home/ubuntu/.ssh/ --recursive

export AWS__REGION=`(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)`
export CHEF__INFRA_SERVER_IP=`(aws ssm get-parameter --name chef_server_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`
export CHEF__INFRA_SERVER_DNS=`(aws ssm get-parameter --name chef_server_dns --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`

echo `(aws ssm get-parameters --names chef_server_config --region=${AWS__REGION} | jq -r '.Parameters | first | .Value' | base64 -d)` > chef_config.json
export CHEF__ORG_NAME=`cat chef_config.json | jq -r '.organization'`

sudo cat > '/home/ubuntu/.chef/knife.rb' << EOF
log_level                :debug
log_location             STDOUT
validation_client_name   "${CHEF__ORG_NAME}-validator"
validation_key           "/home/ubuntu/.ssh/${CHEF__ORG_NAME}.pem"
client_key               "/home/ubuntu/.ssh/dmw2151.pem"
chef_server_url          "https://${CHEF__INFRA_SERVER_DNS}/organizations/${CHEF__ORG_NAME}"
cookbook_path            ['/home/ubuntu/chef-repo/cookbooks']
EOF

knife ssl fetch && knife ssl check

knife role create --disable-editing worker \
    --key /home/ubuntu/.chef/$CHEF__USER_NAME.pem \
    --verbose \
    --user dmw2151 \
    --config /home/ubuntu/.chef/knife.rb

knife role create --disable-editing server\
    --key /home/ubuntu/.chef/$CHEF__USER_NAME.pem \
    --verbose \
    --user dmw2151 \
    --config /home/ubuntu/.chef/knife.rb


cd ~/chef-repo/cookbooks && chef generate cookbook jupyter

