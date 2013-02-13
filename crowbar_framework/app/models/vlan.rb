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

class Vlan < ActiveRecord::Base
  belongs_to :network, :inverse_of => :vlan
  has_many :vlan_interfaces, :inverse_of => :vlan, :dependent => :destroy

  attr_accessible :tag

  validates :tag, :presence => true
end
