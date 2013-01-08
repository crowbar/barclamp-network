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
#

class IpAddress < ActiveRecord::Base
  belongs_to :interface, :inverse_of => :ip_addresses
  attr_accessible :cidr

  validates :cidr, :presence => true, :format => { :with => /^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\/([0-9]|1[0-9]|2[0-9]|3[0-2]))?$/, :message => "not a valid IP" }


  def get_ip
    cidr_parts = cidr.split('/')
    cidr_parts[0]
  end


  def get_netmask
    cidr_parts = cidr.split('/')
    IPAddr.new("255.255.255.255").mask(cidr_parts[1])
  end


  def get_broadcast
    netmask = get_netmask()

    cidr_parts = cidr.split('/')
    IPAddr.new(cidr_parts[0]) | ~netmask
  end
end
