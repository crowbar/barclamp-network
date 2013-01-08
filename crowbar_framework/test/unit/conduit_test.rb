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
    assert_raise ActiveRecord::RecordInvalid do
      conduit = Conduit.new
      conduit.name = "intf0"
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
end
