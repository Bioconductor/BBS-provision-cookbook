include_recipe 'apt'
resources(execute: 'apt-get update').run_action(:run)


execute "fix ec2 hostname bs" do
  command %Q(echo "127.0.0.1 $(hostname)" >> /etc/hosts)
  not_if "grep -q $(hostname) /etc/hosts"
end


package "language-pack-en"

if node["reldev"] == "devel"
  reldev = :dev
elsif node["reldev"] == "release"
  reldev = :rel
else
  raise "are the bbs_devel and bbs_release roles defined?"
end

bioc_version = node['bioc_version'][reldev]
r_version = node['r_version'][reldev]
execute "change time zone" do
    user "root"
    command "rm -f /etc/localtime && ln -sf /usr/share/zoneinfo/#{node['time_zone']} /etc/localtime"
    not_if "file /etc/localtime | grep -q #{node['time_zone']}"
end

control_group 'time zone' do
  control 'should be set properly' do
    describe command("file /etc/localtime") do
      its(:stdout) { should_not match /UTC|GMT/}
    end
  end
end


# TODO set hostname

user "biocbuild" do
    supports :manage_home => true
    home "/home/biocbuild"
    shell "/bin/bash"
    action :create
end


control_group 'biocbuild' do
  control 'biocbuild user' do
    it 'should exist' do
      expect(file('/etc/passwd')).to contain(/biocbuild/)
      expect(file('/home/biocbuild')).to exist
      expect(file('/home/biocbuild')).to be_directory
      expect(file('/home/biocbuild')).to be_owned_by('biocbuild')
    end
  end
end


bbsdir = "/home/biocbuild/bbs-#{node['bioc_version'][reldev]}-bioc"

directory bbsdir do
    owner "biocbuild"
    group "biocbuild"
    mode "0755"
    action :create
end



control_group "bbsdir group" do
  control bbsdir do
    it 'should exist' do
      expect(file(bbsdir)).to exist
      expect(file(bbsdir)).to be_directory
      expect(file(bbsdir)).to be_owned_by('biocbuild')
    end
  end
end


directory "/home/biocbuild/.ssh" do
    owner "biocbuild"
    group "biocbuild"
    mode "0755"
    action :create
end

directory "/home/biocbuild/.BBS" do
    owner "biocbuild"
    group "biocbuild"
    mode "0755"
    action :create
end

%w(log NodeInfo svninfo meat R).each do |dir|
    directory "#{bbsdir}/#{dir}" do
        owner "biocbuild"
        group "biocbuild"
        mode "0755"
        action :create
    end
end

