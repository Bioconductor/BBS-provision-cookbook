default['bioc_version'] = {rel: '3.4', dev: '3.5'}
default['use_r_devel'] = {rel: false, dev: true}
default['r_version'] = {rel: '3.3', dev: '3.4'}
default['desired_hostname'] = {rel: "malbec1", dev: "malbec2"}
default['time_zone'] = "America/New_York"
default['bbs_repos'] = 'https://github.com/Bioconductor/BBS'
default['bbs_branch'] = 'master'
default['r_url'] = {rel: 'https://cran.rstudio.com/src/base/R-3/R-3.3.1.tar.gz',
  dev: 'https://stat.ethz.ch/R/daily/R-devel.tar.gz'}
default['r_src_dir'] = {rel: 'R-3.3.1', dev: 'R-devel'}
default['root_url'] = {dev: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz",
  rel: "https://root.cern.ch/download/root_v5.34.36.source.tar.gz"}
default['jags_url'] = {dev: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download",
  rel: "https://sourceforge.net/projects/mcmc-jags/files/JAGS/4.x/Source/JAGS-4.2.0.tar.gz/download"}
default['jags_dir'] = {dev: "JAGS-4.2.0", rel: "JAGS-4.2.0"}
default['libsbml_url']  = "https://s3.amazonaws.com/linux-provisioning/libSBML-5.10.2-core-src.tar.gz"
default['libsbml_dir'] = "libsbml-5.10.2"
default['vienna_rna_url'] = "https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_2_x/ViennaRNA-2.2.7.tar.gz"
default['vienna_rna_dir'] = "ViennaRNA-2.2.7"
default['vep_url'] = {dev: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84",
  rel: "https://codeload.github.com/Ensembl/ensembl-tools/zip/release/84"}
default['vep_dir'] = {dev: "ensembl-tools-release-84", rel: "ensembl-tools-release-84"}
default['argtable_url'] = "http://prdownloads.sourceforge.net/argtable/argtable2-13.tar.gz"
default['clustalo_url'] = "http://www.clustal.org/omega/clustal-omega-1.2.1.tar.gz"

# cron info

def starhash(minute: '*', hour: '*', day: '*', month: '*', weekday: '*')
  {minute: minute.to_s, hour: hour.to_s, day: day.to_s,
    month: month.to_s, weekday: weekday.to_s}
end

## biocbuild

default['cron']['pre_run_time']['bioc'] = {
  rel: starhash(hour: 17, minute: 10),
  dev: starhash(hour: 17, minute: 10)
}

default['cron']['run_time']['bioc'] = {
  rel: starhash(hour: 17, minute: 55),
  dev: starhash(hour: 17, minute: 55)
}

default['cron']['post_run_time']['bioc']= {
  rel: starhash(hour: 14, minute: 55),
  dev: starhash(hour: 14, minute: 55)
}

default['cron']['pre_run_time']['data-experiment'] = {
  rel: starhash(hour: 9, minute: 20),
  dev: starhash(hour: 9, minute: 20)
}

default['cron']['run_time']['data-experiment'] = {
  rel: starhash(hour: 9, minute: 55),
  dev: starhash(hour: 9, minute: 55)
}

default['cron']['post_run_time']['data-experiment'] = {
  rel: starhash(hour: 16, minute: 55),
  dev: starhash(hour: 16, minute: 55)
}

## biocadmin

default['cron']['propagate_time']['bioc'] = {
  rel: starhash(hour: 15, minute: 35),
  dev: starhash(hour: 15, minute: 35)
}

default['cron']['propagate_time']['data-experiment'] = {
  rel: starhash(hour: 17, minute: 35),
  dev: starhash(hour: 17, minute: 35)
}

default['cron']['propagate_time']['data-annotation'] = {
  rel: starhash(hour: 5, minute: 20),
  dev: starhash(hour: 5, minute: 20)
}
