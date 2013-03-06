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
 
class CreateBridgeTest < ActiveSupport::TestCase

  # Test successful creation
  test "CreateBridge creation: success, no ip" do
    BarclampNetwork::CreateBridge.create!(:order => 1)
  end


  # Test creation success when missing ip
  test "CreateBridge creation: success with ip" do
    actions = create_bridge_with_ip()
    
    assert 1, actions.size
    assert 1, actions[0].order
    assert actions[0].instance_of? BarclampNetwork::CreateBridge
    assert_equal "192.168.123.1", actions[0].ip.cidr
  end


  # Test cascade delete to ip
  test "CreateBridge deletion: cascade delete to ip" do
    actions = create_bridge_with_ip()

    create_bridge = actions[0]
    bridge_ip = create_bridge.ip
    create_bridge.destroy

    assert_raise ActiveRecord::RecordNotFound do
      BarclampNetwork::IpAddress.find(bridge_ip.id)
    end
  end


  private

  def create_bridge_with_ip()
    actions_config = [
      {
        "action" => "CreateBridge",
        "ip" => "192.168.123.1"
      }
    ]

    BarclampNetwork::ConfigAction.create_actions(actions_config)
  end
end
