#
# Cookbook:: base
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
include_recipe 'dnsmasq'

cookbook_file '/etc/dhcp/dhclient-enter-hooks' do
  owner 'root'
  group 'root'
  mode '0755'
  source 'dhclient-enter-hooks'
  action :create
end

execute 'create upstream dnsmasq' do
  command '/sbin/dhclient -r eth0 && /sbin/dhclient eth0 > /etc/resolv.dnsmasq.conf'
  creates '/etc/resolv.dnsmasq.conf'
  notifies :restart, 'service[dnsmasq]', :immediately
end

include_recipe 'resolver'

file '/etc/NetworkManager/conf.d/nodnsupdate' do
  content "[main]\ndns=none"
  mode '0755'
end


