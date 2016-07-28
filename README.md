# BBS-provision-cookbook

## Bootstraping a node

1. Manually (?) upload the data bags secret to `/etc/chef/encrypted_data_bag_secret`

2. Run the bootstrap command, for example for malbec1 over VPN it is

  ```
  knife bootstrap 172.29.0.3 --ssh-user USER --ssh-password 'PASS' --sudo --use-sudo-password --node-name malbec1 --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'
  ```

## Update the node's configuration 

1. Upload the cookbook to the Chef server

  ```
  knife cookbook upload BBS-provision-cookbook
  ```

2. Run the cookbook on your node

  ```
  knife ssh ADDRESS 'sudo chef-client' --manual-list --ssh-user USER --ssh-password 'PASSWORD'
  ```
