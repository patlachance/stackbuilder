require 'stacks/hosts/hosts'
require 'stacks/hosts/host_policies'

describe Stacks::Hosts::HostPolicies do
  before do
    @machine_repo = Object.new
    @machine_repo.extend Stacks::DSL
  end

  def test_env_with_refstack
    @machine_repo.stack "ref" do
      virtual_appserver "refapp"
    end

    @machine_repo.env "test", :primary_site => "t" do
      instantiate_stack "ref"
    end

    @machine_repo.find_environment("test")
  end

  it 'allows allocations that have no machine of the same group to the same host' do
    env = test_env_with_refstack
    machines = env.flatten
    h1 = Stacks::Hosts::Host.new("h1")
    Stacks::Hosts::HostPolicies.ha_group().call(h1, machines[1])[:passed].should eql(true)
  end

  it 'rejects allocations that allocate >1 machine of the same group to the same host' do
    env = test_env_with_refstack
    machines = env.flatten
    h1 = Stacks::Hosts::Host.new("h1")
    h1.allocated_machines << machines[0]
    Stacks::Hosts::HostPolicies.ha_group().call(h1, machines[1])[:passed].should eql(false)
  end

  it 'allows allocation if the availability group is unset' do
    machine = double
    running_machine= double

    machine.stub(:availability_group).and_return(nil)
    running_machine.stub(:availability_group).and_return(nil)

    h1 = Stacks::Hosts::Host.new("h1")
    h1.allocated_machines << running_machine
    Stacks::Hosts::HostPolicies.ha_group().call(h1, machine)[:passed].should eql(true)
  end

  it 'allows allocations where the host ram is sufficient' do
    candidate_machine = double
    provisionally_allocated_machine = double
    existing_machine = double

    candidate_machine.stub(:ram).and_return('2097152') # 2GB
    provisionally_allocated_machine.stub(:ram).and_return('2097152') # 2GB
    existing_machine.stub(:ram).and_return('2097152') # 2GB

    h1 = Stacks::Hosts::Host.new("h1", :ram => '8388608') # 8GB
    h1.allocated_machines << existing_machine
    h1.provisionally_allocated_machines << provisionally_allocated_machine

    Stacks::Hosts::HostPolicies.do_not_overallocated_ram_policy().call(h1, candidate_machine)[:passed].should eql(true)
  end

  it 'rejects allocations where the host ram is insufficient due to host reserve' do
    candidate_machine = double
    provisionally_allocated_machine = double
    existing_machine = double

    candidate_machine.stub(:ram).and_return('2097152') # 2GB
    provisionally_allocated_machine.stub(:ram).and_return('2097152') # 2GB
    existing_machine.stub(:ram).and_return('2097152') # 2GB

    h1 = Stacks::Hosts::Host.new("h1", :ram => '8388607') # 1 byte under 8GB
    h1.allocated_machines << existing_machine
    h1.provisionally_allocated_machines << provisionally_allocated_machine

    Stacks::Hosts::HostPolicies.do_not_overallocated_ram_policy().call(h1, candidate_machine)[:passed].should eql(false)
  end

  it 'rejects allocations where the host ram is insufficient' do
    candidate_machine = double
    provisionally_allocated_machine = double
    existing_machine = double

    candidate_machine.stub(:ram).and_return('2097152') # 2GB
    provisionally_allocated_machine.stub(:ram).and_return('2097152') # 2GB
    existing_machine.stub(:ram).and_return('2097152') # 2GB

    h1 = Stacks::Hosts::Host.new("h1", :ram => '4194304') # 4GB
    h1.allocated_machines << existing_machine
    h1.provisionally_allocated_machines << provisionally_allocated_machine

    Stacks::Hosts::HostPolicies.do_not_overallocated_ram_policy().call(h1, candidate_machine)[:passed].should eql(false)
  end
end
