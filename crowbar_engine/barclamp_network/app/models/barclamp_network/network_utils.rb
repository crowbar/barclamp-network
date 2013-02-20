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

  ACTIVE_BARCLAMP_INSTANCE = 0
  PROPOSED_BARCLAMP_INSTANCE = 1


  def self.find_network(
      network_id,
      barclamp_config_id = DEFAULT_BARCLAMP_CONFIG_NAME,
      barclamp_instance_type = PROPOSED_BARCLAMP_INSTANCE)

    barclamp_config_id = DEFAULT_BARCLAMP_CONFIG_NAME if barclamp_config_id.nil?

    # Find the barclamp config
    barclamp_config = BarclampConfiguration.find_key(barclamp_config_id)
    return [404, "There is no BarclampConfiguration with id #{barclamp_config_id}"] if barclamp_config.nil?

    # If there is no proposed, then return the active one instead
    barclamp_instance_type = ACTIVE_BARCLAMP_INSTANCE if barclamp_instance_type == PROPOSED_BARCLAMP_INSTANCE && barclamp.config.proposed.nil?
    barclamp_instance = (barclamp_instance_type == ACTIVE_BARCLAMP_INSTANCE ? barclamp_config.active :  barclamp_config.proposed)

    # If a network ID was passed, then look up the network by that ID
    if Network.db_id?(network_id)
      begin
        network = Network.find(network_id)
      rescue ActiveRecord::RecordNotFound => ex
        return [404, ex.message]
      end

      # Do a consistency check to make sure that the found network is
      # associated with the appropriate BarclampInstance
      if network.barclamp_instance.id != barclamp_instance.id
        return [400, "BarclampConfig/Instance #{log_name(barclamp_config)}/#{log_name(barclamp_instance)} is not associated with network #{log_name(network)}"]
      end
    else
      # network_id is a name, so look up the network by BarclampInstance ID and network name
      network = Network.where("barclamp_instance_id = ? AND name = ?", barclamp_instance.id, network_id).first
      return [404, "There is no network #{network_id} with BarclampConfig/Instance #{log_name(barclamp_config)}/#{log_name(barclamp_instance)}"] if network.nil?
    end

    [200, network]
  end


  def self.log_name(object)
    return "nil(nil)" if object.nil?
    "#{object.name}(#{object.object_id})"
  end
end
