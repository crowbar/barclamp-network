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

class BarclampNetwork::Server < Role


  def conduit?
    false
  end

  # used by the network-server role to get interfaces
  def interfaces
    o = {}
    if name.eql? 'network-server'
      raw = template
      raw["crowbar"]["interface_map"].each { |im| o[im["pattern"]] = im["bus_order"] }
    end
    o
  end

  def update_interface(pattern, bus_order)
    data = self.template
    found = false
    data["crowbar"]["interface_map"].each_with_index do |item, index|
      if pattern.eql? item["pattern"]
        data["crowbar"]["interface_map"][index]["bus_order"] = bus_order
        found = true
      end
    end
    unless found
      iface = { "crowbar" => { "interface_map" => { "pattern"=>pattern, "bus_order"=>bus_order } } }
      template_update(iface)
      self.save!
    end
  end

end
