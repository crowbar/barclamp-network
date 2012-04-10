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

# Find the list of unique vlans
unique_vlans={}
search(:node, "*:*").each { |aNode|
  aNode["network"]["networks"].each do |aNetworkName, aNetwork|
    next if !aNetwork["use_vlan"]
    vlan = aNetwork["vlan"]
    unique_vlans[vlan] = ""
  end
}

# TODO: Put this file in a reasonable place
template "/tmp/switch_config.json" do
  mode 0644
  source "switch_config.erb"
  owner "root"
  group "root"
  variables(
    :admin_node_ip => admin_ip,
    :unique_vlans => unique_vlans.keys.sort
  )
end
