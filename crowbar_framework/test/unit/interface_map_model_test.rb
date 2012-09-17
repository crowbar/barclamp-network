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
 
class InterfaceMapModelTest < ActiveSupport::TestCase
  # Test successful creation
  test "InterfaceMap creation: success" do
    create_an_interface_map()
  end


  # Test creation failure due to missing BusMap
  test "IntefaceMap creation: failure due to missing BusMap" do
    assert_raise ActiveRecord::RecordInvalid do
      InterfaceMap.create!()
    end
  end


  # Test deletion cascade to BusMaps
  test "IntefaceMap deletion: cascade" do
    interface_map = create_an_interface_map()
    bus_map_id = interface_map.bus_maps[0]
    interface_map.destroy

    assert_raise ActiveRecord::RecordNotFound do
      BusMap.find(bus_map_id)
    end
  end


  private
  def create_an_interface_map
    interface_map = InterfaceMap.new()
    interface_map.bus_maps << create_a_bus_map()
    assert_not_nil interface_map
    interface_map
  end


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
