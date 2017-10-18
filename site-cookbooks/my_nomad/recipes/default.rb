#
# Cookbook:: my_nomad
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'ark'

nomad = node['nomad']

nomad_client_config '01-default' do
  network_interface 'eth1'
  node_class nomad['client']['node_class'] if nomad['client']['node_class']
  options nomad['client']['options'] if nomad['client']['options']
  notifies :restart, 'service[nomad]', :delayed
end

nomad_server_config '01-default' do
  bootstrap_expect nomad['bootstrap_expect'] if nomad['bootstrap_expect']
  notifies :restart, 'service[nomad]', :delayed
end

nomad_config '01-default' do
  bind_addr node['ipaddress']
  datacenter 'dc1'
  leave_on_interrupt true
  leave_on_terminate true
  notifies :restart, 'service[nomad]', :delayed
end

include_recipe 'nomad'

if node.role?('nomad_server') || node.role?('nomad_server_initial')
  include_recipe "#{cookbook_name}::hashui"
end
