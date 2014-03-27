#
# Cookbook Name:: rackspace_jetty
# Recipe:: default
#
# Copyright 2012-2013, HipSnip Limited
# Copyright 2014, Rackspace US Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'rackspace_java'

#require 'fileutils'

################################################################################
# Guess node['rackspace_jetty']['contexts'] attribute if not set based on the given jetty
#  version in node['rackspace_jetty']['version']
#  Reason why: webapps contexts are in /contexts in Jetty 7/8
#  and in Jetty 9, there are in alongs with the war file (in /webapps)

node.set['rackspace_jetty']['webapps'] = "#{node['rackspace_jetty']['home']}/webapps"
version = 8
if /^9.*/.match(node['rackspace_jetty']['version'])
  version = 9
  node.set['rackspace_jetty']['contexts'] = node['rackspace_jetty']['webapps']
else
  node.set['rackspace_jetty']['contexts'] = "#{node['rackspace_jetty']['home']}/contexts"
end

################################################################################
# Set node attributes

node.set['rackspace_jetty']['download']  = "#{node['rackspace_jetty']['directory']}/jetty-distribution-#{node['rackspace_jetty']['version']}.tar.gz"
node.set['rackspace_jetty']['extracted'] = "#{node['rackspace_jetty']['directory']}/jetty-distribution-#{node['rackspace_jetty']['version']}"
node.set['rackspace_jetty']['args'] =  (node['rackspace_jetty']['args'] + ["-Djetty.port=#{node['rackspace_jetty']['port']}", "-Djetty.logs=#{node['rackspace_jetty']['logs']}"]).uniq

################################################################################
# Create user and group

user node['rackspace_jetty']['user'] do
  home  node['rackspace_jetty']['home']
  shell '/bin/false'
  system true
  action :create
end

group node['rackspace_jetty']['group'] do
  members "jetty"
  system true
  action :create
end

################################################################################
# Create few directories for jetty


[node['rackspace_jetty']['home'], node['rackspace_jetty']['contexts'], node['rackspace_jetty']['webapps'], "#{node['rackspace_jetty']['home']}/lib","#{node['rackspace_jetty']['home']}/resources"].each do |d|
  directory d do
    owner node['rackspace_jetty']['user']
    group node['rackspace_jetty']['group']
    mode  '755'
  end
end


################################################################################
# Download and install Jetty

service 'jetty' do
  action :nothing
end

remote_file node['rackspace_jetty']['download'] do
  source   node['rackspace_jetty']['link']
  checksum node['rackspace_jetty']['checksum']
  mode     0644
end

execute 'unzip downloaded tarball' do 
  command `tar xzf #{node['rackspace_jetty']['download']} -C #{node['rackspace_jetty']['directory']}`
  raise "Failed to extract Jetty package" unless File.exists?(node['rackspace_jetty']['extracted'])
  action :create
end


#ruby_block 'Extract Jetty' do
#  block do
#    Chef::Log.info "Extracting Jetty archive #{node['rackspace_jetty']['download']} into #{node['rackspace_jetty']['directory']}"
#    `tar xzf #{node['rackspace_jetty']['download']} -C #{node['rackspace_jetty']['directory']}`
#    raise "Failed to extract Jetty package" unless File.exists?(node['rackspace_jetty']['extracted'])
#  end
#
#  action :create
#
#  not_if do
#    File.exists?(node['rackspace_jetty']['extracted'])
#  end
#end


ruby_block 'Copy Jetty lib files' do
  block do
    Chef::Log.info "Copying Jetty lib files into #{node['rackspace_jetty']['home']}"
    FileUtils.cp_r File.join(node['rackspace_jetty']['extracted'], 'lib', ''), node['rackspace_jetty']['home']
    FileUtils.chown_R(node['rackspace_jetty']['user'],node['rackspace_jetty']['group'],File.join(node['rackspace_jetty']['home'], 'lib', ''))
    raise "Failed to copy Jetty libraries" if Dir[File.join(node['rackspace_jetty']['home'], 'lib', '*')].empty?
  end

  action :create

  only_if do
    Dir[File.join(node['rackspace_jetty']['home'], 'lib', '*')].empty?
  end
