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
 
class InterfaceModelTest < ActiveSupport::TestCase

  # Test successful creation
  test "Interface creation: success" do
    interface = Interface.new(:name => "fred")
    interface.save!
  end


  # Test creation failure due to missing team_mode
  test "Interface creation: failure due to missing name" do
    assert_raise ActiveRecord::RecordInvalid do
      interface = Interface.new()
      interface.save!
    end
  end


  # Test cascade allocated ip deletion on interface deletion
  test "Interface deletion: cascade delete to allocated ips" do
    interface = Interface.new(:name => "fred")
    interface.ip_addresses << IpAddress.new( :cidr => "192.168.130.24" )
    interface.save!

    ip_id = interface.ip_addresses.first.id
    interface.destroy()

    ips = IpAddress.where( :id => ip_id )
    assert_equal 0, ips.size
  end
end
