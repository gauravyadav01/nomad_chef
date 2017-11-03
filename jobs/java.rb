#!/usr/bin/env ruby
#

require 'gadabout'
require 'optparse'

options = {}
ARGV << "-h" if ARGV.empty?
options[:count] = 1
options[:artrepo] = "ebs-snapshot-repo"

optparse = OptionParser.new do |opts|
  opts.on('-d', '--datacenter DATACENTER', Array, 'Datacenter comma seperated - required') do |d|
    options[:datacenter] = d
  end
  opts.on('-c', '--count n', '<Number of instances> Default to 1') do |c|
    options[:count] = c.to_i
  end
  opts.on('-j', '--jobname <JOB NAME>', 'Name of Job') do |j|
    options[:jobname] = j
  end
  opts.on('--nodeclass <NAME>', 'Logical Name of node') do |nc|
    options[:nodeclass] = nc
  end
  opts.on('-s', '--service <SERVICE NAME>', Array, 'Service Name') do |s|
    options[:service] = s
  end
  opts.on('-t', '--tags <tags1,tags2..>', Array, 'Tags for consul service, No dots in tags, If tags are not provided, default will be consul service name') do |t|
    options[:tags] = t
  end
  opts.on('--artrepo <Artifact REPO>', 'Artifact Repo, default is ebs-snapshot-repo') do |ar|
    options[:artrepo] = ar
  end
  opts.on('--artgroup <Artifact GROUP>', 'Artifact GROUP required') do |ag|
    options[:artgroup] = ag
  end
  opts.on('--artname <Artifact NAME>', 'Artifact Name required') do |an|
    options[:artname] = an
  end
  opts.on('--artversion <Artifact VERSION>', 'Artifact Version required') do |av|
    options[:artversion] = av
  end
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:datacenter, :jobname, :service, :nodeclass, :artgroup, :artversion, :artname]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

options[:tags] = options[:service] if options[:tags].to_s.empty?

client = Gadabout::Client.new(host='192.168.10.5')

var = job do
  id options[:jobname]
  name options[:jobname]
  region "global"
  type "service"
  #datacenters "#{options[:datacenter][0]}", "#{options[:datacenter][1]}"
  datacenters options[:datacenter]

  task_group do
    name options[:jobname]
    count options[:count]
    task do
      name options[:jobname]
      constraint do
        l_target "${node.class}"
        operand "="
        r_target options[:nodeclass]
      end
      artifact do
        source "https://artifactory.dev.cci.wellsfargo.com/artifactory/#{options[:artrepo]}/#{options[:artgroup]}/#{options[:artname]}/#{options[:artversion]}/#{options[:artname]}-#{options[:artversion]}-jdk8.jar"
      end

      driver "java"
      config "jar_path", "local/#{options[:artname]}-#{options[:artversion]}-jdk8.jar"
      config "args", [
        "-f"
      ]
      services do
        name options[:service][0]
#        tags "#{options[:tags][0]}", "#{options[:tags][1]}", "#{options[:tags][2]}", "#{options[:tags][3]}", "#{options[:tags][4]}"
        tags options[:tags]
        port_label "http"
        checks do
          type "tcp"
          port_label "http"
          interval 10000000000
          timeout 2000000000
        end
      end
      resources do
        network do |n|
          reserved_port "http", 80
        end

      end
    end
  end
end

payload = var.instance_variable_get :@output

puts payload
#client.register_job(payload)
