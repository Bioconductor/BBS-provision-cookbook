# BBS-provision-cookbook

## Updating the cookbook

To list all cookbooks on Chef server run
```
knife cookbook list
```
Upload your cookbook with
```
knife cookbook upload BBS-provision-cookbook
```
Resolve dependencies on other cookbooks with Berkshelf.
```
berks install
berks upload
```

## Bootstraping a node

1. Manually (?) upload the data bags secret to `/etc/chef/encrypted_data_bag_secret`

2. Run the bootstrap command, for example for malbec1 over VPN it is

  ```
  knife bootstrap 172.29.0.3 --ssh-user USER --ssh-password 'PASS' --sudo --use-sudo-password --node-name malbec1 --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'
  ```

## Updating the node's configuration 

Work on the cookbook locally. Once ready, upload it to the Chef server

  ```
  knife cookbook upload BBS-provision-cookbook
  ```

and run the cookbook on your node

  ```
  knife ssh ADDRESS 'sudo chef-client' --manual-list --ssh-user USER --ssh-password 'PASSWORD'
  ```

## Add a new recipe

Generate the file with `chef generate recipe cron` and reference the new recipe in `recipes/default.rb`.
```
include_recipe 'BBS-provision-cookbook::cron'
```
