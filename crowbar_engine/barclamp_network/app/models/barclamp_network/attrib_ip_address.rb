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

class BarclampNetwork::AttribIpAddress < Attrib
  def state 
    Attrib.calc_state(value_actual , value_request, jig_run_id)
  end
  

  def request=(value)
    # Discard since this attribute is a facade over AR objects
    raise "Not implemented"
  end
  

  def request
    raise "Not implemented"
  end
  

  def actual=(value)
    # Discard since this attribute is a facade over AR objects
  end
  

  def actual(network_id="admin", deployment_id=BarclampNetwork::Barclamp::DEPLOYMENT_NAME,
             snapshot_type=BarclampNetwork::NetworkUtils::ACTIVE_SNAPSHOT)
    error_code, result = BarclampNetwork::NetworkUtils.find_network(
        network_id,
        deployment_id,
        snapshot_type)
    raise "#{error_code}: #{result}" if error_code != 200

    network = result

    results = BarclampNetwork::AllocatedIpAddress.joins(:interface).where("#{BarclampNetwork::TABLE_PREFIX}interfaces" => {:node_id => node.id}).where(:network_id => network.id)
    if results.length == 0
      raise "Node #{BarclampNetwork::NetworkUtils.log_name(node)} does not have an address allocated on Deployment/Snapshot #{BarclampNetwork::NetworkUtils.log_name(network.snapshot.deployment)}/#{BarclampNetwork::NetworkUtils.log_name(network.snapshot)} network #{BarclampNetwork::NetworkUtils.log_name(self)}"
    end

    results.first.ip
  end


  def value(network_id="admin", deployment_id=BarclampNetwork::Barclamp::DEPLOYMENT_NAME,
             snapshot_type=BarclampNetwork::NetworkUtils::ACTIVE_SNAPSHOT)
    return self.actual(network_id, deployment_id, snapshot_type)
  end
end
