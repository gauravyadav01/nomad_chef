#!/usr/bin/env ruby
#

require 'gadabout'
require 'optparse'

options = {}
ARGV << "-h" if ARGV.empty?
options[:nomadhost] = '162.111.147.76'
options[:count] = 1
options[:arturl] = "https://artifactory.dev.cci.wellsfargo.com/artifactory"
options[:artrepo] = "ebs-apps-snapshot"
options[:artgroup] = "wf/ebs/emsa"
options[:release] = "[RELEASE]"
optparse = OptionParser.new do |opts|
  opts.on('--nomadhost IPADDRESS', 'Nomad IP Address, default to dev 162.111.147.76') do |h|
    options[:nomadhost] = h
  end
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
  opts.on('--artgroup <Artifact GROUP>', 'Artifact GROUP, default is wf/ebs/emsa') do |ag|
    options[:artgroup] = ag
  end
  opts.on('--artname <Artifact NAME>', 'Artifact Name required') do |an|
    options[:artname] = an
  end
  opts.on('--release <Artifact VERSION>', 'Artifact Version required') do |av|
    options[:release] = av
  end
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:datacenter, :jobname, :service, :release, :artname]
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

client = Gadabout::Client.new(host="#{options[:nomadhost]}")

var = job do
  id options[:jobname]
  name options[:jobname]
  region "global"
  type "service"
  datacenters options[:datacenter]

  task_group do
    name options[:jobname]
    count options[:count]
    task do
      name options[:jobname]
      if options[:nodeclass]
        constraint do
          l_target "${node.class}"
          operand "="
          r_target options[:nodeclass]
        end
      end
      artifact do
        source "#{options[:arturl]}/#{options[:artrepo]}/#{options[:artgroup]}/#{options[:artname]}/#{options[:release]}/#{options[:artname]}-#{options[:release]}-jdk8.jar"
      end

      driver "java"
      config "jar_path", "local/#{options[:artname]}-#{options[:release]}-jdk8.jar"
      config "args", [
        "--server.port=${NOMAD_PORT_http}",
        "--spring.profiles.active=desktop"
      ]
      services do
        name options[:service][0]
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
          dynamic_port "http"
        end
        memory 2000
        cpu 1000
      end
    end
  end
end

puts "Formatting nomad job in json\n"
payload = var.output
puts var.output
puts "\n"
puts "Submitting job"
client.register_job(payload)
