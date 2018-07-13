# BBS-provision-cookbook

## Table of Contents

- [Background](#Background)
- [Setup Chef](#SetupChef)
- [The Chef server](#TheChefServer)
    - [Upload cookbook](#UploadCookbook)
    - [Resolve dependencies](#ResolveDependencies)
- [Configure the node](#ConfigureTheNode)
    - [Bootstrapping](#Bootstrapping)
    - [Data bags](#DataBags)
- [Run the recipe](#RunTheRecipe)
- [Redefine the central build node](#RedefineTheCentralBuildNode)
- [Crontabs](#Crontabs)
- [Further development](#FurtherDevelopment)
    - [Updating node configuration](#UpdatingNodeConfiguration)
    - [Adding a new recipe](#AddingANewRecipe)


<a name="Background"></a>
## Background 

The BBS-provision-cookbook is used to configure test machines
when rolling out new Bioconductor Build System (BBS) features.
It is not currently run on the primary build machines.

As of July 2018 the default recipe takes about 1 hour and 10 minutes
to complete.

Some terminology:

* workstation: 

  The computer from which you author your cookbooks and 
  administer your network.

* Chef server: 

  Acts as a central repository for cookbooks as well as for 
  information about nodes it manages.

* node: 

  Any computer managed by a Chef server. Every node has the Chef 
  client installed on it.

<a name="SetupChef"></a>
## Setup Chef

The normal Chef workflow involves managing servers remotely from a local
workstation. Logging into the node to manage it directly is important when
trouble shooting. The Chef Development Kit provides tools that enable node
management both remotely and from a local workstation.

If you are not set up with a local Chef installation, follow one of the
tutorials at

https://learn.chef.io/#/modules
https://learn.chef.io/modules/learn-the-basics/ubuntu/aws/set-up-a-machine-to-manage#/

<a name="TheChefServer"></a>
## The Chef server

We use a hosted Chef server at https://manage.chef.io/. You should have
an account and be able to log in to see the nodes and cookbooks.

The Chef server acts as a configuration hub. It stores cookbooks, polices
applied to nodes and other metadata. Nodes use the `chef-client` executable
to query the Chef server for configuration details. Configuration work
is then done on the nodes (vs the server).

All cookbooks, data and dependencies needed by a Chef recipe must be present
on the Chef server so they are accessible by the node. 

<a name="UploadCookbook"></a>
### Upload cookbook

The BBS-provision-cookbook should already be uploaded to the server. To see a
list of all cookbooks from the command line:

    knife cookbook list

Making any necessary local changes to the cookbook, bump the version in 
metadata.rb and upload:

    knife cookbook upload BBS-provision-cookbook

Confirm the new version is on the server:

    knife cookbook list

<a name="ResolveDependencies"></a>
### Resolve dependencies

Chef itself does not resolve cookbook dependencies. All dependencies are 
assumed to either be installed on the Chef server or available from the official 
Chef Supermarket. 

To get the necessary cookbook dependencies to the Chef server we use Berkshelf.
Berkshelf is a dependency manager for Chef cookbooks and it is now included in
the Chef DK. It (or something similar) is needed to get cookbook dependencies
from locations other than the Chef Supermarket such as GitHub or a local path. 

If you don't have Chef DK installed you can get Berkshelf with

    gem install berkshelf

The Berksfile is the most critical component of Berkshelf and is modeled
after Bundler's Gemfile. The file contains 
3 primary settings:

    source : Location of cookbooks and dependencies if not available locally with Berkshelf.
    metadata : Directive to read metadata.rb.
    cookbook : List of all the cookbooks/dependencies required.

Calling `berks install` downloads all cookbook dependencies to the local
workstation and `berks upload` uploads them to the Chef server. The `berks`
command must be run at the same level as the Berksfile.

Resolve dependencies on other cookbooks with Berkshelf:

    cd BBS-provision-cookbook/
    berks install
    berks upload --no-freeze

<a name="ConfigureTheNode"></a>
## Configure the node 

This example uses an AWS EC2 instance as the node.

Launch an AWS EC2 instance with at least 4 cpus and 16 GB of memory.  Increase
the disk storage to 20 or 50 GB depending on what type of testing will be done.
Open ports 22, 80 and 443.

Once the instance is running it can be configured manually by logging
into the EC2 or remotely from your local workstation. These instructions
describe a remote configuration. For a manual approach, see this page:

https://learn.chef.io/modules/learn-the-basics/ubuntu/aws/set-up-a-machine-to-manage#/

<a name="Bootstrapping"></a>
### Bootstrapping

Configure Chef on the node:

    knife bootstrap 34.207.158.122 --ssh-user ubuntu --sudo --identity-file /home/vobencha/.ssh/vobencha-keypair.pem --node-name val-test-malbec 

Confirm the node was associated with the server:

    knife node list
    knife node show val-test-malbec 

At this point the run list on the node is empty. Run list options in the
BBS-provision-cookbook/test/integration/roles/ directory.

Add the run list:

    knife node run_list add val-test-malbec 'recipe[BBS-provision-cookbook::default],role[bbs_devel_linux]'

Confirm the run list was added:

    knife node show val-test-malbec 

The run list involves a "role". There are several ways to handle 'special
cases' and using roles is one of them. There are roles for release and devel -
each set a variable value on the node which is accessed by the cookbook recipe
during run time. Use 'role list' and 'role show' to see the roles defined on
the server.

    knife role list
    knife role show bbs_devel_linux

The above steps can be combined into one. Running them separately (as above)
has the advantage of confirming each step as you go and makes troubleshooting
easier. To combine them, these would be the one-liners:

Key authentication:

    knife bootstrap 34.207.158.122 --ssh-user ubuntu --identity-file ~/.ssh/vobencha-keypair.pem --sudo --use-sudo-password --node-name val-test-malbec --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'

Or when password authentication is used:

    knife bootstrap 34.207.158.122 --ssh-user ubuntu --ssh-password 'PASS' --sudo --use-sudo-password --node-name val-test-malbec --run-list 'role[bbs_devel_linux],recipe[BBS-provision-cookbook]'

<a name="DataBags"></a>
### Data bags

A data bag is a global variable that is stored as JSON and is accessible
from a Chef server. The bags are indexed for searching and can be loaded by a
recipe or accessed during a search. We use these to store keys.

Inside a data bag are data bag items. Each item has been encrypted with a
secret key. To use these data in a recipe the items must be on the
Chef server and the encryption key must be on the Chef client.

* Data bags on the Chef server:

The data bags in BBS-provision-cookbook were uploaded when we invoked
`knife upload ...`. Confirm the BBS data bag is on the server:

    knife data bag list
    knife data bag show BBS

* Encryption key to Chef client:

The encryption key is in the Google Doc "Credentials for Bioconductor
Resources". Copy the key to /etc/chef/encrypted_data_bag_secret file on the
client node. Permissions on the encrypted_data_bag_secret file should be 600.

<a name="RunTheRecipe"></a>
## Run the recipe

The recipe can be run on the node by invoking the `chef-client` executable.
This was installed on the node during the bootstrap stage and invoking it
forces execution of the run list.

    knife ssh 'name:val-test-malbec' 'sudo chef-client' --ssh-user ubuntu --ssh-identity-file ~/.ssh/vobencha-keypair.pem --attribute cloud.public_ipv4

<a name="RedefineTheCentralBuildNode"></a>
## Redefine the central build node

This Chef recipe configures a Linux build node and pulls in the BBS code base
from GitHub. When we configure a node with this recipe we (usually) want the
newly configured node to play the role of the central builder.

To accomplish this, the `BBS_CENTRAL_RHOST` and `BBS_MEAT0_RHOST` variables in 
the BBS code on the node need to reference the node's hostname instead of the
canonical central builder.

In the context of the regular build system, the master builder 
and all machines participating in the builds have `BBS_CENTRAL_RHOST` 
and `BBS_MEAT0_RHOST` set to either malbec1.bioconductor.org or
malbec2.bioconductor.org.

The Chef recipe configures a node with hostname malbec1 or malbec2, without
the `.bioconductor.org` extension.

Confirm the hostname of the newly configured node. For example, we'll say
this returns malbec1:

    echo $HOSTNAME 

Set `BBS_CENTRAL_RHOST` to malbec1 instead of malbec1.bioconductor.org
in these config.sh files:

    /home/biocbuild/BBS/3.8/config.sh
    /home/biocadmin/BBS/3.8/config.sh

Make sure the following works:

  cd ~/BBS/3.8/bioc/malbec1
  . config.sh
  /usr/bin/ssh -qi /home/biocbuild/.BBS/id_rsa $BBS_CENTRAL_RHOST

Set `BBS_MEAT0_RHOST` to malbec1 instead of malbec1.bioconductor.org
in the appropriate sub-build config file:

    /home/biocbuild/BBS/3.8/bioc/config.sh
    /home/biocbuild/BBS/3.8/bioc-longtests/config.sh
    /home/biocbuild/BBS/3.8/data-experiment/config.sh
    /home/biocbuild/BBS/3.8/workflows/config.sh

<a name="Crontabs"></a>
## Crontabs

The BBS-provision-cookbook has a separate recipe for generating crontabs for
the `biocbuild` and `biocadmin` users. This is not run as part of the default
recipe.

The cron tasks details are specified in
BBS-provision-cookbook/attributes/default.rb. If the
BBS-provision-cookbook::crontab recipe is run, be sure to modify the BBS config
files on the test nodes to avoid unwanted communication with the primary build
machines.

<a name="FurtherDevelopment"></a>
## Further Development

<a name="UpdatingNodeConfiguration"></a>
### Updating node configuration 

When developing, make changes to the local cookbook then uploaded to the 
Chef server:

    knife cookbook upload BBS-provision-cookbook

Re-run the cookbook on the node:

    knife ssh 'name:val-test-malbec' 'sudo chef-client' --ssh-user ubuntu --ssh-identity-file ~/.ssh/vobencha-keypair.pem --attribute cloud.public_ipv4

Good practice is to bump the version in metadata.rb for each substantial
change and commit to GitHub.

<a name="AddingANewRecipe"></a>
### Adding a new recipe

New recipes can be generated with `chef generate`, e.g., to create a 
recipe "crontab":

    chef generate recipe crontab 

Add a reference to the new recipe in `recipes/default.rb`:

    include_recipe 'BBS-provision-cookbook::crontab'

Alternatively, add it to the node's runlist on the Chef server:

    knife node run_list add val-test-malbec 'recipe[BBS-provision-cookbook::crontab]'
