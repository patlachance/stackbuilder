require 'stacks/namespace'
require 'stacks/machine_def_container'
require 'stacks/virtual_service'
require 'stacks/virtual_proxy_service'
require 'stacks/machine_set'
require 'stacks/app_service'
require 'stacks/loadbalancer'
require 'stacks/nat_server'
require 'stacks/proxy_server'
require 'stacks/virtual_sftp_service'
require 'stacks/virtual_rabbitmq_service'
require 'stacks/ci_slave'
require 'stacks/elasticsearch_node'
require 'stacks/puppetmaster'

class Stacks::Stack
  attr_reader :name

  include Stacks::MachineDefContainer

  def initialize(name)
    @name = name
    @definitions = {}
  end

  def virtual_appserver(name, &block)
    machineset_with(name, [Stacks::VirtualService, Stacks::AppService], Stacks::AppServer, &block);
  end

  def standalone_appserver(name, &block)
    machineset_with(name, [Stacks::AppService], Stacks::AppServer, &block);
  end

  def virtual_proxyserver(name, &block)
    machineset_with(name, [Stacks::VirtualService, Stacks::XProxyService], Stacks::ProxyServer, &block)
  end

  def virtual_sftpserver(name, &block)
    machineset_with(name, [Stacks::VirtualService, Stacks::VirtualSftpService], Stacks::SftpServer, &block)
  end

  def virtual_rabbitmqserver(&block)
    machineset_with('rabbitmq', [Stacks::VirtualService, Stacks::VirtualRabbitMQService], Stacks::RabbitMQServer, &block)
  end

  def puppetmaster(name="puppetmaster-001")
    @definitions[name] = Stacks::PuppetMaster.new(name)
  end

  def loadbalancer(&block)
    machineset_with('lb', [], Stacks::LoadBalancer, &block)
  end

  def natserver(&block)
    machineset_with('nat', [], Stacks::NatServer, &block)
  end

  def ci_slave(&block)
    machineset_with('jenkinsslave', [], Stacks::CiSlave, &block)
  end

  def elasticsearch(&block)
    machineset_with('elasticsearch', [], Stacks::ElasticSearchNode, &block)
  end

  def [](key)
    return @definitions[key]
  end

  private
  def machineset_with(name, extends, type, &block)
    machineset = Stacks::MachineSet.new(name, &block)
    machineset.extend(Stacks::MachineGroup)
    extends.each { |e| machineset.extend(e) }
    machineset.type=type
    @definitions[name]=machineset
  end
end

