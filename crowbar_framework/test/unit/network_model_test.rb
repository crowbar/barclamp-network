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
    network = NetworkTestHelper.create_a_network()
    network.save!
  end


  # Successful delete
  test "Network deletion: success" do
    network = NetworkTestHelper.create_a_network()
    network.save!

    subnet_id = network.subnet.id
    conduit_id = network.conduit.id
    router_id = network.router.id
    ip_range_ids = network.ip_ranges.collect { |ip_range| ip_range.id }
    allocated_ip_ids = network.allocated_ips.collect { |allocated_ip| allocated_ip.id }

    network.destroy

    # Verify subnet destroyed on network destroy
    assert_raise ActiveRecord::RecordNotFound do
      IpAddress.find( subnet_id )
    end
 
    # Verify conduit NOT destroyed on network destroy
    conduit = Conduit.find( conduit_id )
    assert_not_nil conduit

    # Verify router destroyed on network destroy
    assert_raise ActiveRecord::RecordNotFound do
      Router.find( router_id )
    end

    # Verify ip_ranges destroyed on network destroy
    ip_range_ids.each { |ip_range_id|
      assert_raise ActiveRecord::RecordNotFound do
        IpRange.find( ip_range_id )
      end
    }

    # Verify allocated_ips destroyed on network destroy
    allocated_ip_ids.each { |allocated_ip_id|
      assert_raise ActiveRecord::RecordNotFound do
        IpAddress.find( allocated_ip_id )
      end
    }
  end


  # name does not exist
  test "Network creation: failure due to missing name" do
    network = Network.new
    network.dhcp_enabled = true
    network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # dhcp_enabled does not exist
  test "Network creation: failure due to missing dhcp_enabled" do
    network = Network.new
    network.name = "fred"
    network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # dhcp_enabled must be true or false
  test "Network creation: failure due to invalid dhcp_enabled" do
    network = Network.new
    network.name = "fred"
    network.dhcp_enabled = "blah"
    network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end
  

  # subnet does not exist
  test "Network creation: failure due to missing subnet" do
    network = Network.new
    network.name = "fred"
    network.dhcp_enabled = false
    network.conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    network.ip_ranges << NetworkTestHelper.create_an_ip_range()
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # no ip_ranges specified
  test "Network creation: failure due to no ip_ranges" do
    network = Network.new
    network.name = "fred"
    network.dhcp_enabled = false
    network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
    network.conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    assert_raise ActiveRecord::RecordInvalid do
      network.save!
    end
  end


  # Test cascade Vlan deletion on Network deletion
  test "Network deletion: cascade delete to Vlans" do
    network = NetworkTestHelper.create_a_network()
    network.vlan = Vlan.new(:tag => 100)
    network.save!

    vlan_id = network.vlan.id
    network.destroy()

    vlans = Vlan.where( :id => vlan_id )
    assert_equal 0, vlans.size
  end


  # Test ip alloc failure due to no range
  test "Network allocate ip: failure due to no range" do
    network = NetworkTestHelper.create_a_network()
    network.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!
    
    error_code, result = network.allocate_ip(nil, node)
    assert_equal 400, error_code
  end


  # Test ip alloc failure due to no node
  test "Network allocate ip: failure due to no node" do
    network = NetworkTestHelper.create_a_network()
    network.save!

    http_error, result = network.allocate_ip("host", nil)
    assert_equal 400, http_error
  end


  # Test ip alloc success due to node already has an ip
  test "Network allocate_ip: success due to node already has allocated IP" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
    network.save!

    ip = AllocatedIpAddress.new(:ip => "192.168.122.4")
    ip.network = network
    ip.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.allocated_ip_addresses << ip
    intf.save!

    http_error, message = network.allocate_ip("host",node)
    assert_equal 200, http_error
  end


  # Test ip alloc success due to suggested ip ok
  test "Network allocate_ip: success due to suggested IP being available" do
    ip_address = "192.168.122.3"
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
    network.save!

    http_error, message = network.allocate_ip("host",node,ip_address)
    assert_equal 200, http_error

    na = node.attrib_get("ip_address")
    assert_equal na.value, ip_address
  end


  # Test ip alloc success
  test "Network allocate_ip: success" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
    network.save!

    http_error, message = network.allocate_ip("host",node)
    assert_equal 200, http_error

    ip_address = message["address"]

    na = node.attrib_get("ip_address")
    assert_equal ip_address, na.value
  end


  # Test ip alloc success when suggested ip already allocated
  test "Network allocate_ip: success due to suggested IP unavailable" do
    network = NetworkTestHelper.create_a_network()
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
    network = NetworkTestHelper.create_a_network()
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
    network = NetworkTestHelper.create_a_network()
    network.save!

    http_error, message = network.deallocate_ip(nil)
    assert_equal 400, http_error
  end
  

  # Deallocate IP success due to no IP allocated to node
  test "Network deallocate_ip: success due to no IP allocated" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.save!
    
    network = NetworkTestHelper.create_a_network()
    network.save!
    
    http_error, message = network.deallocate_ip(node)
    assert_equal 200, http_error
  end


  # Deallocate IP success - perfect path
  test "Network deallocate_ip: success" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
    network.save!

    ip = AllocatedIpAddress.new(:ip => "192.168.122.2")
    ip.network = network
    ip.save!

    intf = PhysicalInterface.new(:name => "eth0")
    intf.node = node
    intf.allocated_ip_addresses << ip
    intf.save!

    http_error, message = network.deallocate_ip(node)
    assert_equal 200, http_error
  end


  # Enable interface success due to no existing interface
  test "Network enable_ip: success" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
    network.save!
  
    http_error, net_info = network.enable_interface(node)
    assert_equal 200, http_error
  end


  # Enable interface success due to existing interface
  test "Network enable_ip: success due to existing interface" do
    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    network = NetworkTestHelper.create_a_network()
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
