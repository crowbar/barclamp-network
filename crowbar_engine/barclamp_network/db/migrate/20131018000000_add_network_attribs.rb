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

# Adds the attributes that we want to generically expose for Nodes
class AddNetworkAttribs < ActiveRecord::Migration

  def self.up

    Attrib.create :name=>'nics', :description=>'Ethernet Interface Ports', :map=>'ohai/crowbar_ohai/detected/network'

    BarclampNetwork::AttribSwitches.create :name=>'switches', :description=>'Connected Networking Switches', :map=>'ohai/crowbar_ohai/switch_config'

  end

  def self.down
    keys = ['nics', 'switches']
    keys.each { |k| Attrib.delete Attrib.find_key(k).id }
  end
end
