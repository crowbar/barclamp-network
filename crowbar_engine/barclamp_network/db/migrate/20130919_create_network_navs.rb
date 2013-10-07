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
class CreateNetworkNavs < ActiveRecord::Migration
  def self.up

    # networks
    Nav.find_or_create_by_item :item=>'networks', :parent_item=>'root', :name=>'nav.networks', :description=>'nav.networks_description', :path=>"barclamp_network.networks_path", :order=>1500
      Nav.find_or_create_by_item :item=>'networks_child', :parent_item=>'networks', :name=>'nav.networks', :description=>'nav.networks_description', :path=>"barclamp_network.networks_path", :order=>1000
      Nav.find_or_create_by_item :item=>'network_map', :parent_item=>'networks', :name=>'nav.network_map', :description=>'nav.network_map_description', :path=>"barclamp_network.network_map_path", :order=>5000
      Nav.find_or_create_by_item :item=>'interfaces', :parent_item=>'networks', :name=>'nav.interfaces', :description=>'nav.interfaces_description', :path=>"barclamp_network.interfaces_path", :order=>5000

    # scaffolds
    Nav.find_or_create_by_item :item=>'scaffold_networks',  :parent_item=>'scaffold', :name=>'nav.scaffold.networks',  :path=>"barclamp_network.scaffolds_networks_path", :order=>2000
    Nav.find_or_create_by_item :item=>'scaffold_allocations',  :parent_item=>'scaffold', :name=>'nav.scaffold.allocations',  :path=>"barclamp_network.scaffolds_allocations_path", :order=>2040
  end

  def self.down
    Nav.delete_by_item 'scaffold_networks'
    Nav.delete_by_item 'network_map'
    Nav.delete_by_item 'networks_child'
    Nav.delete_by_item 'networks'
  end
end
