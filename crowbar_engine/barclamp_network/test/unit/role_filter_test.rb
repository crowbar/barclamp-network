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
 
class RoleFilterTest < ActiveSupport::TestCase
  test "Test successful match" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    snapshot = deployment.proposed_snapshot

    cf = BarclampNetwork::RoleFilter.new()
    cf.pattern = "^dns_.+"
    cf.save!

    node = Node.create!(:name => "fred.flintstone.org")
    NetworkTestHelper.add_role(snapshot, node, "ganglia_client")
    NetworkTestHelper.add_role(snapshot, node, "dns_server")

    result = cf.match(node)
    assert result
  end


  test "Test unsuccessful match" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()
    snapshot = deployment.proposed_snapshot

    cf = BarclampNetwork::RoleFilter.new()
    cf.pattern = "^.*fred.*$"
    cf.save!

    node = Node.create!(:name => "fred.flintstone.org")
    NetworkTestHelper.add_role(snapshot, node, "ganglia_client")
    NetworkTestHelper.add_role(snapshot, node, "dns_server")
      
    result = cf.match(node)
    assert !result
  end
end
