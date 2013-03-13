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

require 'test_helper'
require 'network_test_helper'
 
class NetworkModelTest < ActiveSupport::TestCase

  # Successful create
  test "Network creation: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!
  end


  # Successful delete
  test "Network deletion: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    subnet_id = network.subnet.id
    conduit_id = network.conduit.id
    router_id = network.router.id
    ip_range_ids = network.ip_ranges.collect { |ip_range| ip_range.id }
    allocated_ip_ids = network.allocated_ips.collect { |allocated_ip| allocated_ip.id }

    network.destroy

    # Verify subnet destroyed on network destroy
    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::IpAddress.find( subnet_id )
    end
 
    # Verify conduit NOT destroyed on network destroy
    conduit = BarclampNetwork::Conduit.find( conduit_id )
    assert_not_nil conduit

    # Verify router destroyed on network destroy
    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::Router.find( router_id )
    end

    # Verify ip_ranges destroyed on network destroy
    ip_range_ids.each { |ip_range_id|
      assert_raise ActiveRecord::RecordNotFound do
        BarclampNetwork::IpRange.find( ip_range_id )
      end
    }

    # Verify allocated_ips destroyed on network destroy
    allocated_ip_ids.each { |allocated_ip_id|
      assert_raise ActiveRecord::RecordNotFound do
        BarclampNetwork::IpAddress.find( allocated_ip_id )
      end
    }
  end


  # name does not exist
  test "Network creation: failure due to missing name" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = BarclampNetwork::Network.new()
    network.dhcp_enabled = true
    network.subnet = BarclampNetwork::IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # dhcp_enabled does not exist
  test "Network creation: failure due to missing dhcp_enabled" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = BarclampNetwork::Network.new
    network.name = "fred"
    network.subnet = BarclampNetwork::IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # subnet does not exist
  test "Network creation: failure due to missing subnet" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = BarclampNetwork::Network.new
    network.name = "fred"
    network.dhcp_enabled = false
    network.conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # no ip_ranges specified
  test "Network creation: failure due to no ip_ranges" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = BarclampNetwork::Network.new
    network.name = "fred"
    network.dhcp_enabled = false
    network.subnet = BarclampNetwork::IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # Test cascade Vlan deletion on Network deletion
  test "Network deletion: cascade delete to Vlans" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.vlan = BarclampNetwork::Vlan.new(:tag => 100)
    network.save!

    vlan_id = network.vlan.id
    network.destroy()

    vlans = BarclampNetwork::Vlan.where( :id => vlan_id )
    assert_equal 0, vlans.size
  end


  # Test ip alloc failure due to no range
  test "Network allocate ip: failure due to no range" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    
    error_code, result = network.allocate_ip(nil, node)
    assert_equal 400, error_code
  end


  # Test ip alloc failure due to no node
  test "Network allocate ip: failure due to no node" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    http_error, result = network.allocate_ip("host", nil)
    assert_equal 400, http_error
  end


  # Test ip alloc success due to node already has an ip
  test "Network allocate_ip: success due to node already has allocated IP" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    ip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.122.4")
    ip.network = network
    ip.save!

    intf = BarclampNetwork::PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.allocated_ip_addresses << ip
    intf.save!

    http_error, message = network.allocate_ip("host",node)
    assert_equal 200, http_error
  end


  # Test ip alloc success due to suggested ip ok
  test "Network allocate_ip: success due to suggested IP being available" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    ip_address = "192.168.122.3"
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    http_error, message = network.allocate_ip("host",node,ip_address)
    assert_equal 200, http_error

    na = node.get_attrib("ip_address")
    assert_equal ip_address, na.value(NetworkTestHelper::DEFAULT_NETWORK_NAME, deployment.id, BarclampNetwork::NetworkUtils::PROPOSED_SNAPSHOT)
  end


  # Test ip alloc success
  test "Network allocate_ip: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    http_error, message = network.allocate_ip("host",node)
    assert_equal 200, http_error

    ip_address = message["address"]

    na = node.get_attrib("ip_address")
    assert_equal ip_address, na.value(NetworkTestHelper::DEFAULT_NETWORK_NAME, deployment.id, BarclampNetwork::NetworkUtils::PROPOSED_SNAPSHOT)
  end


  # Test ip alloc success when suggested ip already allocated
  test "Network allocate_ip: success due to suggested IP unavailable" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    node1 = Node.new(:name => "fred1.flintstone.org")
    node1.save!

    # First allocate a selected ip
    http_error, message = network.allocate_ip("host",node1,"192.168.122.3")
    assert_equal 200, http_error

    node2 = Node.new(:name => "fred2.flintstone.org")
    node2.save!

    # Try to allocate it again
    http_error, message = network.allocate_ip("host",node2,"192.168.122.3")
    assert_equal 200, http_error
  end


  # Test ip alloc failure due to out of addresses
  test "Network allocate_ip: failure due to out of addresses" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    create_a_node_and_allocate_ip(network, "fred3.flintstone.org") # .2
    create_a_node_and_allocate_ip(network, "fred4.flintstone.org") # .3
    create_a_node_and_allocate_ip(network, "fred5.flintstone.org") # .4
    create_a_node_and_allocate_ip(network, "fred6.flintstone.org") # .5

    # All IPs in the range are allocated, so the test below should blow up
    node = Node.new(:name => "fred7.flintstone.org")
    node.save!

    http_error, message = network.allocate_ip("host",node)
    assert_equal 404, http_error
  end


  # Deallocate IP failure due to missing node
  test "Network deallocate_ip: failure due to missing node" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    http_error, message = network.deallocate_ip(nil)
    assert_equal 400, http_error
  end
  

  # Deallocate IP success due to no IP allocated to node
  test "Network deallocate_ip: success due to no IP allocated" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    intf = BarclampNetwork::PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.save!
    
    network = NetworkTestHelper.create_a_network(deployment)
    network.save!
    
    http_error, message = network.deallocate_ip(node)
    assert_equal 200, http_error
  end


  # Deallocate IP success - perfect path
  test "Network deallocate_ip: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    ip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.122.2")
    ip.network = network
    ip.save!

    intf = BarclampNetwork::PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.allocated_ip_addresses << ip
    intf.save!

    http_error, message = network.deallocate_ip(node)
    assert_equal 200, http_error
  end


  # Enable interface success due to no existing interface
  test "Network enable_ip: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!
  
    http_error, net_info = network.enable_interface(node)
    assert_equal 200, http_error
  end


  # Enable interface success due to existing interface
  test "Network enable_ip: success due to existing interface" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    barclamp.save!
    deployment = barclamp.create_or_get_deployment()
    deployment.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!
  
    http_error, net_info = network.enable_interface(node)
    assert_equal 200, http_error

    http_error, net_info = network.enable_interface(node)
    assert_equal 200, http_error
  end


  private
  def create_a_node_and_allocate_ip(network, node_name)
    node = Node.create!(:name => node_name)
    http_error, message = network.allocate_ip("host",node)
    assert_equal 200, http_error
  end
end
