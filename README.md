# nomad_chef

This repository to help you configure your nomad development environment with Chef-server. This Vagrant file will help you to create a Chef server.
This repository is using batali to solve cookbook dependency. 
It is using vagrant landrush plugin for DNS purpose. 

You can add many servers you want in servers.yaml file. Nomad server is running hashi-ui for nomad GUI support. Nomad server and worker will deploy java 8.
Haproxy is having consul-template. Consul Template will monitor consul and add or remove backend on the basis of consul service. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

Follow below instructions

```
git clone https://github.com/gauravyadav01/chef-server.git
cd nomad-server
gem install
```

Install below vagrant plugin.

* vagrant-omnibus 
* chef landrush 
* vagrant-cachier 
* vagrant-ohai ( Please download vagrant-ohai from https://github.com/gauravyadav01/vagrant-ohai/blob/master/vagrant-ohai-0.1.14.gem) 


"Batali update" will create a cookbooks directory and fetch all dependent cookbooks in cookbook directory.

```
batali update
```

When using Landrush on OS X, Landrush will try to create a file in
`/etc/resolver` to make the guest VM visible via DNS on the host. See *OS X* in the *Visibility on the Host* section of the link:Usage.adoc[Usage guide]. To create this file, sudo permissions are needed and Landrush
will ask you for your sudo password. +
 +
This can be avoided by adding the
following entries to the bottom of the sudoer configuration. Make sure
to edit your `/etc/sudoers` configuration via `sudo visudo`:

```
Begin Landrush config
Cmnd_Alias VAGRANT_LANDRUSH_HOST_MKDIR = /bin/mkdir /etc/resolver/*
Cmnd_Alias VAGRANT_LANDRUSH_HOST_CP = /bin/cp /*/vagrant_landrush_host_config* /etc/resolver/*
Cmnd_Alias VAGRANT_LANDRUSH_HOST_CHMOD = /bin/chmod 644 /etc/resolver/*
%admin ALL=(ALL) NOPASSWD: VAGRANT_LANDRUSH_HOST_MKDIR, VAGRANT_LANDRUSH_HOST_CP, VAGRANT_LANDRUSH_HOST_CHMOD
End Landrush config
```

Create your chef-server running below command.


```
vagrant up chef-server
```
Chef-server will be ready and it will create admin user and example organization. This process will create admin and example key in .chef directory with chef-server certificates.

userid: admin
password: admin123

You can reach to server through https://chef-server.example.com


Run below commad to verify 

```
➜ knife ssl check
Connecting to host chef-server.example.com:443
Successfully verified certificates from `chef-server.example.com'
```

and 

```
➜ knife node list
```

Please run below commad to relove cookbook dependency again. It will create cookbooks directory with cookbook and vaersion as suffix.

```
batali resolve --infrastructure
batali install
```

Upload all information to chef-server.

```
knife upload .
```


you can run vagrant up consul0 and further to spin up instance.

* consul0 - consul Initial server - URL: http://consul0.example.com:8500
* server1 - Nomad Initial server  - URL: http://server1.example.com:3000/
* haproxy0 - haproxy server       - URL: http://haproxy0.example.com:8080/stats


## Advance Configuration
You can modify instance variable from servers.yaml. 

Example of servers.yml file

```
---
  :domain: example.com
  :network: 192.168.10.0/24
  :box: bento/centos-7.3
  :vms:
    - :name: chef-server
      :ip: 192.168.10.2
      :role: my_chef_zero
      :cpu: 2
      :memory: 2048
    - :name: chef-node1
      :ip: 192.168.10.3
      :role: base
```

## adding your changes to cookbook
Make all your changes to site-cookbooks direcory. Run below command after making any chnages.

```
batali update
knife upload .
```

Run vagrant provision server-name  to provision the server with new changes.


