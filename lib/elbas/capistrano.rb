require 'aws-sdk-v1'
require 'capistrano/dsl'

load File.expand_path("../tasks/elbas.rake", __FILE__)

def autoscale(groupname, *args)
  include Capistrano::DSL
  include Elbas::AWS::AutoScaling

  autoscale_group   = autoscaling.groups[groupname]
  running_instances = autoscale_group.ec2_instances.filter('instance-state-name', 'running')

  set :aws_autoscale_group, groupname

  running_instances.each do |instance|
    hostname = if instance.dns_name && !instance.dns_name.empty?
                 instance.dns_name
               else
                 instance.private_ip_address
               end
    # hostname = instance.dns_name || instance.private_ip_address
    p "ELBAS: Adding server: #{hostname}"
    server(hostname, *args) if hostname && !hostname.empty?
  end

  if running_instances.count > 0
    after('deploy', 'elbas:scale')
  else
    p "ELBAS: AMI could not be created because no running instances were found. Is your autoscale group name correct?"
  end
end
