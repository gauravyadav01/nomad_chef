default['nomad']['package'] = '0.6.3/nomad_0.6.3_linux_amd64.zip'
default['nomad']['checksum'] = '908ee049bda380dc931be2c8dc905e41b58e59f68715dce896d69417381b1f4e'
#default['nomad']['package'] = '0.6.2/nomad_0.6.2_linux_amd64.zip'
#default['nomad']['checksum'] = 'fbcb19a848fab36e86ed91bb66a1602cdff5ea7074a6d00162b96103185827b4'
#default['nomad']['package'] = 'nomad_0.7.0-beta1_linux_amd64.zip'
#default['nomad']['checksum'] = '174794d96d2617252875e2e2ff9e496120acc4a97be54965c324b9a5d11b37ab'
default['nomad']['client']['options'] = {
  "driver.raw_exec.enable" => "1",
 }

default['hashi_ui']['version'] = 'v0.20.1'
default['hashi_ui']['config']['nomad-address'] = "http://#{node['ipaddress']}:4646"
default['hashi_ui']['config']['consul-enable'] = false
default['hashi_ui']['config']['nomad-enable'] = true
