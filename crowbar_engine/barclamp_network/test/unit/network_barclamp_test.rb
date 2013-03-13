# Copyright 2013, Dell 
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
require 'barclamp'
 
class NetworkBarclampTest < ActiveSupport::TestCase

  # Test creation
  test "network_create: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    create_a_network(barclamp, deployment, "public")
  end


  # Test failed network creation due to missing router_pref
  test "network_create: missing router_pref" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, network = barclamp.network_create(
        deployment.id,
        "public2",
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network creation due to missing router_ip
  test "network_create: missing router_ip" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, network = barclamp.network_create(
        deployment.id,
        "public3",
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test failed network creation due to missing ip range
  test "network_create: missing no ip range" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, network = barclamp.network_create(
        deployment.id,
        "public4",
        "intf0",
        "192.168.122.0/24",
        false,
        nil,
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test retrieval by name
  test "network_get: by name success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name="public"
    create_a_network(barclamp, deployment, net_name)

    # Get by name
    network = get_a_network(barclamp, deployment.id, net_name)
    assert_equal net_name, network.name, "Expected to get network with name #{net_name}, got network with name #{network.name}"
  end


  # Test retrieval by id
  test "network_get: by id success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name="public"
    network = create_a_network(barclamp, deployment, net_name)

    # Get by id
    id=network.id
    network = get_a_network(barclamp, deployment.id, id)
    assert_equal id, network.id, "Expected to get network with id #{id}, got network with id #{network.id}"
  end
  

  # Test retrieval of non-existant object
  test "network_get: non-existant network" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    # Get by name
    http_error, network = barclamp.network_get(deployment.id, "zippityDoDa")
    assert_not_nil network, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "Expected to get HTTP error code 404, got HTTP error code: #{http_error}, #{network}"
  end


  # Test adding an ip range
  test "network_update: add ip range" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name="public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }, "admin": { "start": "192.168.122.128", "end": "192.168.122.149" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_range = BarclampNetwork::IpRange.where( :name => "admin", :network_id => network.id )
    assert_not_nil ip_range, "Expecting ip_range, got nil"
  end


  # Test removing an ip range
  test "network_update: remove ip range" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }}'),
        5,
        "192.168.122.1" )
    assert_equal 200, http_error, "Expected to get HTTP error code 200, got HTTP error code: #{http_error}, #{network}"

    ip_ranges = BarclampNetwork::IpRange.where( :name => "dhcp", :network_id => network.id )
    assert_equal 0, ip_ranges.size, "Expected to get 0 ip_ranges, got #{ip_ranges}"
  end


  # Test removing all IP ranges from a network
  test "network_update: remove all ip ranges" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        '',
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no start
  test "network_update: ip range with no start" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test updating to an IP range that has no end
  test "network_update: ip range with no end" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        5,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_pref
  test "network_update: missing router_pref" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        nil,
        "192.168.122.1" )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end


  # Test failed network update due to missing router_ip
  test "network_update: missing router_ip" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    http_error, network = barclamp.network_update(
        deployment.id,
        net_name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.49" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        nil )
    assert_equal 400, http_error, "Expected to get HTTP error code 400, got HTTP error code: #{http_error}, #{network}"
    assert_not_nil network, "Expected to get error message, but got nil"
  end
  

  # Test deletion of non-existant network
  test "network_delete: non-existant network" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    delete_nonexistant_network( barclamp, deployment.id, "zippityDoDa")
  end


  # Test deletion
  test "network_delete: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    net_name = "public"
    create_a_network(barclamp, deployment, net_name)

    # Delete by name
    http_error, msg = barclamp.network_destroy(deployment.id, net_name)
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{msg}"

    # Verify deletion
    delete_nonexistant_network(barclamp, deployment.id, net_name)
  end


  # Test population of network defaults
  test "network_defaults_populate" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    assert BarclampNetwork::Conduit.all.count > 0, "There are no Conduits"
    assert BarclampNetwork::InterfaceMap.all.count == 1, "There are #{BarclampNetwork::InterfaceMap.all.count} InterfaceMaps"
    assert BarclampNetwork::Network.all.count > 0, "There are no Networks"
  end


  # Allocate IP failure due to missing network_id
  test "network_allocate_ip: failure due to missing network_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_allocate_ip("default",nil,"host","fred")
    assert_equal 400, http_error
  end


  # Allocate IP failure due to missing node_id
  test "network_allocate_ip: failure due to missing node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_allocate_ip("default","network1","host",nil)
    assert_equal 400, http_error
  end


  # Allocate IP failure due to bad node_id
  test "network_allocate_ip: failure due to bad node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_allocate_ip("default","network1","host","fred")
    assert_equal 404, http_error
  end


  # Allocate IP failure due to unable to lookup Deployment or Network
  test "network_allocate_ip: failure due to unable to lookup Deployment or Network" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_allocate_ip("betty","wilma","host","fred.flintstone.org")
    assert_not_equal 200, http_error
  end


  # Allocate IP success - perfect path
  test "network_allocate_ip: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = create_a_network(barclamp, deployment, "public")
    network.save!

    http_error, message = barclamp.network_allocate_ip(deployment.id, network.id, "host", "fred.flintstone.org")
    assert_equal 200, http_error
  end


  # Deallocate IP failure due to missing network_id
  test "network_deallocate_ip: failure due to missing network_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_deallocate_ip("default",nil,"fred")
    assert_equal 400, http_error
  end


  # Deallocate IP failure due to missing node_id
  test "network_deallocate_ip: failure due to missing node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_deallocate_ip("default","network1",nil)
    assert_equal 400, http_error
  end


  # Deallocate IP failure due to bad node_id
  test "network_deallocate_ip: failure due to bad node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_deallocate_ip("default","network1","fred")
    assert_equal 404, http_error
  end


  # Deallocate IP failure due to unable to lookup Deployment or Network
  test "network_deallocate_ip: failure due to unable to lookup Deployment or Network" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_deallocate_ip("betty","wilma","fred.flintstone.org")
    assert_not_equal 200, http_error
  end
  

  # Deallocate IP success - perfect path
  test "network_deallocate_ip: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = create_a_network(barclamp, deployment, "public")
    network.save!

    intf = BarclampNetwork::PhysicalInterface.new(:name => "eth0")
    intf.node = node
    ip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.122.2")
    ip.network = network
    intf.allocated_ip_addresses << ip
    intf.save!

    http_error, message = barclamp.network_deallocate_ip(deployment.id,network.id,"fred.flintstone.org")
    assert_equal 200, http_error
  end


  # Enable interface failure due to missing network_id
  test "network_enable_interface: failure due to missing network_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, message = barclamp.network_enable_interface(deployment.id,nil,"fred")
    assert_equal 400, http_error
  end


  # Enable interface failure due to missing node_id
  test "network_enable_interface: failure due to missing node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, message = barclamp.network_enable_interface(deployment.id,"network1",nil)
    assert_equal 400, http_error
  end


  # Enable interface failure due to bad node_id
  test "network_enable_interface: failure due to bad node_id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    http_error, message = barclamp.network_enable_interface(deployment.id,"network1","fred")
    assert_equal 404, http_error
  end


  # Enable interface failure due to unable to lookup Deployment or Network
  test "network_enable_interface: failure due to unable to lookup Deployment or Network" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    barclamp = NetworkTestHelper.create_a_barclamp()
    http_error, message = barclamp.network_enable_interface("betty","wilma","fred.flintstone.org")
    assert_not_equal 200, http_error
  end
  

  # Enable interface success - perfect path
  test "network_enable_interface: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = create_a_network(barclamp, deployment, "public")
    network.save!
    
    http_error, message = barclamp.network_enable_interface(deployment.id,network.id,"fred.flintstone.org")
    assert_equal 200, http_error
  end
  

  # Create a Network
  def create_a_network(barclamp, deployment, name)
    conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    conduit.save!

    http_error, network = barclamp.network_create(
        deployment.id,
        name,
        "intf0",
        "192.168.122.0/24",
        false,
        JSON.parse('{ "host": { "start": "192.168.122.2", "end": "192.168.122.5" }, "dhcp": { "start": "192.168.122.50", "end": "192.168.122.127" }}'),
        "5",
        "192.168.122.1" )
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end
  

  private
  # Retrieve a Network
  def get_a_network(barclamp, deployment_id, network_id)
    http_error, network = barclamp.network_get(deployment_id, network_id)
    assert_not_nil network
    assert_equal 200, http_error, "HTTP error code returned: #{http_error}, #{network}"
    network
  end


  # Try to delete a Network that does not exist
  def delete_nonexistant_network( barclamp, deployment_id, network_id )
    http_error, msg = barclamp.network_destroy(deployment_id, network_id)
    assert_not_nil msg, "Expected to get error message, but got nil"
    assert_equal 404, http_error, "HTTP error code returned: #{http_error}, #{msg}"
  end
end
