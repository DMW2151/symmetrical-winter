#
# Cookbook:: jupyter
# Recipe:: common-efs-dir
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Create /efs/hub for mount - `/efs/` for the mount and `/efs/hub` for the 
# mount into the shared notebook server
directory '/efs/hub' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    recursive true
    action :create
end

# Mount NFS/EFS volume to the `/efs` directory if mount is 
# not there
execute "nfs_mount" do
    command "
    set -x; 

    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    export AWS__NFS_MOUNT_IP=$(aws ssm get-parameter --name nfs_mount_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value')

    sudo mount -t nfs4 \
        -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $AWS__NFS_MOUNT_IP:/ /efs
    "
    action :run
    not_if 'mount -l | grep nfs'
end

