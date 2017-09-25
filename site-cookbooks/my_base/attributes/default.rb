#default['my_base']['package'] = %w{dnsmasq}
default['dnsmasq']['dns'] = {
  'domain-needed' => nil,
  'bogus-priv' => nil,
  'domain' => "#{node['domain']}",
  'resolv-file' => '/etc/resolv.dnsmasq.conf',
  'server' => '/consul/127.0.0.1#8600'
}

default['resolver']['nameservers'] = ['127.0.0.1']
default['resolver']['search'] = nil
