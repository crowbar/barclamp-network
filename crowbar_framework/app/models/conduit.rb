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

class Conduit < ActiveRecord::Base
  attr_protected :id
  has_many :networks, :inverse_of => :conduit, :dependent => :nullify
  has_many :conduit_rules, :dependent => :destroy
  belongs_to :proposal

  attr_accessible :name
  accepts_nested_attributes_for :networks, :conduit_rules

  validates_uniqueness_of :name, :presence => true, :scope => :proposal_id
  validates :conduit_rules, :presence => true
  validates :proposal, :presence => true


  def self.get_conduit_rules(node)
    conduit_rules = {}
    # Loop thru each of the Conduits (intf0, intf1, etc)
    Conduit.all.each do |conduit|
      # Find the ConduitRule where...
      conduit.conduit_rules.each do |conduit_rule|
        # each of the supplied ConduitFilters match 
        found_match=true
        conduit_rule.conduit_filters.each do |conduit_filter|
          if !conduit_filter.match(node)
            found_match=false
            break
          end
        end

        # If the conduit filters for this ConduitRule did match, then...
        if found_match
          # This is the ConduitRule that we want, so put it in the hash
          conduit_rules[conduit.name] = conduit_rule
          break
        end
      end
    end

    conduit_rules
  end
end
