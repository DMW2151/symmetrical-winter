
# Apt Get Install NFS Client


# Create /efs for mount
directory '/efs' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
end

execute 'apache_configtest' do
    command 'export MOUNT_IP=`(aws ssm get-parameter --name chef_server_ip --region=${AWS__REGION} | jq -r '.Parameter | .Value' )`'
end

# Install nfs-common
package "nfs-common" do
    action :install
end

