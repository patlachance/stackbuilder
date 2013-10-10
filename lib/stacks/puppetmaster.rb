require 'stacks/namespace'

class Stacks::PuppetMaster < Stacks::MachineDef

  def initialize(base_hostname)
    super(base_hostname, [:mgmt])
  end

  def bind_to(environment)
    super(environment)
  end

  def to_spec
    return {
      :hostname            => @hostname,
      :networks            => @networks,
      :domain              => @domain,
      :fabric              => @fabric,
      :template            => 'puppetmaster',
      :qualified_hostnames => Hash[@networks.map { |network| [network, qualified_hostname(network)] }],
    }
  end

  def to_enc
  end
end
