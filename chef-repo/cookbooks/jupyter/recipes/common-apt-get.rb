#
# Cookbook:: jupyter
# Recipe:: hub-master-init-apt
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Update and Upgrade Apt
execute "apt-update-upgrade" do
    command "
        sudo apt-get update &&\
        sudo DEBIAN_FRONTEND=noninteractive 
        apt-get -y \
            -o Dpkg::Options::='--force-confdef' \
            -o Dpkg::Options::='--force-confold' \
            upgrade
    "
    action :run
end

# Install Basic Apt Requirements for the Build 
#
# Should be New To the Instance:
#   nfs-common - NFS was developed to allow file sharing between systems residing on a local area network.
#   docker, dockerio -  Docker image and container command line interface &&
# 
# Should be installed by user data - Install here In event we switch the base AMI
#   jq - can transform JSON in various ways, by selecting, iterating, reducing and otherwise mangling JSON documents.
#   awscli - AWS command line client!
#
package %w(awscli jq nfs-common docker docker.io) do 
    action :install
end
