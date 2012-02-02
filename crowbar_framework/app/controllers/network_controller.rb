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

class NetworkController < BarclampController
  # Make a copy of the barclamp controller help
  self.help_contents = Array.new(superclass.help_contents)
  def initialize
    @service_object = NetworkService.new logger
  end

  # Below here handles ip address assignment.
  add_help(:allocate_ip,[:id,:network,:range,:name],[:post])
  def allocate_ip
    id = params[:id]       # Network id
    network = params[:network]
    range = params[:range]
    name = params[:name]

    ret = @service_object.allocate_ip(id, network, range, name)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  # Below here handles ip address assignment.
  add_help(:enable_interface,[:id,:network,:name],[:post])
  def enable_interface
    id = params[:id]       # Network id
    network = params[:network]
    name = params[:name]

    ret = @service_object.enable_interface(id, network, name)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  def switch
    @vports = {}
    @sum = 0
    @groups = {}
    @switches = {}
    @nodes = {}
    nodes = (params[:name] ? NodeObject.find_nodes_by_name(params[:name]) : NodeObject.all)
    nodes.each do |node|
      @sum = @sum + node.name.hash
      @nodes[node.handle] = { :alias=>node.alias, :description=>node.description(false, true), :status=>node.status }
      #build groups
      group = node.group
      @groups[group] = { :automatic=>!node.display_set?('group'), :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{} } unless @groups.key? group
      @groups[group][:nodes][node.group_order] = node.handle
      @groups[group][:status][node.status] = (@groups[group][:status][node.status] || 0).to_i + 1
      #build switches
      node_nics(node).each do |switch|
        key = switch[:switch]
        if key
          @switches[key] = { :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{}, :max_port=>24} unless @switches.key? key
          port = if switch['switch_port'] == -1 or switch['switch_port'] == "-1"
            @vports[key] = 1 + (@vports[key] || 0)
          else
            switch[:port]
          end
          @switches[key][:max_port] = port if port>@switches[key][:max_port]
          @switches[key][:nodes][port] = { :handle=>node.handle, :intf=>switch[:intf] }
          @switches[key][:status][node.status] = (@switches[key][:status][node.status] || 0).to_i + 1
        end
      end
    end
    #make sure port max is even
    flash[:notice] = "<b>#{I18n.t :warning, :scope => :error}:</b> #{I18n.t :no_nodes_found, :scope => :error}" if @nodes.empty? #.html_safe if @nodes.empty?
  end

  def vlan
    net_bc = RoleObject.find_role_by_name 'network-config-default'
    if net_bc.barclamp == 'network'
      @vlans = net_bc.default_attributes['network']['networks']
    end
    @nodes = {}
    NodeObject.all.each do |node|
      @nodes[node.handle] = { :alias=>node.alias, :description=>node.description(false, true), :vlans=>{} }
      @nodes[node.handle][:vlans] = node_vlans(node)
    end
    
  end
  
  private 
  
#  "network":{"bmc":{"address":"192.168.124.174","netmask":"255.255.255.0","add_bridge":false,"usage":"bmc","node":"d00-26-6c-f2-85-84.dell.com","router":null,"broadcast":"192.168.124.255","vlan":100,"subnet":"192.168.124.0","use_vlan":false,"conduit":"bmc"},"admin":{"add_bridge":false,"netmask":"255.255.255.0","address":"192.168.124.92","usage":"admin","router":"192.168.124.1","node":"d00-26-6c-f2-85-84.dell.com","broadcast":"192.168.124.255","vlan":100,"use_vlan":false,"subnet":"192.168.124.0","conduit":"intf0"}},
  
  def node_vlans(node)
    nv = {}
    vlans = node["crowbar"]["network"].each do |vlan, vdetails|
      nv[vlan] = { :address => vdetails["address"], :active=>vdetails["use_vlan"] }
    end
    nv
  end
  
  def node_nics(node)
    switches = []
    begin
      # list the interfaces
      if_list = node["crowbar_ohai"]["detected"]["network"].keys
      # this is a virtual switch if ALL the interfaces are virtual
      physical = if_list.map{ |intf| node["crowbar_ohai"]["switch_config"][intf]['switch_name'] != '-1' }.include? true
      if_list.each do | intf |
        connected = !physical #if virtual, then all ports are connected
        raw = node["crowbar_ohai"]["switch_config"][intf]
        s_name = raw['switch_name'] || -1
        s_unit =  raw['switch_unit'] || -1
        if s_name == -1 or s_name == "-1"
          s_name = I18n.t('network.controller.virtual') + ":" + intf.split('.')[0]
          s_unit = nil
        else
          connected = true
        end
        if connected
          s_name= "#{s_name}:#{s_unit}" unless s_unit.nil?
          switches << { :switch=>s_name, :intf=>intf, :port=>raw['switch_port'].to_i }
        end
      end
    rescue Exception=>e
      Rails.logger.debug("could not build interface/switch list for #{node.name} due to #{e.message}")
    end
    switches
  end
  
end

