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

  # Our template == the template that our matching network definition has.
  # For now, just hashify the stuff we care about[:ranges]
  def template
    if name.eql? 'network-server'
      read_attribute("template")
    else
      "{\"crowbar\": {\"network\": {\"#{network.name}\": #{network.to_template} } } }"
    end
  end

  # used by the network-server role to get interfaces
  def interfaces
    o = {}
    if name.eql? 'network-server'
      raw = JSON.parse(read_attribute("template"))
      raw["crowbar"]["interface_map"].each { |im| o[im["pattern"]] = im["bus_order"] }
    end
    o
  end

  def update_interface(pattern, bus_order)
    if name.eql? 'network-server'
      data = JSON.parse(read_attribute("template"))
      found = false
      data["crowbar"]["interface_map"].each_with_index do |item, index|
        if pattern.eql? item["pattern"]
          data["crowbar"]["interface_map"][index]["bus_order"] = bus_order
          found = true
        end
      end
      data["crowbar"]["interface_map"] << { "pattern"=>pattern, "bus_order"=>bus_order } unless found
      write_attribute("template",JSON.generate(data))
      self.save!
    end
  end

  def jig_role(name)
    chef_role = Chef::Role.new
    chef_role.name(name)
    chef_role.description("#{name}: Automatically created by Crowbar")
    chef_role.run_list(Chef::RunList.new("recipe[network]"))
    chef_role.save
    true
  end

  def on_proposed(nr)
    NodeRole.transaction do
      d = nr.sysdata
      addresses = (d["crowbar"]["network"][network.name]["addresses"] rescue nil)
      return if addresses && !addresses.empty?
      addr_range = nr.role.network.ranges.where(:name => nr.node.admin ? "admin" : "host").first
      addr_range.allocate(nr.node)
    end
  end
end
