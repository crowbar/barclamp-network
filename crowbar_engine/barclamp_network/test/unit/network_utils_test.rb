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
require 'network_service'
 
class NetworkUtilsTest < ActiveSupport::TestCase

  # Failure to find BarclampConfig due to bad id
  test "find_network: failure to find BarclampConfig due to bad id" do
    http_error, result = NetworkUtils.find_network("fred", "badbcc")
    assert_equal 404, http_error
  end


  # Failure to find network due to bad network id when proposal unspecified
  test "find_network: failure to find network due to bad network id" do
    barclamp = BarclampNetwork::Barclamp.new()
    barclamp_config = barclamp.create_proposal()

    http_error, result = NetworkUtils.find_network("fred", barclamp_config.id)
    assert_equal 404, http_error
  end


  # Consistency check of barclamp instance id given network DB id
  test "find_network: consistency check of network id failure" do
    barclamp = BarclampNetwork::Barclamp.new()
    barclamp_config = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network("public", BarclampInstance.create!())
    network.save!

    http_error, network = NetworkUtils.find_network(network.id)
    assert_equal 400, http_error
  end


  # Successfully find network when only network name supplied
  test "find_network: success when only network name supplied" do
    barclamp = BarclampNetwork::Barclamp.new()
    barclamp_config = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network("public", barclamp_config.proposed_instance)
    network.save!

    http_error, network = NetworkUtils.find_network("public")
    assert_equal 200, http_error
    assert_not_nil network
    assert_equal network.barclamp_instance.id, barclamp_config.proposed_instance.id
  end


  # Successfully find network when network name and BarclampConfig supplied
  test "find_network: success when network name and BarclampConfig supplied" do
    barclamp = BarclampNetwork::Barclamp.new()
    barclamp_config = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network("public", barclamp_config.proposed_instance)
    network.save!

    http_error, network = NetworkUtils.find_network("public", barclamp_config)
    assert_equal 200, http_error
    assert_not_nil network
    assert_equal network.barclamp_instance.id, barclamp_config.proposed_instance.id
  end


  # Successfully find network when network name, BarclampConfig, and proposed type supplied
  test "find_network: success when network name, BarclampConfig, and active supplied" do
    barclamp = BarclampNetwork::Barclamp.new()
    barclamp_config = barclamp.create_proposal()

    network = NetworkTestHelper.create_a_network("public", barclamp_config.proposed_instance)
    network.save!

    http_error, network = NetworkUtils.find_network("public", barclamp_config, NetworkUtils.PROPOSED_BARCLAMP_INSTANCE)
    assert_equal 200, http_error
    assert_not_nil network
    assert_equal network.barclamp_instance.id, barclamp_config.proposed_instance.id
  end
end
