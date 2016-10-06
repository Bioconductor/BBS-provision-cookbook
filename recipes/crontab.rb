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

%w(bioc data-experiment).each do |type|
  
  %w(prerun run postrun).each do |action|
    
    cron "#{action} #{type}" do
      time = cron[action][type][reldev]
      user 'biocbuild'
      command %W{
        /bin/bash --login -c
        'cd /home/biocbuild/BBS/#{bioc_version}/#{type}/`hostname` &&
        ./#{action}.sh >>/home/biocbuild/bbs-#{bioc_version}-#{type}/log/`hostname`-`date +\\%Y\\%m\\%d`-#{action}.log 2>%1'
        }.join(' ')
      minute time['minute']
      hour time['hour']
      day time['day']
      month time['month']
      weekday time['weekday']
    end
    
  end
  
end

## biocadmin

%w(bioc data-experiment data-annotation).each do |type|

  cron "propagate #{type}" do
    time = cron['propagate'][type][reldev]
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
