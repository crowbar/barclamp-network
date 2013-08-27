# Copyright 2011, Dell
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

class NetworkService < ServiceObject

  def initialize(thelogger)
    @bc_name = "network"
    @logger = thelogger
  end

  def acquire_ip_lock
    acquire_lock "ip"
  end

  def release_ip_lock(f)
    release_lock f
  end


  def allocate_ip_by_type(bc_instance, network, range, object, type, suggestion = nil)
    @logger.debug("Network allocate ip for #{type}: entering #{object} #{network} #{range}")
    return [404, "No network specified"] if network.nil?
    return [404, "No range specified"] if range.nil?
    return [404, "No object specified"] if object.nil?
    return [404, "No type specified"] if type.nil?

    if type == :node
      node = NodeObject.find_node_by_name object
      @logger.error("Network allocate ip from node: return node not found: #{object} #{network}") if node.nil?
      return [404, "No node found"] if node.nil?
      name = node.name.to_s
    else
      name = object.to_s
    end

    role = RoleObject.find_role_by_name "network-config-#{bc_instance}"
    @logger.error("Network allocate ip by type: No network data found: #{object} #{network} #{range}") if role.nil?
    return [404, "No network data found"] if role.nil?

    net_info = {}
    found = false
    begin
      f = acquire_ip_lock
      db = ProposalObject.find_data_bag_item "crowbar/#{network}_network"
      net_info = build_net_info(network, name, db)

      rangeH = db["network"]["ranges"][range]
      rangeH = db["network"]["ranges"]["host"] if rangeH.nil?

      index = IPAddr.new(rangeH["start"]) & ~IPAddr.new(net_info["netmask"])
      index = index.to_i
      stop_address = IPAddr.new(rangeH["end"]) & ~IPAddr.new(net_info["netmask"])
      stop_address = IPAddr.new(net_info["subnet"]) | (stop_address.to_i + 1)
      address = IPAddr.new(net_info["subnet"]) | index

      if suggestion
        @logger.error("Allocating with suggestion: #{suggestion}")
        subsug = IPAddr.new(suggestion) & IPAddr.new(net_info["netmask"])
        subnet = IPAddr.new(net_info["subnet"]) & IPAddr.new(net_info["netmask"])
        if subnet == subsug
          if db["allocated"][suggestion].nil?
            @logger.error("Using suggestion for #{type}: #{name} #{network} #{suggestion}")
            address = suggestion
            found = true
          end
        end
      end

      unless found
        # Did we already allocate this, but the node lose it?
        unless db["allocated_by_name"][name].nil?
          found = true
          address = db["allocated_by_name"][name]["address"]
        end
      end


      # Let's search for an empty one.
      while !found do
        if db["allocated"][address.to_s].nil?
          found = true
          break
        end
        index = index + 1
        address = IPAddr.new(net_info["subnet"]) | index
        break if address == stop_address
      end


      if found
        net_info["address"] = address.to_s
        db["allocated_by_name"][name] = { "machine" => name, "interface" => net_info["conduit"], "address" => address.to_s }
        db["allocated"][address.to_s] = { "machine" => name, "interface" => net_info["conduit"], "address" => address.to_s }
        db.save
      end
    rescue Exception => e
      @logger.error("Error finding address: #{e.message}")
    ensure
      release_ip_lock(f)
    end

    @logger.info("Network allocate ip for #{type}: no address available: #{name} #{network} #{range}") if !found
    return [404, "No Address Available"] if !found

    if type == :node
      # Save the information.
      node.crowbar["crowbar"]["network"][network] = net_info
      node.save
    end

    @logger.info("Network allocate ip for #{type}: Assigned: #{name} #{network} #{range} #{net_info["address"]}")
    [200, net_info]
  end

  def allocate_virtual_ip(bc_instance, network, range, service, suggestion = nil)
    allocate_ip_by_type(bc_instance, network, range, service, :virtual, suggestion)
  end

  def allocate_ip(bc_instance, network, range, name, suggestion = nil)
    allocate_ip_by_type(bc_instance, network, range, name, :node, suggestion)
  end

  def deallocate_ip_by_type(bc_instance, network, object, type)
    @logger.debug("Network deallocate ip from #{type}: entering #{object} #{network}")

    return [404, "No network specified"] if network.nil?
    return [404, "No type specified"] if type.nil?
    return [404, "No object specified"] if object.nil?

    if type == :node
      # Find the node
      node = NodeObject.find_node_by_name object
      @logger.error("Network deallocate ip from node: return node not found: #{object} #{network}") if node.nil?
      return [404, "No node found"] if node.nil?
    end

    # Find an interface based upon config
    role = RoleObject.find_role_by_name "network-config-#{bc_instance}"
    @logger.error("Network deallocate ip from #{type}: No network data found: #{object} #{network}") if role.nil?
    return [404, "No network data found"] if role.nil?

    db = ProposalObject.find_data_bag_item "crowbar/#{network}_network"

    if type == :node
      # If we already have on allocated, return success
      net_info = node.get_network_by_type(network)
      if net_info.nil? or net_info["address"].nil?
        @logger.error("Network deallocate ip from #{type}: node does not have address: #{object} #{network}")
        return [200, nil]
      end
      name = node.name
    else
      name = object
    end
    if db.nil?
      return [404, "Network deallocate ip from #{type}: network does not exists: #{object} #{network}"]
    end

    save = false
    begin # Rescue block
      f = acquire_ip_lock

      address = type == :node ? net_info["address"] : nil

      # Did we already allocate this, but the node lose it?
      unless db["allocated_by_name"][name].nil?
        save = true

        newhash = {}
        db["allocated_by_name"].each do |k,v|
          unless k == name
            newhash[k] = v
          else
            address = v["address"]
          end
        end
        db["allocated_by_name"] = newhash
      end

      unless db["allocated"][address.to_s].nil?
        save = true
        newhash = {}
        db["allocated"].each do |k,v|
          newhash[k] = v unless k == address.to_s
        end
        db["allocated"] = newhash
      end

      if save
        db.save
      end
    rescue Exception => e
      @logger.error("Error finding address: #{e.message}")
    ensure
      release_ip_lock(f)
    end

    if type == :node
      # Save the information.
      newhash = {}
      node.crowbar["crowbar"]["network"].each do |k, v|
        newhash[k] = v unless k == network
      end
      node.crowbar["crowbar"]["network"] = newhash
      node.save
    end
    @logger.info("Network deallocate_ip: removed: #{name} #{network}")
    [200, nil]
  end

  def deallocate_virtual_ip(bc_instance, network, name)
    deallocate_ip_by_type(bc_instance, network, name, :virtual)
  end

  def deallocate_ip(bc_instance, network, name)
    deallocate_ip_by_type(bc_instance, network, name, :node)
  end

  def create_proposal
    @logger.debug("Network create_proposal: entering")
    base = super

    @logger.debug("Network create_proposal: exiting")
    base
  end

  def apply_role_pre_chef_call(old_role, role, all_nodes)
    @logger.debug("Network apply_role_pre_chef_call: entering #{all_nodes.inspect}")

    role.default_attributes["network"]["networks"].each do |k,net|
      db = ProposalObject.find_data_bag_item "crowbar/#{k}_network"
      if db.nil?
        @logger.debug("Network: creating #{k} in the network")
        bc = Chef::DataBagItem.new
        bc.data_bag "crowbar"
        bc["id"] = "#{k}_network"
        bc["network"] = net
        bc["allocated"] = {}
        bc["allocated_by_name"] = {}
        db = ProposalObject.new bc
        db.save
      end
    end

    @logger.debug("Network apply_role_pre_chef_call: leaving")
  end

  def transition(inst, name, state)
    @logger.debug("Network transition: Entering #{name} for #{state}")

    if state == "discovered"

      db = ProposalObject.find_proposal "network", inst
      role = RoleObject.find_role_by_name "network-config-#{inst}"
      if NodeObject.find_node_by_name(name).try(:[], 'crowbar').try(:[], 'admin_node')
        @logger.error("Admin node transitioning to discovered state.  Adding switch_config role.")
        result = add_role_to_instance_and_node("network", inst, name, db, role, "switch_config")
      end

      @logger.debug("Network transition: make sure that network role is on all nodes: #{name} for #{state}")
      result = add_role_to_instance_and_node("network", inst, name, db, role, "network")

      @logger.debug("Network transition: Exiting #{name} for #{state} discovered path")
      return [200, NodeObject.find_node_by_name(name).to_hash] if result
      return [400, "Failed to add role to node"] unless result
    end

    if state == "delete" or state == "reset"
      node = NodeObject.find_node_by_name name
      @logger.error("Network transition: return node not found: #{name}") if node.nil?
      return [404, "No node found"] if node.nil?

      nets = node.crowbar["crowbar"]["network"].keys
      nets.each do |net|
        next if net == "admin"
        ret, msg = self.deallocate_ip(inst, net, name)
        return [ ret, msg ] if ret != 200
      end
    end

    @logger.debug("Network transition: Exiting #{name} for #{state}")
    [200, NodeObject.find_node_by_name(name).to_hash]
  end

  def enable_interface(bc_instance, network, name)
    @logger.debug("Network enable_interface: entering #{name} #{network}")

    return [404, "No network specified"] if network.nil?
    return [404, "No name specified"] if name.nil?

    # Find the node
    node = NodeObject.find_node_by_name name
    @logger.error("Network enable_interface: return node not found: #{name} #{network}") if node.nil?
    return [404, "No node found"] if node.nil?

    # Find an interface based upon config
    role = RoleObject.find_role_by_name "network-config-#{bc_instance}"
    @logger.error("Network enable_interface: No network data found: #{name} #{network}") if role.nil?
    return [404, "No network data found"] if role.nil?

    # If we already have on allocated, return success
    net_info = node.get_network_by_type(network)
    unless net_info.nil?
      @logger.error("Network enable_interface: node already has address: #{name} #{network}")
      return [200, net_info]
    end

    net_info={}
    begin # Rescue block
      net_info = build_net_info(network, name)
    rescue Exception => e
      @logger.error("Error finding address: #{e.message}")
    ensure
    end

    # Save the information.
    node.crowbar["crowbar"]["network"][network] = net_info
    node.save

    @logger.info("Network enable_interface: Assigned: #{name} #{network}")
    [200, net_info]
  end


  def build_net_info(network, name, db = nil)
    db = ProposalObject.find_data_bag_item "crowbar/#{network}_network" unless db

    net_info = {}
    db["network"].each { |k,v|
      net_info[k] = v unless v.nil?
    }
    net_info["usage"]= network
    net_info["node"] = name
    net_info
  end

end
