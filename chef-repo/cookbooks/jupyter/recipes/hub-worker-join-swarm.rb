#
# Cookbook:: jupyter
# Recipe:: Hub Worker Join Swarm
#
# Copyright:: 2021, The Authors, All Rights Reserved.


# Docker Swarm Worker Node - Get SSM Parameter and Join Node
execute 'docker_swarm_join' do
    command "        
        AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
        SVC__SWARM_TOKEN=$(aws ssm get-parameter --name swarm_leader_token --region $AWS__REGION | jq -r '.Parameter.Value')
        SVC__SWARM_LEADER=$(aws servicediscovery discover-instances --namespace-name local.maphub.dev --service-name swarm_svc --region $AWS__REGION | jq -r '.Instances | first | .Attributes.AWS_INSTANCE_IPV4')
        
        sudo docker swarm join \
            --token $SVC__SWARM_TOKEN $SVC__SWARM_LEADER:2377
    "
    not_if "sudo docker info --format '{{.Swarm.LocalNodeState}}' | grep -iE ^active"
    action :run
end
