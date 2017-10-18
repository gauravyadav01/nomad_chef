#
# Cookbook:: base
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#
#
 file '/etc/NetworkManager/conf.d/10NetworkManager.conf' do
   content "[main]\ndns=dnsmasq\n"
   mode '0644'
   notifies :restart, 'service[NetworkManager]', :delayed
 end

 file '/etc/resolv.dnsmasq.conf' do
   content "nameserver 10.0.2.3"
   mode '0644'
   notifies :restart, 'service[NetworkManager]', :delayed
 end

 file '/etc/resolv.conf' do
   content "nameserver 127.0.0.1"
   mode '0644'
   notifies :restart, 'service[NetworkManager]', :delayed
 end


 cookbook_file '/etc/NetworkManager/dnsmasq.d/dnsmasq.conf' do
   source 'dnsmasq.conf'
   mode '0644'
   notifies :restart, 'service[NetworkManager]', :delayed
 end

 service 'NetworkManager' do
   action [:enable, :start]
 end