end


ruby_block 'Copy Jetty start.jar' do
  block do
    Chef::Log.info "Copying Jetty start.jar into #{node['rackspace_jetty']['home']}"

    FileUtils.cp File.join(node['rackspace_jetty']['extracted'], 'start.jar'), node['rackspace_jetty']['home']
    FileUtils.chown_R(node['rackspace_jetty']['user'],node['rackspace_jetty']['group'],File.join(node['rackspace_jetty']['home'], 'start.jar'))
    raise "Failed to copy Jetty start.jar" unless File.exists?(File.join(node['rackspace_jetty']['home'], 'start.jar'))
  end

  action :create

  not_if do
    File.exists?(File.join(node['rackspace_jetty']['home'], 'start.jar'))
  end
end

#################################################################################
# Init script and setup service

if node['rackspace_jetty']['syslog']['enable']
  template '/etc/init.d/jetty' do
    source "jetty-#{version}.sh.erb"
    mode   '544'
    action :create
  end
else
  ruby_block 'Copy Jetty init file (jetty.sh)' do
    block do
      Chef::Log.info "Copying Jetty init file (jetty.sh) into /etc/init.d/ folder"

      FileUtils.cp File.join(node['rackspace_jetty']['extracted'], 'bin/jetty.sh'), "/etc/init.d/jetty"
      raise "Failed to copy Jetty init file (jetty.sh)" unless File.exists?("/etc/init.d/jetty")
    end

    action :create

    not_if do
      File.exists?("/etc/init.d/jetty")
    end
  end
end

service "jetty" do
  action :enable
end

################################################################################
# Jetty Config

directory "/etc/jetty" do
  mode '755'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
end

directory "#{node['rackspace_jetty']['home']}/start.d" do
  mode '755'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
end

link "#{node['rackspace_jetty']['home']}/etc" do
  to "/etc/jetty"
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
end

ruby_block 'Copy Jetty config files' do
  block do
    Chef::Log.info "Copying Jetty config files into #{node['rackspace_jetty']['home']}/etc"

    FileUtils.cp_r File.join(node['rackspace_jetty']['extracted'], 'etc', ''), node['rackspace_jetty']['home']
    FileUtils.remove_file(File.join(node['rackspace_jetty']['home'], 'etc', 'jetty.conf'), true)
    FileUtils.chown_R(node['rackspace_jetty']['user'],node['rackspace_jetty']['group'],File.join(node['rackspace_jetty']['home'], 'etc', ''))
    raise "Failed to copy Jetty config files" if Dir[File.join(node['rackspace_jetty']['home'], 'etc', '*')].empty?
  end

  action :create

  only_if do
    Dir[File.join(node['rackspace_jetty']['home'], 'etc', '*')].empty?
  end
end

template '/etc/default/jetty' do
  source 'jetty.default.erb'
  mode   '644'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
  notifies :restart, "service[jetty]"
  action :create
end


template "/etc/jetty/jetty.conf" do
  source "jetty.conf.erb"
  mode   '644'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
  notifies :restart, "service[jetty]"
end

if node['rackspace_jetty']['start_ini']['custom']
  template "#{node['rackspace_jetty']['home']}/start.ini" do
    source "start.ini.erb"
    mode   '644'
    owner node['rackspace_jetty']['user']
    group node['rackspace_jetty']['group']
    notifies :restart, "service[jetty]"
  end
else
  cookbook_file "#{node['rackspace_jetty']['home']}/start.ini" do
    source "jetty-#{version}-start.ini"
    mode   '644'
    owner node['rackspace_jetty']['user']
    group node['rackspace_jetty']['group']
    notifies :restart, "service[jetty]"
  end
end

################################################################################
# Logs

# folder for logs mandatory at least for the request logs
directory node['rackspace_jetty']['logs'] do
  mode '755'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
end

template File.join(node['rackspace_jetty']['home'], 'resources/jetty-logging.properties') do
  source 'jetty-logging.properties.erb'
  mode   '644'
  owner node['rackspace_jetty']['user']
  group node['rackspace_jetty']['group']
  notifies :restart, "service[jetty]"
  action :create
end
