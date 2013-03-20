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

class BarclampNetwork::NodeObserver < ActiveRecord::Observer
  observe :node

  def before_destroy(node)
    node_refs = BarclampNetwork::NodeRef.where(:node_id => node.id)
    node_refs.each { |node_ref|
      node_ref.destroy
    }

    allocated_ips = BarclampNetwork::AllocatedIpAddress.where(:node_id => node.id)
    allocated_ips.each { |allocated_ip|
      allocated_ip.destroy
    }
  end
end
