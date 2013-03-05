require 'stacks/namespace'

class Stacks::MachineDefContainer
  attr_reader :definitions
  attr_reader :environment

  def initialize()
    @definitions = {}
  end

  def children
    # pretend we have a sorted dictionary
    return @definitions.sort.map do |k, v| v end
  end

  def accept(&block)
    block.call(self)
    children.each do |child|
      child.accept(&block)
    end
  end

  def bind_to(environment)
    @environment = environment
    children.each do |child|
      child.bind_to(environment)
    end
  end

  def clazz
    return "container"
  end

  def to_specs
    return self.children.map do |child|
      child.to_specs
    end.flatten
  end

end
