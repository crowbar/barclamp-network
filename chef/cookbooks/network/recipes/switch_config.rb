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

def setup_interface(unique_vlans, interfaces, a_node, conduit, interface_id )
    a_node["crowbar"]["network"].each do |network_name, network|
      next if network["conduit"] != conduit
      vlan = network["vlan"]
      unique_vlans[vlan] = ""

      interfaces[interface_id] = {} if interfaces[interface_id].nil?
      vlans_for_interface = interfaces[interface_id]
      vlans_for_interface[vlan] = network["use_vlan"]
    end
end

admin_ip = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address

unique_vlans={}
interfaces = {}
next_lag_id=1
lags = {}

search(:node, "*:*").each do |a_node|
  node_map = Chef::Recipe::Barclamp::Inventory.build_node_map(a_node)

  node_map.each do |conduit, conduit_info|
    if_list = conduit_info["if_list"]
    team_mode = conduit_info["team_mode"] rescue nil

    interface_id=""
    if if_list.size > 1 && team_mode != 5 && team_mode != 6

      lag_ports = []
      found_lag_port = false

      if_list.each do |intf|
        switch_unit=a_node["crowbar_ohai"]["switch_config"][intf]["switch_unit"]
        switch_port=a_node["crowbar_ohai"]["switch_config"][intf]["switch_port"]
        next if switch_unit == -1

        found_lag_port = true
        lag_ports << "#{switch_unit}/0/#{switch_port}"
      end

      # Only create the LAG if at least one interface is connected to the switch
      if found_lag_port
        lag_ports.sort!

        lag_id = next_lag_id
        next_lag_id += 1

        lag = {}
        lag["lag_id"] = lag_id
        lag["ports"] = lag_ports

        lags[lag_id] = lag

        setup_interface(unique_vlans, interfaces, a_node, conduit, lag_id.to_s )
      end
    else
      if_list.each do |intf|
        switch_unit=a_node["crowbar_ohai"]["switch_config"][intf]["switch_unit"]
        switch_port=a_node["crowbar_ohai"]["switch_config"][intf]["switch_port"]
        next if switch_unit == -1

        setup_interface(unique_vlans, interfaces, a_node, conduit, "#{switch_unit}/0/#{switch_port}" )
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
    :lags => lags,
    :interfaces => interfaces
  )
end
