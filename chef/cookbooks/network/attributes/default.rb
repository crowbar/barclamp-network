# Copyright 2015, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node["platform"]
when "suse"
  default[:network][:base_pkgs] = ["bridge-utils",
                                   "vlan"]
  default[:network][:ovs_pkgs] =  ["openvswitch",
                                   "openvswitch-switch",
                                   "openvswitch-kmp-default"]
  default[:network][:ovs_service] = "openvswitch-switch"
when "centos", "redhat"
  default[:network][:base_pkgs] = ["bridge-utils",
                                   "vconfig"]
  default[:network][:ovs_pkgs] = ["openvswitch",
                                  "openstack-neutron-openvswitch"]
  default[:network][:ovs_service] = "openvswitch"

else
  default[:network][:base_pkgs] = ["bridge-utils",
                                   "vlan"]
  default[:network][:ovs_pkgs] = ["linux-headers-#{`uname -r`.strip}",
                                  "openvswitch-datapath-dkms",
                                  "openvswitch-switch"]
  default[:network][:ovs_service] = "openvswitch-service"
end

default[:network][:ovs_module] = "openvswitch"
