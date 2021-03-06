require 'stacks/hosts/host_repository'

describe Stacks::Hosts::HostRepository do
  before do
    extend Stacks::DSL
  end

  def test_env_with_refstack
    stack "ref" do
      virtual_appserver "refapp"
    end

    env "test", :primary_site => "t" do
      instantiate_stack "ref"
    end

    find_environment("test")
  end

  it 'removes all policies if using local fabric' do
    env = test_env_with_refstack
    compute_node_client = double

    preference_functions = []
    policy = Proc.new do |machine,host|
      raise "I should not be called"
    end

    result = {"onlyhost" => {:active_domains=>[]}}
    compute_node_client.stub(:audit_hosts).and_return(result)

    host_repo = Stacks::Hosts::HostRepository.new(
      :machine_repo => self,
      :preference_functions=>preference_functions,
      :policies=>[policy],
      :compute_node_client => compute_node_client)

    hosts = host_repo.find_current("local")
    hosts.hosts.size.should eql(1)
    hosts.allocate(env.flatten)
  end
  
  it 'creates a Hosts object with corresponding Host objects' do
    env = test_env_with_refstack
    machines = env.flatten.map {|machine| machine.hostname}

    compute_node_client = double
    n = 5
    result = {}
    n.times do |i|
      result["h#{i}"] = {
        :active_domains=>machines
      }
    end

    preference_functions = []
    compute_node_client.stub(:audit_hosts).and_return(result)

    host_repo = Stacks::Hosts::HostRepository.new(
    :machine_repo => self,
    :preference_functions=>preference_functions,
    :compute_node_client => compute_node_client)

    hosts = host_repo.find_current("t")
    hosts.hosts.size.should eql(n)
    hosts.hosts.each do |host|
      host.preference_functions.should eql(preference_functions)
      host.machines.should eql(env.flatten)
    end
  end
end
