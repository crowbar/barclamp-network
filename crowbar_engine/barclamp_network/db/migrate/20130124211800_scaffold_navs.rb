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
#
#
class ScaffoldNavs < ActiveRecord::Migration
 def self.up
    Nav.find_or_create_by_item :item=>'scaffold_network', :parent_item=>'scaffold', :name=>'nav.scaffold.network.top', :description=>'nav.scaffold.network.top_description', :path=>'scaffolds_networks_path', :order=>600, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_allocated_ip_addresses', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.allocated_ip_addresses', :description=>'nav.scaffold.network.allocated_ip_addresses_description', :path=>'scaffolds_allocated_ip_addresses_path', :order=>601, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_bmc_interfaces', :parent_item=>'scaffold_network_interfaces', :name=>'nav.scaffold.network.bmc_interfaces', :description=>'nav.scaffold.network.bmc_interfaces_description', :path=>'scaffolds_bmc_interfaces_path', :order=>602, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_bonds_interfaces', :parent_item=>'scaffold_network_interfaces', :name=>'nav.scaffold.network.bonds', :description=>'nav.scaffold.network.bonds_description', :path=>'scaffolds_bonds_path', :order=>603, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_bus_maps', :parent_item=>'scaffold_network_interface_maps', :name=>'nav.scaffold.network.bus_maps', :description=>'nav.scaffold.network.bus_maps_description', :path=>'scaffolds_bus_maps_path', :order=>604, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_buses', :parent_item=>'scaffold_network_bus_maps', :name=>'nav.scaffold.network.buses', :description=>'nav.scaffold.network.buses_description', :path=>'scaffolds_buses_path', :order=>605, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_conduit_actions', :parent_item=>'scaffold_network_conduit_rules', :name=>'nav.scaffold.network.conduit_actions', :description=>'nav.scaffold.network.conduit_actions_description', :path=>'scaffolds_conduit_actions_path', :order=>606, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_conduit_filters', :parent_item=>'scaffold_network_conduit_rules', :name=>'nav.scaffold.network.conduit_filters', :description=>'nav.scaffold.network.conduit_filters_description', :path=>'scaffolds_conduit_filters_path', :order=>607, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_conduit_rules', :parent_item=>'scaffold_network_conduits', :name=>'nav.scaffold.network.conduit_rules', :description=>'nav.scaffold.network.conduit_rules_description', :path=>'scaffolds_conduit_rules_path', :order=>608, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_conduits', :parent_item=>'scaffold_network', :name=>'nav.scaffold.network.conduits', :description=>'nav.scaffold.network.conduits_description', :path=>'scaffolds_conduits_path', :order=>609, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_create_bonds', :parent_item=>'scaffold_network_conduit_actions', :name=>'nav.scaffold.network.create_bonds', :description=>'nav.scaffold.network.create_bonds_description', :path=>'scaffolds_create_bonds_path', :order=>610, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_create_vlans', :parent_item=>'scaffold_network_conduit_actions', :name=>'nav.scaffold.network.create_vlans', :description=>'nav.scaffold.network.create_vlans_description', :path=>'scaffolds_create_vlans_path', :order=>611, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_interface_maps', :parent_item=>'scaffold_network', :name=>'nav.scaffold.network.interface_maps', :description=>'nav.scaffold.network.interface_maps_description', :path=>'scaffolds_interface_maps_path', :order=>612, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_interface_selectors', :parent_item=>'scaffold_network_conduit_rules', :name=>'nav.scaffold.network.interface_selectors', :description=>'nav.scaffold.network.interface_selectors_description', :path=>'scaffolds_interface_selectors_path', :order=>613, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_interfaces', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.interfaces', :description=>'nav.scaffold.network.interfaces_description', :path=>'scaffolds_interfaces_path', :order=>614, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_ip_addresses', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.ip_addresses', :description=>'nav.scaffold.network.ip_addresses_description', :path=>'scaffolds_ip_addresses_path', :order=>615, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_ip_ranges', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.ip_ranges', :description=>'nav.scaffold.network.ip_ranges_description', :path=>'scaffolds_ip_ranges_path', :order=>616, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_network_mode_filters', :parent_item=>'scaffold_network_conduit_filters', :name=>'nav.scaffold.network.network_mode_filters', :description=>'nav.scaffold.network.network_mode_filters_description', :path=>'scaffolds_network_mode_filters_path', :order=>617, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_networks', :parent_item=>'scaffold_network', :name=>'nav.scaffold.network.networks', :description=>'nav.scaffold.network.networks_description', :path=>'scaffolds_networks_path', :order=>618, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_node_attribute_filters', :parent_item=>'scaffold_network_conduit_filters', :name=>'nav.scaffold.network.node_attribute_filters', :description=>'nav.scaffold.network.node_attribute_filters_description', :path=>'scaffolds_node_attribute_filters_path', :order=>619, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_physical_interfaces', :parent_item=>'scaffold_physical_interfaces', :name=>'nav.scaffold.network.physical_interfaces', :description=>'nav.scaffold.network.physical_interfaces_description', :path=>'scaffolds_physical_interfaces_path', :order=>620, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_routers', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.routers', :description=>'nav.scaffold.network.routers_description', :path=>'scaffolds_routers_path', :order=>621, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_select_by_indices', :parent_item=>'scaffold_network_interface_selectors', :name=>'nav.scaffold.network.select_by_indices', :description=>'nav.scaffold.network.select_by_indices_description', :path=>'scaffolds_select_by_indices_path', :order=>622, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_select_by_speeds', :parent_item=>'scaffold_network_interface_selectors', :name=>'nav.scaffold.network.select_by_speeds', :description=>'nav.scaffold.network.select_by_speeds_description', :path=>'scaffolds_select_by_speeds_path', :order=>623, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_vlan_interfaces', :parent_item=>'scaffold_interfaces', :name=>'nav.scaffold.network.vlan_interfaces', :description=>'nav.scaffold.network.vlan_interfaces_description', :path=>'scaffolds_vlan_interfaces_path', :order=>624, :development=>true
    Nav.find_or_create_by_item :item=>'scaffold_network_vlans', :parent_item=>'scaffold_network_networks', :name=>'nav.scaffold.network.vlans', :description=>'nav.scaffold.network.vlans_description', :path=>'scaffolds_vlans_path', :order=>625, :development=>true
  end

 def self.down
    Nav.delete_by_item 'scaffold_network'
    Nav.delete_by_item 'scaffold_network_allocated_ip_addresses'
    Nav.delete_by_item 'scaffold_network_bmc_interfaces'
    Nav.delete_by_item 'scaffold_network_bonds'
    Nav.delete_by_item 'scaffold_network_bus_maps'
    Nav.delete_by_item 'scaffold_network_buses'
    Nav.delete_by_item 'scaffold_network_conduit_actions'
    Nav.delete_by_item 'scaffold_network_conduit_filters'
    Nav.delete_by_item 'scaffold_network_conduit_rules'
    Nav.delete_by_item 'scaffold_network_conduits'
    Nav.delete_by_item 'scaffold_network_create_bonds'
    Nav.delete_by_item 'scaffold_network_create_vlans'
    Nav.delete_by_item 'scaffold_network_interface_maps'
    Nav.delete_by_item 'scaffold_network_interface_selectors'
    Nav.delete_by_item 'scaffold_network_interfaces'
    Nav.delete_by_item 'scaffold_network_ip_addresses'
    Nav.delete_by_item 'scaffold_network_ip_ranges'
    Nav.delete_by_item 'scaffold_network_network_mode_filters'
    Nav.delete_by_item 'scaffold_network_networks'
    Nav.delete_by_item 'scaffold_network_node_attribute_filters'
    Nav.delete_by_item 'scaffold_network_physical_interfaces'
    Nav.delete_by_item 'scaffold_network_routers'
    Nav.delete_by_item 'scaffold_network_select_by_indices'
    Nav.delete_by_item 'scaffold_network_select_by_speeds'
    Nav.delete_by_item 'scaffold_network_vlan_interfaces'
    Nav.delete_by_item 'scaffold_network_vlans'
  end
end