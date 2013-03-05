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
 
class ConfigActionModelTest < ActiveSupport::TestCase

  # Test successful creation
  test "ConfigAction creation: success" do

    actions_config = [
      {
        "action" => "ConfigAction"
      },
      {
        "action" => "CreateBond",
        "team_mode" => 6
      },
      {
        "action" => "CreateVlan",
        "tag" => 100
      }
    ]

    actions = BarclampNetwork::ConfigAction.create_actions(actions_config)

    assert 3, actions.size
    assert 1, actions[0].order
    assert 2, actions[1].order
    assert 3, actions[2].order
    assert actions[0].instance_of? BarclampNetwork::ConfigAction
    assert actions[1].instance_of? BarclampNetwork::CreateBond
    assert actions[2].instance_of? BarclampNetwork::CreateVlan
    assert_equal 6, actions[1].team_mode
    assert_equal 100, actions[2].tag
  end


  # Test creation failure due to low index
  test "ConfigAction creation: failure due to low index" do
    assert_raise ActiveRecord::RecordInvalid do
      BarclampNetwork::ConfigAction.create!(:order => 0)
    end
  end


  # Test creation failure due to no index
  test "ConfigAction creation: failure due to no index" do
    assert_raise ActiveRecord::RecordInvalid do
      BarclampNetwork::ConfigAction.create!()
    end
  end
end
