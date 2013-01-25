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

class AttribInstanceIpAddress < AttribInstance
  def state 
    AttribInstance.calc_state(value_actual , value_request, jig_run_id)
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
  

  def actual(proposal="default", network="admin")
    error_code, *rest = NetworkUtils.find_proposal_and_network(proposal, network)
    raise "#{error_code}: #{rest[0]}" if error_code != 200

    proposal = rest[0]
    network = rest[1]

    results = AllocatedIpAddress.joins(:interface).where(:interfaces => {:node_id => node.id}).where(:network_id => network.id)
    if results.length == 0
      raise "Node #{NetworkUtils.log_name(node)} does not have an address allocated on network #{log_name(self)}"
    end

    results.first.ip
  end
end
