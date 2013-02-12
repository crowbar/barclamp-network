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

class NetworkService < ServiceObject

  def apply_role_pre_chef_call(old_config, new_config, all_nodes)
    proposal = new_config.proposal

    # TODO Remove the below HACK and add code the retrieves the new network
    # json from the barclamp template

    # Start HACK
    new_json = read_new_network_json()
    attrs_config = new_json["attributes"]
    # End HACK

    populate_network_defaults( attrs_config["network"], proposal )
  end


  def self.read_new_network_json()
    fp = File.join(Rails.root,"..","barclamps","network","chef","data_bags","crowbar","bc-template-network-new.json")
    JSON.load File.open(fp, "r")
  end


  def populate_network_defaults( network_attrs_config, proposal )
    create_interface_map( network_attrs_config, proposal )
    create_conduits( network_attrs_config, proposal )
    create_networks( network_attrs_config, proposal )
  end


  def create_interface_map( network_attrs_config, proposal )
    interface_map = InterfaceMap.new()
    interface_map.proposal = proposal
    interface_map_config = network_attrs_config["interface_map"]
    interface_map_config.each { |bus_map_config|
      bus_map = BusMap.new()
      bus_map.pattern = bus_map_config["pattern"]
      interface_map.bus_maps << bus_map

      bus_index = 1
      bus_order_config = bus_map_config["bus_order"]
      bus_order_config.each { |bus_config|
        bus = Bus.new()
        bus.designator = bus_config
        bus.order = bus_index
        bus_index += 1
        bus_map.buses << bus
      }
    }

    interface_map.save!
    interface_map
  end


  def create_conduits( network_attrs_config, proposal )
    conduits_config = network_attrs_config["conduit_map"]
    conduits_config.each { |conduit_config|
      conduit = Conduit.new()
      conduit.proposal = proposal
      conduit.name = conduit_config["conduit_name"]

      conduit_rules_config = conduit_config["conduit_rules"]
      conduit_rules_config.each { |conduit_rule_config|
        conduit_rule = ConduitRule.new()
        conduit.conduit_rules << conduit_rule

        conduit_filters_config = conduit_rule_config["conduit_filters"]
        conduit_filters_config.each { |conduit_filter_name, conduit_filter_parms|
          conduit_filter = Object.const_get(conduit_filter_name).new()
          conduit_rule.conduit_filters << conduit_filter
          conduit_filter_parms.each { |param_name, param_value|
            conduit_filter.send( "#{param_name}=", param_value )
          }
          conduit_filter.save!
        }

        interface_selectors_config = conduit_rule_config["interface_selectors"]
        interface_selectors_config.each { |interface_selector_config|
          interface_selector_config.each { |interface_selector_name, interface_selector_parms|
            interface_selector = Object.const_get(interface_selector_name).new()
            conduit_rule.interface_selectors << interface_selector
            interface_selector_parms.each { |param_name, param_value|
              interface_selector.send( "#{param_name}=", param_value )
            }
            interface_selector.save!
          }
        }

        conduit_actions_config = conduit_rule_config["conduit_actions"]
        conduit_actions_config.each { |conduit_action_config|
          conduit_action_config.each { |conduit_action_name, conduit_action_parms|
            conduit_action = Object.const_get(conduit_action_name).new()
            conduit_rule.conduit_actions << conduit_action
            conduit_action_parms.each { |param_name, param_value|
              conduit_action.send( "#{param_name}=", param_value )
            }
            conduit_action.save!
          }
        }
        conduit_rule.save!
      }

      conduit.save!
    }
  end


  def create_networks( network_attrs_config, proposal )
    networks_config = network_attrs_config["networks"]
    networks_config.each { |network_name, network_config|
      network = Network.new()
      network.proposal = proposal
      network.name = network_name
      network_config.each { |param_name, param_value|
        case param_name
        when "conduit"
          network.conduit = ServiceObject.get_object(Conduit, param_value)
        when "use_vlan"
          network.use_vlan = param_value
        when "vlan"
          network.vlan = Vlan.new(:tag => param_value)
        when "subnet"
          network.subnet = IpAddress.new(:cidr => param_value)
        when "dhcp_enabled"
          network.dhcp_enabled = param_value
        when "router"
          network.router = Router.new() if network.router.nil?
          network.router.ip = IpAddress.new(:cidr => param_value)
        when "router_pref"
          network.router = Router.new() if network.router.nil?
          network.router.pref = param_value.to_i
        when "ranges"
          param_value.each { |range_name, range|
            ip_range = IpRange.new(:name => range_name)
            start_address = range["start"]
            ip_range.start_address = IpAddress.new(:cidr => start_address)
            end_address = range["end"]
            ip_range.end_address = IpAddress.new(:cidr => end_address)
            network.ip_ranges << ip_range
          }
        end
      }

      network.save!
    }
  end


  def allocate_ip(bc_instance, network, range, name, suggestion = nil)
    @logger.debug("Network allocate_ip: entering #{name} #{network} #{range}")

    return [404, "No network specified"] if network.nil?
    return [404, "No range specified"] if range.nil?
    return [404, "No name specified"] if name.nil?

    # Find the node
    node = NodeObject.find_node_by_name name
    @logger.error("Network allocate_ip: return node not found: #{name} #{network} #{range}") if node.nil?
    return [404, "No node found"] if node.nil?

    # Find an interface based upon config
    role = RoleObject.find_role_by_name "network-config-#{bc_instance}"
    @logger.error("Network allocate_ip: No network data found: #{name} #{network} #{range}") if role.nil?
    return [404, "No network data found"] if role.nil?

    # If we already have on allocated, return success
    unless node.address(network)
      @logger.error("Network allocate_ip: node already has address: #{name} #{network} #{range}")
      return [200, node[:crowbar][:network][network]]
    end

    net_info={}
    found = false
    CrowbarUtils.with_lock("ip") do
      begin # Rescue block
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
              @logger.error("Using suggestion: #{name} #{network} #{suggestion}")
              address = suggestion
              found = true
            end
          end
        end

        unless found
          # Did we already allocate this, but the node lose it?
          unless db["allocated_by_name"][node.name].nil?
            found = true
            address = db["allocated_by_name"][node.name]["address"]
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
          db["allocated_by_name"][node.name] = { "machine" => node.name, "interface" => net_info["conduit"], "address" => address.to_s }
          db["allocated"][address.to_s] = { "machine" => node.name, "interface" => net_info["conduit"], "address" => address.to_s }
          db.save
        end
      rescue Exception => e
        @logger.error("Error finding address: #{e.message}")
      end
    end

    @logger.info("Network allocate_ip: no address available: #{name} #{network} #{range}") if !found
    return [404, "No Address Available"] if !found

    # Save the information.
    node.crowbar["crowbar"]["network"][network] = net_info
    node.save

    @logger.info("Network allocate_ip: Assigned: #{name} #{network} #{range} #{net_info["address"]}")
    [200, net_info]
  end


  def network_allocate_ip(proposal_id, network_id, range, node_id, suggestion = nil)
    @logger.debug("Entering network_allocate_ip(proposal_id: #{proposal_id}, network_id: #{network_id}, range: #{range}, node_id: #{node_id}, suggestion: #{suggestion})")

    proposal_id = proposal_id.to_s
    proposal_id = nil if proposal_id.empty?

    # Validate inputs
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = ServiceObject.get_object_safe(Node, node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?

    # Find the proposal and network
    error_code, *rest = NetworkUtils.find_proposal_and_network(proposal_id, network_id)
    return [error_code, rest[0]] if error_code != 200
    proposal = rest[0]
    network = rest[1]

    network.allocate_ip(range, node, suggestion)
  end


  def deallocate_ip(bc_instance, network, name)
    @logger.debug("Network deallocate_ip: entering #{name} #{network}")

    return [404, "No network specified"] if network.nil?
    return [404, "No name specified"] if name.nil?

    # Find the node
    node = NodeObject.find_node_by_name name
    @logger.error("Network deallocate_ip: return node not found: #{name} #{network}") if node.nil?
    return [404, "No node found"] if node.nil?

    # Find an interface based upon config
    role = RoleObject.find_role_by_name "network-config-#{bc_instance}"
    @logger.error("Network allocate_ip: No network data found: #{name} #{network}") if role.nil?
    return [404, "No network data found"] if role.nil?

    # If we already have on allocated, return success
    net_info = node.get_network_by_type(network)
    if net_info.nil? or net_info["address"].nil?
      @logger.error("Network deallocate_ip: node does not have address: #{name} #{network}")
      return [200, nil]
    end

    save = false
    CrowbarUtils.with_lock("ip") do
      begin # Rescue block
        db = ProposalObject.find_data_bag_item "crowbar/#{network}_network"

        address = net_info["address"]
 
        # Did we already allocate this, but the node lose it?
        unless db["allocated_by_name"][node.name].nil?
          save = true

          newhash = {}
          db["allocated_by_name"].each do |k,v|
            newhash[k] = v unless k == node.name
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
      end
    end

    # Save the information.
    newhash = {} 
    node.crowbar["crowbar"]["network"].each do |k, v|
      newhash[k] = v unless k == network
    end
    node.crowbar["crowbar"]["network"] = newhash
    node.save

    @logger.info("Network deallocate_ip: removed: #{name} #{network}")
    [200, nil]
  end


  def network_deallocate_ip(proposal_id, network_id, node_id)
    @logger.debug("Entering network_deallocate_ip(proposal_id: #{proposal_id}, network_id: #{network_id}, node_id: #{node_id}")

    proposal_id = proposal_id.to_s
    proposal_id = nil if proposal_id.empty?
    
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = ServiceObject.get_object_safe(Node, node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?
    
    # Find the proposal and network
    error_code, *rest = NetworkUtils.find_proposal_and_network(proposal_id, network_id)
    return [error_code, rest[0]] if error_code != 200
    proposal = rest[0]
    network = rest[1]

    network.deallocate_ip(node)
  end


  def create_proposal(name)
    @logger.debug("Network create_proposal: entering")
    base = super(name)

    networks = base.current_config.config_hash["network"]["networks"] rescue nil
    unless networks
      @logger.warn("Network doesn't have any networks specified")
      network = {}
    end
    networks.each do |k,net|
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

    @logger.debug("Network create_proposal: exiting")
    base
  end

  def transition(inst, name, state)
    @logger.debug("Network transition: Entering #{name} for #{state}")

    if state == "discovered"
      node = Node.find_by_name(name)
      if node.is_admin?
        @logger.error("Admin node transitioning to discovered state.  Adding switch_config role.")
        result = add_role_to_instance_and_node(name, inst, "switch_config")
      end

      @logger.debug("Network transition: make sure that network role is on all nodes: #{name} for #{state}")
      result = add_role_to_instance_and_node(name, inst, "network")

      @logger.debug("Network transition: Exiting #{name} for #{state} discovered path")
      return [200, ""] if result
      return [400, "Failed to add role to node"] unless result
    end

    if state == "delete" or state == "reset"
      node = NodeObject.find_node_by_name name
      @logger.error("Network transition: return node not found: #{name}") if node.nil?
      return [404, "No node found"] if node.nil?

      nets = node.crowbar["crowbar"]["network"].keys
      nets.each do |net|
        ret, msg = self.deallocate_ip(inst, net, name)
        return [ ret, msg ] if ret != 200
      end
    end

    @logger.debug("Network transition: Exiting #{name} for #{state}")
    [200, ""]
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
    if node.interface(network)
      @logger.error("Network enable_interface: node already has address: #{name} #{network}")
      return [200, node[:crowbar][:network][network]]
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


  def network_enable_interface(proposal_id, network_id, node_id)
    @logger.debug("Entering network_enable_interface(proposal_id: #{proposal_id}, network_id: #{network_id}, node_id: #{node_id})")

    proposal_id = proposal_id.to_s
    proposal_id = nil if proposal_id.empty?
    
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = ServiceObject.get_object_safe(Node, node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?

    # Find the proposal and network
    error_code, *rest = NetworkUtils.find_proposal_and_network(proposal_id, network_id)
    return [error_code, rest[0]] if error_code != 200
    proposal = rest[0]
    network = rest[1]

    network.enable_interface(node)
  end


  def build_net_info(network, name, db = nil)
    db = ProposalObject.find_data_bag_item "crowbar/#{network}_network" unless db

    subnet = db["network"]["subnet"]
    vlan = db["network"]["vlan"]
    use_vlan = db["network"]["use_vlan"]
    add_bridge = db["network"]["add_bridge"]
    broadcast = db["network"]["broadcast"]
    router = db["network"]["router"]
    router_pref = db["network"]["router_pref"] unless db["network"]["router_pref"].nil?
    netmask = db["network"]["netmask"]
    conduit = db["network"]["conduit"]
    net_info = { 
      "conduit" => conduit, 
      "netmask" => netmask, "node" => name, "router" => router,
      "subnet" => subnet, "broadcast" => broadcast, "usage" => network, 
      "use_vlan" => use_vlan, "vlan" => vlan, "add_bridge" => add_bridge }
    net_info["router_pref"] = router_pref unless router_pref.nil?
    net_info
  end
  

  def network_get(id)
    begin
      [200, ServiceObject.get_object(Network, id)]
    rescue ActiveRecord::RecordNotFound => ex
      @logger.warn(ex.message)
      [404, ex.message]
    rescue RuntimeError => ex
      @logger.error(ex.message)
      [500, ex.message]
    end
  end


  def network_create(name, proposal_id, conduit_id, subnet, dhcp_enabled, use_vlan, ip_ranges, router_pref, router_ip)
    @logger.debug("Entering service network_create #{name}")

    network = nil
    begin
      Network.transaction do
        subnet = IpAddress.create!(:cidr => subnet)
        network = Network.new(
            :name => name,
            :dhcp_enabled => dhcp_enabled,
            :use_vlan => use_vlan)
        network.subnet = subnet
        network.proposal = ServiceObject.get_object_safe( Proposal, proposal_id ) if proposal_id != "-1"
        network.conduit = ServiceObject.get_object( Conduit, conduit_id )

        # Either both router_pref and router_ip are passed, or neither are
        if !((router_pref.nil? and router_ip.nil?) or
             (!router_pref.nil? and !router_ip.nil?))
          raise ArgumentError, "Both router_ip and router_pref must be specified"
        end

        if !router_pref.nil?
          network.router = create_router(router_pref, router_ip)
        end

        if ip_ranges.nil? || ip_ranges.size < 1
          raise ArgumentError, "At least one ip_range must be specified"
        end

        ip_ranges.each_pair { |ip_range_name, ip_range_hash|
          network.ip_ranges << create_ip_range( ip_range_name, ip_range_hash )
        }

        network.save!
      end

      [200, network]
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ArgumentError => ex
      @logger.warn(ex.message)
      [400, ex.message]
    rescue RuntimeError => ex
      @logger.error(ex.message)
      [500, ex.message]
    end
  end


  def network_update(id, conduit_id, subnet, dhcp_enabled, use_vlan, ip_ranges, router_pref, router_ip)
    @logger.debug("Entering service network_update #{id}")

    network = nil
    begin
      Network.transaction do
        network = ServiceObject.get_object( Network, id )
        conduit = ServiceObject.get_object( Conduit, conduit_id )
        if conduit.name != network.conduit.name
          @logger.debug("Updating conduit to #{conduit_id}")
          network.conduit = conduit
        end

        if network.subnet.cidr != subnet
          @logger.debug("Updating subnet to #{subnet}")
          network.subnet = IpAddress.new(:cidr => subnet)
        end

        if network.dhcp_enabled != dhcp_enabled
          @logger.debug("Updating dhcp_enabled to #{dhcp_enabled}")
          network.dhcp_enabled = dhcp_enabled
        end

        if network.use_vlan != use_vlan
          @logger.debug("Updating use_vlan to #{use_vlan}")
          network.use_vlan = use_vlan
        end

        if ip_ranges.nil? || ip_ranges.size < 1
          raise ArgumentError, "At least one ip_range must be specified"
        end

        ranges = {}
        network.ip_ranges.each { |range|
          ranges[range.name] = range
        }

        ip_ranges.each_pair { |ip_range_name, ip_range_hash|
          ip_range = ranges[ip_range_name]
          if ip_range.nil?
            network.ip_ranges << create_ip_range(ip_range_name, ip_range_hash)
          else
            ranges.delete( ip_range_name)

            start_ip_str = ip_range_hash["start"]
            if start_ip_str.nil? or start_ip_str.empty?
              raise ArgumentError, "The ip_range #{ip_range_name} is missing a \"start\" address."
            end
            if ip_range.start_address.cidr != start_ip_str
              @logger.debug("Setting starting address of ip_range #{ip_range_name} to #{start_ip_str}")
              ip_range.start_address.cidr = start_ip_str
              ip_range.start_address.save!
            end

            end_ip_str = ip_range_hash["end"]
            if end_ip_str.nil? or end_ip_str.empty?
              raise ArgumentError, "The ip_range #{ip_range_name} is missing an \"end\" address."
            end
            if ip_range.end_address.cidr != end_ip_str
              @logger.debug("Setting ending address of ip_range #{ip_range_name} to #{end_ip_str}")
              ip_range.end_address.cidr = end_ip_str
              ip_range.end_address.save!
            end
          end
        }

        ranges.each_pair { |range_name, range|
          @logger.debug("Destroying ip_range #{range_name}(#{range.id})")
          range.destroy
        }

        # Either both router_pref and router_ip are passed, or neither are
        if !((router_pref.nil? and router_ip.nil?) or
             (!router_pref.nil? and !router_ip.nil?))
          raise ArgumentError, "Both router_ip and router_pref must be specified"
        end

        if router_pref.nil? and !network.router.nil?
          @logger.debug("Deleting associated router #{network.router.id}")
          network.router.destroy
        elsif network.router.nil? and !router_pref.nil?
          @logger.debug("Creating associated router")
          network.router = create_router(router_pref, router_ip)
        else
          if network.router.pref != router_pref.to_i
            @logger.debug("Updating router_pref to #{router_pref.to_i}")
            network.router.pref = router_pref.to_i
            network.router.save!
          end

          if router_ip != network.router.ip.cidr
            @logger.debug("Updating router_ip to #{router_ip}")
            network.router.ip.cidr = router_ip
            network.router.ip.save!
          end
        end

        network.save!
      end

      [200, network]
    rescue ActiveRecord::RecordNotFound, ArgumentError => ex
      @logger.warn(ex.message)
      [400, ex.message]
    rescue RuntimeError => ex
      @logger.error(ex.message)
      [500, ex.message]
    end
  end


  def network_delete(id)
    @logger.debug("Entering service network_delete #{id}")

    begin
      network = ServiceObject.get_object(Network, id)

      @logger.debug("Deleting network #{network.id}/\"#{network.name}\"")
      network.destroy

      [200, ""]
    rescue ActiveRecord::RecordNotFound => ex
      @logger.warn(ex.message)
      [404, ex.message]
    rescue RuntimeError => ex
      @logger.error(ex.message)
      [500, ex.message]
    end
  end


  private
  def create_ip_range( ip_range_name, ip_range_hash )
    @logger.debug("Creating ip_range #{ip_range_name}")
    ip_range = IpRange.new( :name => ip_range_name )

    start_ip_str = ip_range_hash[ "start" ]
    if start_ip_str.nil? or start_ip_str.empty?
      raise ArgumentError, "The ip_range #{ip_range_name} is missing a \"start\" address."
    end
    @logger.debug("Creating start ip #{start_ip_str}")
    start_ip = IpAddress.create!( :cidr => start_ip_str )
    ip_range.start_address = start_ip

    end_ip_str = ip_range_hash[ "end" ]
    if end_ip_str.nil? or end_ip_str.empty?
      raise ArgumentError, "The ip_range #{ip_range_name} is missing an \"end\" address."
    end
    @logger.debug("Creating end ip #{end_ip_str}")
    end_ip = IpAddress.create!( :cidr => end_ip_str )
    ip_range.end_address = end_ip

    ip_range.save!
    ip_range
  end


  def create_router(router_pref, router_ip)
    router = Router.new( :pref => router_pref )

    @logger.debug("Creating router_ip #{router_ip}")
    router.ip = IpAddress.create!( :cidr => router_ip )

    router.save!
    router
  end
end
