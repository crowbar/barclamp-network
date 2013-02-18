# Copyright 2013, Dell
# Copyright 2012, SUSE Linux Products GmbH
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

# Make sure packages we need will be present
case node[:platform]
when "ubuntu","debian"
  %w{bridge-utils vlan}.each do |pkg|
    p = package pkg do
      action :nothing
    end
    p.run_action :install
  end
when "centos","redhat","suse"
  %w{bridge-utils vconfig}.each do |pkg|
    p = package pkg do
      action :nothing
    end
    p.run_action :install
  end
end

if ::File.exists?("/etc/init/network-interface.conf")
  # Make upstart stop trying to dynamically manage interfaces.
  ::File.unlink("/etc/init/network-interface.conf")
  ::Kernel.system("killall -HUP init")
end

# Stop udev from jacking up our vlans and bridges as we create them.
["40-bridge-network-interface.rules","40-vlan-network-interface.rules"].each do |rule|
  next if ::File.exists?("/etc/udev/rules.d/#{rule}")
  next unless ::File.exists?("/lib/udev/rules.d/#{rule}")
  ::Kernel.system("echo 'ACTION==\"add\", SUBSYSTEM==\"net\", RUN+=\"/bin/true\"' >/etc/udev/rules.d/#{rule}")
end

provisioner = search(:node, "roles:provisioner-server")[0]
conduit_map = Barclamp::Inventory.build_node_map(node)
Chef::Log.debug("Conduit mapping for this node:  #{conduit_map.inspect}")
route_pref = 10000
ifs = Mash.new
old_ifs = node["crowbar_wall"]["network"]["interfaces"] || Mash.new rescue Mash.new
if_mapping = Mash.new
addr_mapping = Mash.new
default_route = {}

# dhclient running?  Not for long.
::Kernel.system("killall -w -q -r '^dhclient'")

# Silly little helper for sorting Crowbar networks.
# Netowrks that use vlans and bridges will be handled later
def net_weight(net)
  res = 0
  if node["crowbar"]["network"][net]["use_vlan"] then res += 1 end
  if node["crowbar"]["network"][net]["add_bridge"] then res += 1 end
  res
end

