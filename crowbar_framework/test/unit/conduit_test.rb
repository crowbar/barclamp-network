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
 
class ConduitTest < ActiveSupport::TestCase

  # Test successful creation
  test "Conduit creation: success" do
    conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    conduit.save!
  end


  # Test creation failure due to missing conduit rule
  test "Conduit creation: failure due to missing conduit rule" do
    conduit = Conduit.new
    conduit.name = "intf0"
    assert_raise ActiveRecord::RecordInvalid do
      conduit.save!
    end    
  end


  # Test delete cascade
  test "Conduit deletion: cascade to conduit rules" do
    conduit = NetworkTestHelper.create_or_get_conduit("intf0")
    conduit.save!
    conduit_rule_id = conduit.conduit_rules[0].id
    conduit.destroy

    # Verify conduit rules destroyed on conduit destroy
    assert_raise ActiveRecord::RecordNotFound do
      ConduitRule.find(conduit_rule_id)
    end
  end


  # Test successful retrieval of conduit rules
  test "Successful retrieval of conduit rules" do
    # Create a node with a couple of Roles
    node = Node.new(:name => "fred.flintstone.org")

    NetworkTestHelper.add_role(node, "ganglia_client")
    NetworkTestHelper.add_role(node, "dns_server")
    node.save!
    
    # Set up intf0 conduit with 2 rules and 3 filters
    # The idea is that the 1st rule will match for this conduit
    conduit1 = Conduit.new(:name => "intf0")
    conduit1.proposal = NetworkTestHelper.create_or_get_proposal()
    conduit1.proposal.save!

    rule1 = ConduitRule.new()
    rule1.interface_selectors << SelectBySpeed.new(:comparitor => "=", :value => "1g")
    conduit1.conduit_rules << rule1

    nmf1 = NetworkModeFilter.new()
    nmf1.network_mode = "single"
    rule1.conduit_filters << nmf1
    nmf1.save!

    rf1 = RoleFilter.new()
    rf1.pattern = "^ganglia_.+"
    rule1.conduit_filters << rf1
    rf1.save!

    naf1 = NodeAttributeFilter.new()
    naf1.attr = "nics.size"
    naf1.comparitor = "=="
    naf1.value = "2"
    rule1.conduit_filters << naf1
    naf1.save!

    rule1.save!
    
    rule2 = ConduitRule.new()
    rule2.interface_selectors << SelectBySpeed.new(:comparitor => "=", :value => "1g")
    conduit1.conduit_rules << rule2

    nmf2 = NetworkModeFilter.new()
    nmf2.network_mode = "team"
    rule2.conduit_filters << nmf2
    nmf2.save!

    rf2 = RoleFilter.new()
    rf2.pattern = "^dns_.+"
    rule2.conduit_filters << rf2
    rf2.save!

    naf2 = NodeAttributeFilter.new()
    naf2.attr = "nics.size"
    naf2.comparitor = "=="
    naf2.value = "2"
    rule2.conduit_filters << naf2
    naf2.save!

    rule2.save!

    conduit1.save!

    # Set up intf1 conduit with 2 rules and 3 filters
    # The idea is that the 2nd rule will match for this conduit
    conduit2 = Conduit.new(:name => "intf1")
    conduit2.proposal = NetworkTestHelper.create_or_get_proposal()
    conduit2.proposal.save!

    rule3 = ConduitRule.new()
    rule3.interface_selectors << SelectBySpeed.new(:comparitor => "=", :value => "1g")
    conduit2.conduit_rules << rule3

    nmf3 = NetworkModeFilter.new()
    nmf3.network_mode = "single"
    rule3.conduit_filters << nmf3
    nmf3.save!

    rf3 = RoleFilter.new()
    rf3.pattern = "^dns_.+"
    rule3.conduit_filters << rf3
    rf3.save!

    naf3 = NodeAttributeFilter.new()
    naf3.attr = "nics.size"
    naf3.comparitor = "=="
    naf3.value = "42"
    rule3.conduit_filters << naf3
    naf3.save!

    rule3.save!

    rule4 = ConduitRule.new()
    rule4.interface_selectors << SelectBySpeed.new(:comparitor => "=", :value => "1g")
    conduit2.conduit_rules << rule4

    nmf4 = NetworkModeFilter.new()
    nmf4.network_mode = "single"
    rule4.conduit_filters << nmf4
    nmf4.save!

    rf4 = RoleFilter.new()
    rf4.pattern = "^ganglia_.+"
    rule4.conduit_filters << rf4
    rf4.save!

    naf4 = NodeAttributeFilter.new()
    naf4.attr = "nics.size"
    naf4.comparitor = "=="
    naf4.value = "2"
    rule4.conduit_filters << naf4
    naf4.save!

    rule4.save!

    conduit2.save!

    # Set up intf2 conduit
    # The idea is that no rules will match for this conduit
    conduit3 = Conduit.new(:name => "intf2")
    conduit3.proposal = NetworkTestHelper.create_or_get_proposal()
    conduit3.proposal.save!

    rule5 = ConduitRule.new()
    rule5.interface_selectors << SelectBySpeed.new(:comparitor => "=", :value => "1g")
    conduit3.conduit_rules << rule5

    rf5 = RoleFilter.new()
    rf5.pattern = "^coffee_maker_.+"
    rule5.conduit_filters << rf5
    rf5.save!

    rule5.save!

    conduit3.save!

    # FINALLY run the test..
    result = Conduit.get_conduit_rules(node)

    result_conduit_rule1 = result["intf0"]
    assert rule1, result_conduit_rule1

    result_conduit_rule2 = result["intf1"]
    assert rule4, result_conduit_rule2

    result_conduit_rule3 = result["intf2"]
    assert result_conduit_rule3.nil?
  end
end
