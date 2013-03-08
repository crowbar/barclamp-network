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
 
class AllocatedIpAddressModelTest < ActiveSupport::TestCase
  # Test creation failure, no ip
  test "AllocatedIpAddress creation: failure no ip" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new()
    aip.network = network

    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end


  # Test creation failure, no network
  test "AllocatedIpAddress creation: failure no network" do
    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.122.2")

    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end
  

  # Test successful creation, min
  test "AllocatedIpAddress creation: min success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "0.0.0.0")
    aip.network = network
    aip.save!
  end


  # Test successful creation, max
  test "AllocatedIpAddress creation: max success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "255.255.255.255")
    aip.network = network
    aip.save!
  end


  # Test successful creation, normal
  test "AllocatedIpAddress creation: success" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.132.124")
    aip.network = network
    aip.save!
  end


  # Test validation: alpha
  test "AllocatedIpAddress creation: alpha failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.blah.132.124")
    aip.network = network
    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end


  # Test validation: overflow 1st octet
  test "AllocatedIpAddress creation: 1st octet overflow failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "256.168.132.124")
    aip.network = network
    
    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end


  # Test validation: overflow 2nd octet
  test "AllocatedIpAddress creation: 2nd octet overflow failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.256.132.124")
    aip.network = network

    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end


  # Test validation: overflow 3rd octet
  test "AllocatedIpAddress creation: 3rd octet overflow failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.256.124")
    aip.network = network

    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end


  # Test validation: overflow 4th octet
  test "AllocatedIpAddress creation: 4th octet overflow failure" do
    barclamp = NetworkTestHelper.create_a_barclamp()
    deployment = barclamp.create_or_get_deployment()

    network = NetworkTestHelper.create_a_network(deployment)
    network.save!

    aip = BarclampNetwork::AllocatedIpAddress.new(:ip => "192.168.132.256")
    aip.network = network
    
    assert_raise( ActiveRecord::RecordInvalid ) do
      aip.save!
    end
  end
end
