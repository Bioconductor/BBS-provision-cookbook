default['bioc_version'] = {rel: '3.3', dev: '3.4'}
default['use_r_devel'] = {rel: false, dev: false}
default['r_version'] = {rel: '3.3', dev: '3.3'}
default['is_bioc_devel'] = true # change this depending on what we are provisioning
default['hostname'] = {dev: "linux2.bioconductor.org",
  rel: "linux1.bioconductor.org"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'master' # FIXME change me, probably
default['r_url'] = {rel: 'https://cran.rstudio.com/src/base-prerelease/R-latest.tar.gz',
  dev: 'https://cran.rstudio.com/src/base-prerelease/R-latest.tar.gz'}
default['r_src_dir'] = 'R-beta'
default['root_url'] = {dev: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz",
  rel: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz"}
default['jags_url'] = {dev: "http://iweb.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Source/JAGS-4.2.0.tar.gz",
  rel: "http://iweb.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Source/JAGS-4.2.0.tar.gz"}
default['jags_dir'] = {dev: "JAGS-4.2.0", rel: "JAGS-4.2.0"}
