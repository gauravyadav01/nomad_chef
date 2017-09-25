include_recipe 'ark'

ark 'consul-template' do
  url 'https://releases.hashicorp.com/consul-template/0.19.3/consul-template_0.19.3_linux_amd64.zip'
  version '0.19.3'
  path '/opt/consul-template/0.19.3'
  strip_components 0
  has_binaries %w(consul-template)
  action :install
  mode '0755'
end

directory '/etc/consul-template.d' do
  action :create
end

systemd_unit 'consul-template.service' do
  content <<-EOF
  [Unit]
  Description=consul-template
  Requires=network-online.target

  [Service]
  EnvironmentFile=-/etc/sysconfig/consul-template
  Restart=on-failure
  ExecStart=/usr/local/consul-template/consul-template -config=/etc/consul-template.d

  [Install]
  WantedBy=multi-user.target
  EOF
  .gsub(/^ +/, "")

  action [:create, :enable]
  notifies :restart, 'systemd_unit[consul-template.service]', :delayed
end

template '/etc/haproxy/haproxy.ctmpl' do
  source 'haproxy.ctmpl.erb'
  notifies :restart, 'service[consul-template]', :delayed
end

service 'consul-template' do
  action [:enable, :start]
end

template '/etc/consul-template.d/consul-template.cfg' do
  source 'consul-template.cfg.erb'
  notifies :restart, 'service[consul-template]', :delayed
end


