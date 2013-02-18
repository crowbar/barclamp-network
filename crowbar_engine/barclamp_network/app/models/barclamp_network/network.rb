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

class BarclampNetwork::Network < ActiveRecord::Base
  attr_protected :id

  has_many :allocated_ips, :class_name => "AllocatedIpAddress", :dependent => :nullify

  has_one :subnet, :foreign_key => "subnet_id", :class_name => "IpAddress", :dependent => :destroy
  belongs_to :conduit, :inverse_of => :networks
  has_one :router, :inverse_of => :network, :dependent => :destroy
  has_many :ip_ranges, :dependent => :destroy
  belongs_to :proposal
  has_one :vlan, :inverse_of => :network, :dependent => :destroy
  has_and_belongs_to_many :interfaces

  # attr_accessible :name, :dhcp_enabled, :use_vlan

  validates_uniqueness_of :name, :presence => true, :scope => :proposal_id
  validates :use_vlan, :inclusion => { :in => [true, false] }
  validates :dhcp_enabled, :inclusion => { :in => [true, false] }
  validates :subnet, :presence => true
  validates :ip_ranges, :presence => true
  #validates :proposal, :presence => true


  def allocate_ip(range, node, suggestion = nil)
    logger.debug("Entering Network#{NetworkUtils.log_name(self)}.allocate_ip(range: #{range}, node: #{NetworkUtils.log_name(node)}, suggestion: #{suggestion}")

    # Validate inputs
    return [400, "No range specified"] if range.nil?
    return [400, "No node specified"] if node.nil?

    # If the node already has an IP on this network then just return success
    results = AllocatedIpAddress.joins(:interface).where(:interfaces => {:node_id => node.id}).where(:network_id => id)
    if results.length > 0
      allocated_ip = results.first.ip
      logger.info("Network.allocate_ip: node #{NetworkUtils.log_name(node)} already has address #{allocated_ip} on network #{NetworkUtils.log_name(self)}, range #{range}")
      net_info = build_net_info(node)
      net_info["address"] = allocated_ip
      return [200, net_info]
    end

    subnet_addr = IPAddr.new(subnet.cidr)
    netmask_addr = subnet.get_netmask()

    # Find the ip range
    ip_range = ip_ranges.where(:name => range).first
    return [404, "IP range not found"] if ip_range.nil?

    index = IPAddr.new(ip_range.start_address.get_ip) & ~netmask_addr
    index = index.to_i
    stop_address = IPAddr.new(ip_range.end_address.get_ip) & ~netmask_addr
    stop_address = subnet_addr | (stop_address.to_i + 1)
    address = subnet_addr | index

    logger.debug("Starting address: #{address.to_s}")

    if suggestion
      logger.info("Allocating with suggestion: #{suggestion}")
      subsug = IPAddr.new(suggestion) & netmask_addr
      if subnet_addr == subsug
        if allocated_ips.where(:ip => suggestion).length == 0
          logger.info("Using suggestion: node #{NetworkUtils.log_name(node)}, network #{NetworkUtils.log_name(self)} #{suggestion}")
          address = suggestion
          found = true
        end
      end
    end

    allocation_successful = false
    tries=5
    while !allocation_successful and tries>0
      if !found
        # Snag all the allocated IPs for this network and convert to a hash
        ips={}
        for allocated_ip in allocated_ips(true) do
          ips[allocated_ip.ip] = true
        end

        while !found do
          unless ips.key?(address.to_s)
            found = true
            break
          end
          index = index + 1
          address = subnet_addr | index
          break if address == stop_address
        end
      end

      if found
        begin
          AllocatedIpAddress.transaction do
            ip_addr = AllocatedIpAddress.new( :ip => address.to_s )
            ip_addr.network = self

            node.set_attrib("ip_address", nil, 0, AttribInstanceIpAddress)

            # TODO - Interfaces should be discovered, not created on the fly
            interfaces = Interface.where( "node_id = ?", node.id )
            logger.debug("Found #{interfaces.size} interfaces")
            interface = nil
            if interfaces.size == 0
              interface = PhysicalInterface.new(:name => "eth0")
              interface.node = node
              interface.networks << self
              interface.save!
              logger.debug("Created interface #{interface.id}")
            else
              interface = interfaces[0]
            end
            ip_addr.interface = interface
            ip_addr.save!
          end

          allocation_successful = true
          net_info = build_net_info(node)
          net_info["address"] = address.to_s
        rescue ActiveRecord::RecordNotUnique => ex
          found = false
          tries -= 1
          logger.warn("#{address.to_s} has already been allocated.  Retrying...")
        end
      else
        logger.info("Network.allocate_ip: no addresses available: node #{node.id}, network #{id}, range #{range}")
        return [404, "No addresses available"]
      end
    end

    if !found and tries == 0
      logger.error("Network.allocate_ip: retries exceeded while allocating IP address for node #{NetworkUtils.log_name(node)} network #{NetworkUtils.log_name(self)} range #{range}")
      return [404, "Unable to allocate IP address due to retries exceeded"]
    end

    logger.info("Network.allocate_ip: Assigned: node #{node.id}, network #{id}, range #{range}, ip #{address}")
    [200, net_info]
  end
    

  def deallocate_ip(node)
    # Validate inputs
    return [400, "No node specified"] if node.nil?

    # If we don't have one allocated, return success
    results = AllocatedIpAddress.joins(:interface).where(:interfaces => {:node_id => node.id}).where(:network_id => id)
    if results.length == 0
      logger.warn("Network.deallocate_ip: node #{NetworkUtils.log_name(node)} does not have an address allocated on network #{NetworkUtils.log_name(self)}")
      return [200, nil]
    end

    allocated_ip = results.first
    allocated_ip.destroy

    logger.info("Network.deallocate_ip: deallocated ip #{allocated_ip.ip} for node #{NetworkUtils.log_name(node)} on network #{NetworkUtils.log_name(self)}")
    
    [200, nil]
  end


  def enable_interface(node)
    net_info = build_net_info(node)

    # If we already have an enabled inteface then return success
    intf = Interface.where(:node_id => node.id).first
    if !intf.nil? and intf.networks.where( :id => id).exists?
      logger.info("Network.enable_interface: node #{NetworkUtils.log_name(node)} already has an enabled interface on network #{NetworkUtils.log_name(self)}")
      return [200, net_info]
    end

    # TODO: Remove this hack when interfaces are discovered
    interface = PhysicalInterface.new(:name => "eth0")
    interface.node = node
    interface.networks << self
    interface.save!

    logger.info("Network.enable_interface: Enabled interface: node #{node.id}, network #{id}")
    [200, net_info]
  end


  def build_net_info(node)
    unless router.nil?
      router_addr = router.ip.get_ip
      router_pref = router.pref
    end

    net_info = { 
      "conduit" => conduit.name,
      "netmask" => subnet.get_netmask().to_s,
      "node" => node.name,
      "router" => router_addr,
      "subnet" => subnet.get_ip,
      "broadcast" => subnet.get_broadcast().to_s,
      "usage" => name, 
      "use_vlan" => "#{use_vlan}",
      "vlan" => vlan.nil? ? "" :"#{vlan.tag}" }
    net_info["router_pref"] = "#{router_pref}" unless router_pref.nil?
    net_info
  end
end
