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
 
class ConduitRuleTest < ActiveSupport::TestCase

  # Test successful creation
  test "ConduitRule creation: success" do
    rule = NetworkTestHelper.create_a_conduit_rule()
    rule.save!
  end


  # Test creation failure due to missing interface selectors
  test "ConduitRule creation: failure due to missing interface selectors" do
    rule = ConduitRule.new()
    rule.conduit_filters << NetworkTestHelper.create_a_conduit_filter()
    rule.conduit_actions << NetworkTestHelper.create_a_conduit_action()
    assert_raise ActiveRecord::RecordInvalid do
      rule.save!
    end    
  end


  # Test delete cascade
  test "ConduitRule deletion: cascade to conduit filter, conduit action, and interface selectors" do
    rule = NetworkTestHelper.create_a_conduit_rule()
    rule.save!

    conduit_filter_id = rule.conduit_filters[0].id
    conduit_action_id = rule.conduit_actions[0].id
    interface_selector_id = rule.interface_selectors[0].id

    rule.destroy

    # Verify conduit filter destroyed on conduit rule destroy
    assert_raise ActiveRecord::RecordNotFound do
      ConduitFilter.find(conduit_filter_id)
    end

    # Verify conduit action destroyed on conduit rule destroy
    assert_raise ActiveRecord::RecordNotFound do
      ConduitAction.find(conduit_action_id)
    end

    # Verify interface selector destroyed on conduit rule destroy
    assert_raise ActiveRecord::RecordNotFound do
      InterfaceSelector.find(interface_selector_id)
    end
  end


  test "ConduitRule.bus_index: Test nil bus_order" do
    index = ConduitRule.bus_index(nil, "0000:00/0000:00:09.0/0000:02:01.0")
    assert_equal ConduitRule::MAX_INDEX, index
  end


  test "ConduitRule.bus_index: Test nil path" do
    bus_order = create_bus_order()
    index = ConduitRule.bus_index(bus_order,nil)
    assert_equal ConduitRule::MAX_INDEX, index
  end
  

  test "ConduitRule.bus_index: Test 0 index retrieval" do
    bus_order = create_bus_order()
    index = ConduitRule.bus_index(bus_order, "0000:00/0000:00:1c.0/0000:02:01.0")
    assert_equal 0, index
  end


  test "ConduitRule.bus_index: Test non-0 index retrieval" do
    bus_order = create_bus_order()
    index = ConduitRule.bus_index(bus_order, "0000:00/0000:00:09.0/0000:02:01.0")
    assert_equal 2, index
  end


  test "ConduitRule.sort_ifs: Test proper interface sorting when product_name in interface map" do
    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "PowerEdge C6145")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map()
    if_map.save!

    result = ConduitRule.sort_ifs(node)

    assert_equal "eth1", result[0]
    assert_equal "eth0", result[1]
  end


  test "ConduitRule.sort_ifs: Test proper interface sorting when product_name not in interface map" do
    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "Magical Mystery Box")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map()
    if_map.save!

    result = ConduitRule.sort_ifs(node)

    assert_equal "eth0", result[0]
    assert_equal "eth1", result[1]
  end


  test "ConduitRule.build_if_remap: Remap with known product name" do
    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "PowerEdge C6145")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map()
    if_map.save!

    if_remap = ConduitRule.build_if_remap(node)

    assert if_remap.has_key?("1g1")
    assert if_remap["1g1"] == "eth1"
    assert if_remap.has_key?("10g1")
    assert if_remap["10g1"] == "eth1"

    assert if_remap.has_key?("100m1")
    assert if_remap["100m1"] == "eth0"
    assert if_remap.has_key?("1g2")
    assert if_remap["1g2"] == "eth0"

    assert if_remap.size == 4
  end


  test "ConduitRule.build_if_remap: Remap with unknown product name" do
    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "Magical Mystery Box")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map()
    if_map.save!

    if_remap = ConduitRule.build_if_remap(node)

    assert if_remap.has_key?("1g1")
    assert if_remap["1g1"] == "eth0"
    assert if_remap.has_key?("10g1")
    assert if_remap["10g1"] == "eth1"

    assert if_remap.has_key?("100m1")
    assert if_remap["100m1"] == "eth0"
    assert if_remap.has_key?("1g2")
    assert if_remap["1g2"] == "eth1"

    assert if_remap.size == 4
  end
  

  test "ConduitRule.select_interfaces: Successful interface selection 1" do
    sbs = SelectBySpeed.create!(:value => "1g")
    sbi = SelectByIndex.create!(:value => "2")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.index("eth0")
    assert_equal 1, ifs.size
  end


  test "ConduitRule.select_interfaces: Successful interface selection 2" do
    sbs = SelectBySpeed.create!(:value => "1g")
    sbi = SelectByIndex.create!(:value => "1")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.index("eth1")
    assert_equal 1, ifs.size
  end


  test "ConduitRule.select_interfaces: Successful interface selection 3" do
    sbs = SelectBySpeed.create!(:value => "10g")
    sbi = SelectByIndex.create!(:value => "1")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.index("eth1")
    assert_equal 1, ifs.size
  end
  

  test "ConduitRule.select_interfaces: Successful interface selection 4" do
    sbs = SelectBySpeed.create!(:value => "100m")
    sbi = SelectByIndex.create!(:value => "1")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.index("eth0")
    assert_equal 1, ifs.size
  end
  

  test "ConduitRule.select_interfaces: Unsuccessful interface selection due to no index" do
    sbs = SelectBySpeed.create!(:value => "10g")
    sbi = SelectByIndex.create!(:value => "2")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.empty?
  end
  

  test "ConduitRule.select_interfaces: Unsuccessful interface selection due to no speed" do
    sbs = SelectBySpeed.create!(:value => "10m")
    sbi = SelectByIndex.create!(:value => "1")

    ifs_selector = InterfaceSelector.new()
    ifs_selector.selectors << sbs
    ifs_selector.selectors << sbi
    ifs_selector.save!

    ifs = test_select_interfaces(ifs_selector)

    assert ifs.empty?
  end


  private

  def create_bus_order
    bus_order = []
    bus_order << Bus.create!(:order=>0,:path=>"0000:00/0000:00:1c")
    bus_order << Bus.create!(:order=>1,:path=>"0000:00/0000:00:07")
    bus_order << Bus.create!(:order=>2,:path=>"0000:00/0000:00:09")
    bus_order
  end


  def test_select_interfaces(ifs_selector)
    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "PowerEdge C6145")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map()
    if_map.save!

    rule = ConduitRule.new()
    rule.interface_selectors << ifs_selector
    rule.save!

    rule.select_interfaces(node)
  end
end
