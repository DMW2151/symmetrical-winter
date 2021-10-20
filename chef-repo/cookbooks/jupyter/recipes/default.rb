#
# Cookbook:: jupyter
# Recipe:: default
#
# Copyright:: 2021, The Authors, All Rights Reserved.

include_recipe 'jupyter::common-apt-get'
include_recipe 'jupyter::common-efs-dir'
include_recipe 'jupyter::hub-master-docker-init'
include_recipe 'jupyter::hub-master-jupyter'
include_recipe 'jupyter::hub-master-nginx'