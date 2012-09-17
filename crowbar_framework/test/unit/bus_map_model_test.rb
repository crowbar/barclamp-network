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
 
class BusMapModelTest < ActiveSupport::TestCase
  # Test successful creation
  test "BusMap creation: success" do
    create_a_bus_map()
  end


  # Test creation failure due to missing pattern
  test "BusMap creation: failure due to missing pattern" do
    assert_raise ActiveRecord::RecordInvalid do
      bus_map = BusMap.new()
      bus_map.buses << create_a_bus()
      bus_map.save!
    end
  end


  # Test creation failure due to missing bus
  test "BusMap creation: failure due to missing bus" do
    assert_raise ActiveRecord::RecordInvalid do
      bus_map = BusMap.new( :pattern => "PowerEdge C2100")
      bus_map.save!
    end
  end


  # Test deletion cascade to Buses
  test "BusMap deletion: cascade" do
    bus_map = create_a_bus_map()
    bus_id = bus_map.buses[0]
    bus_map.destroy

    assert_raise ActiveRecord::RecordNotFound do
      Bus.find(bus_id)
    end
  end


  private
  def create_a_bus_map
    bus_map = BusMap.new( :pattern => "PowerEdge C2100")
    bus_map.buses << create_a_bus()
    bus_map.save!

    assert_not_nil bus_map
    bus_map
  end


  def create_a_bus
    Bus.new( :order => 1, :designator => "0000:00/0000:00:1c" )
  end
end
