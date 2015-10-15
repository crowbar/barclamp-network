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

return if node[:platform] == "windows"

# Make sure packages we need will be present
node[:network][:base_pkgs].each do |pkg|
  p = package pkg do
    action :nothing
  end
  p.run_action :install
end

require 'fileutils'

if node[:platform] == "ubuntu"
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
end

if %w(suse).include? node.platform
  # We used to create this file. Clean it up
  file "/etc/modprobe.d/10-bridge-disable-netfilter.conf" do
    action :delete
  end

  # Make sure netfilter is enabled for bridges
  cookbook_file "modprobe-bridge.conf" do
    source "modprobe-bridge.conf"
    path "/etc/modprobe.d/10-bridge-netfilter.conf"
    mode "0644"
  end

  # If the module is already loaded when we create the modprobe config file,
  # then we need to act and manually change the settings
  execute "enable netfilter for bridges" do
    command <<-EOF
      echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables;
      echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables;
      echo 1 > /proc/sys/net/bridge/bridge-nf-call-arptables
    EOF
    only_if "lsmod | grep -q '^bridge '"
    action :nothing
    subscribes :run, resources(:cookbook_file => "modprobe-bridge.conf"), :delayed
  end
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

def kill_nic(nic)
  raise "Cannot kill #{nic.name} because it does not exist!" unless Nic.exists?(nic.name)

  # Ignore loopback interfaces for now.
  return if nic.loopback?

  Chef::Log.info("Interface #{nic.name} is no longer being used, deconfiguring it.")
  nic.destroy

  case node["platform"]
  when "centos","redhat"
    # Redhat and Centos have lots of small files definining interfaces.
    # Delete the ones we no longer care about here.
    if ::File.exists?("/etc/sysconfig/network-scripts/ifcfg-#{nic.name}")
      ::File.delete("/etc/sysconfig/network-scripts/ifcfg-#{nic.name}")
    end
  when "suse"
    # SuSE also has lots of small files, but in slightly different locations.
    if ::File.exists?("/etc/sysconfig/network/ifcfg-#{nic.name}")
      ::File.delete("/etc/sysconfig/network/ifcfg-#{nic.name}")
    end
    if ::File.exists?("/etc/sysconfig/network/ifroute-#{nic.name}")
      ::File.delete("/etc/sysconfig/network/ifroute-#{nic.name}")
    end
  end
end

