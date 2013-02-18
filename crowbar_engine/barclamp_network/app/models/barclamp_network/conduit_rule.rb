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

class BarclampNetwork::ConduitRule < ActiveRecord::Base
  has_many :conduit_filters, :dependent => :destroy
  has_many :interface_selectors, :dependent => :destroy
  has_many :conduit_actions, :dependent => :destroy
  belongs_to :conduit, :inverse_of => :conduit_rules

  validates :interface_selectors, :presence => true


  def match_filters(node)
    # Check to see if all of the supplied ConduitFilters match 
    found_match=true
    if !self.conduit_filters.nil?
      self.conduit_filters.each do |conduit_filter|
        if !conduit_filter.match(node)
          found_match=false
          break
        end
      end
    end
    found_match
  end


  def select_interfaces(node)
    # if_remap is a hash that maps "1g1" to "eth0", etc
    if_remap = ConduitRule.build_if_remap(node)

    ifs = []
    self.interface_selectors.each do |if_selector|

      interface = if_selector.select_interface(if_remap, node)
      next if interface.nil?

      ifs << interface
    end

    ifs
  end


  private

  MAX_INDEX = 999

  # This method finds the Bus object that contains a path that matches the
  # supplied path.  The supplied path comes from a discovered NIC.  The order
  # of the matched Bus object is returned.
  # bus_order is a list of Buses
  # path is a path string from the discovered NIC
  def self.bus_index(bus_order, path)
    return MAX_INDEX if bus_order.nil? or path.nil?

    dpath = path.split(".")[0].split("/")

    bus_order.each do |bus|
      subindex = 0
      bs = bus.path.split(".")[0].split("/")

      match = true
      bs.each do |bp|
        break if subindex >= dpath.size
        match = false if bp != dpath[subindex]
        break unless match
        subindex = subindex + 1
      end

      return bus.order if match
    end

    MAX_INDEX
  end
  
  def self.sort_ifs(node)
    bus_order = InterfaceMap.get_bus_order(node)

    nic_map = node.get_attrib("nics").value

    nics = nic_map.keys

    answer = nics.sort{|a,b|
      aindex = bus_index(bus_order, nic_map[a]["path"])
      bindex = bus_index(bus_order, nic_map[b]["path"])
      aindex == bindex ? a <=> b : aindex <=> bindex
    }
    answer
  end


  def self.build_if_remap(node)
    # Create a list of interfaces sorted by the bus order
    sorted_ifs = sort_ifs(node)

    # Create if_remap which maps "1g1" to a specific interface_name
    nic_map = node.get_attrib("nics").value
    if_remap = {}
    count_map = {}
    sorted_ifs.each do |intf|
      speeds = nic_map[intf]["speeds"]
      speeds = ['1g'] unless speeds   #legacy object support
      speeds.each do |speed|
        count = count_map[speed] || 1
        if_remap["#{speed}#{count}"] = intf
        count_map[speed] = count + 1
      end
    end
    if_remap
  end
end
