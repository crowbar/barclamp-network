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
class BarclampNetwork::RangesController < ::ApplicationController
  respond_to :json

  def index
    network =  BarclampNetwork::Network.find_key params[:network_id]
    respond_to do |format|
      format.json { render api_index :range, network.ranges }
    end
  end

  def show
    network =  BarclampNetwork::Network.find_key params[:network_id]
    range = network.ranges.find_key(params[:id]) rescue nil
    respond_to do |format|
      format.json { render api_show :range, BarclampNetwork::Range, nil, nil, range }
    end
  end

  def create
    params[:network_id] = BarclampNetwork::Network.find_key(params[:network]).id if params.has_key? :network
    @range = BarclampNetwork::Range.new
    @range.first = params[:new_first]
    @range.last = params[:new_last]
    @range.name = params[:name]
    @range.network_id = params[:network_id]
    @range.save!
    respond_to do |format|
      format.json { render api_show :range, BarclampNetwork::Range, @range.id.to_s, nil, @range }
    end

  end

  def update
    respond_to do |format|
      format.json { render api_update :range, BarclampNetwork::Range }
    end
  end

end
