#
# Cookbook:: my_haproxy
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.
#

package 'haproxy' do
  action :install
end

service 'haproxy' do
  action [:enable, :start]
end

consul_definition 'haproxy' do 
  type 'service'
  parameters(
    port: 8200,
    address: '127.0.0.1',
    tags: ['haproxy'],
    check: {
      interval: '10s',
      timeout: '5s',
      http: 'http://127.0.0.1:8080/stats'
    }
  )
  notifies :reload, 'consul_service[consul]', :delayed
end

include_recipe "#{cookbook_name}::consul-template"