# Dynamically create our new local interfaces.
node["crowbar"]["network"].keys.sort{|a,b|
  net_weight(a) <=> net_weight(b)
}.each do |name|
  next if name == "bmc"
  net_ifs = Array.new
  network = node["crowbar"]["network"][name]
  addr = if network["address"]
           IP.coerce("#{network["address"]}/#{network["netmask"]}")
         else
           nil
         end
  conduit = network["conduit"]
  base_ifs = conduit_map[conduit]["if_list"].map{|i| Nic.new(i)}.sort
  Chef::Log.info("Using base interfaces #{base_ifs.map{|i|i.name}.inspect} for network #{name}")
  base_ifs.each do |i|
    ifs[i.name] ||= Hash.new
    ifs[i.name]["addresses"] ||= Array.new
    ifs[i.name]["type"] = "physical"
  end
  case base_ifs.length
  when 0
    Chef::Log.fatal("Conduit #{conduit} does not have any nics. Your config is invalid.")
    raise ::RangeError.new("Invalid conduit mapping #{conduit_map.inspect}")
  when 1
    Chef::Log.info("Using interface #{base_ifs[0]} for network #{name}")
    our_iface = base_ifs[0]
  else
    # We want a bond.  Figure out what mode it should be.  Default to 5
    team_mode = conduit_map[conduit]["team_mode"] ||
      (network["teaming"] && network["teaming"]["mode"]) || 5
    # See if a bond that matches our specifications has already been created,
    # or if there is an empty bond lying around.
    bond = Nic.nics.detect do|i|
      i.kind_of?(Nic::Bond) &&
        (i.slaves.empty? ||
         (i.slaves.sort == base_ifs))
    end
    if bond
      Chef::Log.info("Using bond #{bond.name} for network #{name}")
    else
      bond = Nic::Bond.create("bond#{Nic.nics.select{|i| Nic::bond?(i)}.length}",
                       team_mode)
      Chef::Log.info("Creating bond #{bond.name} for network #{name}")
    end
    ifs[bond.name] ||= Hash.new
    ifs[bond.name]["addresses"] ||= Array.new
    ifs[bond.name]["slaves"] = Array.new
    base_ifs.each do |i|
      bond.add_slave i
      ifs[bond.name]["slaves"] << i.name
      ifs[i.name]["slave"] = true
      ifs[i.name]["master"] = bond.name
    end
    ifs[bond.name]["mode"] = team_mode
    ifs[bond.name]["type"] = "bond"
    our_iface = bond
  end
  net_ifs << our_iface.name
  # If we want a vlan interface, create one on top of the base physical
  # interface and/or bond that we already have
  if network["use_vlan"]
    vlan = "#{our_iface.name}.#{network["vlan"]}"
    if Nic.exists?(vlan)
      Chef::Log.info("Using vlan #{vlan} for network #{name}")
      our_iface = Nic.new vlan
    else
      Chef::Log.info("Creating vlan #{vlan} for network #{name}")
      our_iface = Nic::Vlan.create(our_iface,network["vlan"])
    end
    # Destroy any vlan interfaces for this vlan that might
    # already exist
    Nic.nics.each do |n|
      next unless n.kind_of?(Nic::Vlan)
      next if n == our_iface
      next unless n.vlan == network["vlan"].to_i
      n.destroy
    end
    ifs[our_iface.name] ||= Hash.new
    ifs[our_iface.name]["addresses"] ||= Array.new
    ifs[our_iface.name]["type"] = "vlan"
    ifs[our_iface.name]["vlan"] = our_iface.vlan
    ifs[our_iface.name]["parent"] = our_iface.parents[0].name
    net_ifs << our_iface.name
  end
  # Ditto for a bridge.
  if network["add_bridge"]
    bridge = if our_iface.kind_of?(Nic::Vlan)
               "br#{our_iface.vlan}"
             else
               "br-#{name}"
             end
    br = if Nic.exists?(bridge)
           Chef::Log.info("Using bridge #{bridge} for network #{name}")
           Nic.new bridge
         else
           Chef::Log.info("Creating bridge #{bridge} for network #{name}")
           Nic::Bridge.create(bridge)
         end
    ifs[br.name] ||= Hash.new
    ifs[br.name]["addresses"] ||= Array.new
    ifs[our_iface.name]["slave"] = true
    ifs[our_iface.name]["master"] = br.name
    br.add_slave our_iface
    ifs[br.name]["slaves"] = [our_iface.name]
    ifs[br.name]["type"] = "bridge"
    our_iface = br
    net_ifs << our_iface.name
  end
  # Make sure our addresses are correct
  if_mapping[name] = net_ifs
  ifs[our_iface.name]["addresses"] ||= Array.new
  if addr
    ifs[our_iface.name]["addresses"] << addr
    addr_mapping[name] = addr.to_s
    # Ditto for our default route
    if network["router_pref"] && (network["router_pref"].to_i < route_pref)
      Chef::Log.info("#{name}: Will use #{network["router"]} as our default route")
      route_pref = network["router_pref"].to_i
      default_route = {:nic => our_iface.name, :gateway => network["router"]}
    end
  end
end

# Kill any nics that we don't want hanging around anymore.
old_ifs.each do |name,params|
  next if ifs[name]
  Chef::Log.info("#{name} is no longer being used, deconfiguring it.")
  Nic.new(name).destroy if Nic.exists?(name)
  case node["platform"]
  when "centos","redhat"
    # Redhat and Centos have lots of small files definining interfaces.
    # Delete the ones we no longer care about here.
    if ::File.exists?("/etc/sysconfig/network-scripts/ifcfg-#{name}")
      ::File.delete("/etc/sysconfig/network-scripts/ifcfg-#{name}")
    end
  when "suse"
    # SuSE also has lots of small files, but in slightly different locations.
    if ::File.exists?("/etc/sysconfig/network/ifcfg-#{name}")
      ::File.delete("/etc/sysconfig/network/ifcfg-#{name}")
    end
    if ::File.exists?("/etc/sysconfig/network/ifroute-#{name}")
      ::File.delete("/etc/sysconfig/network/ifroute-#{name}")
    end
  end
end

Nic.refresh_all

