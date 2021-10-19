sudo knife cookbook upload jupyter --config /home/ubuntu/.chef/knife.rb --user foo


knife role run_list add worker 'recipe[jupyter::foo]' --user foo --config /home/ubuntu/.chef/knife.rb 

chef-client -z ./recipes/foo.rb

knife ssh "role:app" "sudo chef-client" -x myuser -p 22

- NGINX derivative openresty is not officially supported by certbot
