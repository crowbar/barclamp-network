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

class BarclampNetwork::Allocation < ActiveRecord::Base

  validate :sanity_check_address
  
  attr_protected :id
  belongs_to :range, :class_name => "BarclampNetwork::Range"
  belongs_to :node, :dependent => :destroy

  scope  :node,     ->(n)  { where(:node_id => n.id) }
  scope  :network,  ->(net){ joins(:range).where('ranges.network_id' => net.id) }

  def address
    IP.coerce(read_attribute("address"))
  end

  def address=(addr)
    write_attribute("address",IP.coerce(addr).to_s)
  end

  def network
    range.network
  end

  private

  def sanity_check_address
    unless range === address
      errors.add("Allocation #{network.name}.#{range.name}.{address.to_s} not in parent range!")
    end
  end
  
end
