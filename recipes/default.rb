# __END__
# comment out the above but don't remove it
# include_recipe 'cron'
include_recipe 'apt'
resources(execute: 'apt-get update').run_action(:run)


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



file "/etc/hostname" do
  content node['desired_hostname'][reldev]
  mode "0644"
end

execute "set hostname" do
  command "hostname $(cat /etc/hostname)"
  not_if "hostname | grep -q $(cat /etc/hostname)"
end



execute "fix ec2 hostname bs" do
  command %Q(echo "127.0.0.1 $(hostname)" >> /etc/hosts)
  not_if "grep -q $(hostname) /etc/hosts"
end


user "biocbuild" do
    manage_home true
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

%w(log NodeInfo meat R).each do |dir|
    directory "#{bbsdir}/#{dir}" do
        owner "biocbuild"
        group "biocbuild"
        mode "0755"
        action :create
    end
end

%W(src public_html public_html/BBS public_html/BBS/#{node['bioc_version'][reldev]}).each do |dir|
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
  group "biocbuild"
end


%w(log NodeInfo meat STAGE2_tmp).each do |dir|
    directory "#{dataexpdir}/#{dir}" do
        owner "biocbuild"
        group "biocbuild"
        mode "0755"
        action :create
    end
end


# workflows
workflowdir = bbsdir.sub(/bioc$/, "workflows")

directory workflowdir do
  action :create
  owner "biocbuild"
  group "biocbuild"
end


%w(log NodeInfo meat STAGE2_tmp).each do |dir|
    directory "#{workflowdir}/#{dir}" do
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
if reldev == :dev
    branch = 'trunk'
else
    branch = "branches/RELEASE_#{node['bioc_version'][reldev].sub(".", "_")}"
end


%w(ack-grep libnetcdf-dev libhdf5-serial-dev sqlite libfftw3-dev libfftw3-doc
    libopenbabel-dev fftw3 fftw3-dev pkg-config xfonts-100dpi xfonts-75dpi
    libopenmpi-dev openmpi-bin mpi-default-bin openmpi-common
    libexempi3 openmpi-doc texlive-science python-mpi4py
    texlive-bibtex-extra texlive-fonts-extra fortran77-compiler gfortran
    libreadline-dev libx11-dev libxt-dev texinfo apache2 libxml2-dev
    libcurl4-openssl-dev libcurl4-nss-dev xvfb  libpng12-dev
    libjpeg62-dev libcairo2-dev libcurl4-gnutls-dev libtiff5-dev
    tcl8.5-dev tk8.5-dev libicu-dev libgsl2 libgsl0-dev
    libgtk2.0-dev gcj-4.8 openjdk-8-jdk texlive-latex-extra
    texlive-fonts-recommended libgl1-mesa-dev libglu1-mesa-dev
    htop libgmp3-dev imagemagick unzip libhdf5-dev libncurses-dev libbz2-dev
    libxpm-dev liblapack-dev libv8-3.14-dev libperl-dev
    libarchive-extract-perl libfile-copy-recursive-perl libcgi-pm-perl tabix
    libdbi-perl libdbd-mysql-perl ggobi libgtkmm-2.4-dev libssl-dev byacc
    automake libmysqlclient-dev postgresql-server-dev-all
    firefox graphviz python-pip libxml-simple-perl texlive-lang-european
    libmpfr-dev libudunits2-dev tree python-yaml libmodule-build-perl gdb biber
    python-numpy python-pandas python-h5py
    libprotoc-dev libprotobuf-dev protobuf-compiler libapparmor-dev libgeos-dev
    librdf0-dev libmagick++-dev libsasl2-dev libpoppler-cpp-devel
    texlive-pstricks texlive-pstricks-doc texlive-luatex
    libglpk-dev libgdal-dev
).each do |pkg|
    package pkg do
        action :install
    end
end

package 'libnetcdf-dev'

# Some packages are not installed by the above, even though the output
# suggests they are. See
# https://discourse.chef.io/t/package-not-installed-by-package-resource-on-ubuntu/8456
# So explicitly install using apt-get:

# comment this out for now for testing
# execute "install libnetcdf-dev" do
#   command "apt-get install -y libnetcdf-dev"
#   not_if "dpkg --get-selections libnetcdf-dev|grep -q libnetcdf-dev"
# end

package 'git'

# install a newer version of pandoc than available from the Ubuntu package repo
pandoc_deb = node['pandoc_url'].split("/").last

remote_file "/tmp/#{pandoc_deb}" do
  source node['pandoc_url']
end

dpkg_package "pandoc" do
  source "/tmp/#{pandoc_deb}"
end

execute "install jupyter" do
  command "pip install jupyter"
  not_if "which jupyter | grep -q jupyter"
end

execute "install ipython" do
  command "pip install ipython==4.1.2"
  not_if "pip freeze | grep -q ipython"
end

execute "install nbconvert" do
  command "pip install nbconvert==4.1.0"
  not_if "pip freeze | grep -q nbconvert"
end

execute "install h5pyd" do
  command "pip install h5pyd"
  not_if "pip freeze | grep -q h5pyd"
end

execute "install scikit-learn" do
  command "pip install scikit-learn"
  not_if "pip freeze | grep -q scikit-learn"
end

execute "install tensorflow" do
  command "pip install tensorflow"
  not_if "pip freeze | grep -q tensorflow"
end

argtable_tarball = node['argtable_url'].split('/').last
argtable_dir = argtable_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{argtable_tarball}" do
  source node['argtable_url']
end

execute "build argtable" do
  command "tar zxf #{argtable_tarball.split('/').last} && cd #{argtable_dir} && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{argtable_dir}/config.log"}