%W(src public_html public_html/BBS public_html/BBS/#{node['bioc_version'][reldev]} public_html/BBS/#{node['bioc_version'][reldev]}/bioc).each do |dir|
    directory "/home/biocbuild/#{dir}" do
        owner "biocbuild"
        group "biocbuild"
        mode "0755"
        action :create
    end
end

# data experiment
dataexpdir = bbsdir.sub(/bioc$/, "data-experiment")

directory dataexpdir do
  action :create
  owner "biocbuild"
end


%w(log NodeInfo svninfo meat STAGE2_tmp).each do |dir|
    directory "#{dataexpdir}/#{dir}" do
        owner "biocbuild"
        group "biocbuild"
        mode "0755"
        action :create
    end
end



package "subversion"

control_group 'package subversion group' do
  control 'package subversion' do
    it 'should be installed' do
      expect(package('subversion')).to be_installed
    end
  end
end



base_url = "https://hedgehog.fhcrc.org/bioconductor"
base_data_url = "https://hedgehog.fhcrc.org/bioc-data"
if node['is_bioc_devel']
    branch = 'trunk'
else
    branch = "branches/RELEASE_#{node['bioc_version'][reldev].sub(".", "_")}"
end

svn_meat_url = "#{base_url}/#{branch}/madman/Rpacks"

dataexp_meat_url = "#{base_data_url}/#{branch}/experiment/pkgs"


## FIXME! These svn co commands do NOT 'seed' the svn auth system so that
## further actions (e.g. svn up) don't require authentication. Need to figure that out...
## or change build system code to specify username/password (readonly/readonly is ok....)
## try suggestions in
# https://stackoverflow.com/questions/5062232/svn-wont-cache-credentials

execute 'shallow MEAT0 checkout' do
  command "svn co --depth empty --non-interactive --username readonly --password readonly #{svn_meat_url} MEAT0"
  cwd bbsdir
  user 'biocbuild'
end

execute 'shallow MEAT0 checkout (data-experiment)' do
  command "svn co --depth empty --non-interactive --username readonly --password readonly #{dataexp_meat_url} MEAT0"
  cwd dataexpdir
  user 'biocbuild'
end


control_group 'MEAT0 checkout group' do
  control 'MEAT0 checkout' do
    it 'should have .svn dir' do
      expect(file("#{bbsdir}/MEAT0/.svn")).to exist
      expect(file("#{bbsdir}/MEAT0/.svn")).to be_directory
      expect(file("#{bbsdir}/MEAT0/.svn")).to be_owned_by "biocbuild"
    end
  end
end




%w(libnetcdf-dev libhdf5-serial-dev sqlite libfftw3-dev libfftw3-doc
    libopenbabel-dev fftw3 fftw3-dev pkg-config xfonts-100dpi xfonts-75dpi
    libopenmpi-dev openmpi-bin mpi-default-bin openmpi-common
    libexempi3 openmpi-doc texlive-science python-mpi4py
    texlive-bibtex-extra texlive-fonts-extra fortran77-compiler gfortran
    libreadline-dev libx11-dev libxt-dev texinfo apache2 libxml2-dev
    libcurl4-openssl-dev libcurl4-nss-dev xvfb  libpng12-dev
    libjpeg62-dev libcairo2-dev libcurl4-gnutls-dev libtiff5-dev
    tcl8.5-dev tk8.5-dev libicu-dev libgsl2 libgsl0-dev
    libgtk2.0-dev gcj-4.8 openjdk-8-jdk texlive-latex-extra
    texlive-fonts-recommended pandoc libgl1-mesa-dev libglu1-mesa-dev
    htop libgmp3-dev imagemagick unzip libhdf5-dev libncurses-dev libbz2-dev
    libxpm-dev liblapack-dev libv8-3.14-dev libperl-dev
    libarchive-extract-perl libfile-copy-recursive-perl libcgi-pm-perl tabix
    libdbi-perl libdbd-mysql-perl
).each do |pkg|
    package pkg do
        # this might timeout, but adding a 'timeout' here
        # causes an error. hmmm.
        # texlive-science seems to be the culprit
        # also texlive-fonts-extra
        # timeout 10000
        action :install
    end
end

package 'git'

git "/home/biocbuild/BBS" do
  repository node['bbs_repos']
  revision node['bbs_branch']
  user 'biocbuild'
end

directory "#{bbsdir}/rbuild" do
  action :create
  owner 'biocbuild'
end

remote_file "#{bbsdir}/rbuild/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'biocbuild'
end

execute "untar R" do
  command "tar zxf #{bbsdir}/rbuild/#{node['r_url'][reldev].split("/").last}"
  user 'biocbuild'
  cwd "#{bbsdir}/rbuild"
  not_if {File.exists? "#{bbsdir}/rbuild/#{node['r_src_dir']}"}
end


execute "build R" do
  command "#{bbsdir}/rbuild/#{node['r_src_dir']}/configure --enable-R-shlib && make -j"
  user 'biocbuild'
  cwd "#{bbsdir}/R"
  not_if {File.exists? "#{bbsdir}/R/Makefile"}
end

execute "set R flags" do
  command "/home/biocbuild/BBS/utils/R-fix-flags.sh"
  user "biocbuild"
  cwd "#{bbsdir}/R/etc"
  not_if {File.exists? "#{bbsdir}/R/etc/Makeconf.original"}
end

execute "set up arp alias" do
  command %Q(echo 'alias arp="export PATH=$PATH:$HOME/bbs-#{node['bioc_version'][reldev]}-bioc/R/bin"' >> /home/biocbuild/.bash_profile)
  cwd "/home/biocbuild"
  user "biocbuild"
  not_if "grep -q arp /home/biocbuild/.bash_profile"
end

execute "install BiocInstaller" do
  command %Q(#{bbsdir}/R/bin/R -e "source('https://bioconductor.org/biocLite.R')")
  user "biocbuild"
  not_if {File.exists? "#{bbsdir}/R/library/BiocInstaller"}
end

# FIXME run useDevel() if appropriate

link "/var/www/html/BBS" do
    to "/home/biocbuild/public_html/BBS"
end

# biocadmin

user "biocadmin" do
    supports :manage_home => true
    home "/home/biocadmin"
    shell "/bin/bash"
    action :create
end


%W(bin InstalledPkgs tmp rbuild
PACKAGES/#{bioc_version}
PACKAGES/#{bioc_version}/biocViews
PACKAGES/#{bioc_version}/bioc
PACKAGES/#{bioc_version}/bioc/src/contrib
PACKAGES/#{bioc_version}/bioc/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment
PACKAGES/#{bioc_version}/data/experiment/src/contrib
PACKAGES/#{bioc_version}/data/experiment/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation
PACKAGES/#{bioc_version}/data/annotation/src/contrib
PACKAGES/#{bioc_version}/data/annotation/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra
PACKAGES/#{bioc_version}/extra/src/contrib
PACKAGES/#{bioc_version}/extra/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/mavericks/contrib/#{r_version}
cron.log/#{bioc_version}
).each do |dir|
  directory "/home/biocadmin/#{dir}" do
    owner "biocadmin"
    action :create
    recursive true
  end
end

%W(BiocInstaller biocViews DynDoc graph).each do |pkg|
  directory "/home/biocadmin/InstalledPkgs/#{pkg}" do
    action :create
    owner 'biocadmin'
  end
  subversion "/home/biocadmin/InstalledPkgs/#{pkg}" do
    user "biocadmin"
    svn_username "readonly"
    svn_password "readonly"
    repository "https://hedgehog.fhcrc.org/bioconductor/trunk/madman/Rpacks/#{pkg}"
    action :sync
  end
end

git "/home/biocadmin/BBS" do
  user "biocadmin"
  repository node['bbs_repos']
  revision node['bbs_branch']
end

link "/home/biocadmin/manage-BioC-repos"  do
  to "/home/biocadmin/BBS/manage-BioC-repos"
  owner "biocadmin"
end

%W(bioc data/annotation data/experiment extra).each do |dir|
  link "/home/biocadmin/PACKAGES/#{bioc_version}/#{dir}/bin/windows64" do
    to "/home/biocadmin/PACKAGES/#{bioc_version}/#{dir}/bin/windows"
    owner "biocadmin"
  end
end

# install R
# install knitcitations
# install all pkgs in ~/InstalledPkgs




remote_file "/home/biocadmin/rbuild/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'biocadmin'
end

execute "untar R" do
  command "tar zxf /home/biocadmin/rbuild/#{node['r_url'][reldev].split("/").last} && mv #{node['r_src_dir']} /home/biocadmin/R-#{r_version}"
  user 'biocadmin'
  cwd "/home/biocadmin/rbuild"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}"}
end



execute "build R" do
  command "./configure --enable-R-shlib && make -j"
  user 'biocadmin'
  cwd "/home/biocadmin/R-#{r_version}/"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/config.log"}
end

# should really install these from ~/InstalledPkgs but this is easier.
execute "install pkgs needed by biocadmin" do
  user 'biocadmin'
  command %Q(/home/biocadmin/R-#{r_version}/bin/R -e "source('https://bioconductor.org/biocLite.R');biocLite(c('biocViews','DynDoc','graph','knitcitations'))")
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/library/knitcitations"}
end

link "/home/biocadmin/bin/R-#{r_version}" do
  owner 'biocadmin'
  to "/home/biocadmin/R-#{r_version}/bin/R"
end


# ROOT

remote_file "/tmp/#{node['root_url'][reldev].split("/").last}" do
  source node['root_url'][reldev]
end

directory "/tmp/rootbuild" do
  action :create
end

execute "build root" do
  cwd "/tmp/rootbuild"
  command "tar zxf /tmp/#{node['root_url'][reldev].split("/").last} && cd root && ./configure --prefix=/usr/local/root && make && make install"
  not_if {File.exists? "/tmp/rootbuild/root"}
end


file "/etc/ld.so.conf.d/ROOT.conf" do
  content "/usr/local/root/lib/root"
end

execute "ldconfig" do
  command "ldconfig"
end

execute "add root to path" do
  command "echo 'export PATH=$PATH:/usr/local/root/bin' >> /etc/profile"
  not_if "grep -q /usr/local/root/bin /etc/profile"
end

execute "add rootsys" do
  command "echo 'export ROOTSYS=/usr/local/root' >> /etc/profile"
  not_if "grep -q ROOTSYS /etc/profile"
end

# jags

remote_file "/tmp/#{node['jags_url'][reldev].split('/').last}" do
  source node['jags_url'][reldev]
end

execute "build jags" do
  command "tar zxf #{node['jags_url'][reldev].split('/').last} && cd #{node['jags_dir'][reldev]} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['jags_dir'][reldev]}/config.log"}
end

# libsbml

remote_file "/tmp/#{node['libsbml_url'].split('/').last}" do
  source node['libsbml_url']
end

execute "build libsbml" do
  command "tar zxf #{node['libsbml_url'].split('/').last} && cd #{node['libsbml_dir']} && ./configure --enable-layout && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['libsbml_dir']}/config.log"}
