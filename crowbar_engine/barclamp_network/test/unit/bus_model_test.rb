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
require 'network_test_helper'
 
class BusModelTest < ActiveSupport::TestCase
  # Test successful creation
  test "Bus creation: success" do
    NetworkTestHelper.create_a_bus()
  end


  # Creation failure: non-existent order
  test "Bus creation: failure due to non-existent order" do
    assert_raise ActiveRecord::RecordInvalid do
      Bus.create!( :path => "0000:00/0000:00:1c" )
    end
  end


  # Creation failure: non-numeric order
  test "Bus creation: failure due to non-numeric order" do
    assert_raise ActiveRecord::RecordInvalid do
      Bus.create!( :order => "fred", :path => "0000:00/0000:00:1c" )
    end
  end


  # Creation failure: non-existent path
  test "Bus creation: failure due to non-existent path" do
    assert_raise ActiveRecord::RecordInvalid do
      Bus.create!( :order => "fred" )
    end
  end
end
