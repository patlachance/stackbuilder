require 'stacks/namespace'
require 'stacks/machine_def_container'
require 'stacks/server'

class Stacks::VirtualService < Stacks::MachineDefContainer
  attr_reader :name
  attr_reader :environment

  def initialize(name, env)
    @name = name
    @network = :prod
    @definitions = {}
  end

  def bind_to(environment)
    @environment = environment
    @fabric = environment.options[:primary]
    @domain = "#{@fabric}.net.local"
    2.times do |i|
      index = sprintf("%03d",i+1)
      @definitions["#{name}-#{index}"] = Stacks::Server.new(self, index, :primary)
    end
    super(environment)
  end

  def clazz
    return 'virtualservice'
  end

  def realservers
    return @definitions.values
  end

  def vip_fqdn
    "#{@environment.name}-#{name}-vip.#{@domain}"
  end

  def to_vip_spec
    {
      :fabric => @fabric,
      :networks => [@network],
      :qualified_hostnames => {@network => vip_fqdn}
    }
  end

end
