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
  def self.find_proposal_and_network(proposal_id, network_id)
    # Find the proposal
    proposal = nil
    unless proposal_id.nil?
      proposal = Proposal.find_key(proposal_id)
      return [404, "There is no proposal with proposal_id #{proposal_id}"] if proposal.nil?
    end

    # Find the network
    if proposal.nil?
      network = Network.find_key(network_id)
      return [404, "There is no network with network_id #{network_id}"] if network.nil?
      proposal = network.proposal
    else
      # We have a proposal
      # If a network ID was passed, then look up the network by that ID
      if Network.db_id?(network_id)
        begin
          network = Network.find(network_id)
        rescue ActiveRecord::RecordNotFound => ex
          return [404, ex.message]
        end

        # Do a consistency check to make sure that the found network is
        # associated with the specified proposal
        if network.proposal_id != proposal.id
          return [400, "Proposal #{proposal_id} is not associated with network #{network_id}"]
        end
      else
        # network_id is a name, so look up the network by proposal ID and network name
        network = Network.where("proposal_id = ? AND name = ?", proposal.id, network_id ).first
        return [404, "There is no network with proposal_id #{proposal_id} and name #{network_id}"] if network.nil?
      end
    end

    [200, proposal, network]
  end


  def self.log_name(object)
    return "(nil/nil)" if object.nil?
    "(#{object.object_id}/#{object.name})"
  end
end
