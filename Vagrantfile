# -*- mode: ruby -*-
# vi: set ft=ruby noet :
#
#
# Require YAML module
require 'yaml'
require 'chef'


# mutable by ARGV and settings file
file    = 'servers.yaml'
default_domain  = 'example.com'
default_network = '192.168.2.0/24'


# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"
vagrantfiledir = File.expand_path File.dirname(__FILE__)
f = File.join(vagrantfiledir, file)
Chef::Config.from_file(File.join(File.dirname(__FILE__), '.chef', 'knife.rb'))


# Read YAML file with box details
begin
  settings = YAML.load_file f
  domain   = settings.fetch(:domain, default_domain)
  network  = settings.fetch(:network, default_network)
  if settings[:vms].is_a?(Array)
    vms = settings[:vms]
  end
rescue
  puts "Create a servers.yaml file in current direcory"
  message = <<-EOF
  ---
  - name: coreos-01
    box: coreos-alpha
    ip: 192.168.10.2
  EOF
  puts message
  exit 1
end

msg = <<MSG
*************************************************
* Chef-server URL : https://chef-server.example.com
*
* Username: admin
* Password: admin123
*************************************************
MSG


# Create boxes
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if Vagrant.has_plugin?('vagrant-cachier')
    config.cache.scope = :box
    config.cache.auto_detect = true
    #config.cache.synced_folder_opts = { type: :nfs }
  else
    puts 'WARN:  Vagrant-cachier plugin not detected. Continuing unoptimized.'
  end

	default_cpu = 1
	default_memory = 512
	default_box = 'bento/centos-7.3'
  config.omnibus.cache_packages = false
  config.ssh.insert_key         = false
  config.vm.box_check_update    = false
  config.landrush.enabled       = true
  config.landrush.tld           = domain
  config.vm.synced_folder       ".", "/vagrant"

  # Iterate through entries in YAML file
  vms.each_with_index do |x, i|
		name   = x[:name]
		ip     = x[:ip]
		role   = x.fetch(:role, 'base')
		box    = x.fetch(:box, default_box)
		memory = x.fetch(:memory, default_memory)
		cpu    = x.fetch(:cpu, default_cpu)


    config.vm.define name.to_sym do |vm|
      vm.vm.hostname  = "#{name}.#{domain}"
      vm.vm.box       = box
      vm.vm.network   :private_network, ip: ip
      vm.vm.provider  :virtualbox do |vb|
	    vb.linked_clone = true
      vb.name         = name
      vb.memory       = memory
      vb.cpus         = cpu
			vb.auto_nat_dns_proxy = false
			vb.customize    ["modifyvm", :id, "--natdnshostresolver1", "on"]
			vb.customize    ["modifyvm", :id, "--natdnsproxy1", "on"]
		  vb.customize    ["modifyvm", :id, "--nictype1", "virtio" ]
		  vb.customize    ["modifyvm", :id, "--nictype2", "virtio" ]
    end
      if name == 'chef-server'
        config.vm.provision :chef_solo do |chef|
	        chef.roles_path = 'roles'
	        chef.data_bags_path = 'data_bags'
	        chef.add_role("role[#{role}]")
	        chef.log_level = 'info'
	      end
				config.vm.post_up_message = "#{msg}"
      else
        config.vm.provision           :chef_client do |chef|
          config.omnibus.chef_version = '13.2.20'
          chef.chef_server_url        = Chef::Config[:chef_server_url]
          chef.log_level              = Chef::Config[:log_level]
          chef.validation_key_path    = Chef::Config[:validation_key]
          chef.validation_client_name = Chef::Config[:validation_client_name]
          chef.node_name              = vm.vm.hostname
          chef.delete_node            = true
          chef.delete_client          = true
          chef.environment            = "development"
	        chef.run_list               = [
	          "role[#{role}]"
	        ]
        end
      end
    end
  end
end
