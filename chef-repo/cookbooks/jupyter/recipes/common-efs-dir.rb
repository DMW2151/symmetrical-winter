
# Apt Get Install NFS Client

# Create /efs for mount
directory '/efs' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    action :create
end


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

