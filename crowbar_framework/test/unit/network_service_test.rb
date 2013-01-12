# Copyright 2012, Dell 
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 
require 'test_helper'
require 'network_service'
 
class NetworkServiceTest < ActiveSupport::TestCase

  # Test creation
  test "network_create: success" do
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, "public")
  end


  # Test failed network creation due to missing router_pref
  test "network_create: missing router_pref" do
    net_service = NetworkService.new(Rails.logger)

    proposal = NetworkTestHelper.create_or_get_proposal()

    http_error, network = net_service.network_create(
        "public2",
        proposal.id,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network creation due to missing router_ip
  test "network_create: missing router_ip" do
    net_service = NetworkService.new(Rails.logger)

    proposal = NetworkTestHelper.create_or_get_proposal()

    http_error, network = net_service.network_create(
        "public3",
        proposal.id,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test failed network creation due to missing ip range
  test "network_create: missing no ip range" do
    net_service = NetworkService.new(Rails.logger)

    proposal = NetworkTestHelper.create_or_get_proposal()

    http_error, network = net_service.network_create(
        "public4",
        proposal.id,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        nil,
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test retrieval by name
  test "network_get: by name success" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    # Get by name
    network = get_a_network(net_service, net_name)
    assert_equal net_name, network.name, "Expected to get network with name #{net_name}, got network with name #{network.name}"
  end


  # Test retrieval by id
  test "network_get: by id success" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    network = create_a_network(net_service, net_name)

    # Get by id
    id=network.id
    network = get_a_network(net_service, id)
    assert_equal id, network.id, "Expected to get network with id #{id}, got network with id #{network.id}"
  end
  

  # Test retrieval of non-existant object
  test "network_get: non-existant network" do
    net_service = NetworkService.new(Rails.logger)

    # Get by name
    http_error, network = net_service.network_get("zippityDoDa")
    assert_not_nil network, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "Expected to get HTTP error code 404, got HTTP error code: #{http_error}, #{network}"
  end


  # Test adding an ip range
  test "network_update: add ip range" do
    net_name="public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }, "admin": { "start": "192.168.122.128", "end": "192.168.122.149" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_range = IpRange.where( :name => "admin", :network_id => network.id )
    assert_not_nil ip_range, "Expecting ip_range, got nil"
  end


  # Test removing an ip range
  test "network_update: remove ip range" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_ranges = IpRange.where( :name => "dhcp", :network_id => network.id )
    assert_equal 0, ip_ranges.size, "Expected to get 0 ip_ranges, got #{ip_ranges}"
  end


  # Test removing all IP ranges from a network
  test "network_update: remove all ip ranges" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        '',
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no start
  test "network_update: ip range with no start" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no end
  test "network_update: ip range with no end" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_pref
  test "network_update: missing router_pref" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_ip
  test "network_update: missing router_ip" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    http_error, network = net_service.network_update(
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test deletion of non-existant network
  test "network_delete: non-existant network" do
    delete_nonexistant_network( NetworkService.new(Rails.logger), "zippityDoDa")
  end


  # Test deletion
  test "network_delete: success" do
    net_name = "public"
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, net_name)

    # Delete by name
    http_error, msg = net_service.network_delete(net_name)
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{msg}"

    # Verify deletion
    delete_nonexistant_network(net_service, net_name)
  end


  # Test population of network defaults
  test "network_defaults_populate" do
    template_file = "barclamps/templates/bc-template-network-new.json"
    json = JSON::load File.open(template_file, 'r')

    proposal = NetworkTestHelper.create_or_get_proposal()
    network_service = NetworkService.new(Rails.logger)
    network_service.populate_network_defaults( json["attributes"]["network"], proposal )

    assert Conduit.count > 0, "There are no Conduits"
    assert InterfaceMap.count == 1, "There is no InterfaceMap"
    assert Network.count > 0, "There are no Networks"
  end


  # Failure to find proposal due to bad proposal id
  test "find_proposal_and_network: failure to find proposal due to bad proposal id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, *rest = net_service.find_proposal_and_network(99, nil)
    assert_equal 404, http_error
  end


  # Failure to find network due to bad network id when proposal unspecified
  test "find_proposal_and_network: failure to find network due to bad network id when proposal unspecified" do
    net_service = NetworkService.new(Rails.logger)
    http_error, *rest = net_service.find_proposal_and_network(nil, "fred")
    assert_equal 404, http_error
  end


  # Successfully find network when no proposal id
  test "find_proposal_and_network: success when no proposal id" do
    net_service = NetworkService.new(Rails.logger)
    create_a_network(net_service, "public")
    http_error, proposal, network = net_service.find_proposal_and_network(nil, "public")
    assert_equal 200, http_error
    assert_not_nil network
    assert_equal network.proposal.id, proposal.id unless proposal.nil?
    assert_equal network.proposal, proposal if proposal.nil?
  end


  # Successfully find network by name when valid proposal id
  test "find_proposal_and_network: successfully find network by name when valid proposal id" do
    net_service = NetworkService.new(Rails.logger)
    new_network = create_a_network(net_service, "public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = net_service.find_proposal_and_network(new_proposal.id, "public")
    assert_equal 200, http_error
    assert_equal new_proposal.id, proposal.id
    assert_equal new_network.id, network.id
  end
  

  # Fail to find network by name when valid proposal id
  test "find_proposal_and_network: fail to find network by name when valid proposal id" do
    net_service = NetworkService.new(Rails.logger)
    new_network = create_a_network(net_service, "public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = net_service.find_proposal_and_network(new_proposal.id, "barney")
    assert_equal 404, http_error
  end


  # Successfully find network by id when valid proposal id
  test "find_proposal_and_network: successfully find network by id when valid proposal id" do
    net_service = NetworkService.new(Rails.logger)
    new_network = create_a_network(net_service, "public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = net_service.find_proposal_and_network(new_proposal.id, new_network.id)
    assert_equal 200, http_error
    assert_equal new_proposal.id, proposal.id
    assert_equal new_network.id, network.id
  end


  # Consistency check of network id failure
  test "find_proposal_and_network: consistency check of network id failure" do
    net_service = NetworkService.new(Rails.logger)
    new_network = create_a_network(net_service, "public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    new_network2 = create_a_network(net_service, "public")
    new_network2.save!
    http_error, proposal, network = net_service.find_proposal_and_network(new_proposal.id, new_network2.id)
    assert_equal 400, http_error
  end


  # Allocate IP failure due to missing network_id
  test "network_allocate_ip: failure due to missing network_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_allocate_ip("proposal1",nil,"host","fred")
    assert_equal 400, http_error
  end


  # Allocate IP failure due to missing node_id
  test "network_allocate_ip: failure due to missing node_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_allocate_ip("proposal1","network1","host",nil)
    assert_equal 400, http_error
  end


  # Allocate IP failure due to missing range
  test "network_allocate_ip: failure due to missing range" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_allocate_ip("proposal1","network1",nil,"fred")
    assert_equal 400, http_error
  end


  # Allocate IP failure due to bad node_id
  test "network_allocate_ip: failure due to bad node_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_allocate_ip("proposal1","network1","host","fred")
    assert_equal 404, http_error
  end


  # Allocate IP failure due to unable to lookup proposal or network
  test "network_allocate_ip: failure due to unable to lookup proposal or network" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_allocate_ip("betty","wilma","host","fred.flintstone.org")
    assert_not_equal 200, http_error
  end


  # Allocate IP success due to node already having allocated IP
  test "network_allocate_ip: success due to node already has allocated IP" do
    net_service = NetworkService.new(Rails.logger)

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    ip = IpAddress.new(:cidr => "192.168.122.4")
    intf.ip_addresses << ip
    intf.save!

    network = create_a_network(net_service, "public")
    network.allocated_ips << ip
    network.save!

    http_error, message = net_service.network_allocate_ip(nil,network.id,"host","fred.flintstone.org")
    assert_equal 200, http_error
  end


  # Allocate IP success due to suggested IP being available
  test "network_allocate_ip: success due to suggested IP being available" do
    net_service = NetworkService.new(Rails.logger)

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = create_a_network(net_service, "public")
    network.save!

    http_error, message = net_service.network_allocate_ip(nil,network.id,"host","fred.flintstone.org","192.168.122.30")
    assert_equal 200, http_error
  end
  

  # Allocate IP success - perfect path
  test "network_allocate_ip: success" do
    net_service = NetworkService.new(Rails.logger)

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = create_a_network(net_service, "public")
    network.save!

    http_error, message = net_service.network_allocate_ip(nil,network.id,"host","fred.flintstone.org")
    assert_equal 200, http_error
  end


  # Allocate IP failure due to out of addresses
  test "network_allocate_ip: failure due to out of addresses" do
    net_service = NetworkService.new(Rails.logger)

    network = create_a_network(net_service, "public")
    network.save!

    create_a_node_and_allocate_ip(net_service, network, "fred1.flintstone.org") # .2
    create_a_node_and_allocate_ip(net_service, network, "fred2.flintstone.org") # .3
    create_a_node_and_allocate_ip(net_service, network, "fred3.flintstone.org") # .4
    create_a_node_and_allocate_ip(net_service, network, "fred4.flintstone.org") # .5

    # All IPs in the range are allocated, so the test below should blow up
    node = Node.new(:name => "fred5.flintstone.org")
    node.save!

    http_error, message = net_service.network_allocate_ip(nil,network.id,"host",node.id)
    assert_equal 404, http_error
  end


  # Deallocate IP failure due to missing network_id
  test "network_deallocate_ip: failure due to missing network_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_deallocate_ip("proposal1",nil,"fred")
    assert_equal 400, http_error
  end


  # Deallocate IP failure due to missing node_id
  test "network_deallocate_ip: failure due to missing node_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_deallocate_ip("proposal1","network1",nil)
    assert_equal 400, http_error
  end


  # Deallocate IP failure due to bad node_id
  test "network_deallocate_ip: failure due to bad node_id" do
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_deallocate_ip("proposal1","network1","fred")
    assert_equal 404, http_error
  end


  # Deallocate IP failure due to unable to lookup proposal or network
  test "network_deallocate_ip: failure due to unable to lookup proposal or network" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    net_service = NetworkService.new(Rails.logger)
    http_error, message = net_service.network_deallocate_ip("betty","wilma","fred.flintstone.org")
    assert_not_equal 200, http_error
  end
  

  # Deallocate IP success due to no IP allocated to node
  test "network_deallocate_ip: success due to no IP allocated" do
    net_service = NetworkService.new(Rails.logger)

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.save!
    
    network = create_a_network(net_service, "public")
    network.save!
    
    http_error, message = net_service.network_deallocate_ip(nil,network.id,"fred.flintstone.org")
    assert_equal 200, http_error
  end


  # Deallocate IP success - perfect path
  test "network_deallocate_ip: success" do
    net_service = NetworkService.new(Rails.logger)

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    ip = IpAddress.new(:cidr => "192.168.122.2")
    intf.ip_addresses << ip
    intf.save!

    network = create_a_network(net_service, "public")
    network.allocated_ips << ip
    network.save!

    http_error, message = net_service.network_deallocate_ip(nil,network.id,"fred.flintstone.org")
    assert_equal 200, http_error
  end


  private
  # Create a Network
  def create_a_network(net_service, name)
    # HACK!  We should remove this line when conduits are prepopulated in the system
    conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    conduit.save!

    proposal = NetworkTestHelper.create_or_get_proposal()

    http_error, network = net_service.network_create(
        name,
        proposal.id,
        "intf0",
        "192.168.122.0/24",
        false,
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.5" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        "192.168.122.1" )
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end


  # Retrieve a Network
  def get_a_network(net_service, id)
    http_error, network = net_service.network_get(id)
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end


  # Try to delete a Network that does not exist
  def delete_nonexistant_network( net_service, id )
    http_error, msg = net_service.network_delete(id)
    assert_not_nil msg, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "HTTP error code returned: #{http_error}, #{msg}"
  end


  def create_a_node_and_allocate_ip(net_service, network, node_name)
    node = Node.new(:name => node_name).save!
    http_error, message = net_service.network_allocate_ip(nil,network.id,"host",node_name)
    assert_equal 200, http_error
  end
end
