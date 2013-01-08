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
 
class BondModelTest < ActiveSupport::TestCase

  # Test successful creation
  test "Bond creation: success" do
    bond = Bond.new( :name => "fred", :team_mode => 6 )
    bond.physical_interfaces << PhysicalInterface.new(:name => "wilma")
    bond.physical_interfaces << PhysicalInterface.new(:name => "betty")
    bond.save!
  end


  # Test creation failure due to missing team_mode
  test "Bond creation: failure due to missing team_mode" do
    assert_raise ActiveRecord::RecordInvalid do
      bond = Bond.new( :name => "fred" )
      bond.physical_interfaces << PhysicalInterface.new(:name => "wilma")
      bond.physical_interfaces << PhysicalInterface.new(:name => "betty")
      bond.save!
    end
  end


  # Test creation failure due to low team_mode
  test "Bond creation: failure due to low team_mode" do
    assert_raise ActiveRecord::RecordInvalid do
      bond = Bond.new( :name => "fred", :team_mode => -1 )
      bond.physical_interfaces << PhysicalInterface.new(:name => "wilma")
      bond.physical_interfaces << PhysicalInterface.new(:name => "betty")
      bond.save!
    end
  end


  # Test creation failure due to high team_mode
  test "Bond creation: failure due to high team_mode" do
    assert_raise ActiveRecord::RecordInvalid do
      bond = Bond.new( :name => "fred", :team_mode => 7 )
      bond.physical_interfaces << PhysicalInterface.new(:name => "wilma")
      bond.physical_interfaces << PhysicalInterface.new(:name => "betty")
      bond.save!
    end
  end


  # Test creation failure due to no physical interfaces
  test "Bond creation: failure due to no physical interfaces" do
    assert_raise ActiveRecord::RecordInvalid do
      bond = Bond.new( :name => "fred", :team_mode => 7 )
      bond.save!
    end
  end


  # Test creation failure due to 1 physical interface
  test "Bond creation: failure due to 1 physical interface" do
    assert_raise ActiveRecord::RecordInvalid do
      bond = Bond.new( :name => "fred", :team_mode => 7 )
      bond.physical_interfaces << PhysicalInterface.new(:name => "wilma")
      bond.save!
    end
  end
end
