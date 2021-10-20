#! /bin/sh/

# [IS IDEMPOTENT] Set Recipes to Roles
knife role run_list set worker "recipe[jupyter::common-apt-get]", "recipe[jupyter::common-efs-dir]"\
    --user ${CHEF__USER_NAME} \
    --config /home/ubuntu/.chef/knife.rb

knife role run_list set server "role[worker]",  "recipe[jupyter::hub-master-docker-init]", "recipe[jupyter::hub-master-jupyter]", "recipe[jupyter::hub-master-nginx]"\
    --user ${CHEF__USER_NAME} \
    --config /home/ubuntu/.chef/knife.rb

# Upload Newest Version of the recipe to the Server
knife cookbook upload jupyter \
    --config /home/ubuntu/.chef/knife.rb \
    --user ${CHEF__USER_NAME} \
    --include-dependencies

# Run on!
knife ssh "role:worker" "sudo chef-client" \
    --ssh-user ubuntu \
    --user ${CHEF__USER_NAME}

knife ssh "role:server" "sudo chef-client" \
    --ssh-user ubuntu \
    --user ${CHEF__USER_NAME}