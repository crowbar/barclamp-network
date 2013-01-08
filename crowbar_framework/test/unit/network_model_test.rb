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
    assert_raise ActiveRecord::RecordInvalid do
      network = Network.new
      network.dhcp_enabled = true
      network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
      network.conduit = Conduit.create!( :name => "intf0" )
      network.ip_ranges << NetworkTestHelper.create_an_ip_range()
      network.save!
    end
  end


  # dhcp_enabled does not exist
  test "Network creation: failure due to missing dhcp_enabled" do
    assert_raise ActiveRecord::RecordInvalid do
      network = Network.new
      network.name = "fred"
      network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
      network.conduit = Conduit.create!( :name => "intf0" )
      network.ip_ranges << NetworkTestHelper.create_an_ip_range()
      network.save!
    end
  end


  # dhcp_enabled must be true or false
  test "Network creation: failure due to invalid dhcp_enabled" do
    assert_raise ActiveRecord::RecordInvalid do
      network = Network.new
      network.name = "fred"
      network.dhcp_enabled = "blah"
      network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
      network.conduit = Conduit.create!( :name => "intf0" )
      network.ip_ranges << NetworkTestHelper.create_an_ip_range()
      network.save!
    end
  end
  

  # subnet does not exist
  test "Network creation: failure due to missing subnet" do
    assert_raise ActiveRecord::RecordInvalid do
      network = Network.new
      network.name = "fred"
      network.dhcp_enabled = false
      network.conduit = Conduit.create!( :name => "intf0" )
      network.ip_ranges << NetworkTestHelper.create_an_ip_range()
      network.save!
    end
  end


  # no ip_ranges specified
  test "Network creation: failure due to no ip_ranges" do
    assert_raise ActiveRecord::RecordInvalid do
      network = Network.new
      network.name = "fred"
      network.dhcp_enabled = false
      network.subnet = IpAddress.create!( :cidr => "192.168.130.11/24" )
      network.conduit = Conduit.create!( :name => "intf0" )
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
end