end

clustalo_tarball = node['clustalo_url'].split('/').last
clustalo_dir = clustalo_tarball.sub(".tar.gz", "")

remote_file "/tmp/#{clustalo_tarball}" do
  source node['clustalo_url']
end

execute "build clustalo" do
  command "tar zxf #{clustalo_tarball} && cd #{clustalo_dir} && ./configure && make && make install"
  not_if "which clustalo | grep -q clustalo"
  cwd "/tmp"
end

gitlfs_dir = node['git-lfs_dir']
gitlfs_tarball = "#{gitlfs_dir}.tar.gz"

remote_file "/tmp/#{gitlfs_tarball}" do
  source node['git-lfs_url']
end

execute "install git-lfs" do
  command "tar zxf #{gitlfs_tarball} && cd #{gitlfs_dir} && ./install.sh"
  not_if "which git-lfs | grep -q git-lfs"
  cwd "/tmp"
end

git "/home/biocbuild/BBS" do
  repository node['bbs_repos']
  revision node['bbs_branch']
  user 'biocbuild'
  group 'biocbuild'
end

directory "#{bbsdir}/rdownloads" do
  action :create
  owner 'biocbuild'
  group 'biocbuild'
end

remote_file "#{bbsdir}/rdownloads/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner 'biocbuild'
  group 'biocbuild'
end

execute "untar R" do
  command "tar zxf #{bbsdir}/rdownloads/#{node['r_url'][reldev].split("/").last}"
  user "biocbuild"
  group "biocbuild"
  cwd "#{bbsdir}/rdownloads"
  not_if {File.exists? "#{bbsdir}/rdownloads/#{node['r_src_dir'][reldev]}"}
end


execute "build R" do
  command "#{bbsdir}/rdownloads/#{node['r_src_dir'][reldev]}/configure --enable-R-shlib && make"
  user "biocbuild"
  group "biocbuild"
  cwd "#{bbsdir}/R"
  not_if {File.exists? "#{bbsdir}/R/Makefile"}
end

execute "set R flags" do
  command "/home/biocbuild/BBS/utils/R-fix-flags.sh"
  user "biocbuild"
  group "biocbuild"
  cwd "#{bbsdir}/R/etc"
  not_if {File.exists? "#{bbsdir}/R/etc/Makeconf.original"}
end

