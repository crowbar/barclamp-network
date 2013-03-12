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
# 
require 'test_helper'
 
class NetworkUtilsTest < ActiveSupport::TestCase

  # Failure to find Deployment due to bad id
  test "find_network: failure to find Deployment due to bad id" do
    http_error, result = BarclampNetwork::NetworkUtils.find_network("fred", "badbcc")
    assert_equal 404, http_error, result
  end


  # Return nil if no active snapshot was found
  test "find_network: return nil if no active snapshot found" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    http_error, result = BarclampNetwork::NetworkUtils.find_network("fred", deployment.id, BarclampNetwork::NetworkUtils::ACTIVE_SNAPSHOT)
    assert_equal 404, http_error, result
  end


  # Failure to find network due to bad network id when proposal unspecified
  test "find_network: failure to find network due to bad network id" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    http_error, result = BarclampNetwork::NetworkUtils.find_network("fred", deployment.id)
    assert_equal 404, http_error, result
  end


  # Consistency check of snapshot id given network DB id
  test "find_network: consistency check of network id failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network(deployment)

    # This is somewhat contrived, but is the only way to test this case at the moment
    snapshot = Snapshot.new()
    snapshot.barclamp = barclamp
    snapshot.save!
    network.snapshot = snapshot

    network.save!

    http_error, network = BarclampNetwork::NetworkUtils.find_network(network.id)
    assert_equal 400, http_error, network
  end


  # Successfully find network when only network name supplied
  test "find_network: success when only network name supplied" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network(deployment, "public")
    network.save!

    http_error, network = BarclampNetwork::NetworkUtils.find_network("public")

    assert_equal 200, http_error, "Return code of 200 expected, got #{http_error}: #{network}"
    assert_not_nil network
    assert_equal network.snapshot.id, deployment.proposed_snapshot.id
  end


  # Successfully find network when network name and Deployment supplied
  test "find_network: success when network name and Deployment supplied" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network(deployment, "public")
    network.save!

    http_error, network = BarclampNetwork::NetworkUtils.find_network("public", deployment.id)
    assert_equal 200, http_error, network
    assert_not_nil network
    assert_equal network.snapshot.id, deployment.proposed_snapshot.id
  end


  # Successfully find network when network name, Deployment, and proposed type supplied
  test "find_network: success when network name, Deployment, and proposed supplied" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network(deployment, "public")
    network.save!

    http_error, network = BarclampNetwork::NetworkUtils.find_network("public", deployment.id, BarclampNetwork::NetworkUtils::PROPOSED_SNAPSHOT)
    assert_equal 200, http_error, network
    assert_not_nil network
    assert_equal network.snapshot.id, deployment.proposed_snapshot.id
  end
end
