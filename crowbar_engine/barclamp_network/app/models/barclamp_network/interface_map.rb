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

class BarclampNetwork::InterfaceMap < ActiveRecord::Base
  has_many :bus_maps, :dependent => :destroy
  belongs_to :proposal

  validates :bus_maps, :presence => true
  validates :proposal, :presence => true


  # This method finds the bus order for the node and returns a list of the
  # Buses in the appropriate order
  def self.get_bus_order(node)
    buses = nil
    product_name_attrib = node.get_attrib("product_name")

    BusMap.all.each do |bus_map|
      buses = bus_map.buses if product_name_attrib.value =~ /#{bus_map.pattern}/
      break if buses
    end
    buses.sort! {|bus1,bus2| bus1.order.to_i <=> bus2.order.to_i} if !buses.nil?
    buses
  end
end