execute "set up arp alias" do
  command %Q(echo 'alias arp="export PATH=$PATH:$HOME/bbs-#{node['bioc_version'][reldev]}-bioc/R/bin"' >> /home/biocbuild/.bash_profile)
  cwd "/home/biocbuild"
  user "biocbuild"
  group "biocbuild"
  not_if "grep -q arp /home/biocbuild/.bash_profile"
end

execute "install BiocInstaller" do
  command %Q(#{bbsdir}/R/bin/R -e "source('https://bioconductor.org/biocLite.R')")
  user "biocbuild"
  group "biocbuild"
  not_if {File.exists? "#{bbsdir}/R/library/BiocInstaller"}
end

if reldev == :dev
  execute "run useDevel()" do
    command %Q(#{bbsdir}/R/bin/R -e "BiocInstaller::useDevel()")
    user "biocbuild"
    group "biocbuild"
    not_if %Q(#{bbsdir}/R/bin/R --slave -q -e "BiocInstaller:::IS_USER" | grep -q FALSE)
  end
end

link "/var/www/html/BBS" do
    to "/home/biocbuild/public_html/BBS"
end



# biocadmin

user "biocadmin" do
    manage_home true
    home "/home/biocadmin"
    shell "/bin/bash"
    action :create
end


dirs = %W(
bin InstalledPkgs tmp rdownloads
PACKAGES/#{bioc_version}/biocViews
PACKAGES/#{bioc_version}/bioc/src/contrib
PACKAGES/#{bioc_version}/bioc/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/bioc/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/src/contrib
PACKAGES/#{bioc_version}/data/experiment/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/experiment/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/src/contrib
PACKAGES/#{bioc_version}/data/annotation/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/data/annotation/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/src/contrib
PACKAGES/#{bioc_version}/extra/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/extra/bin/macosx/mavericks/contrib/#{r_version}
PACKAGES/#{bioc_version}/workflows/src/contrib
PACKAGES/#{bioc_version}/workflows/bin/windows/contrib/#{r_version}
PACKAGES/#{bioc_version}/workflows/bin/macosx/contrib/#{r_version}
PACKAGES/#{bioc_version}/workflows/bin/macosx/mavericks/contrib/#{r_version}
cron.log/#{bioc_version}
)

def parent_dirs(dir)
  path = ""
  dir.split("/").collect{|d| path = path.empty? ? d : path+"/"+d; path}
end

## explicitly create parent directories in order to properly set owner/group
dirs.collect{|dir| parent_dirs(dir)}.flatten.uniq.each do |dir|
  directory "/home/biocadmin/#{dir}" do
    action :create
    owner "biocadmin"
    group "biocadmin"
  end
end

git "/home/biocadmin/BBS" do
  user "biocadmin"
  group "biocadmin"
  repository node['bbs_repos']
  revision node['bbs_branch']
end

link "/home/biocadmin/propagation-pipe"  do
  to "/home/biocadmin/BBS/propagation-pipe"
  owner "biocadmin"
  group "biocadmin"
end

%W(bioc data/annotation data/experiment extra).each do |dir|
  link "/home/biocadmin/PACKAGES/#{bioc_version}/#{dir}/bin/windows64" do
    to "windows"
    owner "biocadmin"
    group "biocadmin"
  end
end

# install R
# install knitcitations
# install all pkgs in ~/InstalledPkgs




remote_file "/home/biocadmin/rdownloads/#{node['r_url'][reldev].split("/").last}" do
  source node['r_url'][reldev]
  owner "biocadmin"
  group "biocadmin"
end

execute "untar R" do
  command "tar zxf /home/biocadmin/rdownloads/#{node['r_url'][reldev].split("/").last} && mv #{node['r_src_dir'][reldev]} /home/biocadmin/R-#{r_version}"
  user "biocadmin"
  group "biocadmin"
  cwd "/home/biocadmin/rdownloads"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}"}
end



execute "build R" do
  command "./configure --enable-R-shlib && make"
  user "biocadmin"
  group "biocadmin"
  cwd "/home/biocadmin/R-#{r_version}/"
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/config.log"}
end

# should really install these from ~/InstalledPkgs but this is easier.
execute "install pkgs needed by biocadmin" do
  user "biocadmin"
  group "biocadmin"
  command %Q(/home/biocadmin/R-#{r_version}/bin/R -e "source('https://bioconductor.org/biocLite.R');biocLite(c('biocViews','DynDoc','graph','knitr','knitcitations'))")
  not_if {File.exists? "/home/biocadmin/R-#{r_version}/library/knitcitations"}
end

link "/home/biocadmin/bin/R-#{r_version}" do
  owner "biocadmin"
  group "biocadmin"
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

execute "build ViennaRNA" do
  command "tar zxf #{node['vienna_rna_dir']}.tar.gz && cd #{node['vienna_rna_dir']}/ && ./configure && make && make install"
  cwd "/tmp"
  not_if {File.exists? "/tmp/#{node['vienna_rna_dir']}/config.log"}
end

# ensemblVEP

remote_file "/tmp/#{node['vep_dir'][reldev]}.zip" do
  source node['vep_url'][reldev]
end

execute "install VEP" do
  command "unzip #{node['vep_dir'][reldev]} && mv #{node['vep_dir'][reldev]} /usr/local/ && cd /usr/local/#{node['vep_dir'][reldev]} && perl INSTALL.pl --NO_HTSLIB -a a"
  cwd "/tmp"
  not_if {File.exists? "/usr/local/#{node['vep_dir'][reldev]}"}
end

# add /usr/local/vep to path

execute "add vep to path" do
  command "echo 'export PATH=$PATH:/usr/local/vep' >> /etc/profile"
  not_if "grep -q vep /etc/profile"
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

# get stuff from encrypted data bags

file "/home/biocbuild/.BBS/id_rsa" do
  owner "biocbuild"
  group "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'incoming_private_key')['value']
end

execute "add public key to authorized_keys" do
  user "biocbuild"
  group "biocbuild"
  command "echo #{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']} >> /home/biocbuild/.ssh/authorized_keys"
  not_if %Q(grep -q "#{Chef::EncryptedDataBagItem.load('BBS',
    'incoming_public_key')['value']}" /home/biocbuild/.ssh/authorized_keys)
end

execute "add google api key to /etc/profile" do
  user "root"
  command %Q(echo "export GOOGLE_API_KEY=#{Chef::EncryptedDataBagItem.load('BBS',
    'google_api_key')['value']}" >> /etc/profile)
  not_if %Q(grep -q GOOGLE_API_KEY /etc/profile)
end

execute "add ISR_login to /etc/profile" do
  user "root"
  command %Q(echo "export ISR_login=#{Chef::EncryptedDataBagItem.load('BBS',
    'isr_credentials')['username']}" >> /etc/profile)
  not_if %Q(grep -q ISR_login /etc/profile)
end

execute "add ISR_pwd to /etc/profile" do
  user "root"
  command %Q(echo "export ISR_pwd=#{Chef::EncryptedDataBagItem.load('BBS',
    'isr_credentials')['password']}" >> /etc/profile)
  not_if %Q(grep -q ISR_pwd /etc/profile)
end

file "/home/biocbuild/.ssh/id_rsa" do
  owner "biocbuild"
  group "biocbuild"
  mode "0400"
  content Chef::EncryptedDataBagItem.load('BBS',
    'outgoing_private_key')['value']
end

# FIXME more stuff that needs to be in data bags:
# * github oauth token for codecov
# * codecov token
# * aws credentials for archiving build reports to s3


# set up cron.d entries for biocbuild

# first, indicate in crontab to look elsewhere:
execute "tell viewers of crontab to look in /etc/cron.d" do
  command %Q(echo "# scheduled tasks are defined in /etc/cron.d, not here" | crontab -)
  user "biocbuild"
  not_if %Q(crontab -l |grep -q "# scheduled tasks are defined in /etc/cron.d")
end

# cron_d "pre-build-script" do
#
# end



# FIXME - set up pkgbuild stuff (e.g., logrotate) if this is a devel builder
# github_chef_key (from data bag)
