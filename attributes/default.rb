## At release time these 4 need to be modified:
## 'bioc_version', 'r_version', 'r_url' and 'r_src_dir'
default['bioc_version'] = {rel: '3.5', dev: '3.6'}
default['r_version'] = {rel: '3.4', dev: '3.4'}
default['r_url'] = {rel: 'https://cran.rstudio.com/src/base/R-3/R-3.4.0.tar.gz',
  dev: 'https://cran.rstudio.com/src/base/R-3/R-3.4.0.tar.gz'}
default['r_src_dir'] = {rel: 'R-3.4.0', dev: 'R-3.4.0'}

default['desired_hostname'] = {rel: "malbec2", dev: "malbec1"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'master'
default['root_url'] = {dev: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz",
  rel: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz"}
default['jags_url'] = {dev: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download",
  rel: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download"}
default['jags_dir'] = {dev: "JAGS-4.2.0", rel: "JAGS-4.2.0"}
default['libsbml_url']  = "https://s3.amazonaws.com/linux-provisioning/libSBML-5.10.2-core-src.tar.gz"
default['libsbml_dir'] = "libsbml-5.10.2"
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_2_x/ViennaRNA-2.2.7.tar.gz"
default['vienna_rna_dir'] = "ViennaRNA-2.2.7"
default['vep_url'] = {dev: "https://github.com/Ensembl/ensembl-vep/archive/release/90.zip",
  rel: "https://github.com/Ensembl/ensembl-vep/archive/release/90.zip"}
default['vep_dir'] = {dev: "ensembl-vep-release-90", rel: "ensembl-vep-release-90"}
default['argtable_url'] = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz"
default['clustalo_url'] = "http://www.clustal.org/omega/clustal-omega-1.2.1.tar.gz"
default['pandoc_url'] = "https://github.com/jgm/pandoc/releases/download/1.19.1/pandoc-1.19.1-1-amd64.deb"
default['git-lfs_url'] = "https://github.com/git-lfs/git-lfs/releases/download/v1.5.5/git-lfs-linux-amd64-1.5.5.tar.gz"
default['git-lfs_dir'] = "git-lfs-1.5.5"

# cron info

def starhash(minute: '*', hour: '*', day: '*', month: '*', weekday: '*')
  {minute: minute.to_s, hour: hour.to_s, day: day.to_s,
    month: month.to_s, weekday: weekday.to_s}
end

## biocbuild

default['cron']['prerun']['bioc'] = {
  rel: starhash(hour: 17, minute: 20),
  dev: starhash(hour: 17, minute: 15)
}

default['cron']['run']['bioc'] = {
  rel: starhash(hour: 17, minute: 55),
  dev: starhash(hour: 17, minute: 55)
}

default['cron']['postrun']['bioc']= {
  rel: starhash(hour: 15, minute: 55),
  dev: starhash(hour: 15, minute: 55)
}

default['cron']['prerun']['data-experiment'] = {
  rel: starhash(hour: 9, minute: 20),
  dev: starhash(hour: 9, minute: 20)
}

default['cron']['run']['data-experiment'] = {
  rel: starhash(hour: 9, minute: 55),
  dev: starhash(hour: 9, minute: 55)
}

default['cron']['postrun']['data-experiment'] = {
  rel: starhash(hour: 16, minute: 55),
  dev: starhash(hour: 16, minute: 55)
}

## biocadmin

default['cron']['propagate']['bioc'] = {
  rel: starhash(hour: 16, minute: 25),
  dev: starhash(hour: 16, minute: 25)
}

default['cron']['propagate']['data-experiment'] = {
  rel: starhash(hour: 17, minute: 35),
  dev: starhash(hour: 17, minute: 35)
}

default['cron']['propagate']['data-annotation'] = {
  rel: starhash(hour: 5, minute: 20),
  dev: starhash(hour: 5, minute: 20)
}