end

# Vienna RNA

remote_file "/tmp/#{node['vienna_rna_dir']}.tar.gz" do
  source node["vienna_rna_url"]
end

# commenting this out now as it fails to build.
# however, it seems like this is not needed at the moment because
# the RNAfold program is not actually called in an evaluted
# vignette chunk/example/test in GeneGA

# execute "build ViennaRNA" do
#   command "tar zxf #{node['vienna_rna_dir']}.tar.gz && cd #{node['vienna_rna_dir']}/ && ./configure && make && make install"
#   cwd "/tmp"
#   not_if {File.exists? "/tmp/#{node['vienna_rna_dir']}/config.log"}
# end

# ensemblVEP

remote_file "/tmp/#{node['vep_dir'][reldev]}.zip" do
  source node['vep_url'][reldev]
end

execute "install VEP" do
  command "unzip #{node['vep_dir'][reldev]} && cd #{node['vep_dir'][reldev]}/scripts && mv variant_effect_predictor /usr/local/ && cd /usr/local/variant_effect_predictor && perl INSTALL.pl --NO_HTSLIB -a a"
  cwd "/tmp"
  not_if {File.exists? "/usr/local/variant_effect_predictor"}
end

# add /usr/local/variant_effect_predictor to path

execute "add vep to path" do
  command "echo 'export PATH=$PATH:/usr/local/variant_effect_predictor' >> /etc/profile"
  not_if "grep -q variant_effect_predictor /etc/profile"
