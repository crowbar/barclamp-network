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
 
class SelectBySpeedTest < ActiveSupport::TestCase

  # Test successful interface selection with exact match
  test "SelectBySpeed: exact match" do
    if_remap = { "1g1" => "eth2", "1g2" => "eth3", "1g3" => "eth1",
                 "10g1" => "eth4", "10g2" => "eth5", "100m2" => "eth6" }

    sbs = SelectBySpeed.create!(:value => "10g")

    new_if_remap = sbs.select(if_remap)

    assert new_if_remap.has_key?("10g1")
    assert_equal if_remap["10g1"], new_if_remap["10g1"]

    assert new_if_remap.has_key?("10g2")
    assert_equal if_remap["10g2"], new_if_remap["10g2"]

    assert_equal 2, new_if_remap.size
  end


  # Test no interface selection
  test "SelectBySpeed: no selection" do
    if_remap = { "10m1" => "eth1", "100m2" => "eth2", "10g3" => "eth3" }

    sbs = SelectBySpeed.create!(:value => "1g")

    new_if_remap = sbs.select(if_remap)

    assert new_if_remap.empty?
  end
  

  # Test successful interface selection with faster match
  test "SelectBySpeed: faster match" do
                 # Missing desired speed, with speeds below and above
    if_remap = { "10m1" => "eth1", "1g1" => "eth2", "10g1" => "eth3",
                 # Has desired speed
                 "100m2" => "eth4", "1g2" => "eth5", "10g2" => "eth6",
                 # Missing desired speed, with speeds above
                 "1g3" => "eth7", "10g3" => "eth8",
                 # Missing desired speed, with speeds below
                 "10m4" => "eth9" }

    sbs = SelectBySpeed.create!(:value => "+100m")

    new_if_remap = sbs.select(if_remap)

    # Tests selecting faster speed from above and below speeds
    assert new_if_remap.has_key?("1g1")
    assert_equal if_remap["1g1"], new_if_remap["1g1"]

    # Tests selecting requested speed
    assert new_if_remap.has_key?("100m2")
    assert_equal if_remap["100m2"], new_if_remap["100m2"]

    # Tests selecting faster speed from above speeds
    assert new_if_remap.has_key?("1g3")
    assert_equal if_remap["100m2"], new_if_remap["100m2"]

    assert_equal 3, new_if_remap.size
  end
  

  # Test successful interface selection with slower match
  test "SelectBySpeed: slower match" do
                 # Missing desired speed, with speeds below and above
    if_remap = { "10m1" => "eth1", "1g1" => "eth2", "10g1" => "eth3",
                 # Has desired speed
                 "100m2" => "eth4", "1g2" => "eth5", "10g2" => "eth6",
                 # Missing desired speed, with speeds above
                 "1g3" => "eth7", "10g3" => "eth8",
                 # Missing desired speed, with speeds below
                 "10m4" => "eth9" }

    sbs = SelectBySpeed.create!(:value => "-100m")

    new_if_remap = sbs.select(if_remap)

    # Tests selecting slower speed from above and below speeds
    assert new_if_remap.has_key?("10m1")
    assert_equal if_remap["10m1"], new_if_remap["10m1"]

    # Tests selecting requested speed
    assert new_if_remap.has_key?("100m2")
    assert_equal if_remap["100m2"], new_if_remap["100m2"]

    # Tests selecting slower speed from below speeds
    assert new_if_remap.has_key?("10m4")
    assert_equal if_remap["10m4"], new_if_remap["10m4"]

    assert_equal 3, new_if_remap.size
  end
  

  # Test successful interface selection with slower match
  test "SelectBySpeed: up then down match" do
                 # Missing desired speed, with speeds below and above
    if_remap = { "10m1" => "eth1", "1g1" => "eth2", "10g1" => "eth3",
                 # Has desired speed
                 "100m2" => "eth4", "1g2" => "eth5", "10g2" => "eth6",
                 # Missing desired speed, with speeds above
                 "1g3" => "eth7", "10g3" => "eth8",
                 # Missing desired speed, with speeds below
                 "10m4" => "eth9" }

    sbs = SelectBySpeed.create!(:value => "?100m")

    new_if_remap = sbs.select(if_remap)

    # Tests selecting faster speed from above and below speeds
    assert new_if_remap.has_key?("1g1")
    assert_equal if_remap["1g1"], new_if_remap["1g1"]

    # Tests selecting requested speed
    assert new_if_remap.has_key?("100m2")
    assert_equal if_remap["100m2"], new_if_remap["100m2"]

    # Tests selecting faster speed from above speeds
    assert new_if_remap.has_key?("1g3")
    assert_equal if_remap["1g3"], new_if_remap["1g3"]

    # Tests selecting slower speed from below speeds
    assert new_if_remap.has_key?("10m4")
    assert_equal if_remap["10m4"], new_if_remap["10m4"]

    assert_equal 4, new_if_remap.size
  end
end
