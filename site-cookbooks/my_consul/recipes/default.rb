#
# Cookbook:: my_consul
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#

include_recipe 'consul'

execute 'remove download consul' do
  command 'rm -rf /tmp/vagrant-cache/chef/*consul_0.9.3_linux_amd64.zip'
end

service_name = node['consul']['service_name']
  config = consul_config service_name do |r|
  node['consul']['config'].each_pair { |k, v| r.send(k, v) }
  notifies :restart, "consul_service[#{service_name}]", :delayed
end
