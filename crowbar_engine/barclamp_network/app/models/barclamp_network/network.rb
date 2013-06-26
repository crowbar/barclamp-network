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

  has_many :allocated_ips, :dependent => :destroy, :class_name => "BarclampNetwork::AllocatedIpAddress"

  has_one :subnet, :foreign_key => "subnet_id", :dependent => :destroy, :class_name => "BarclampNetwork::IpAddress"
  belongs_to :conduit, :inverse_of => :networks, :class_name => "BarclampNetwork::Conduit"
  has_one :router, :inverse_of => :network, :dependent => :destroy, :class_name => "BarclampNetwork::Router"
  has_many :ip_ranges, :dependent => :destroy, :class_name => "BarclampNetwork::IpRange"
  has_many :node_refs, :dependent => :destroy
  has_and_belongs_to_many :interfaces, :join_table => "#{BarclampNetwork::TABLE_PREFIX}interfaces_networks", :class_name => "BarclampNetwork::Interface"
  has_many :network_actions, :dependent => :destroy, :class_name => "BarclampNetwork::ConfigAction"

  # attr_accessible :name, :dhcp_enabled

  validates :name, :presence => true
  validates_uniqueness_of :name, :scope => :snapshot_id
  validates_inclusion_of :dhcp_enabled, :in => [true, false]
  validates :subnet, :presence => true
  validates :ip_ranges, :presence => true
  #validates :snapshot, :presence => true


  def allocate_ip(range, node, suggestion = nil)
    logger.debug("Entering Network#{BarclampNetwork::NetworkUtils.log_name(self)}.allocate_ip(range: #{range}, node: #{BarclampNetwork::NetworkUtils.log_name(node)}, suggestion: #{suggestion}")

    # Validate inputs
    return [400, "No range specified"] if range.nil?
    return [400, "No node specified"] if node.nil?

    # If the node already has an IP on this network then just return success
    results = BarclampNetwork::AllocatedIpAddress.where(:node_id => node.id).where(:network_id => id)
    if results.length > 0
      allocated_ip = results.first.ip
      logger.info("Network.allocate_ip: node #{BarclampNetwork::NetworkUtils.log_name(node)} already has address #{allocated_ip} on network #{BarclampNetwork::NetworkUtils.log_name(self)}, range #{range}")
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
          logger.info("Using suggestion: node #{BarclampNetwork::NetworkUtils.log_name(node)}, network #{BarclampNetwork::NetworkUtils.log_name(self)} #{suggestion}")
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
          BarclampNetwork::AllocatedIpAddress.transaction do
            ip_addr = BarclampNetwork::AllocatedIpAddress.new( :ip => address.to_s )
            ip_addr.node = node
            ip_addr.network = self
            ip_addr.save!

            node_ref = BarclampNetwork::NodeRef.new()
            node_ref.node = node
            node_ref.network = self
            node_ref.save!

            node.set_attrib("ip_address", nil, 0, BarclampNetwork::AttribIpAddress)
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
      logger.error("Network.allocate_ip: retries exceeded while allocating IP address for node #{BarclampNetwork::NetworkUtils.log_name(node)} network #{BarclampNetwork::NetworkUtils.log_name(self)} range #{range}")
      return [404, "Unable to allocate IP address due to retries exceeded"]
    end

    logger.info("Network.allocate_ip: Assigned: node #{node.id}, network #{id}, range #{range}, ip #{address}")
    [200, net_info]
  end
    

  def deallocate_ip(node)
    # Validate inputs
    return [400, "No node specified"] if node.nil?

    node_ref = BarclampNetwork::NodeRef.where(:node_id => node.id).where(:network_id => self.id)[0]
    node_ref.destroy if !node_ref.nil?

    # If we don't have one allocated, return success
    results = BarclampNetwork::AllocatedIpAddress.where(:node_id => node.id).where(:network_id => id)
    if results.length == 0
      logger.warn("Network.deallocate_ip: node #{BarclampNetwork::NetworkUtils.log_name(node)} does not have an address allocated on network #{BarclampNetwork::NetworkUtils.log_name(self)}")
      return [200, nil]
    end

    allocated_ip = results.first
    allocated_ip.destroy

    logger.info("Network.deallocate_ip: deallocated ip #{allocated_ip.ip} for node #{BarclampNetwork::NetworkUtils.log_name(node)} on network #{BarclampNetwork::NetworkUtils.log_name(self)}")
    
    [200, nil]
  end


  def enable_interface(node)
    net_info = build_net_info(node)

    # If we already have an enabled interface then return success
    node_ref = BarclampNetwork::NodeRef.where(:node_id => node.id).where(:network_id => self.id)
    if !node_ref.nil?
      logger.info("Network.enable_interface: node #{BarclampNetwork::NetworkUtils.log_name(node)} already has an enabled interface on network #{BarclampNetwork::NetworkUtils.log_name(self)}")
      return [200, net_info]
    end

    node_ref = BarclampNetwork::NodeRef.new()
    node_ref.node = node
    node_ref.network = self
    node_ref.save!

    logger.info("Network.enable_interface: Enabled interface: node #{node.id}, network #{id}")
    [200, net_info]
  end


  def self.get_networks_hash(node)
    networks = BarclampNetwork::Network.joins(:node_ref).where(:node_id => node.id)

    networks_hash = {}
    networks.each { |network|
      networks_hash[network.name] = network.to_hash()
    }

    networks_hash
  end


  def to_hash()
    network_hash = {}

    add_bridge = "false"
    create_vlan = nil
    self.network_actions.each { |network_action|
      if network_action.instance_of? BarclampNetwork::CreateBridge
        add_bridge = "true"
      elsif network_action.instance_of? BarclampNetwork::CreateVlan
        create_vlan = network_action
      end
    }

    network_hash["add_bridge"] = add_bridge

    if create_vlan.nil?
      network_hash["use_vlan"] = "false"
      network_hash["vlan"] = "100"
    else
      network_hash["use_vlan"] = "true"
      network_hash["vlan"] = create_vlan.tag.to_s
    end

    network_hash["conduit"] = self.conduit.name

    router = self.router
    if !router.nil?
      network_hash["router"] = router.ip.get_ip()
      network_hash["router_pref"] = router.router_pref
    end

    network_hash["subnet"] = subnet.get_ip()
    network_hash["netmask"] = subnet.get_netmask().to_s
    network_hash["broadcast"] = subnet.get_broadcast().to_s

    ip_ranges_hash = {}
    self.ip_ranges.each { |ip_range|
      ip_ranges_hash[ip_range.name] = ip_range.to_hash()
    }

    network_hash["ranges"] = ip_ranges_hash
    network_hash
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
      "usage" => name }
    net_info["router_pref"] = "#{router_pref}" unless router_pref.nil?
    net_info
  end
end
