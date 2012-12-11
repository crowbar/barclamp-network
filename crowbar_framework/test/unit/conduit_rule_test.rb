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
end
