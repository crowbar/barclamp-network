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

return if  node[:platform] == "windows"

# check if there are any 1g/10g interfaces detected.
detected = Barclamp::Inventory.get_detected_intfs(node)
log "detected interfaces: #{detected.inspect}"
tuning_location='/etc/sysctl.d/20-10gbe.conf'
tune = detected.any?{ |intf_name, intf| intf[:speeds].join.index('g') }

begin
  log "Applying 10gbe system tuning values" do
    level    :info
  end

  # Make sure we have an /etc/sysctl.d path on Redhat 6.2
  directory "/etc/sysctl.d" do
    mode "755"
  end

  template "sysctl-10gbe" do
    path    tuning_location
    source  "sysctl_10gbe.conf.erb"
    mode    "0644"
  end

  # if we just created or modified the params, reload things
  bash "reload sysctl" do
    code "/sbin/sysctl -e -p #{tuning_location}"
    action :nothing
    subscribes :run, resources(:template=> "sysctl-10gbe"), :delayed
  end
end if tune
