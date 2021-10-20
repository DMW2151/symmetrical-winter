#
# Cookbook:: jupyter
# Recipe:: hub-master-init-apt
#
# Copyright:: 2021, The Authors, All Rights Reserved.

execute "apt-update-upgrade" do
    command "sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
    action :run
end

# Install Basic Apt Requirements
package %w(nfs-common docker docker.io) do 
    action :install
end
