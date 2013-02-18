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

class BarclampNetwork::BusMap < ActiveRecord::Base
  has_many :buses, :dependent => :destroy
  belongs_to :interface_map, :inverse_of => :bus_maps

  attr_accessible :pattern

  validates :pattern, :presence => true
  validates :buses, :presence => true
end
