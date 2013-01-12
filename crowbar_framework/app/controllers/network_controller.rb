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
 
  add_help(:network_list,[],[:get])
  def networks
    Rails.logger.debug("Listing networks");

    network_refs = []

    Network.all.each { |network|
      network_refs << network.id
    }

    respond_to do |format|
      format.json { render :json => network_refs }
      format.xml { render :xml => network_refs }
    end
  end

  add_help(:network_show,[:id],[:get])
  def network_show
    id = params[:id]

    Rails.logger.debug("Showing network #{id}")

    ret = operations.network_get(id)

    return render :text => ret[1], :status => ret[0] if ret[0] != 200

    respond_to do |format|
      format.json { render :json => ret[1].to_json( :include => {:subnet => {:only => :cidr}, :router => {:only => :pref, :include => {:ip => {:only => :cidr}}}, :ip_ranges => {:only => :name, :include => {:start_address => {:only => :cidr}, :end_address => {:only => :cidr}}}})}
    end
  end

  add_help(:network_create,[:name, :proposal_id, :conduit_id, :subnet, :dhcp_enabled, :use_vlan, :ip_ranges, :router_pref, :router_ip],[:post])
  def network_create
    name = params[:name]
    proposal_id = params[:proposal_id]
    conduit_id = params[:conduit_id]
    subnet = params[:subnet]
    dhcp_enabled = to_bool( params[:dhcp_enabled] )
    use_vlan = to_bool( params[:use_vlan] )
    ip_ranges = params[:ip_ranges]
    router_pref = params[:router_pref]
    router_ip = params[:router_ip]

    Rails.logger.debug("Creating network #{name}");

    ret = operations.network_create(name, proposal_id, conduit_id, subnet, dhcp_enabled, use_vlan, ip_ranges, router_pref, router_ip)

    return render :text => ret[1], :status => ret[0] if ret[0] != 200

    respond_to do |format|
      format.json { render :json => ret[1].to_json( :include => {:subnet => {:only => :cidr}, :router => {:only => :pref, :include => {:ip => {:only => :cidr}}}, :ip_ranges => {:only => :name, :include => {:start_address => {:only => :cidr}, :end_address => {:only => :cidr}}}})}
    end
  end

  add_help(:network_update,[:id, :conduit_id, :subnet, :dhcp_enabled, :use_vlan, :ip_ranges, :router_pref, :router_ip],[:put])
  def network_update
    id = params[:id]
    conduit_id = params[:conduit_id]
    subnet = params[:subnet]
    dhcp_enabled = to_bool( params[:dhcp_enabled] )
    use_vlan = to_bool( params[:use_vlan] )
    ip_ranges = params[:ip_ranges]
    router_pref = params[:router_pref]
    router_ip = params[:router_ip]

    Rails.logger.debug("Updating network #{id}");

    ret = operations.network_update(id, conduit_id, subnet, dhcp_enabled, use_vlan, ip_ranges, router_pref, router_ip)

    return render :text => ret[1], :status => ret[0] if ret[0] != 200

    respond_to do |format|
      format.json { render :json => ret[1].to_json( :include => {:subnet => {:only => :cidr}, :router => {:only => :pref, :include => {:ip => {:only => :cidr}}}, :ip_ranges => {:only => :name, :include => {:start_address => {:only => :cidr}, :end_address => {:only => :cidr}}}})}
    end
  end

  add_help(:network_delete,[:id],[:delete])
  def network_delete
    Rails.logger.debug("Deleting network #{params[:id]}");

    ret = operations.network_delete(params[:id])
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  add_help(:allocate_ip,[:id,:network,:range,:name],[:post])
  def allocate_ip
    id = params[:id]       # Network id
    network = params[:network]
    range = params[:range]
    name = params[:name]
    suggestion = params[:suggestion]

    ret = operations.allocate_ip(id, network, range, name, suggestion)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  add_help(:network_allocate_ip,[:id,:network_id,:node_id,:range],[:post])
  def network_allocate_ip
    proposal_id = params[:id]
    proposal_id = nil if proposal_id == "-1"
    network_id = params[:network_id]
    node_id = params[:node_id]
    range = params[:range]
    suggestion = params[:suggestion]

    ret = operations.network_allocate_ip(proposal_id, network_id, range, node_id, suggestion)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end
  
  add_help(:deallocate_ip,[:id,:network,:name],[:post])
  def deallocate_ip
    id = params[:id]       # Network id
    network = params[:network]
    name = params[:name]

    ret = operations.deallocate_ip(id, network, name)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  add_help(:network_deallocate_ip,[:id,:network_id,:node_id],[:delete])
  def network_deallocate_ip
    proposal_id = params[:id]
    proposal_id = nil if proposal_id == "-1"
    network_id = params[:network_id]
    node_id = params[:node_id]

    ret = operations.network_deallocate_ip(proposal_id, network_id, node_id)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end
  
  add_help(:enable_interface,[:id,:network,:name],[:post])
  def enable_interface
    id = params[:id]       # Network id
    network = params[:network]
    name = params[:name]

    ret = operations.enable_interface(id, network, name)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  add_help(:disable_interface,[:id,:network,:name],[:post])
  def disable_interface
    id = params[:id]       # Network id
    network = params[:network]
    name = params[:name]

    ret = operations.disable_interface(id, network, name)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  def switch
    @vports = {}
    @sum = 0
    @groups = {}
    @switches = {}
    @nodes = {}
    @port_start = 1
    nodes = (params[:node] ? NodeObject.find_nodes_by_name(params[:node]) : NodeObject.all)
    nodes.each do |node|
      @sum = @sum + node.name.hash
      @nodes[node.name] = { :alias=>node.alias, :description=>node.description(false, true), :status=>node.status }
      #build groups
      group = node.group
      @groups[group] = { :automatic=>!node.display_set?('group'), :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{} } unless @groups.key? group
      @groups[group][:nodes][node.group_order] = node.name
      @groups[group][:status][node.status] = (@groups[group][:status][node.status] || 0).to_i + 1
      #build switches
      node_nics(node).each do |switch|
        key = switch[:switch]
        if key
          @switches[key] = { :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{}, :max_port=>(23+@port_start)} unless @switches.key? key
          port = if switch['switch_port'] == -1 or switch['switch_port'] == "-1"
            @vports[key] = 1 + (@vports[key] || 0)
          else
            switch[:port]
          end
          @port_start = 0 if port == 0
          @switches[key][:max_port] = port if port>@switches[key][:max_port]
          @switches[key][:nodes][port] = { :handle=>node.name, :intf=>switch[:intf] }
          @switches[key][:status][node.status] = (@switches[key][:status][node.status] || 0).to_i + 1
        end
      end
    end
    #make sure port max is even
    flash[:notice] = "<b>#{I18n.t :warning, :scope => :error}:</b> #{I18n.t :no_nodes_found, :scope => :error}".html_safe if @nodes.empty?
  end

  def vlan
    net_bc = RoleObject.find_role_by_name 'network-config-default'
    if net_bc.barclamp == 'network'
      @vlans = net_bc.default_attributes['network']['networks']
    end
    @nodes = {}
    NodeObject.all.each do |node|
      @nodes[node.name] = { :alias=>node.alias, :description=>node.description(false, true), :vlans=>{} }
      @nodes[node.name][:vlans] = node_vlans(node)
    end
    
  end
  
  def nodes

    net_bc = RoleObject.find_role_by_name 'network-config-default'
    @modes = []
    @active_mode = @mode = net_bc.default_attributes['network']['mode']
    # first, we need a mode list
    net_bc.default_attributes['network']['conduit_map'].each do |conduit| 
      mode = conduit['pattern'].split('/')[0]
      @modes << mode unless @modes.include? mode
      @mode = params[:mode] if @modes.include? params[:mode]
    end
    # now we need to complete conduit list for the mode (we have to inspect all conduits!)
    @conduits = []
    net_bc.default_attributes['network']['conduit_map'].each do |conduit| 
      mode = conduit['pattern'].split('/')[0]
      conduit['conduit_list'].each { |c, details| @conduits << c unless @conduits.include? c } if mode == @mode
    end
            
    @nodes = {}
    NodeObject.all.each do |node|
      @nodes[node.name] = {:alias=>node.alias, :description=>node.description, :model=>node.hardware, :bus=>node.get_bus_order, :conduits=>node.build_node_map }
    end
    @conduits = @conduits.sort
    
  end
    
  private 
  def to_bool(value)
    return true if value == true || value =~ /^true|t$/i
    return false if value == false || value =~ /^false|f$/i
    raise ArgumentError.new("Invalid boolean value")
  end    
  
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
      if_list = node.crowbar_ohai["detected"]["network"].keys
      # this is a virtual switch if ALL the interfaces are virtual
      physical = if_list.map{ |intf| node.crowbar_ohai["switch_config"][intf]['switch_name'] != '-1' }.include? false
      if_list.each do | intf |
        connected = !physical #if virtual, then all ports are connected
        raw = node.crowbar_ohai["switch_config"][intf]
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
