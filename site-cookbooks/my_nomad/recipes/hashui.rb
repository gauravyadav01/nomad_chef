include_recipe 'hashi_ui'

consul_definition 'hash-ui' do
  type 'service'
  parameters(
    port: 3000,
    address: "#{node['ipaddress']}",
    tags: ['hash-ui'],
    check: {
      interval: '10s',
      timeout: '5s',
      http: "http://#{node['ipaddress']}:3000"
    }
  )
  notifies :reload, 'consul_service[consul]', :delayed
end
