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
require 'network_test_helper'

class IpRangeModelTest < ActiveSupport::TestCase

  # Test successful creation
  test "IpRange creation: success" do
    ip_range = NetworkTestHelper.create_an_ip_range()
    ip_range.save!
  end


  # Test creation failure due to missing name
  test "IpRange creation: failure due to missing name" do
    ip_range = IpRange.new()

    ip = IpAddress.new( :cidr => "192.168.24.23" )
    ip_range.start_address = ip

    ip = IpAddress.new( :cidr => "192.168.24.99" )
    ip_range.end_address = ip

    assert_raise ActiveRecord::RecordInvalid do
      ip_range.save!
    end
  end


  # Test creation failure due to missing start_address
  test "IpRange creation: failure due to start address" do
    ip_range = IpRange.new( :name => "dhcp" )

    ip = IpAddress.new( :cidr => "192.168.24.99" )
    ip_range.end_address = ip

    assert_raise ActiveRecord::RecordInvalid do
      ip_range.save!
    end
  end


  # Test creation failure due to missing end_address
  test "IpRange creation: failure due to end address" do
    ip_range = IpRange.new( :name => "dhcp" )

    ip = IpAddress.new( :cidr => "192.168.24.99" )
    ip_range.start_address = ip

    assert_raise ActiveRecord::RecordInvalid do
      ip_range.save!
    end
  end


  # Test delete cascade to start & end addresses
  test "IpRange deletion: casaded delete test" do
    ip_range = NetworkTestHelper.create_an_ip_range()
    ip_range.save!

    ip_range_id = ip_range.id
    ip_range.destroy()

    ip_ranges = IpAddress.where( :start_ip_range_id => ip_range_id )
    assert_equal 0, ip_ranges.size

    ip_ranges = IpAddress.where( :end_ip_range_id => ip_range_id )
    assert_equal 0, ip_ranges.size
  end
end