# At this point, any new interfaces we need have been configured, we know
# what IP addresses should be assigned to each interface, and we know what
# default route we should use. Make reality match our expectations.
Nic.nics.each do |nic|
  # If this nic is neither in our old config nor in our new config, skip
  next unless ifs[nic.name]
  iface = ifs[nic.name]
  old_iface = old_ifs[nic.name]
  # If we are a member of a bond or a bridge, then the bond or bridge
  # gets our config instead of us. The order in which Nic.nics returns
  # interfaces ensures that this will always function properly.
  if (master = nic.bond_master || nic.bridge_master)
    if iface["slave"]
      # We should continue to be a slave.
      Chef::Log.info("#{master.name}: usurping #{nic.name}")
      ifs[nic.name]["addresses"].each{|a|
        ifs[master.name]["addresses"] << a
      }
      ifs[nic.name]["addresses"] = []
      default_route[:nic] = master.name if default_route[:nic] == nic.name
      if_mapping.each { |k,v|
        v << master.name if v.last == nic.name
      }
    else
      # We no longer want to be a slave.
      Chef::Log.info("#{nic.name} no longer wants to be a slave of #{master.name}")
      master.remove_slave nic
    end
  end
  nic.up
  Chef::Log.info("#{nic.name}: current addresses: #{nic.addresses.map{|a|a.to_s}.sort.inspect}") unless nic.addresses.empty?
  Chef::Log.info("#{nic.name}: required addresses: #{iface["addresses"].map{|a|a.to_s}.sort.inspect}") unless iface["addresses"].empty?
  # Ditch old addresses, add new ones.
  old_iface["addresses"].reject{|i|iface["addresses"].member?(i)}.each do |addr|
    Chef::Log.info("#{nic.name}: Removing #{addr.to_s}")
    nic.remove_address addr
  end if old_iface
  iface["addresses"].reject{|i|nic.addresses.member?(i)}.each do |addr|
    Chef::Log.info("#{nic.name}: Adding #{addr.to_s}")
    nic.add_address addr
  end
  # Make sure we are using the proper default route.
  if ::Kernel.system("ip route show dev #{nic.name} |grep -q default") &&
      (default_route[:nic] != nic.name)
    Chef::Log.info("Removing default route from #{nic.name}")
    ::Kernel.system("ip route del default dev #{nic.name}")
  elsif default_route[:nic] == nic.name
    ifs[nic.name]["gateway"] = default_route[:gateway]
    unless ::Kernel.system("ip route show dev #{nic.name} |grep -q default")
      Chef::Log.info("Adding default route via #{default_route[:gateway]} to #{nic.name}")
      ::Kernel.system("ip route add default via #{default_route[:gateway]} dev #{nic.name}")
    end
  end
end

if ["delete","reset"].member?(node["state"])
  # We just had the rug pulled out from under us.
  # Do our darndest to get an IP address we can use.
  Nic.refresh_all
  Nic.nics.each{|n|
    next if n.name =~ /^lo/
    n.up
    break if ::Kernel.system("dhclient -1 #{n.name}")
  }
end

# Wait for the administrative network to come back up.
Chef::Log.info("Waiting up to 60 seconds for the net to come back")
60.times do
  break if ::Kernel.system("ping -c 1 -w 1 -q #{provisioner.address.addr}")
  sleep 1
end if provisioner

node["crowbar_wall"] ||= Mash.new
node["crowbar_wall"]["network"] ||= Mash.new
saved_ifs = Mash.new
ifs.each {|k,v|
  addrs = v["addresses"].map{|a|a.to_s}.sort
  saved_ifs[k]=v
  saved_ifs[k]["addresses"] = addrs
}
Chef::Log.info("Saving interfaces to crowbar_wall: #{saved_ifs.inspect}")

node["crowbar_wall"]["network"]["interfaces"] = saved_ifs
node["crowbar_wall"]["network"]["nets"] = if_mapping
node["crowbar_wall"]["network"]["addrs"] = addr_mapping
node.save

case node["platform"]
when "debian","ubuntu"
  template "/etc/network/interfaces" do
    source "interfaces.erb"
    owner "root"
    group "root"
    variables({ :interfaces => ifs })
  end
when "centos","redhat"
  # add redhat-specific code here
  Nic.nics.each do |nic|
    next unless ifs[nic.name]
    template "/etc/sysconfig/network-scripts/ifcfg-#{nic.name}" do
      source "redhat-cfg.erb"
      owner "root"
      group "root"
      variables({
                  :interfaces => ifs, # the array of config values
                  :nic => nic # the live object representing the current nic.
                })
    end
  end
when "suse"
  Nic.nics.each do |nic|
    next unless ifs[nic.name]
    template "/etc/sysconfig/network/ifcfg-#{nic.name}" do
      source "suse-cfg.erb"
      variables({
                  :interfaces => ifs,
                  :nic => nic
                })
    end
    template "/etc/sysconfig/network/ifroute-#{nic.name}" do
      source "suse-route.erb"
      variables({
                  :interfaces => ifs,
                  :nic => nic
                })
    end if ifs[nic.name]["gateway"]
  end
end
