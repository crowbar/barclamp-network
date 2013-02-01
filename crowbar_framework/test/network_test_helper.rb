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

class NetworkTestHelper
  # Create a Network
  def self.create_a_network
    network = Network.new
    network.name = "fred"
    network.dhcp_enabled = true
    network.use_vlan = false
    network.subnet = IpAddress.create!( :cidr => "192.168.122.11/24" )
    network.conduit = create_or_get_conduit("intf0")
    network.router = create_a_router()
    network.ip_ranges << create_an_ip_range()
    network.proposal = create_or_get_proposal()
    network
  end
  
  
  # Create a Router
  def self.create_a_router
    router = Router.new()
    router.ip = IpAddress.new( :cidr => "192.168.124.1/24" )
    router.pref = 5
    router
  end

  
  # Create a conduit
  def self.create_or_get_conduit( conduit_name )
    conduits = Conduit.where( :name => conduit_name )
    if conduits.size == 0
      conduit = Conduit.new()
      conduit.name = conduit_name
      conduit.conduit_rules << create_a_conduit_rule()
      conduit.proposal = create_or_get_proposal()
    else
      conduit = conduits[0]
    end

    conduit
  end


  # Create a conduit filter
  def self.create_a_conduit_filter
    conduit_filter = ConduitFilter.new()
    conduit_filter.attr = "num_interfaces"
    conduit_filter.comparitor = "="
    conduit_filter.value = "2"
    conduit_filter
  end


  # Create a conduit rule
  def self.create_a_conduit_rule
    sbs = SelectBySpeed.new()
    sbs.comparitor = "="
    sbs.value = "1g"

    rule = ConduitRule.new()
    rule.conduit_filters << create_a_conduit_filter()
    rule.conduit_actions << create_a_conduit_action()
    rule.interface_selectors << sbs
    rule
  end


  # Create a conduit action
  def self.create_a_conduit_action
    create_bond = CreateBond.new()
    create_bond.team_mode = 6
    create_bond
  end
  
  
  # Create an IpRange
  def self.create_an_ip_range
    ip_range = IpRange.new( :name => "host" )
    ip = IpAddress.new( :cidr => "192.168.122.2" )
    ip_range.start_address = ip
    ip = IpAddress.new( :cidr => "192.168.122.5" )
    ip_range.end_address = ip
    ip_range
  end

  
  # Create an interface map
  def self.create_an_interface_map
    interface_map = InterfaceMap.new()

    interface_map.bus_maps << create_a_bus_map("PowerEdge C6145", { "1" => "0000:00/0000:00:04", "2" => "0000:00/0000:00:02" })
    interface_map.bus_maps << create_a_bus_map("PowerEdge R710", { "1" => "0000:00/0000:00:01", "2" => "0000:00/0000:00:03" })

    interface_map.proposal = create_or_get_proposal()
    interface_map
  end
  
  
  # Create a bus map
  def self.create_a_bus_map(pattern="PowerEdge C6145", bus_order={ "1" => "0000:00/0000:00:04", "2" => "0000:00/0000:00:02"})
    bus_map = BusMap.new( :pattern => pattern)
    bus_map.buses << create_buses(bus_order)
    bus_map
  end

  
  # Create a bus
  def self.create_a_bus(order="1", designator="0000:00/0000:00:01")
      Bus.new( :order => order, :designator => designator )
  end


  def self.create_buses(bus_order)
    buses=[]
    bus_order.each { |order, designator|
      buses << create_a_bus( order, designator )
    }
    buses
  end


  def self.create_or_get_proposal( proposal_name = "network_proposal" )
    proposal = nil

    proposals = Proposal.where( :name => proposal_name )
    if proposals.size == 0
      proposal = Proposal.new( :name=> proposal_name )
      proposal.save!
    else
      proposal = proposals[0]
    end

    proposal
  end


end
