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
 
class InterfaceSelectorTest < ActiveSupport::TestCase

  # Test successful creation
  test "InterfaceSelector creation: success" do
    is = InterfaceSelector.new()
    is.selectors << SelectByIndex.create!(:value => 1)
    is.save!
  end


  # Test failed creation due to missing selectors
  test "InterfaceSelector creation: failure due to missing selectors" do
    assert_raise ActiveRecord::RecordInvalid do
      InterfaceSelector.create!()
    end
  end
  

  # Test delete cascade
  test "InterfaceSelector deletion: cascade to Selector" do
    sbi = SelectByIndex.create!(:value => "1")
    sbs = SelectBySpeed.create!(:value => "1g")

    is = InterfaceSelector.new()
    is.selectors << sbi
    is.selectors << sbs
    is.save!

    is.destroy

    # Verify SelectBy's destroyed on InterfaceSelect destroy
    assert_raise ActiveRecord::RecordNotFound do
      SelectByIndex.find(sbi.id)
    end
    assert_raise ActiveRecord::RecordNotFound do
      SelectBySpeed.find(sbs.id)
    end
  end


  # Test selecting no interfaces
  test "InterfaceSelector: no interfaces selected" do
    node = Node.create!(:name => "fred.flintstone.org")

    is = InterfaceSelector.new()
    is.selectors << SelectByIndex.create!(:value => 271)
    is.save!

    if_remap = {"1g1" => "eth0", "10g1" => "eth1", "1g2" => "eth2"}

    intf = is.select_interface(if_remap, node)
    assert_equal nil, intf
  end


  # Test selecting one interface
  test "InterfaceSelector: one interface selected" do
    node = Node.create!(:name => "fred.flintstone.org")

    is = InterfaceSelector.new()
    is.selectors << SelectByIndex.create!(:value => 2)
    is.selectors << SelectBySpeed.create!(:value => "10g")
    is.save!

    if_remap = {"1g1" => "eth0", "10g1" => "eth1",
                "1g2" => "eth2", "10g2" => "eth3"}

    intf = is.select_interface(if_remap, node)
    assert_equal "eth3", intf
  end
  

  # Test selecting multiple interfaces
  test "InterfaceSelector: multiple interfaces selected" do
    node = Node.create!(:name => "fred.flintstone.org")

    is = InterfaceSelector.new()
    is.selectors << SelectBySpeed.create!(:value => "10g")
    is.save!

    if_remap = {"1g1" => "eth0", "10g1" => "eth1",
                "1g2" => "eth2", "10g2" => "eth3"}

    intf = is.select_interface(if_remap, node)
    assert intf == "eth1" || intf == "eth3"
  end
end
