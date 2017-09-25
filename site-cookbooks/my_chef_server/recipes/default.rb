#
# Cookbook Name:: my-chef-server
# Recipe:: default
#
# Copyright (C) 2017 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'chef-server::default'
include_recipe 'chef-server::addons'

execute 'create-admin-user' do
  command 'chef-server-ctl user-create admin Admin User admin@example.com admin123 --filename /vagrant/.chef/admin.key'
  not_if 'chef-server-ctl user-list | grep "admin"'
end

execute 'create-organization' do
  command 'chef-server-ctl org-create example "Example Inc." --association_user admin --filename /vagrant/.chef/example.key'
  not_if 'chef-server-ctl org-list | grep "sample"'
end

execute 'copy ssl certs' do
  command 'yes | cp -pf /var/opt/opscode/nginx/ca/chef-server.example.com.* /vagrant/.chef/trusted_certs/'
end

