#
# Cookbook Name:: BBS-provision-cookbook
# Recipe:: cron
#
# Copyright (c) 2016 Andrzej Oles, All Rights Reserved.
include_recipe 'cron'

if node["reldev"] == "devel"
  reldev = :dev
elsif node["reldev"] == "release"
  reldev = :rel
else
  raise "are the bbs_devel and bbs_release roles defined?"
end

bioc_version = node['bioc_version'][reldev]
cron = node['cron']


## biocbuild

cron "set PATH" do
  user 'biocbuild'
  path '/usr/bin:/bin:/usr/local/bin'
  ## noop bash command that is never run (Feb 30) 
  command ":"
  month "2"
  day "30"
end

%w(bioc data-experiment).each do |type|

  cron "prerun #{type}" do
    time = cron['pre_run_time'][type][reldev]
    user 'biocbuild'
    command %W{
      cd /home/biocbuild/BBS/#{bioc_version}/#{type}/`hostname` &&
./prerun.sh >>/home/biocbuild/bbs-#{bioc_version}-#{type}/log/`hostname`-`date +\\%Y\\%m\\%d`-prerun.log 2>&1
      }.join(' ')
    minute time['minute']
    hour time['hour']
    day time['day']
    month time['month']
    weekday time['weekday']
  end
  
  cron "run #{type}" do
    time = cron['run_time'][type][reldev]
    user 'biocbuild'
    command %W{
      /bin/bash --login -c
      'cd /home/biocbuild/BBS/#{bioc_version}/#{type}/`hostname` &&
      ./run.sh >>/home/biocbuild/bbs-#{bioc_version}-#{type}/log/`hostname`-`date +\\%Y\\%m\\%d`-run.log 2>%1'
      }.join(' ')
    minute time['minute']
    hour time['hour']
    day time['day']
    month time['month']
    weekday time['weekday']
  end
  
  cron "postrun #{type}" do
    time = cron['post_run_time'][type][reldev]
    user 'biocbuild'
    command %W{
      cd /home/biocbuild/BBS/#{bioc_version}/#{type}/`hostname` &&
      ./postrun.sh >>/home/biocbuild/bbs-#{bioc_version}-#{type}/log/`hostname`-`date +\\%Y\\%m\\%d`-postrun.log 2>&1
      }.join(' ')
    minute time['minute']
    hour time['hour']
    day time['day']
    month time['month']
    weekday time['weekday']
  end
  
end

## biocadmin

%w(bioc data-experiment data-annotation).each do |type|

  cron "propagate #{type}" do
    time = cron['propagate_time'][type][reldev]
    user 'biocadmin'
    command %W{
      cd /home/biocadmin/manage-BioC-repos/#{bioc_version} &&
      (#{"./updateReposPkgs-#{type}.sh && " unless type=="data-annotation"}./prepareRepos-#{type}.sh && ./pushRepos-#{type}.sh)
      >>/home/biocadmin/cron.log/#{bioc_version}/updateRepos-#{type}-`date +\\%Y\\%m\\%d`.log 2>&1
    }.join(' ')
    minute time['minute']
    hour time['hour']
    day time['day']
    month time['month']
    weekday time['weekday']
  end

end
