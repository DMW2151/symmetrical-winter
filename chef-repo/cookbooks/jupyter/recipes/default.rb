#
# Cookbook:: jupyter
# Recipe:: default
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Always run in Debug Mode -> Keep Logs Active
Chef::Log.info('Enabling debug log for first run')
Chef::Log.level = :debug

# Include Jupyter Notebook Init Recipes
include_recipe 'jupyter::common-apt-get'
include_recipe 'jupyter::common-efs-dir'
include_recipe 'jupyter::hub-master-docker-init'
include_recipe 'jupyter::hub-master-jupyter'
include_recipe 'jupyter::hub-worker-join-swarm'