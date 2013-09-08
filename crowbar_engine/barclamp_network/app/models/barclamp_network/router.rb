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

class BarclampNetwork::Router < ActiveRecord::Base

  validate  :router_is_sane
  
  attr_protected :id
  belongs_to     :network

  attr_accessible :pref

  def address
    IP.coerce(read_attribute("address"))
  end

  def address=(addr)
    write_attribute("address",IP.coerce(addr).to_s)
  end

  private
  
  def router_is_sane
    # A router is sane when its address is in a subnet covered by one of its ranges
    unless network.ranges.any?{|r|r.start.subnet === address}
      errors.add("Router #{address.to_s} is not any range for #{network.name}")
    end
  end
end

  
