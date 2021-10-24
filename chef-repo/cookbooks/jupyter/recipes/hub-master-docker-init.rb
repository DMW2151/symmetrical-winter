#
# Cookbook:: jupyter
# Recipe:: Hub Master Start Docker
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Docker Swarm Master Node - Generate Token for Worker Node to add self to swarn
execute 'docker_swarm_add' do
    command "sudo docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')"
    not_if 'sudo docker swarm join-token worker'
    action :run
end

# Docker Swarm Master Node - Advertise Leader Node via SSM parameter...
execute 'advertize_swarm_token' do
    command "aws ssm put-parameter \
        --name swarm_leader_token \
        --region $(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r) \
        --value $(sudo docker swarm join-token --quiet worker)\
        --type String\
        --overwrite"
    action :run
end
