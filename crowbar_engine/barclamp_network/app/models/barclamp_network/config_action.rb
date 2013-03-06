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

class BarclampNetwork::ConfigAction < ActiveRecord::Base
  attr_accessible :order

  belongs_to :conduit_rule, :inverse_of => :conduit_actions, :class_name => "BarclampNetwork::ConduitRule"
  belongs_to :network, :inverse_of => :network_actions, :class_name => "BarclampNetwork::Network"

  validates :order, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1 }

  ACTION = "action"
  

  def self.create_actions(actions_config)
    action_index = 1
    actions = []
    actions_config.each { |action_config|
      actions << create_action(action_index, action_config)
      action_index += 1
    }
    actions
  end


  def self.create_action(action_index, action_config)
    action_name = action_config[ACTION]
    action = BarclampNetwork.const_get(action_name).new()
    action.handle_parameters(action_config)
    action.order = action_index
    action.save!
    action
  end


  def handle_parameters(params)
    params.each { |param_name, param_value|
      handle_parameter(param_name, param_value) if param_name != ACTION
    }
  end


  def handle_parameter(param_name, param_value)
    self.send( "#{param_name}=", param_value )
  end
end
