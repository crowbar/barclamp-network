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
 
class ConduitRuleTest < ActiveSupport::TestCase

  # Test successful creation
  test "ConduitRule creation: success" do
    rule = NetworkTestHelper.create_a_conduit_rule()
    rule.save!
  end


  # Test creation failure due to missing conduit action
  test "ConduitRule creation: failure due to missing conduit action" do
    assert_raise ActiveRecord::RecordInvalid do
      sbs = SelectBySpeed.new()
      sbs.comparitor = "="
      sbs.value = "1g"
      rule = ConduitRule.new()
      rule.interface_selectors << sbs
      rule.save!
    end
  end


  # Test creation failure due to missing interface selectors
  test "ConduitRule creation: failure due to missing interface selectors" do
    assert_raise ActiveRecord::RecordInvalid do
      create_bond = CreateBond.new()
      create_bond.name = "intf0"
      create_bond.team_mode = 6
      rule = ConduitRule.new()
      rule.conduit_action = create_bond
      rule.save!
    end    
  end


  # Test delete cascade
  test "ConduitRule deletion: cascade to conduit action and interface selectors" do
    rule = NetworkTestHelper.create_a_conduit_rule()
    rule.save!

    conduit_action_id = rule.conduit_action.id
    interface_selector_id = rule.interface_selectors[0].id

    rule.destroy

    # Verify conduit action destroyed on conduit rule destroy
    assert_raise ActiveRecord::RecordNotFound do
      ConduitAction.find(conduit_action_id)
    end

    # Verify interface selector destroyed on conduit rule destroy
    assert_raise ActiveRecord::RecordNotFound do
      InterfaceSelector.find(interface_selector_id)
    end
  end
end
