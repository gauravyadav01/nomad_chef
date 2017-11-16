#!/usr/bin/env ruby
#*****************************************************************************************************
#  This script helps in placing nomad jobs, Check allocation and Helath check,
#  Please check help
#  Author: Gaurav Yadav
#  v 0.5
#  ./nomad_java.rb -h
#
#  0.3 - Nov 15, 2017, Added --dry options help you to just see nomad json, added --server.port=${NOMAD_PORT_http} default argument for nomad jobs
#
#
#*****************************************************************************************************

require 'gadabout'
require 'net/http'
require 'optparse'
require 'json'
require 'pp'

options = {}
ARGV << "-h" if ARGV.empty?
new_allocations = []
do_break = false
options[:nomadhost] = '162.111.147.76'
options[:count] = 1
options[:arturl] = "https://artifactory.dev.cci.wellsfargo.com/artifactory"
options[:artrepo] = "ebs-apps-snapshot"
options[:artgroup] = "wf/ebs"
options[:release] = "[RELEASE]"
options[:tags] = []
options[:args] = ['--server.port=${NOMAD_PORT_http}']

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
  opts.on('-j', '--jobname <JOB NAME>', 'Name of Job, default: artname') do |j|
    options[:jobname] = j
  end
  opts.on('--nodeclass <NAME>', 'Logical Name of node') do |nc|
    options[:nodeclass] = nc
  end
  opts.on('-s', '--service <SERVICE NAME>', 'Service Name') do |s|
    options[:service] = s
  end
  opts.on('-t', '--tags <tags1,tags2..>', Array, 'Tags for consul service, No dots in tags, If tags are not provided, default will be consul service name') do |t|
    options[:tags] = t
  end
  opts.on('--artrepo <Artifact REPO>', 'Artifact Repo, default is ebs-snapshot-repo') do |ar|
    options[:artrepo] = ar
  end
  opts.on('--artgroup <Artifact GROUP>', 'Artifact GROUP, default is wf/ebs') do |ag|
    options[:artgroup] = ag
  end
  opts.on('--artname <Artifact NAME>', 'Artifact Name required') do |an|
    options[:artname] = an
  end
  opts.on('--release <Artifact VERSION>', 'Artifact Version, default: artname ') do |av|
    options[:release] = av
  end
  opts.on('--args <Jobs Arguments>', Array, "Args can be passwd in 'arg1','arg2','arg3' in single quotes seperated by qoma" ) do |arg|
    options[:args] << arg
  end
  opts.on('--dry', "Dry run will not schedule any jobs , Will give you print the job in JSON" ) do |dry|
    options[:dry] = true
  end
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:datacenter, :artname]
  missing = mandatory.select{ |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

options[:service] = options[:artname] if options[:service].to_s.empty?
options[:tags] << options[:service]
options[:jobname] = "#{options[:artname]}" + "-" + "#{options[:datacenter][0]}" if options[:jobname].to_s.empty?

client = Gadabout::Client.new(:host => options[:nomadhost])

var = job do
  id options[:jobname]
  name options[:jobname]
  update do
    stagger 30
    max_parallel 1
  end
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
      if options[:args]
      config "args", options[:args].flatten
      end

      services do
        name options[:service]
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


#*********************************************************
puts "Formatting nomad job in json\n"
payload = var.output
puts var.output
puts "\n"
#*********************************************************
unless options[:dry]
puts "Current job information if exists"
current_job = client.job(options[:jobname])
if current_job.length == 0
  puts "No job exists in System"
  new_version = 0
else
  current_version = current_job['Version']
  new_version = current_version.to_i + 1
  puts "Current Job Information for #{options[:jobname]}"
  100.times{ print "*" }
  puts "\n"
  puts JSON.pretty_generate(current_job)
  100.times{ print "*" }
  puts "\n\n"
  puts "Current Version: #{current_version}"
  puts "Newer Version: #{new_version}"
end


puts "Submitting job"
job_output = client.register_job(payload)
evalID = job_output['EvalID']
puts "Submitted job with following EvalID: #{evalID}"
sleep 5
puts "\n"
alloc = client.evaluation_allocations(evalID)

if alloc.length == 0
  puts "There is no allocation. It seems you are not updating any job"
  exit 0
end

allocations = client.job_allocations(options[:jobname])
puts "Wait for all allocation to be placed"
while true do
  allocations.each do |a|
    if a['JobVersion'] == new_version && a['ClientStatus'] == 'running'
      new_allocations << a['ID'] unless new_allocations.include?(a['ID'])
    end
    if new_allocations.length == options[:count]
      do_break = true
    end
  end
   sleep 10
   allocations = client.job_allocations(options[:jobname])
   print "."
   break if do_break
end

puts "\n\n"
puts "Allocations are:"
new_allocations.each_with_index do |v,i|
  i = i +1
  puts "#{i}. #{v}"
end
puts "\n"
sleep 40
puts "Checking Service Health Check"
printf("%40s, %20s, %6s, %20s\n", 'Allocation', 'IP', 'PORT', 'HealthCheck')
new_allocations.each do |na|
  a = client.allocation(na)
  ip = a['Resources']['Networks'][0]['IP']
  port = a['Resources']['Networks'][0]['DynamicPorts'][0]['Value']
  uri = URI("http://#{ip}:#{port}/healthCheck")
  output = Net::HTTP.get(uri)
  printf("%40s, %20s, %6s, %20s\n",  na, ip, port, output)
end
end
