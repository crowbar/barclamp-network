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

class BarclampNetwork::Conduit < ActiveRecord::Base
  attr_protected :id
  has_many :networks, :inverse_of => :conduit, :dependent => :nullify
  has_many :conduit_rules, :dependent => :destroy
  belongs_to :proposal

  attr_accessible :name
  accepts_nested_attributes_for :networks, :conduit_rules

  validates_uniqueness_of :name, :presence => true, :scope => :proposal_id
  validates :conduit_rules, :presence => true
  validates :proposal, :presence => true


  # This method finds the conduit rule associated with each conduit that passes
  # all the conduit filters on the node, and returns a hash that maps:
  # "intf0" => ConduitRule
  def self.get_conduit_rules(node)
    conduit_rules = {}
    # Loop thru each of the Conduits (intf0, intf1, etc)
    Conduit.all.each do |conduit|

      # Find the ConduitRule where each of the supplied ConduitFilters match 
      next if conduit.conduit_rules.nil?

      conduit.conduit_rules.each do |conduit_rule|
        # If the conduit filters for this ConduitRule match, then...
        if conduit_rule.match_filters(node)
          # This is the ConduitRule that we want, so put it in the hash
          conduit_rules[conduit.name] = conduit_rule
          break
        end
      end
    end

    conduit_rules
  end


  def self.build_node_map(node)
    bus_order = InterfaceMap.get_bus_order(node)

    # Find the conduit rule for each conduit that is applicable to the node
    rules = Conduit.get_conduit_rules(node)
    return {} if rules.empty?

    # Build up a map that maps conduit_name to an array of interface names
    ans = {}
    rules.each do |conduit_name, conduit_rule|
      if_list = conduit_rule.select_interfaces(node)
      ans[conduit_name] = if_list
    end

    ans
  end
end
