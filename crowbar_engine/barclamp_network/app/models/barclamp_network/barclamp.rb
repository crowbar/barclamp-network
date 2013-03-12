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

class BarclampNetwork::Barclamp < Barclamp
  def after_initialize
    allow_multiple_proposals = false
  end


  BARCLAMP_NAME = "network"


  def create_deployment(deployment_name=nil)
    deployment = super

    json = BarclampNetwork::Barclamp.read_network_json()
    attrs_config = json["attributes"]

    populate_network_defaults( attrs_config["network"], deployment.proposed_snapshot )
    deployment
  end


  def self.read_network_json()
    fp = File.join(Rails.root,"..","barclamps","network","bc-template-network.json")
    JSON.load File.open(fp, "r")
  end


  def network_allocate_ip(deployment_id, network_id, range, node_id, suggestion = nil)
    Rails.logger.debug("Entering allocate_ip(deployment_id: #{deployment_id}, network_id: #{network_id}, range: #{range}, node_id: #{node_id}, suggestion: #{suggestion})")

    deployment_id = deployment_id.to_s
    deployment_id = nil if deployment_id.empty?

    # Validate inputs
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = Node.find_key(node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?

    # Find the network
    error_code, result = BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
    return [error_code, result] if error_code != 200
    network = result

    network.allocate_ip(range, node, suggestion)
  end


  def network_deallocate_ip(deployment_id, network_id, node_id)
    Rails.logger.debug("Entering deallocate_ip(deployment_id: #{deployment_id}, network_id: #{network_id}, node_id: #{node_id}")

    deployment_id = deployment_id.to_s
    deployment_id = nil if deployment_id.empty?
    
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = Node.find_key(node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?
    
    # Find the Deployment and Network
    error_code, result = BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
    return [error_code, result] if error_code != 200
    network = result

    network.deallocate_ip(node)
  end


  def transition(inst, name, state)
    Rails.logger.debug("Network transition: Entering #{name} for #{state}")

    if state == "discovered"
      node = Node.find_by_name(name)
      if node.is_admin?
        Rails.logger.error("Admin node transitioning to discovered state.  Adding switch_config role.")
        result = add_role_to_instance_and_node(name, inst, "switch_config")
      end

      Rails.logger.debug("Network transition: make sure that network role is on all nodes: #{name} for #{state}")
      result = add_role_to_instance_and_node(name, inst, "network")

      Rails.logger.debug("Network transition: Exiting #{name} for #{state} discovered path")
      return [200, ""] if result
      return [400, "Failed to add role to node"] unless result
    end

    if state == "delete" or state == "reset"
      node = NodeObject.find_node_by_name name
      Rails.logger.error("Network transition: return node not found: #{name}") if node.nil?
      return [404, "No node found"] if node.nil?

      nets = node.crowbar["crowbar"]["network"].keys
      nets.each do |net|
        ret, msg = self.deallocate_ip(inst, net, name)
        return [ ret, msg ] if ret != 200
      end
    end

    Rails.logger.debug("Network transition: Exiting #{name} for #{state}")
    [200, ""]
  end


  def network_enable_interface(deployment_id, network_id, node_id)
    Rails.logger.debug("Entering enable_interface(deployment_id: #{deployment_id}, network_id: #{network_id}, node_id: #{node_id})")

    deployment_id = deployment_id.to_s
    deployment_id = nil if deployment_id.empty?
    
    return [400, "No network_id specified"] if network_id.nil?
    return [400, "No node_id specified"] if node_id.nil?

    # Find the node
    node = Node.find_key(node_id)
    return [404, "Node #{node_id} does not exist"] if node.nil?

    # Find the network
    error_code, result = BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
    return [error_code, result] if error_code != 200
    network = result

    network.enable_interface(node)
  end


  def network_get(deployment_id, network_id)
    BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
  end


  def network_create(deployment_id, name, conduit_id, subnet, dhcp_enabled, ip_ranges, router_pref, router_ip)
    Rails.logger.debug("Entering network_create #{name}")

    network = nil
    begin
      BarclampNetwork::Network.transaction do
        subnet = BarclampNetwork::IpAddress.create!(:cidr => subnet)
        network = BarclampNetwork::Network.new(
            :name => name,
            :dhcp_enabled => dhcp_enabled)
        network.subnet = subnet

        deployment = Deployment.find_key(deployment_id)
        raise ArgumentError, "There is no Deployment with an id of #{deployment_id}" if deployment.nil?
        network.snapshot = deployment.proposed_snapshot

        conduit = BarclampNetwork::Conduit.find_key(conduit_id)
        raise ArgumentError, "There is no Conduit with an id of #{conduit_id}" if conduit.nil?
        network.conduit = conduit

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
      Rails.logger.warn(ex.message)
      [400, ex.message]
    rescue RuntimeError => ex
      Rails.logger.error(ex.message)
      [500, ex.message]
    end
  end


  def network_update(deployment_id, network_id, conduit_id, subnet, dhcp_enabled, ip_ranges, router_pref, router_ip)
    Rails.logger.debug("Entering update_network #{id}")

    network = nil
    begin
      BarclampNetwork::Network.transaction do
        error_code, result = BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
        return [error_code, result] if error_code != 200
        network = result

        conduit = BarclampNetwork::Conduit.find_key(conduit_id)
        if conduit.nil?
          return [400, "Update of network #{id} failed because conduit #{conduit_id} does not exist"]
        end

        if conduit.name != network.conduit.name
          Rails.logger.debug("Updating conduit to #{conduit_id}")
          network.conduit = conduit
        end

        if network.subnet.cidr != subnet
          Rails.logger.debug("Updating subnet to #{subnet}")
          network.subnet = BarclampNetwork::IpAddress.new(:cidr => subnet)
        end

        if network.dhcp_enabled != dhcp_enabled
          Rails.logger.debug("Updating dhcp_enabled to #{dhcp_enabled}")
          network.dhcp_enabled = dhcp_enabled
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
              Rails.logger.debug("Setting starting address of ip_range #{ip_range_name} to #{start_ip_str}")
              ip_range.start_address.cidr = start_ip_str
              ip_range.start_address.save!
            end

            end_ip_str = ip_range_hash["end"]
            if end_ip_str.nil? or end_ip_str.empty?
              raise ArgumentError, "The ip_range #{ip_range_name} is missing an \"end\" address."
            end
            if ip_range.end_address.cidr != end_ip_str
              Rails.logger.debug("Setting ending address of ip_range #{ip_range_name} to #{end_ip_str}")
              ip_range.end_address.cidr = end_ip_str
              ip_range.end_address.save!
            end
          end
        }

        ranges.each_pair { |range_name, range|
          Rails.logger.debug("Destroying ip_range #{range_name}(#{range.id})")
          range.destroy
        }

        # Either both router_pref and router_ip are passed, or neither are
        if !((router_pref.nil? and router_ip.nil?) or
             (!router_pref.nil? and !router_ip.nil?))
          raise ArgumentError, "Both router_ip and router_pref must be specified"
        end

        if router_pref.nil? and !network.router.nil?
          Rails.logger.debug("Deleting associated router #{network.router.id}")
          network.router.destroy
        elsif network.router.nil? and !router_pref.nil?
          Rails.logger.debug("Creating associated router")
          network.router = create_router(router_pref, router_ip)
        else
          if network.router.pref != router_pref.to_i
            Rails.logger.debug("Updating router_pref to #{router_pref.to_i}")
            network.router.pref = router_pref.to_i
            network.router.save!
          end

          if router_ip != network.router.ip.cidr
            Rails.logger.debug("Updating router_ip to #{router_ip}")
            network.router.ip.cidr = router_ip
            network.router.ip.save!
          end
        end

        network.save!
      end

      [200, network]
    rescue ActiveRecord::RecordNotFound, ArgumentError => ex
      Rails.logger.warn(ex.message)
      [400, ex.message]
    rescue RuntimeError => ex
      Rails.logger.error(ex.message)
      [500, ex.message]
    end
  end


  def network_destroy(deployment_id, network_id)
    begin
      error_code, result = BarclampNetwork::NetworkUtils.find_network(network_id, deployment_id)
      return [error_code, result] if error_code != 200
      network = result

      Rails.logger.debug("Destroying network #{network.id}/\"#{network.name}\"")
      network.destroy
      [200, ""]
    rescue RuntimeError => ex
      Rails.logger.error(ex.message)
      [500, ex.message]
    end
  end


  private
  def create_ip_range( ip_range_name, ip_range_hash )
    Rails.logger.debug("Creating ip_range #{ip_range_name}")
    ip_range = BarclampNetwork::IpRange.new( :name => ip_range_name )

    start_ip_str = ip_range_hash[ "start" ]
    if start_ip_str.nil? or start_ip_str.empty?
      raise ArgumentError, "The ip_range #{ip_range_name} is missing a \"start\" address."
    end
    Rails.logger.debug("Creating start ip #{start_ip_str}")
    start_ip = BarclampNetwork::IpAddress.create!( :cidr => start_ip_str )
    ip_range.start_address = start_ip

    end_ip_str = ip_range_hash[ "end" ]
    if end_ip_str.nil? or end_ip_str.empty?
      raise ArgumentError, "The ip_range #{ip_range_name} is missing an \"end\" address."
    end
    Rails.logger.debug("Creating end ip #{end_ip_str}")
    end_ip = BarclampNetwork::IpAddress.create!( :cidr => end_ip_str )
    ip_range.end_address = end_ip

    ip_range.save!
    ip_range
  end


  def create_router(router_pref, router_ip)
    router = BarclampNetwork::Router.new( :pref => router_pref )

    Rails.logger.debug("Creating router_ip #{router_ip}")
    router.ip = BarclampNetwork::IpAddress.create!( :cidr => router_ip )

    router.save!
    router
  end


  def populate_network_defaults( network_attrs_config, snapshot )
    create_interface_map( network_attrs_config, snapshot )
    create_conduits( network_attrs_config, snapshot )
    create_networks( network_attrs_config, snapshot )
  end


  def create_interface_map( network_attrs_config, snapshot )
    interface_map = BarclampNetwork::InterfaceMap.new()
    interface_map.snapshot = snapshot
    interface_map_config = network_attrs_config["interface_map"]
    interface_map_config.each { |bus_map_config|
      bus_map = BarclampNetwork::BusMap.new()
      bus_map.pattern = bus_map_config["pattern"]
      interface_map.bus_maps << bus_map

      bus_index = 0
      bus_order_config = bus_map_config["bus_order"]
      bus_order_config.each { |bus_config|
        bus = BarclampNetwork::Bus.new()
        bus.path = bus_config
        bus.order = bus_index
        bus_index += 1
        bus_map.buses << bus
      }
    }

    interface_map.save!
    interface_map
  end


  def create_conduits( network_attrs_config, snapshot )
    conduits_config = network_attrs_config["conduit_map"]
    conduits_config.each { |conduit_config|
      conduit = BarclampNetwork::Conduit.new()
      conduit.snapshot = snapshot
      conduit.name = conduit_config["conduit_name"]

      conduit_rules_config = conduit_config["conduit_rules"]
      conduit_rules_config.each { |conduit_rule_config|
        conduit_rule = BarclampNetwork::ConduitRule.new()
        conduit.conduit_rules << conduit_rule

        conduit_filters_config = conduit_rule_config["conduit_filters"]
        conduit_filters_config.each { |conduit_filter_name, conduit_filter_parms|
          conduit_filter = BarclampNetwork.const_get(conduit_filter_name).new()
          conduit_rule.conduit_filters << conduit_filter
          conduit_filter_parms.each { |param_name, param_value|
            conduit_filter.send( "#{param_name}=", param_value )
          }
          conduit_filter.save!
        }

        interface_selectors_config = conduit_rule_config["interface_selectors"]
        interface_selectors_config.each { |interface_selector_config|
          interface_selector = BarclampNetwork::InterfaceSelector.new()
          conduit_rule.interface_selectors << interface_selector

          interface_selector_config.each { |selector_name, selector_parms|
            selector = BarclampNetwork.const_get(selector_name).new()
            interface_selector.selectors << selector
            selector_parms.each { |param_name, param_value|
              selector.send( "#{param_name}=", param_value )
            }
            selector.save!
          }
          interface_selector.save!
        }

        conduit_actions_config = conduit_rule_config["conduit_actions"]
        conduit_actions = BarclampNetwork::ConfigAction.create_actions(conduit_actions_config)
        conduit_rule.conduit_actions << conduit_actions
        conduit_rule.save!
      }

      conduit.save!
    }
  end


  def create_networks( network_attrs_config, snapshot )
    networks_config = network_attrs_config["networks"]
    networks_config.each { |network_name, network_config|
      network = BarclampNetwork::Network.new()
      network.snapshot = snapshot
      network.name = network_name
      network_config.each { |param_name, param_value|
        case param_name
        when "conduit"
          network.conduit = BarclampNetwork::Conduit.find_key(param_value)
        when "vlan"
          network.vlan = BarclampNetwork::Vlan.new(:tag => param_value)
        when "subnet"
          network.subnet = BarclampNetwork::IpAddress.new(:cidr => param_value)
        when "dhcp_enabled"
          network.dhcp_enabled = param_value
        when "router"
          network.router = BarclampNetwork::Router.new() if network.router.nil?
          network.router.ip = BarclampNetwork::IpAddress.new(:cidr => param_value)
        when "router_pref"
          network.router = BarclampNetwork::Router.new() if network.router.nil?
          network.router.pref = param_value.to_i
        when "ranges"
          param_value.each { |range_name, range|
            ip_range = BarclampNetwork::IpRange.new(:name => range_name)
            start_address = range["start"]
            ip_range.start_address = BarclampNetwork::IpAddress.new(:cidr => start_address)
            end_address = range["end"]
            ip_range.end_address = BarclampNetwork::IpAddress.new(:cidr => end_address)
            network.ip_ranges << ip_range
          }
        when "network_actions"
          network_actions = BarclampNetwork::ConfigAction.create_actions(param_value)
          network.network_actions << network_actions
        end
      }

      network.save!
    }
  end
end