# Dynamically create our new local interfaces.
node["crowbar"]["network"].keys.sort{|a,b|
  net_weight(a) <=> net_weight(b)
}.each do |name|
  next if name == "bmc"
  net_ifs = Array.new
  network = node["crowbar"]["network"][name]
  next if network.empty?
  addr = if network["address"]
           IP.coerce("#{network["address"]}/#{network["netmask"]}")
         else
           nil
         end
  conduit = network["conduit"]
  base_ifs = conduit_map[conduit]["if_list"]
  # Error out if we were handed an invalid conduit mapping.
  unless base_ifs.all?{|i|i.is_a?(String) && ::Nic.exists?(i)}
    raise ::ArgumentError.new("Conduit mapping \"#{conduit}\" for network \"#{name}\" is not sane: #{base_ifs.inspect}")
  end
  base_ifs = base_ifs.map{|i| ::Nic.new(i)}
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
      (node["network"]["teaming"] && node["network"]["teaming"]["mode"]) || 5
    # See if a bond that matches our specifications has already been created,
    # or if there is an empty bond lying around.
    bond = Nic::Bond.find(base_ifs)
    if bond
      Chef::Log.info("Using bond #{bond.name} for network #{name}")
      bond.mode = team_mode if bond.mode != team_mode
    else
      existing_bond_names = Nic.nics.select{|i| Nic::bond?(i)}.map{|i| i.name}
      bond_names = (0..existing_bond_names.length).to_a.map{|i| "bond#{i}"}
      new_bond_name = (bond_names - existing_bond_names).first

      bond = Nic::Bond.create(new_bond_name, team_mode)
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
    node.set["crowbar"]["bond_list"] = {} if node["crowbar"]["bond_list"].nil?
    node.set["crowbar"]["bond_list"][bond.name] = ifs[bond.name]["slaves"]
  end
  net_ifs << our_iface.name
  # If we want a vlan interface, create one on top of the base physical
  # interface and/or bond that we already have
  if network["use_vlan"]
    vlan = "#{our_iface.name}.#{network["vlan"]}"
    if Nic.exists?(vlan) && Nic.vlan?(vlan)
      Chef::Log.info("Using vlan #{vlan} for network #{name}")
      our_iface = Nic.new vlan
      have_vlan_iface = true
    else
      have_vlan_iface = false
    end
    # Destroy any vlan interfaces for this vlan that might
    # already exist, but with a different naming scheme
    Nic.nics.each do |n|
      next unless n.kind_of?(Nic::Vlan)
      next if have_vlan_iface && n == our_iface
      next unless n.parent == our_iface.name
      next unless n.vlan == network["vlan"].to_i
      kill_nic(n)
    end
    unless have_vlan_iface
      Chef::Log.info("Creating vlan #{vlan} for network #{name}")
      our_iface = Nic::Vlan.create(our_iface,network["vlan"])
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
    br = if Nic.exists?(bridge) && Nic.bridge?(bridge)
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
  if network["add_ovs_bridge"]
    bridge = node[:network][:networks][name][:bridge_name] || "br-#{name}"

    node[:network][:ovs_pkgs].each do |pkg|
      p = package pkg do
        action :nothing
      end
      p.run_action :install
    end

    unless ::File.exists?("/sys/module/#{node[:network][:ovs_module]}")
      ::Kernel.system("modprobe #{node[:network][:ovs_module]}")
    end

    s = service node[:network][:ovs_service] do
      service_name node[:network][:ovs_service]
      supports status: true, restart: true
      action [:nothing]
    end
    s.run_action :enable
    s.run_action :start

    br = if Nic.exists?(bridge) && Nic.ovs_bridge?(bridge)
      Chef::Log.info("Using OVS bridge #{bridge} for network #{name}")
      Nic.new bridge
    else
      Chef::Log.info("Creating OVS bridge #{bridge} for network #{name}")
      Nic::OvsBridge.create(bridge)
    end
    unless ifs.has_key? "ovs-system"
      ifs["ovs-system"] ||= Hash.new
      ifs["ovs-system"]["addresses"] ||= Array.new
      ifs["ovs-system"]["ovs_master"] = true
    end
    ifs[br.name] ||= Hash.new
    ifs[br.name]["addresses"] ||= Array.new
    ifs[our_iface.name]["slave"] = true
    ifs[our_iface.name]["ovs_slave"] = true
    ifs[our_iface.name]["master"] = br.name
    br.add_slave our_iface
    ifs[br.name]["slaves"] = [our_iface.name]
    ifs[br.name]["type"] = "ovs_bridge"
    our_iface = br
    net_ifs << our_iface.name
  end
  if network["mtu"]
    if name == "admin" or name == "storage"
      Chef::Log.info("Setting mtu #{network['mtu']} for #{name} network on #{our_iface.name}")
      ifs[our_iface.name]["mtu"] = network["mtu"]
    else
      Chef::Log.warn("Setting mtu for #{our_iface.name} network is not supported yet, skipping")
    end
  end
  # Make sure our addresses are correct
  if_mapping[name] = net_ifs
  ifs[our_iface.name]["addresses"] ||= Array.new
  if addr
    ifs[our_iface.name]["addresses"] << addr
    addr_mapping[name] ||= Array.new
    addr_mapping[name] << addr.to_s
    # Ditto for our default route
    if network["router_pref"] && (network["router_pref"].to_i < route_pref)
      Chef::Log.info("#{name}: Will use #{network["router"]} as our default route")
      route_pref = network["router_pref"].to_i
      default_route = {:nic => our_iface.name, :gateway => network["router"]}
    end
  end
