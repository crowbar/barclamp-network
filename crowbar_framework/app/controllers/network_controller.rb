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
    raw_nodes = NodeObject.all
    raw_nodes.each do |node|
      @sum = @sum + node.name.hash
      @nodes[node.handle] = { :alias=>node.alias, :description=>node.description(false, true), :status=>node.status }
      #build groups
      group = node.group
      @groups[group] = { :automatic=>!node.display_set?('group'), :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{} } unless @groups.key? group
      @groups[group][:nodes][node.group_order] = node.handle
      @groups[group][:status][node.status] = (@groups[group][:status][node.status] || 0).to_i + 1
      #build switches
      node_nics(node).each do |key, value|
        @switches[key] = { :status=>{"ready"=>0, "failed"=>0, "unknown"=>0, "unready"=>0, "pending"=>0}, :nodes=>{}, :max_port=>24} unless @switches.key? key
        port = if value['switch_port'] == -1 or value['switch_port'] == "-1"
          @vports[key] = 1 + (@vports[key] || 0)
        else
          value['switch_port'].to_i
        end
        @switches[key][:max_port] = port if port>@switches[key][:max_port]
        @switches[key][:nodes][port] = node.handle
        @switches[key][:status][node.status] = (@switches[key][:status][node.status] || 0).to_i + 1
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
  end
  
  private 
  
  def node_nics(node)
    switches = {}
    begin
      if_list = node["crowbar_ohai"]["detected"]["network"] 
      if_list.each do |intf, details|
        raw = node["crowbar_ohai"]["switch_config"][intf]
        s_name = raw['switch_name'] || -1
        s_unit =  raw['switch_unit'] || -1
        if s_name == -1
          s_name = I18n.t('network.controller.virtual') + ":" + intf.split('.')[0]
          s_unit = nil
        end
        s_name= "#{s_name}:#{s_unit}" unless s_unit.nil?
        switches[s_name] = node["crowbar_ohai"]["switch_config"][intf]
      end
    rescue 
      Rails.logger.debug("could not build interface/switch list for #{node.name}")
    end
    switches
  end
  
end

