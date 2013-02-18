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
 
class SelectByIndexTest < ActiveSupport::TestCase

  # Test successful interface selection with string value
  test "SelectByIndex: successful interface selection string value" do
    test_success(SelectByIndex.create!(:value => "2"))
  end


  # Test successful interface selection with Integer value
  test "SelectByIndex: successful interface selection Integer value" do
    test_success(SelectByIndex.create!(:value => 2))
  end


  # Test no interfaces selected
  test "SelectByIndex select: no interfaces selected" do
    if_remap = { "1g1" => "eth2", "1g2" => "eth3",
                 "10g1" => "eth4", "10g2" => "eth5", "100m2" => "eth6" }

    sbi = SelectByIndex.create!(:value => 3)
    new_if_remap = sbi.select(if_remap)

    assert new_if_remap.empty?
  end


  private

  def test_success(sbi)
    if_remap = { "1g1" => "eth2", "1g2" => "eth3", "1g3" => "eth1",
                 "10g1" => "eth4", "10g2" => "eth5", "100m2" => "eth6" }

    new_if_remap = sbi.select(if_remap)

    assert new_if_remap.has_key?("1g2")
    assert_equal if_remap["1g2"], new_if_remap["1g2"]

    assert new_if_remap.has_key?("10g2")
    assert_equal if_remap["10g2"], new_if_remap["10g2"]

    assert new_if_remap.has_key?("100m2")
    assert_equal if_remap["100m2"], new_if_remap["100m2"]

    assert_equal 3, new_if_remap.size
  end
end
