#
# Cookbook:: jupyter
# Recipe:: Hub Worker Join Swarm
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Docker Swarm Worker Node - Get SSM Parameter and Join Node
# TODO - Replace Hardcoded Vals...
execute 'docker_swarm_join' do
    command "   
        set -x;     
        AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
        SVC__SWARM_TOKEN=$(aws ssm get-parameter --name swarm_leader_token --region $AWS__REGION | jq -r '.Parameter.Value')
        SVC__SWARM_LEADER=$(aws servicediscovery discover-instances --namespace-name local.maphub.dev --service-name swarm_svc --region $AWS__REGION | jq -r '.Instances | first | .Attributes.AWS_INSTANCE_IPV4')
        
        sudo docker swarm join --token $SVC__SWARM_TOKEN $SVC__SWARM_LEADER:2377
    "
    not_if "sudo docker info --format '{{.Swarm.LocalNodeState}}' | grep -iE ^active"
    action :run
end

# Pre-Login for Faster Launch for First Users; minimal effect, but allows us to keep
# timeout low while debugging/demoing
execute 'ecr_repo_login' do
    command "
    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    export AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' -r)
    aws ecr get-login-password --region $AWS__REGION | sudo docker login --username AWS --password-stdin $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com
    "
    action :run
end

# Pre-Pull - Minimize Risk of Timeout on Container Launch
execute 'pull_analysis_notebook' do 
    command "
        set -x;
        AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
        AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
        sudo docker pull ${AWS__ACCOUNT_ID}.dkr.ecr.${AWS__REGION}.amazonaws.com/geospatial
    "
    action :run
end
