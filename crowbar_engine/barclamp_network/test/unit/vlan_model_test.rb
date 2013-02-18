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
 
class VlanModelTest < ActiveSupport::TestCase

  # Test successful creation
  test "Vlan creation: success" do
    vlan = Vlan.new(:tag => 100)
    vlan.save!
  end


  # Test creation failure due to missing tag
  test "Vlan creation: failure due to missing tag" do
    vlan = Vlan.new()
    assert_raise ActiveRecord::RecordInvalid do
      vlan.save!
    end
  end


  # Test cascade VlanInterface deletion on vlan deletion
  test "Vlan deletion: cascade delete to VlanInterfaces" do
    vlan = Vlan.new(:tag => 100)
    vlan.vlan_interfaces << VlanInterface.new(:name => "vlanIf1")
    vlan.save!

    vlan_if_id = vlan.vlan_interfaces.first.id
    vlan.destroy()

    vlan_ifs = VlanInterface.where( :id => vlan_if_id )
    assert_equal 0, vlan_ifs.size
  end
end
