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

class Network < ActiveRecord::Base
  has_many :allocated_ips, :class_name => "IpAddress", :dependent => :nullify
  has_one :subnet, :foreign_key => "subnet_id", :class_name => "IpAddress", :dependent => :destroy
  belongs_to :conduit, :inverse_of => :networks
  has_one :router, :inverse_of => :network, :dependent => :destroy
  has_many :ip_ranges, :dependent => :destroy
  belongs_to :proposal, inverse_of => :networks

  attr_accessible :name, :dhcp_enabled

  validates :name, :presence => true, :uniqueness => true
  validates :dhcp_enabled, :inclusion => { :in => [true, false] }
  validates :subnet, :presence => true
  validates :ip_ranges, :presence => true
end
