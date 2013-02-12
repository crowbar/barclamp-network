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

class NetworkModeFilter < ConduitFilter
  def network_mode=( mode )
    self.value = mode
  end


  def match(node)
    # TODO: Figure out the configured networking mode
    # The below is an ugly hack to read in the configured network mode from
    # the new network json
    # Start HACK
    new_json = NetworkService.read_new_network_json()
    configured_teaming_mode = new_json["attributes"]["network"]["mode"]
    # End HACK

    value.casecmp(configured_teaming_mode) == 0
  end
end
