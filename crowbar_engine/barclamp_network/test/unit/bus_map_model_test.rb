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
 
class BusMapModelTest < ActiveSupport::TestCase
  # Test successful creation
  test "BusMap creation: success" do
    bus_map = NetworkTestHelper.create_a_bus_map()
    bus_map.save!
  end


  # Test creation failure due to missing pattern
  test "BusMap creation: failure due to missing pattern" do
    bus_map = BarclampNetwork::BusMap.new()
    bus_map.buses << NetworkTestHelper.create_a_bus()
    assert_raise ActiveRecord::RecordInvalid do
      bus_map.save!
    end
  end


  # Test creation failure due to missing bus
  test "BusMap creation: failure due to missing bus" do
    bus_map = BarclampNetwork::BusMap.new( :pattern => "PowerEdge C2100")
    assert_raise ActiveRecord::RecordInvalid do
      bus_map.save!
    end
  end


  # Test deletion cascade to Buses
  test "BusMap deletion: cascade" do
    bus_map = NetworkTestHelper.create_a_bus_map()
    bus_map.save!
    bus_id = bus_map.buses[0]
    bus_map.destroy

    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::Bus.find(bus_id)
    end
  end


  test "BusMap get_configured_bus_map" do
    bus_map = NetworkTestHelper.create_a_bus_map()
    bus_map.save!

    configured_bus_map = bus_map.get_configured_bus_map()
    assert_equal NetworkTestHelper::DEFAULT_PATTERN, configured_bus_map["pattern"]

    configured_bus_order = configured_bus_map["bus_order"]
    assert !configured_bus_order.nil?
    assert_equal 2, configured_bus_order.size

    assert_equal NetworkTestHelper::DEFAULT_PATH0, configured_bus_order["0"]
    assert_equal NetworkTestHelper::DEFAULT_PATH1, configured_bus_order["1"]
  end
end
