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

class BarclampNetwork::AttribInstanceBusOrder < AttribInstance
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
  

  def actual
    buses = InterfaceMap.get_bus_order(node)
    bus_order=[]
    buses.each {|bus|
      bus_order << bus.path
    }
    bus_order.to_json
  end
end
