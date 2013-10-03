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
    "{\"crowbar\": {\"network\": {\"#{network.name}\": #{network.to_template} } } }"
  end

  def jig_role(name)
    chef_role = Chef::Role.new
    chef_role.name(name)
    chef_role.description("#{name}: Automatically created by Crowbar")
    chef_role.run_list(Chef::RunList.new("recipe[network]"))
    chef_role.save
    true
  end

  def on_node_delete(node)
    # remove IP allocations from nodes
    BarclampNetwork::Allocation.where(:node_id=>node.id).destroy_all
    # TODO do we need to do additional cleanup???
  end

  def on_proposed(nr)
    NodeRole.transaction do
      d = nr.sysdata
      addresses = (d["crowbar"]["network"][network.name]["addresses"] rescue nil)
      return if addresses && !addresses.empty?
      # if the node is an admin node, then use the admin range, otherwise use the host range
      addr_range = nr.role.network.ranges.where(:name => nr.node.is_admin? ? "admin" : "host").first
      addr_range.allocate(nr.node)
    end
  end

end