end

Nic.refresh_all

# Kill any nics that we don't want hanging around anymore.
Nic.nics.reverse_each do |nic|
  next if ifs[nic.name]
  # If we are bringing this node under management, kill any nics we did not
  # configure, except for loopback interfaces.
  if old_ifs[nic.name] || !::File.exist?("/var/cache/crowbar/network/managed")
    kill_nic(nic)
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
  enslaved = false
  # If we are a member of a bond or a bridge, then the bond or bridge
  # gets our config instead of us. The order in which Nic.nics returns
  # interfaces ensures that this will always function properly.
  if (master = nic.master)
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
    elsif !old_ifs[master.name]
      # We have been enslaved to an interface not managed by Crowbar.
      # Skip any further configuration of this nic.
      Chef::Log.info("#{nic.name} is enslaved to #{master.name}, which was not created by Crowbar")
      enslaved = true
    else
      # We no longer want to be a slave.
      Chef::Log.info("#{nic.name} no longer wants to be a slave of #{master.name}")
      master.remove_slave nic
    end
  end

  unless nic.kind_of?(Nic::Vlan) or nic.kind_of?(Nic::Bond)
    nic.rx_offloading = node["network"]["enable_rx_offloading"] || false
    nic.tx_offloading = node["network"]["enable_tx_offloading"] || false
  end

  if ifs[nic.name]["mtu"]
    nic.mtu = ifs[nic.name]["mtu"]
  end

  if !enslaved
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
  Chef::Log.info("Node state is #{node["state"]}; ensuring network up")
  Nic.refresh_all
  Nic.nics.each{|n|
    next if n.name =~ /^lo/
    n.up
    break if ::Kernel.system("dhclient -1 #{n.name}")
  }
end

# Wait for the administrative network to come back up.
Chef::Log.info("Checking we can ping #{provisioner.address.addr}; " +
               "will wait up to 60 seconds") if provisioner
60.times do
  break if ::Kernel.system("ping -c 1 -w 1 -q #{provisioner.address.addr} > /dev/null")
  sleep 1
end if provisioner

node.set["crowbar_wall"] ||= Mash.new
node.set["crowbar_wall"]["network"] ||= Mash.new
saved_ifs = Mash.new
ifs.each {|k,v|
  addrs = v["addresses"].map{|a|a.to_s}.sort
  saved_ifs[k]=v
  saved_ifs[k]["addresses"] = addrs
}
Chef::Log.info("Saving interfaces to crowbar_wall: #{saved_ifs.inspect}")

node.set["crowbar_wall"]["network"]["interfaces"] = saved_ifs
node.set["crowbar_wall"]["network"]["nets"] = if_mapping
node.set["crowbar_wall"]["network"]["addrs"] = addr_mapping
node.save

# Flag to let us know that networking on this node
# is now managed by the netowrk barclamp.
FileUtils.mkdir_p("/var/cache/crowbar/network")
FileUtils.touch("/var/cache/crowbar/network/managed")

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

  ethtool_options = []
  ethtool_options << "rx off" unless node["network"]["enable_rx_offloading"] || false
  ethtool_options << "tx off" unless node["network"]["enable_tx_offloading"] || false
  ethtool_options = ethtool_options.join(" ")

  Nic.nics.each do |nic|
    next unless ifs[nic.name]
    template "/etc/sysconfig/network/ifcfg-#{nic.name}" do
      source "suse-cfg.erb"
      variables({
        :ethtool_options => ethtool_options,
        :interfaces => ifs,
        :nic => nic
      })
    end
    if ifs[nic.name]["gateway"]
      template "/etc/sysconfig/network/ifroute-#{nic.name}" do
        source "suse-route.erb"
        variables({
                    :interfaces => ifs,
                    :nic => nic
                  })
      end
    else
      file "/etc/sysconfig/network/ifroute-#{nic.name}" do
        action :delete
      end
    end

  end
end
