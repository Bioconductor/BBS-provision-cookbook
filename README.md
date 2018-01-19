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

  ```bash
  knife bootstrap 172.29.0.3 --ssh-user USER --ssh-password 'PASS' --sudo --use-sudo-password --node-name malbec1 --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'
  ```
  or when key-based authentication is used
  ```bash
  knife bootstrap 54.243.13.96 --ssh-user ubuntu --identity-file ~/.ssh/id_rsa --sudo --use-sudo-password --node-name Andrzej_workflow_testing --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'
  ```
### Verify the results

```bash
knife node list
knife node show malbec2
```

## Updating the node's configuration 

Work on the cookbook locally. Once ready, upload it to the Chef server

```bash
knife cookbook upload BBS-provision-cookbook
```

and run the cookbook on your node.

```bash
knife ssh ADDRESS 'sudo chef-client' --manual-list --ssh-user USER --ssh-password 'PASSWORD'
```

## Add a new recipe

Generate the file with `chef generate recipe crontab` and reference the new recipe in `recipes/default.rb`.

```bash
include_recipe 'BBS-provision-cookbook::crontab'
```

Alternatively, add it to the node's runlist.

```bash
knife node run_list add malbec2 'recipe[BBS-provision-cookbook::crontab]'
```
