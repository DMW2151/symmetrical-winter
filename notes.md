

# Jhub Notes





# Chef Notes

## Local

```bash
# Send to Workstation
scp -r -i ~/.ssh/public-jump-1.pem ./jupyter ubuntu@18.232.56.212:/home/ubuntu/chef-repo/cookbooks
```

## On Workstation

```bash
knife role run_list add worker 'recipe[jupyter::apt]' \
    --user ${CHEF__USER_NAME} \
    --config /home/ubuntu/.chef/knife.rb

knife role run_list add server 'recipe[jupyter::apt]' \
    --user ${CHEF__USER_NAME} \
    --config /home/ubuntu/.chef/knife.rb

knife cookbook upload jupyter \
    --config /home/ubuntu/.chef/knife.rb \
    --user ${CHEF__USER_NAME} \
    --include-dependencies
```

## On Node

```bash
chef-client
```
