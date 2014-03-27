#
# Cookbook Name:: rackspace_jetty
# Recipe:: default
#
# Copyright 2012-2013, HipSnip Limited
# Copyright 2014, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['rackspace_jetty']['user'] = 'jetty'
default['rackspace_jetty']['group'] = 'jetty'
default['rackspace_jetty']['home'] = '/usr/share/jetty'
default['rackspace_jetty']['port'] = 8080
# The default arguments to pass to jetty.
default['rackspace_jetty']['args'] = []
default['rackspace_jetty']['logs'] = '/var/log/jetty'
# Extra options to pass to the JVM
default['rackspace_jetty']['java_options'] = []

# set of paths of jetty configuration files relative to jetty home directory.
# e.g: ['etc/jetty-webapps.xml', 'etc/jetty-http.xml']
default['rackspace_jetty']['add_confs'] = []

default['rackspace_jetty']['version'] = '8.1.14.v20131031'
default['rackspace_jetty']['link'] = "http://download.eclipse.org/jetty/#{node['rackspace_jetty']['version']}/dist/jetty-distribution-#{node['rackspace_jetty']['version']}.tar.gz"
default['rackspace_jetty']['checksum'] = '5a91529549ac8956feeebc68b02c0f65' # SHA256

default['rackspace_jetty']['directory'] = '/usr/local/src'

# SEVERE ERROR (highest value) WARNING INFO CONFIG FINE FINER FINEST (lowest value)
default['rackspace_jetty']['log']['level']  = 'INFO'
default['rackspace_jetty']['log']['class'] = 'org.eclipse.jetty.util.log.StdErrLog'

# if true, it will use the utility logger to log messages into syslog
default['rackspace_jetty']['syslog']['enable'] = false
# format expected "facility.level", pass the value to the logger utility into the option "--priority"
default['rackspace_jetty']['syslog']['priority'] = ''
# pass the value to the logger utility into the option "--tag"
default['rackspace_jetty']['syslog']['tag'] = ''

default['rackspace_jetty']['start_ini']['custom'] = false
default['rackspace_jetty']['start_ini']['content'] = []