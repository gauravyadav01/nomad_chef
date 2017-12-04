#!/usr/bin/env ruby
#*****************************************************************************************************
#  This script helps in placing nomad jobs, Check allocation and Helath check,
#  Please check help
#  Author: Gaurav Yadav
#  v 0.7
#  ./nomad_java.rb -h
#
#  0.3 - Nov 15, 2017, Added --dry options help you to just see nomad json, added --server.port=${NOMAD_PORT_http} default argument for nomad jobs
#  0.6 - Nov 27, 2017, Added --snapshot-version, -e , snapshot-version and enviornment has been added.
#  0.7 - Nov 27, 2017, Changed /healthCheck to /health
#  0.8 - Nov 27, 2017, Added Nodeclass as subenv
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
events = []
do_break = false
artificaturl = ""
jarpath = ""
options[:count] = 1
options[:arturl] = "https://artifactory.dev.cci.wellsfargo.com/artifactory"
options[:artrepo] = "ebs-apps-snapshot"
options[:artgroup] = "wf/ebs"
options[:release] = "[RELEASE]"
options[:tags] = []
options[:args] = ['--server.port=${NOMAD_PORT_http}']
options[:env] = "dev"

options[:host] = {
  :dev => '162.111.147.76',
  :test => '22.52.33.144',
  :prod => '22.45.34.244'
}
options[:user] = {
  :dev => 'nobody',
  :test => 'ecctest',
  :prod => 'ecccom'
}

optparse = OptionParser.new do |opts|
  opts.on('--nomadhost IPADDRESS', 'Nomad IP Address, default to dev 162.111.147.76') do |h|
    options[:nomadhost] = h
  end
  opts.on('-e', '--env ENV', 'Environment dev, test, prod') do |e|
    options[:env] = e
  end
  opts.on('--subenv SUBENV', 'Environment test,uat,perf,prodimage') do |se|
    options[:subenv] = se
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
  opts.on('--snapshot-version <snapshot VERSION>', 'Snapshot Version 1.0-20171117.171432-1 ') do |sv|
    options[:snapshot] = sv
  end
  opts.on('--args <Jobs Arguments>', Array, "Args can be passwd in 'arg1','arg2','arg3' in single quotes seperated by qoma" ) do |arg|
    options[:args] << arg
  end
  opts.on('-u', '--nomad-user <Nomad User>', "Nomad User, dev: nobody, test: ecctest, prod: ecccom,  default will be nobody" ) do |u|
    options[:nomaduser] = u
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
if options[:subenv]
  options[:service] = options[:service] + "-#{options[:subenv]}"
end
options[:tags] << options[:service]
options[:jobname] = "#{options[:artname]}" + "-" + "#{options[:datacenter][0]}" if options[:jobname].to_s.empty?
if options[:subenv]
  options[:jobname] = options[:jobname] + "-#{options[:subenv]}"
end


if options[:release]
  artifacturl = "#{options[:arturl]}/#{options[:artrepo]}/#{options[:artgroup]}/#{options[:artname]}/#{options[:release]}/#{options[:artname]}-#{options[:release]}-jdk8.jar"
  jarpath = "local/#{options[:artname]}-#{options[:release]}-jdk8.jar"
end
if options[:snapshot]
  a = options[:snapshot].split('-')
  options[:release] = a[0]
  artifacturl = "#{options[:arturl]}/#{options[:artrepo]}/#{options[:artgroup]}/#{options[:artname]}/#{options[:release]}-SNAPSHOT/#{options[:artname]}-#{options[:snapshot]}-jdk8.jar"
  jarpath = "local/#{options[:artname]}-#{options[:snapshot]}-jdk8.jar"
end


if options[:nomadhost].to_s.empty?
  if options[:env] == 'test'
    options[:nomadhost] = options[:host][:test]
  elsif options[:env] == "prod"
    options[:nomadhost] = options[:host][:prod]
  else
    options[:nomadhost] = options[:host][:dev]
  end
end
if options[:nomaduser].to_s.empty?
  if options[:env] == 'test'
    options[:nomaduser] = options[:user][:test]
  elsif options[:env] == "prod"
    options[:nomaduser] = options[:user][:prod]
  else
    options[:nomaduser] = options[:user][:dev]
  end
end

if options[:env] == 'test' || options[:env] == 'prod'
  if !options[:nodeclass]
    options[:nodeclass] = options[:subenv]
  end
end


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
      user options[:nomaduser]
      if options[:nodeclass]
        constraint do
          l_target "${node.class}"
          operand "="
          r_target options[:nodeclass]
        end
      end
      artifact do
        source "#{artifacturl}"
      end

      driver "java"
      #config "jar_path", "local/#{options[:artname]}-#{options[:release]}-jdk8.jar"
      config "jar_path", "#{jarpath}"
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
#while true do
#  allocations.each do |a|
#    if a['JobVersion'] == new_version && a['ClientStatus'] == 'running'
#      new_allocations << a['ID'] unless new_allocations.include?(a['ID'])
#    end
#    if new_allocations.length == options[:count]
#      do_break = true
#    end
#  end
#   sleep 10
#   allocations = client.job_allocations(options[:jobname])
#   #print "."
#   print
#   break if do_break
#end

#puts "\n\n"
#puts "Allocations are:"
#new_allocations.each_with_index do |v,i|
#  i = i +1
#  puts "#{i}. #{v}"
#end
#puts "\n"
#sleep 40
#puts "Checking Service Health Check"
#printf("%40s, %20s, %6s, %20s\n", 'Allocation', 'IP', 'PORT', 'HealthCheck')
#new_allocations.each do |na|
#  a = client.allocation(na)
#  ip = a['Resources']['Networks'][0]['IP']
#  port = a['Resources']['Networks'][0]['DynamicPorts'][0]['Value']
#  uri = URI("http://#{ip}:#{port}/health")
#  output = Net::HTTP.get(uri)
#  printf("%40s, %20s, %6s, %20s\n",  na, ip, port, output)
#end
#
while true do
  allocations.each do |a|
    if a['JobVersion'] == new_version
      while a['ClientStatus'] != 'running'
        a['TaskStates'][options[:jobname]]['Events'].each do |e|
          events << e['Type'] unless events.include?(e['Type'])
          puts events
        end
      end
    end
  end
end


end