end

# TODO s:
# cron - pointer in crontab to crond
# ssh keys
# latex - enablewrite18 and changes below
# rgtk2? gtkmm?
# in encrypted data bags:
#  isr_login
#  google login
#  etc
# the above go in cron envs as well


# latex settings

file "/etc/texmf/texmf.d/01bioc.cnf" do
    content "shell_escape=t"
    owner "root"
    group "root"
    mode "0644"
end

execute "update-texmf" do
    action :run
    user "root"
    command "update-texmf"
end


# FIXME - set up pkgbuild stuff if this is a devel builder

__END__

require 'yaml'

yamlconfig = YAML.load_file "/vagrant/config.yml"

rmajor = yamlconfig["r_version"].sub(/^R-/, "").split("").first

execute "set hostname on aws" do
    command "echo '127.0.0.1 #{yamlconfig['hostname']}' >> /etc/hosts"
    #FIXME, guard doesn't work, line keeps getting appended.
    # does it also happen when not using AWS?
    only_if "curl -I http://169.254.169.254/latest/meta-data/ && grep -vq #{yamlconfig['hostname']} /etc/hosts"
end


# TODO get ssh key from encrypted data bag



execute "add public key" do
    user "biocbuild"
    command "cat /vagrant/id_rsa.pub >> /home/biocbuild/.ssh/authorized_keys"
    not_if "grep 'biocbuild@#{yamlconfig['hostname']}' /home/biocbuild/.ssh/authorized_keys"
end

# note, this wipes out crontab (but should only be run once)
execute "add USER to crontab" do
    user "biocbuild"
    command "echo 'USER=biocbuild' | crontab -"
    not_if "crontab -l|grep 'USER=biocbuild'"
end


execute "javareconf" do
    action :run
    user "biocbuild"
    command "#{bbsdir}/R/bin/R CMD javareconf"
end


# install stuff that needs to be built 'manually'

# test build by putting the following in crontab
# (setting the time to be coming up soon)

# the following comments have hostname hardcoded as 'bbsvm'
# but it may be something different

## bbs-3.0-bioc
# 20 16 * * * cd /home/biocbuild/BBS/3.0/bioc/bbsvm && ./prerun.sh >>/home/biocbuild/bbs-3.0-bioc/log/bbsvm.log 2>&1
# 00 17 * * * /bin/bash --login -c 'cd /home/biocbuild/BBS/3.0/bioc/bbsvm && ./run.sh >>/home/biocbuild/bbs-3.0-bioc/log/bbsvm.log 2>&1'
## IMPORTANT: Make sure this is started AFTER 'biocbuild' has finished its "run.sh" job on ALL other nodes!
# 45 08 * * * cd /home/biocbuild/BBS/3.0/bioc/bbsvm && ./postrun.sh >>/home/biocbuild/bbs-3.0-bioc/log/bbsvm.log 2>&1


# allow biocbuild to sudo?


remote_file "copy texmf config" do
    path "/etc/texmf/texmf.d/01bioc.cnf"
    source "file:///vagrant/01bioc.cnf"
    owner "root"
    group "root"
    mode "0644"
end

execute "update-texmf" do
    action :run
    user "root"
    command "update-texmf"
end

# install: jags/cogaps (both versions?)
# ROOT
# ensemblVEP rggobi GeneGA  rsbml prereqs
# gtkmm gtk2
