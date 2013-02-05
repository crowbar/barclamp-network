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

  # Failure to find proposal due to bad proposal id
  test "find_proposal_and_network: failure to find proposal due to bad proposal id" do
    http_error, *rest = NetworkUtils.find_proposal_and_network(99, nil)
    assert_equal 404, http_error
  end


  # Failure to find network due to bad network id when proposal unspecified
  test "find_proposal_and_network: failure to find network due to bad network id when proposal unspecified" do
    http_error, *rest = NetworkUtils.find_proposal_and_network(nil, "fred")
    assert_equal 404, http_error
  end


  # Successfully find network when no proposal id
  test "find_proposal_and_network: success when no proposal id" do
    network = NetworkTestHelper.create_a_network("public")
    network.save!

    http_error, proposal, network = NetworkUtils.find_proposal_and_network(nil, "public")
    assert_equal 200, http_error
    assert_not_nil network
    assert_equal network.proposal.id, proposal.id unless proposal.nil?
    assert_equal network.proposal, proposal if proposal.nil?
  end


  # Successfully find network by name when valid proposal id
  test "find_proposal_and_network: successfully find network by name when valid proposal id" do
    new_network = NetworkTestHelper.create_a_network("public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = NetworkUtils.find_proposal_and_network(new_proposal.id, "public")
    assert_equal 200, http_error
    assert_equal new_proposal.id, proposal.id
    assert_equal new_network.id, network.id
  end
  

  # Fail to find network by name when valid proposal id
  test "find_proposal_and_network: fail to find network by name when valid proposal id" do
    new_network = NetworkTestHelper.create_a_network("public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = NetworkUtils.find_proposal_and_network(new_proposal.id, "barney")
    assert_equal 404, http_error
  end


  # Successfully find network by id when valid proposal id
  test "find_proposal_and_network: successfully find network by id when valid proposal id" do
    new_network = NetworkTestHelper.create_a_network("public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    http_error, proposal, network = NetworkUtils.find_proposal_and_network(new_proposal.id, new_network.id)
    assert_equal 200, http_error
    assert_equal new_proposal.id, proposal.id
    assert_equal new_network.id, network.id
  end


  # Consistency check of network id failure
  test "find_proposal_and_network: consistency check of network id failure" do
    new_network = NetworkTestHelper.create_a_network("public")
    new_proposal = NetworkTestHelper.create_or_get_proposal("wilma")
    new_network.proposal = new_proposal
    new_network.save!
    new_network2 = NetworkTestHelper.create_a_network("public")
    new_network2.save!
    http_error, proposal, network = NetworkUtils.find_proposal_and_network(new_proposal.id, new_network2.id)
    assert_equal 400, http_error
  end
end
