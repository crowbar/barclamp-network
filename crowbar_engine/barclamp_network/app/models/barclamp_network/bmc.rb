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

class BarclampNetwork::Bmc < BarclampNetwork::Role

  def range_name(nr)
    "bmc"
  end

  def on_proposed(nr)
    NodeRole.transaction do
      if network.allocations.node(nr.node).count == 0
        # TODO: allocate network and bind admin node interfaces here
        #Rails.logger.info("Creating BMC network for #{nr.node.name}")
        # tbd
      end
    end
    Rails.logger.info("Allocating BMC address for #{nr.node.name}")
    super nr  # allocate address in bmc range
  end

  def sysdata(nr)
    # address has been allocated, hook into attributes
    allocated = network.allocations.node(nr.node).last
    if allocated.nil?
      Rails.logger.error("#{name}: Could not find allocated BMC address for #{nr.node.name}!")
      return   # should never happen
    end
    address = allocated.address.addr
    netmask = allocated.address.netmask
    router = network.allocations.first.address.addr # assuming the admin node got first allocation
    use_vlan = network.use_vlan
    vlan = network.vlan

    Rails.logger.info("#{name}: Creating bmc config for #{nr.node.name} #{address}")
    # TODO: this should really be done by examining the attributes themselves and building the
    # json from them.
    {"crowbar" =>
         {"network" =>
              {"bmc" =>
                   {"address" => address,
                    "netmask" => netmask,
                    "router"  => router,
                    "use_vlan" => use_vlan,
                    "vlan" => vlan }}}}
  end

end
