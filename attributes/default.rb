default['bioc_version'] = {rel: '3.3', dev: '3.4'}
default['use_r_devel'] = {rel: false, dev: false}
default['r_version'] = {rel: '3.3', dev: '3.3'}
default['is_bioc_devel'] = true # change this depending on what we are provisioning
default['hostname'] = {dev: "linux2.bioconductor.org",
  rel: "linux1.bioconductor.org"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'feature/linux_builders_at_ub'
default['r_url'] = {rel: 'https://cran.rstudio.com/src/base-prerelease/R-latest.tar.gz',
  dev: 'https://cran.rstudio.com/src/base-prerelease/R-latest.tar.gz'}
default['r_src_dir'] = {rel: 'R-rc', dev: 'R-rc'}
default['root_url'] = {dev: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz",
  rel: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz"}
default['jags_url'] = {dev: "http://iweb.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Source/JAGS-4.2.0.tar.gz",
  rel: "http://iweb.dl.sourceforge.net/project/mcmc-jags/JAGS/4.x/Source/JAGS-4.2.0.tar.gz"}
default['jags_dir'] = {dev: "JAGS-4.2.0", rel: "JAGS-4.2.0"}
default['libsbml_url']  = "https://s3.amazonaws.com/linux-provisioning/libSBML-5.10.2-core-src.tar.gz"
default['libsbml_dir'] = "libsbml-5.10.2"
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/package=viennarna-src-tbi&flavor=sourcecode&dist=1_8_x&arch=src&version=1.8.5"
default['vienna_rna_dir'] = "ViennaRNA-1.8.5"
default['vep_url'] = {dev: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84",
  rel: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84"}
default['vep_dir'] = {dev: "ensembl-tools-release-84", rel: "ensembl-tools-release-84"}

# cron info

def starhash(minute: '*', hour: '*', day: '*', month: '*', weekday: '*')
  {minute: minute, hour: hour, day: day, month: month, weekday: weekday}
end

default['bioc_pre_run_time'] = {
  rel:
    starhash(minute: '20', hour: '19', weekday: '0,1,2,3,4,6'),
  dev:
    starhash(minute: '20', hour: '20', weekday: '0,1,2,3,4,6'),
}
