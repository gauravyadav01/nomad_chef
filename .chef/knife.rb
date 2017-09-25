current_dir = File.dirname(__FILE__)
  node_name                "admin"
  client_key               "#{current_dir}/admin.key"
  validation_client_name   "example-validator"
  validation_key           "#{current_dir}/example.key"
  chef_server_url          "https://chef-server.example.com/organizations/example"
  syntax_check_cache_path  "#{current_dir}/syntax_check_cache"
  cookbook_path            ["#{current_dir}/../cookbooks"]
  log_level                :info
  log_location             STDOUT
  versioned_cookbooks      true
  knife[:roles_path]       = "#{current_dir}/../roles"
