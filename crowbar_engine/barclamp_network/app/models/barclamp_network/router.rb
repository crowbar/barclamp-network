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

class BarclampNetwork::Router < ActiveRecord::Base
  attr_protected :id
  belongs_to :network, :inverse_of => :router
  has_one :ip, :foreign_key => "router_id", :class_name => "IpAddress", :dependent => :destroy

  #attr_accessible :pref
  accepts_nested_attributes_for :ip
  validates :pref, :presence => true, :numericality => { :only_integer => true }
  validates :ip, :presence => true
end
