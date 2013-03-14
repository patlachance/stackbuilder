require 'stacks/environment'
require 'puppet/node'
require 'puppet/indirector/node/plain'

class Puppet::Node::Stacks < Puppet::Node::Plain
  desc "generates the necessary wiring for all nodes in a stack."

  def initialize
    @stacks_inventory = Object.new
    @stacks_inventory.extend Stacks::DSL
    dirs = ['.', '/etc/stacks/']
    dirs.each do |dir|
      file = "#{dir}/stack.rb"
      if File.exist? file
        config = IO.read file
        @stacks_inventory.instance_eval(config, file)
      end
    end
  end

  def find(request)
    node = super
    classes = find_stack_classes(node.parameters['fqdn'])
    if classes
      node.classes = classes
    end
    return node
  end

  def find_stack_classes(fqdn)
    machine = @stacks_inventory.find(fqdn)
    return nil if machine.nil?
    return machine.to_enc
  end

end
