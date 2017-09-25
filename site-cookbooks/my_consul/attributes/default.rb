default['consul']['version'] = '0.9.3'
default['consul']['config']['bind_addr'] = node['ipaddress']
default['consul']['config']['retry_join'] = %w{192.168.10.3}
