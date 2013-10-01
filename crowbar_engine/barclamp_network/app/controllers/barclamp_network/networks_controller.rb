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
class BarclampNetwork::NetworksController < ::ApplicationController
  respond_to :html, :json

  add_help(:show,[:deployment_id, :network_id],[:get])
  def show
    @network = BarclampNetwork::Network.find_key params[:id]
    respond_to do |format|
      format.html { }
      format.json { render api_show :network, BarclampNetwork::Network, nil, nil, @network }
    end
  end
  
  def index
    @networks = BarclampNetwork::Network.all
    respond_to do |format|
      format.html {}
      format.json { render api_index :network, @networks }
    end
  end

  def create

    # cleanup inputs
    params[:use_vlan] = true if params[:vlan].to_int > 0 rescue false 
    params[:vlan] ||= 0
    params[:use_team] = true if params[:team].to_int > 0 rescue false
    params[:team_mode] ||= 5
    params[:use_bridge] = true if params[:use_bridge].to_int > 0 rescue false
    params[:deployment_id] = Deployment.find_key(params[:deployment]).id if params.has_key? :deployment
    BarclampNetwork::Network.transaction do

      @network = BarclampNetwork::Network.create! params
      # Add our IPv6 prefix.
      if (params[:v6prefix] == "auto") || (@network.name == "admin" && !params.key?("v6prefix"))
        BarclampNetwork::Setting.transaction do
          cluster_prefix = BarclampNetwork::Setting["v6prefix"]
          if cluster_prefix.nil?
            cluster_prefix = BarclampNetwork::Network.make_global_v6prefix
            BarclampNetwork::Setting["v6prefix"] = cluster_prefix
          end
          max = BarclampNetwork::Network.count rescue 1
          @network.v6prefix = sprintf("#{cluster_prefix}:%04x",max)
          @network.save!
        end
      end

      # make it easier to batch create
      if params.key? :ranges
        ranges = params[:ranges].is_a?(String) ? JSON.parse(params[:ranges]) : params[:ranges]
        ranges.each do |range|
          range[:network_id] = @network.id
          BarclampNetwork::Range.create! range
        end
        params.delete :ranges
      end

      # make it easier to batch create
      if params.key? :router
        router = router.is_a?(String) ? JSON.parse(params[:router]) : params[:router]
        router[:network_id] = @network.id
        BarclampNetwork::Router.create! router
        params.delete :router
      end

    end

    respond_to do |format|
      format.html { }
      format.json { render api_show :network, BarclampNetwork::Network, @network.id.to_s, nil, @network }
    end

  end

  # Allocations for a node in a network.
  # Includes the automatic IPv6 address.
  def allocations
    network = BarclampNetwork::Network.find_key params[:id]
    raise "Must include a node parameter" unless params.key?(:node)
    nodename = params[:node]
    if nodename.is_a?(String) && nodename == "admin"
      node = Node.admin.where(:available => true).first
    else
      node = Node.find_key nodename
    end
    render :json => network.node_allocations(node).map{|a|a.to_s}
  end
  
  add_help(:update,[:id, :conduit,:team_mode, :use_team],[:put])
  def update
    @network = BarclampNetwork::Network.find_key(params[:id])
    params.delete :name if params.key? :name   # not allowed to update name!!
    # Only allow teaming and conduit stuff to be updated for now.
    @network.team_mode = params[:team_mode] if params.has_key?(:team_mode)
    @network.conduit = params[:conduit] if params.has_key?(:conduit)
    @network.use_team = params[:use_team] if params.has_key?(:use_team)
    @network.description = params[:description] if params.has_key?(:description)
    @network.order = params[:order] if params.has_key?(:order)
    @network.conduit = params[:conduit] if params.has_key?(:conduit)
    @network.save
    respond_with(@network) do |format|
      format.html { render :action=>:show } 
      format.json { render api_show :network, BarclampNetwork::Network, nil, nil, @network }
    end
  end

  def destroy
    if Rails.env.development?
      render api_delete BarclampNetwork::Network
    else
      render api_not_supported("delete", "BarclampNetwork::Network")
    end
  end

  def ip
    if request.post?
      allocate_ip
    elsif request.delete?
      deallocate_ip
    end
  end
      
  def allocate_ip
    network = BarclampNetwork::Network.find_key(params[:id])
    node = Node.find_key(params[:node_id])
    range = network.ranges.where(:name => params[:range]).first
    suggestion = params[:suggestion]

    ret = range.allocate(node,suggestion)
    render :json => ret
  end

  def deallocate_ip
    raise ArgumentError.new("Cannot deallocate addresses for now")
    node = Node.find_key(params[:node_id])
    allocation = BarclampNetwork::Allocation.where(:address => params[:cidr], :node_id => node.id)
    allocation.destroy
  end

  def enable_interface
    raise ArgumentError.new("Cannot enable interfaces without IP address allocation for now.")
    
    deployment_id = params[:deployment_id]
    deployment_id = nil if deployment_id == "-1"
    network_id = params[:id]
    node_id = params[:node_id]

    ret = @barclamp.network_enable_interface(deployment_id, network_id, node_id)
    return render :text => ret[1], :status => ret[0] if ret[0] != 200
    render :json => ret[1]
  end

  def edit
    @network = BarclampNetwork::Network.find_key params[:id]
    respond_to do |format|
      format.html {  }
    end
  end

end
