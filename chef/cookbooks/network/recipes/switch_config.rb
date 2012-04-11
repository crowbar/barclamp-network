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
#

admin_ip = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address

interfaces = {}

# Find the list of unique vlans
unique_vlans={}
search(:node, "*:*").each do |aNode|
  node_map = Chef::Recipe::Barclamp::Inventory.build_node_map(aNode)

  node_map.each do |conduit, if_hash|
    if_list = if_hash["if_list"]
    if if_list.size > 1
      # TBD
    else
      switch_unit=aNode["crowbar_ohai"]["switch_config"][if_list[0]]["switch_unit"]
      switch_port=aNode["crowbar_ohai"]["switch_config"][if_list[0]]["switch_port"]
      port_key = "#{switch_unit}/0/#{switch_port}"
      interfaces[port_key] = {} if interfaces[port_key].nil?

      aNode["crowbar"]["network"].each do |aNetworkName, aNetwork|
        next if aNetwork["conduit"] != conduit
        vlan = aNetwork["vlan"]
        unique_vlans[vlan] = ""
        vlans_for_interface = interfaces[port_key]
        vlans_for_interface[vlan] = aNetwork["use_vlan"]
      end
    end
  end
end

directory "/opt/dell/switch" do
  mode 0755
  owner "root"
  group "root"
end

template "/opt/dell/switch/switch_config.json" do
  mode 0644
  owner "root"
  group "root"
  source "switch_config.erb"
  variables(
    :admin_node_ip => admin_ip,
    :unique_vlans => unique_vlans.keys.sort,
    :interfaces => interfaces
  )
end
