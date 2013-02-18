# Copyright 2012, Dell 
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
 
class IpAddressModelTest < ActiveSupport::TestCase

  # Test successful creation, min
  test "IpAddress creation: min success" do
    IpAddress.create!( :cidr => "0.0.0.0/0" )
  end


  # Test successful creation, max
  test "IpAddress creation: max success" do
    IpAddress.create!( :cidr => "255.255.255.255/32" )
  end


  # Test successful creation, normal
  test "IpAddress creation: success" do
    IpAddress.create!( :cidr => "192.168.132.124/32" )
  end


  # Test validation: alpha
  test "IpAddress creation: alpha failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "192.blah.130.124/24" )
    end
  end


  # Test validation: overflow 1st octet
  test "IpAddress creation: 1st octet overflow failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "256.168.130.124/24" )
    end
  end


  # Test validation: overflow 2nd octet
  test "IpAddress creation: 2nd octet overflow failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "192.256.130.124/24" )
    end
  end


  # Test validation: overflow 3rd octet
  test "IpAddress creation: 3rd octet overflow failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "192.168.256.124/24" )
    end
  end


  # Test validation: overflow 4th octet
  test "IpAddress creation: 4th octet overflow failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "192.168.130.256/24" )
    end
  end


  # Test validation: overflow cidr
  test "IpAddress creation: cidr overflow failure" do
    assert_raise( ActiveRecord::RecordInvalid ) do
      IpAddress.create!( :cidr => "192.168.130.256/33" )
    end
  end


  # Test netmask retrieval: failure due to no /99
  test "IpAddress netmask retrieval: failure" do
    ip = IpAddress.create!( :cidr => "192.168.130.10" )

    assert_raise( RuntimeError ) do
      ip.get_netmask
    end
  end
end
