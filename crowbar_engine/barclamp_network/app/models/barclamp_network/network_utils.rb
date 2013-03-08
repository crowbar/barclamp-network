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

class BarclampNetwork::NetworkUtils

  ACTIVE_SNAPSHOT = 0
  PROPOSED_SNAPSHOT = 1


  def self.find_network(
      network_id,
      deployment_id = Barclamp::DEFAULT_DEPLOYMENT_NAME,
      snapshot_type = PROPOSED_SNAPSHOT)

    # If the passed deployment_id is a DB ID then...
    if Deployment.db_id?(deployment_id)
      # Do a straight lookup on the deployment
      deployment = Deployment.find_key(deployment_id)
    else
      # The deployment_id must be a name, and deployment names are only unique
      # within a given barclamp, so first get the barclamp
      barclamp = BarclampNetwork::Barclamp.find_key(BarclampNetwork::Barclamp::BARCLAMP_NAME)
      deployment = Deployment.where("barclamp_id = ? AND name = ?", barclamp.id, deployment_id).first
    end

    return [404, "There is no Deployment with id #{deployment_id}"] if deployment.nil?

    # If there is no proposed, then return the active one instead
    snapshot_type = ACTIVE_SNAPSHOT if snapshot_type == PROPOSED_SNAPSHOT && deployment.proposed_snapshot.nil?
    snapshot = (snapshot_type == ACTIVE_SNAPSHOT ? deployment.active :  deployment.proposed)

    return [404, "There is no active snapshot"] if snapshot.nil?

    # If a network ID was passed, then look up the network by that ID
    if BarclampNetwork::Network.db_id?(network_id)
      begin
        network = BarclampNetwork::Network.find(network_id)
      rescue ActiveRecord::RecordNotFound => ex
        return [404, ex.message]
      end

      # Do a consistency check to make sure that the found network is
      # associated with the appropriate Snapshot
      if network.snapshot.id != snapshot.id
        return [400, "Deployment/Instance #{log_name(deployment)}/#{log_name(snapshot)} is not associated with network #{log_name(network)}"]
      end
    else
      # network_id is a name, so look up the network by Snapshot ID and network name
      network = BarclampNetwork::Network.where("snapshot_id = ? AND name = ?", snapshot.id, network_id).first
      return [404, "There is no network #{network_id} with Deployment/Instance #{log_name(deployment)}/#{log_name(snapshot)}"] if network.nil?
    end

    [200, network]
  end
  
 def self.get_networks(
    deployment_id = Barclamp::DEFAULT_DEPLOYMENT_NAME,
    snapshot_type = PROPOSED_SNAPSHOT)

    networks = nil
    net_bc_id = BarclampNetwork::Barclamp.find_key("network").id

    # Find the barclamp config
    deployment = Deployment.find_key(deployment_id)
    return [404, "There is no Deployment with id #{deployment_id}"] if deployment.nil?

    # If there is no proposed, then return the active one instead
    snapshot_type = ACTIVE_SNAPSHOT if snapshot_type == PROPOSED_SNAPSHOT && deployment.proposed_snapshot.nil?
    snapshot = (snapshot_type == ACTIVE_SNAPSHOT ? deployment.active :  deployment.proposed)

    return [404, "There is no active snapshot"] if snapshot.nil?

    begin
      networks = BarclampNetwork::Network.find_all_by_snapshot_id(snapshot.id)
    rescue ActiveRecord::RecordNotFound => ex
      return [404, ex.message]
    end

    if networks.nil? || networks.size == 0
      return [400, "Deployment/Instance #{log_name(deployment)} doesn't have any networks."]
    end

    [200, networks]
  end


  def self.log_name(object)
    return "nil(nil)" if object.nil?
    "#{object.name}(#{object.object_id})"
  end
end
