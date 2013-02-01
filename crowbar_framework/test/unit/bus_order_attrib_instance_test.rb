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

require 'test_helper'
 
class BusOrderAttribInstanceTest < ActiveSupport::TestCase

  # Test retrieval of bus order
  test "BusOrder retrieval: success" do
    interface_map = NetworkTestHelper.create_an_interface_map()
    interface_map.save!

    node = Node.new(:name => "fred.flintstone.org")
    node.save!

    node.attrib_set("product_name", "PowerEdge R710")
    node.attrib_set("bus_order", nil, 0, BusOrderAttribInstance)

    bus_order_ai = node.attrib_get("bus_order", BusOrderAttribInstance)
    json = JSON.parse(bus_order_ai.value)
    assert_equal "0000:00/0000:00:01", json[0]
    assert_equal "0000:00/0000:00:03", json[1]
  end
end
