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
 
class ConduitTest < ActiveSupport::TestCase

  # Test successful creation
  test "Conduit creation: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    destroy_preloaded_conduits()

    conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    conduit.save!
  end


  # Test creation failure due to missing conduit rule
  test "Conduit creation: failure due to missing conduit rule" do
    conduit = BarclampNetwork::Conduit.new
    conduit.name = "intf0"
    assert_raise ActiveRecord::RecordInvalid do
      conduit.save!
    end    
  end


  # Test delete cascade
  test "Conduit deletion: cascade to conduit rules" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    destroy_preloaded_conduits()

    conduit = NetworkTestHelper.create_or_get_conduit(deployment, "intf0")
    conduit.save!
    conduit_rule_id = conduit.conduit_rules[0].id
    conduit.destroy

    # Verify conduit rules destroyed on conduit destroy
    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::ConduitRule.find(conduit_rule_id)
    end
  end


  # Test successful retrieval of conduit rules
  test "Successful retrieval of conduit rules" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    snapshot = deployment.proposed_snapshot
    destroy_preloaded_conduits()

    # Create a node with a couple of Roles
    node = NetworkTestHelper.create_node()

    NetworkTestHelper.add_role(snapshot, node, "ganglia_client")
    NetworkTestHelper.add_role(snapshot, node, "dns_server")
    node.save!
    
    # Set up intf0 conduit with 2 rules and 3 filters
    # The idea is that the 1st rule will match for this conduit
    conduit1 = BarclampNetwork::Conduit.new(:name => "intf0")
    conduit1.snapshot = snapshot
    conduit1.snapshot.save!

    sbs1 = BarclampNetwork::SelectBySpeed.create!(:value => "1g")

    is1 = BarclampNetwork::InterfaceSelector.new()
    is1.selectors << sbs1
    is1.save!

    rule1 = BarclampNetwork::ConduitRule.new()
    rule1.interface_selectors << is1
    conduit1.conduit_rules << rule1

    nmf1 = BarclampNetwork::NetworkModeFilter.new()
    nmf1.network_mode = "single"
    rule1.conduit_filters << nmf1
    nmf1.save!

    rule1.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^ganglia_.+")

    naf1 = BarclampNetwork::NodeAttributeFilter.new()
    naf1.attr = "nics.size.to_s"
    naf1.comparitor = "=="
    naf1.value = "2"
    rule1.conduit_filters << naf1
    naf1.save!

    rule1.save!
    
    sbs2 = BarclampNetwork::SelectBySpeed.create!(:value => "1g")

    is2 = BarclampNetwork::InterfaceSelector.new()
    is2.selectors << sbs2
    is2.save!
    
    rule2 = BarclampNetwork::ConduitRule.new()
    rule2.interface_selectors << is2
    conduit1.conduit_rules << rule2

    nmf2 = BarclampNetwork::NetworkModeFilter.new()
    nmf2.network_mode = "team"
    rule2.conduit_filters << nmf2
    nmf2.save!

    rule2.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^dns_.+")

    naf2 = BarclampNetwork::NodeAttributeFilter.new()
    naf2.attr = "nics.size.to_s"
    naf2.comparitor = "=="
    naf2.value = "2"
    rule2.conduit_filters << naf2
    naf2.save!

    rule2.save!

    conduit1.save!

    # Set up intf1 conduit with 2 rules and 3 filters
    # The idea is that the 2nd rule will match for this conduit
    conduit2 = BarclampNetwork::Conduit.new(:name => "intf1")
    conduit2.snapshot = conduit1.snapshot

    sbs3 = BarclampNetwork::SelectBySpeed.create!(:value => "1g")

    is3 = BarclampNetwork::InterfaceSelector.new()
    is3.selectors << sbs3
    is3.save!
    
    rule3 = BarclampNetwork::ConduitRule.new()
    rule3.interface_selectors << is3
    conduit2.conduit_rules << rule3

    nmf3 = BarclampNetwork::NetworkModeFilter.new()
    nmf3.network_mode = "single"
    rule3.conduit_filters << nmf3
    nmf3.save!

    rule3.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^dns_.+")

    naf3 = BarclampNetwork::NodeAttributeFilter.new()
    naf3.attr = "nics.size.to_s"
    naf3.comparitor = "=="
    naf3.value = "42"
    rule3.conduit_filters << naf3
    naf3.save!

    rule3.save!

    sbs4 = BarclampNetwork::SelectBySpeed.create!(:value => "1g")

    is4 = BarclampNetwork::InterfaceSelector.new()
    is4.selectors << sbs4
    is4.save!
    
    rule4 = BarclampNetwork::ConduitRule.new()
    rule4.interface_selectors << is4
    conduit2.conduit_rules << rule4

    nmf4 = BarclampNetwork::NetworkModeFilter.new()
    nmf4.network_mode = "single"
    rule4.conduit_filters << nmf4
    nmf4.save!

    rule4.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^ganglia_.+")

    naf4 = BarclampNetwork::NodeAttributeFilter.new()
    naf4.attr = "nics.size.to_s"
    naf4.comparitor = "=="
    naf4.value = "2"
    rule4.conduit_filters << naf4
    naf4.save!

    rule4.save!

    conduit2.save!

    # Set up intf2 conduit
    # The idea is that no rules will match for this conduit
    conduit3 = BarclampNetwork::Conduit.new(:name => "intf2")
    conduit3.snapshot = conduit1.snapshot

    sbs5 = BarclampNetwork::SelectBySpeed.create!(:value => "1g")

    is5 = BarclampNetwork::InterfaceSelector.new()
    is5.selectors << sbs5
    is5.save!
    
    rule5 = BarclampNetwork::ConduitRule.new()
    rule5.interface_selectors << is5
    conduit3.conduit_rules << rule5

    rule5.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^coffee_maker_.+")
    rule5.save!

    conduit3.save!

    # FINALLY run the test..
    result = BarclampNetwork::Conduit.get_conduit_rules(node)

    result_conduit_rule1 = result["intf0"]
    assert_not_nil result_conduit_rule1
    assert_equal rule1.id, result_conduit_rule1.id

    result_conduit_rule2 = result["intf1"]
    assert_not_nil result_conduit_rule2
    assert_equal rule4.id, result_conduit_rule2.id

    result_conduit_rule3 = result["intf2"]
    assert result_conduit_rule3.nil?
  end


  # Test failed node map construction due to no conduit rules matched
  test "Conduit.build_node_map failure: no conduit rules matched" do
    c1_intf_selectors = []

    c1_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c1_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c1_ifs1.save!
    c1_intf_selectors << c1_ifs1

    c2_intf_selectors = []

    c2_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c2_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c2_ifs1.save!
    c2_intf_selectors << c2_ifs1

    node_map = test_build_node_map("^bambam_.*$", c1_intf_selectors, c2_intf_selectors)

    assert_equal 0, node_map.size
  end


  # Test failed node map construction due to no interfaces selected per conduit
  test "Conduit.build_node_map failure: 0 intf per conduit" do
    c1_intf_selectors = []

    c1_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "10g")
    c1_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "3")
    c1_ifs1.save!
    c1_intf_selectors << c1_ifs1

    c2_intf_selectors = []

    c2_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "10g")
    c2_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "3")
    c2_ifs1.save!
    c2_intf_selectors << c2_ifs1

    node_map = test_build_node_map("^ganglia_.*$", c1_intf_selectors, c2_intf_selectors)

    assert_equal 2, node_map.size

    assert node_map.has_key?("intf0")
    assert_equal 0, node_map["intf0"].size

    assert node_map.has_key?("intf1")
    assert_equal 0, node_map["intf1"].size
  end


  # Test successful node map construction.
  # Select 1 interface per conduit in reverse order
  test "Conduit.build_node_map: 1 intf per conduit reverse" do
    c1_intf_selectors = []

    c1_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c1_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "2")
    c1_ifs1.save!
    c1_intf_selectors << c1_ifs1

    c2_intf_selectors = []

    c2_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c2_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c2_ifs1.save!
    c2_intf_selectors << c2_ifs1
    
    node_map = test_build_node_map("^ganglia_.*$", c1_intf_selectors, c2_intf_selectors)

    assert_equal 2, node_map.size

    assert node_map.has_key?("intf0")
    assert_equal 1, node_map["intf0"].size
    assert_equal "eth0", node_map["intf0"][0]

    assert node_map.has_key?("intf1")
    assert_equal 1, node_map["intf1"].size
    assert_equal "eth1", node_map["intf1"][0]
  end


  # Test successful node map construction.
  # Select 2 interfaces per conduit in forward and reverse order
  test "Conduit.build_node_map: 2 intf per conduit forward and reverse order" do
    c1_intf_selectors = []

    c1_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c1_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c1_ifs1.save!
    c1_intf_selectors << c1_ifs1

    c1_ifs2 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs2.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c1_ifs2.selectors << BarclampNetwork::SelectByIndex.create!(:value => "2")
    c1_ifs2.save!
    c1_intf_selectors << c1_ifs2

    c2_intf_selectors = []

    c2_ifs1 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs1.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c2_ifs1.selectors << BarclampNetwork::SelectByIndex.create!(:value => "2")
    c2_ifs1.save!
    c2_intf_selectors << c2_ifs1

    c2_ifs2 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs2.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "1g")
    c2_ifs2.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c2_ifs2.save!
    c2_intf_selectors << c2_ifs2

    node_map = test_build_node_map("^ganglia_.*$", c1_intf_selectors, c2_intf_selectors)

    assert_equal 2, node_map.size

    assert node_map.has_key?("intf0")
    assert_equal 2, node_map["intf0"].size
    assert_equal "eth1", node_map["intf0"][0]
    assert_equal "eth0", node_map["intf0"][1]

    assert node_map.has_key?("intf1")
    assert_equal 2, node_map["intf1"].size
    assert_equal "eth0", node_map["intf1"][0]
    assert_equal "eth1", node_map["intf1"][1]
  end


  private

  def test_build_node_map(role_pattern, c1_intf_selectors, c2_intf_selectors)
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    snapshot = deployment.proposed_snapshot
    destroy_preloaded_conduits()

    node = NetworkTestHelper.create_node()
    node.set_attrib("product_name", "PowerEdge C6145")
    NetworkTestHelper.add_role(snapshot, node, "ganglia_client")
    NetworkTestHelper.add_role(snapshot, node, "dns_server")
    node.save!

    if_map = NetworkTestHelper.create_an_interface_map(deployment)
    if_map.save!

    # Set up conduit intf0
    c1 = BarclampNetwork::Conduit.new(:name=>"intf0")
    c1.snapshot = snapshot
    
    # Add in a conduit rule that filters on ganglia role
    c1_cr1 = BarclampNetwork::ConduitRule.new()
    c1.conduit_rules << c1_cr1

    c1_cr1.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => role_pattern)

    c1_intf_selectors.each do |intf_selector|
      c1_cr1.interface_selectors << intf_selector
    end
    c1_cr1.save!

    # Add in another conduit rule that filters on a bogus role name
    c1_cr2 = BarclampNetwork::ConduitRule.new()
    c1.conduit_rules << c1_cr2

    # Note that this role filter is set up to deliberately not match
    c1_cr2.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^nomatch_.*$")

    c1_ifs2 = BarclampNetwork::InterfaceSelector.new()
    c1_ifs2.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "100m")
    c1_ifs2.selectors << BarclampNetwork::SelectByIndex.create!(:value => "1")
    c1_ifs2.save!
    c1_cr2.interface_selectors << c1_ifs2
    c1_cr2.save!

    c1.save!

    # Set up conduit intf1
    c2 = BarclampNetwork::Conduit.new(:name=>"intf1")
    c2.snapshot = c1.snapshot
    
    # Add in a conduit rule that filters on ganglia role
    c2_cr1 = BarclampNetwork::ConduitRule.new()
    c2.conduit_rules << c2_cr1

    c2_cr1.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => role_pattern)

    c2_intf_selectors.each do |intf_selector|
      c2_cr1.interface_selectors << intf_selector
    end
    c2_cr1.save!

    # Add in another conduit rule that filters on a bogus role name
    c2_cr2 = BarclampNetwork::ConduitRule.new()
    c2.conduit_rules << c2_cr2

    # Note that this role filter is set up to deliberately not match
    c2_cr2.conduit_filters << BarclampNetwork::RoleFilter.create!(:value => "^nomatch_.*$")

    c2_ifs2 = BarclampNetwork::InterfaceSelector.new()
    c2_ifs2.selectors << BarclampNetwork::SelectBySpeed.create!(:value => "100m")
    c2_ifs2.selectors << BarclampNetwork::SelectByIndex.create!(:value => "2")
    c2_ifs2.save!
    c2_cr2.interface_selectors << c2_ifs2
    c2_cr2.save!

    c2.save!
    
    BarclampNetwork::Conduit.build_node_map(node)
  end


  def destroy_preloaded_conduits()
    BarclampNetwork::Conduit.all.each do |conduit|
      conduit.destroy
    end
  end
end
