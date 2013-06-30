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
 
class InterfaceMapModelTest < ActiveSupport::TestCase
  # Test successful creation
  test "InterfaceMap creation: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!
  end


  # Test creation failure due to missing BusMap
  test "IntefaceMap creation: failure due to missing BusMap" do
    assert_raise ActiveRecord::RecordInvalid do
      BarclampNetwork::InterfaceMap.create!()
    end
  end


  # Test deletion cascade to BusMaps
  test "IntefaceMap deletion: cascade" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!
    bus_map_id = interface_map.bus_maps[0]
    interface_map.destroy

    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::BusMap.find(bus_map_id)
    end
  end


  # Test retrieval of a bus order
  test "InterfaceMap: retrieval of bus order success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    node.set_attrib("product_name", "PowerEdge R710")

    buses = BarclampNetwork::InterfaceMap.get_bus_order(node)
    assert_not_nil buses

    assert_equal "0000:00/0000:00:01", buses[0].path
    assert_equal "0000:00/0000:00:03", buses[1].path
  end


  # Test failure to retrieve bus order
  test "InterfaceMap: retrieval of bus order failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    node.set_attrib("product_name", "Magical Mystery Box")

    buses = BarclampNetwork::InterfaceMap.get_bus_order(node)
    assert_nil buses
  end


  test "InterfaceMap: get_configured_interface_map success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!

    configured_interface_map = interface_map.get_configured_interface_map()

    assert !configured_interface_map.nil?
    assert_equal 2, configured_interface_map.size

    bus_map0 = configured_interface_map["0"]
    bus_map1 = configured_interface_map["1"]

    if bus_map0["pattern"] == "PowerEdge C6145"
      pe_6145_bus_map = bus_map0
      pe_710_bus_map = bus_map1
    else
      pe_6145_bus_map = bus_map1
      pe_710_bus_map = bus_map0
    end

    assert_equal "PowerEdge C6145", pe_6145_bus_map["pattern"]
    assert_equal "0000:00/0000:00:04", pe_6145_bus_map["bus_order"]["0"]
    assert_equal "0000:00/0000:00:02", pe_6145_bus_map["bus_order"]["1"]

    assert "PowerEdge R710", pe_710_bus_map["pattern"]
    assert_equal "0000:00/0000:00:01", pe_710_bus_map["bus_order"]["0"]
    assert_equal "0000:00/0000:00:03", pe_710_bus_map["bus_order"]["1"]
  end


  test "InterfaceMap: get_interface_map failure due to bad deployment_id" do
    assert_raise RuntimeError do
      BarclampNetwork::InterfaceMap.get_interface_map("fred")
    end
  end


  test "InterfaceMap: get_interface_map success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    interface_map = NetworkTestHelper.create_an_interface_map(deployment)
    interface_map.save!

    interface_map = BarclampNetwork::InterfaceMap.get_interface_map(deployment.name)
    assert !interface_map.nil?
  end
end
