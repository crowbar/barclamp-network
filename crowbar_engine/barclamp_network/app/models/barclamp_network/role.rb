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

class BarclampNetwork::Role < Role

  def network
    BarclampNetwork::Network.where(:name => "#{name.split('-',2)[-1]}").first
  end

  def conduit?
    true
  end

  # Our template == the template that our matching network definition has.
  # For now, just hashify the stuff we care about[:ranges]
  def template
    { "crowbar" => { "network" => { network.name => network.to_template } }  }
  end

  def jig_role(nr)
    { "name" => nr.role.name,
      "chef_type" => "role",
      "json_class" => "Chef::Role",
      "description" => "#{nr.role.name}: Automatically created by Crowbar",
      "run_list" => ["recipe[network]"]}
  end

  def on_node_delete(node)
    # remove IP allocations from nodes
    BarclampNetwork::Allocation.where(:node_id=>node.id).destroy_all
    # TODO do we need to do additional cleanup???
  end

  def sysdata(nr)
    our_addrs = network.node_allocations(nr.node).map{|a|a.to_s}
    res = {"crowbar" => {
        "network" => {
          network.name => {
            "addresses" => our_addrs
          }
        }
      }
    }
    # Pick targets for ping testing.
    target = node_roles.partition{|tnr|tnr.id != nr.id}.flatten.detect{|tnr|tnr.active?}
    if target
      res["crowbar"]["network"][network.name]["targets"] = network.node_allocations(target.node).map{|a|a.to_s}
    end
    res
  end

  def on_proposed(nr)
    NodeRole.transaction do
      return if network.allocations.node(nr.node).count != 0
      addr_range = network.ranges.where(:name => nr.node.is_admin? ? "admin" : "host").first
      return if addr_range.nil?
      # get the node for the hint directly (do not use cached version)
      node = nr.node(true)
      # get the suggested ip address (if any) - nil = automatically assign
      hint = ::Attrib.find_key "hint-#{nr.role.name}-v4addr"
      suggestion = hint.get(node, :hint) if hint
      # allocate
      addr_range.allocate(nr.node, suggestion) unless addr_range.nil?
    end
  end

end
