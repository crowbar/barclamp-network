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
#
class NetworkNavs < ActiveRecord::Migration
  def self.up
    
    Nav.find_or_create_by_item :item=>'switches', :parent_item=>'network', :name=>'nav.switch', :description=>'nav.switch_description', :path=>"switch_path", :order=>500
    Nav.find_or_create_by_item :item=>'vlan', :parent_item=>'network', :name=>'nav.vlan', :description=>'nav.vlan_description', :path=>"vlan_path", :order=>600

  end

  def self.down
    Nav.delete_by_item 'switches'
    Nav.delete_by_item 'vlan'
  end
end