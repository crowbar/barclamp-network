# Copyright 2011, Dell
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

include_recipe 'utils'

$bond_count = 0
team_mode = node["network"]["teaming"]["mode"]

# Walk through a hash of interfaces, adding :order tags to each
# interface that reflects the order in which they should be brought up in.
# They should be torn down in reverse order. 
def sort_interfaces(interfaces)
  seq=0
  i=interfaces.keys.sort
  until i.empty?
    i.each do |ifname|
      iface=interfaces[ifname]
      iface[:interface_list] ||= Array.new
      iface[:interface_list] = iface[:interface_list].sort
      # If this interface has children, and any of its children have not
      # been given a sequence number, skip it.
      next if not iface[:interface_list].empty? and 
          not iface[:interface_list].all? {|j| interfaces[j].has_key?(:order)}
      iface[:order] = seq
      seq=seq + 1
    end
    unless i.any? {|j| interfaces[j][:order]}
      raise ::RangeError.new("Interfaces #{i.inspect} touched, but no sequence numbers assigned!\nThis should never happen.")
    end 
    i=interfaces.keys.sort.reject{|k| interfaces[k].has_key?(:order)}
  end
  interfaces
end

# Parse the contents of /etc/network/interfaces, and return a data structure
# equivalent to the one we get from Chef.
def local_debian_interfaces
  res={}
  iface=''
  File.foreach("/etc/network/interfaces") {|line|
    line = line.chomp.strip.split('#')[0] # strip comments
    next if line.nil? or ( line.length == 0 ) # skip blank lines
    parts = line.split
    case parts[0]
    when "auto"
      parts[1..-1].each { |name|
        next if name == "lo"
        res[name] ||= Hash.new
        res[name][:auto] = true
        res[name][:interface] ||= name
      }
    when "iface"
      iface = parts[1]
      next if iface == "lo"
      res[iface] ||= Hash.new 
      res[iface][:interface] = iface
      res[iface][:interface_list] = Array.new
      res[iface][:config] = parts[3]
    when "address" then res[iface][:ipaddress] = parts[1]
    when "netmask" then res[iface][:netmask] = parts[1]
    when "broadcast" then res[iface][:broadcast] = parts[1]
    when "gateway" then res[iface][:router] = parts[1]
    when "bridge_ports" then 
      res[iface][:mode] = "bridge"
      res[iface][:interface_list] = parts[1..-1]
      res[iface][:interface_list].each do |i|
        res[i] ||= Hash.new
        res[i][:bridge]=iface
      end
    when "vlan_raw_device" then
      res[iface][:mode] = "vlan"
      res[iface][:vlan] = iface.split('.',2)[1].to_i
      res[iface][:interface_list] = Array[ parts[1] ]
    when "down" then 
      res[iface][:mode] = "team"
      res[iface][:interface_list] = parts[4..-1]
      res[iface][:interface_list].each do |i|
        res[i] ||= Hash.new
        res[i][:master]=iface
        res[i][:slave]=true
      end
    end
  }
  sort_interfaces(res)
end

def local_suse_interfaces
  res = {}

  ::Dir.entries("/etc/sysconfig/network").sort.each do |entry|
    next unless entry =~ /^ifcfg-/
    next if entry == "ifcfg-lo"
    iface = entry.split('-',2)[1]
    res[iface]=Hash.new unless res[iface]
    res[iface][:interface]=iface
    if File.exist?("/etc/sysconfig/network/ifroute-#{iface}") then
        ::File.foreach("/etc/sysconfig/network/ifroute-#{iface}") do |line|
          line = line.chomp.strip.split('#')[0] # strip comments
          next if line.nil? or ( line.length == 0 ) # skip blank lines
          parts = line.split(' ', 4)
          next if parts[0] != "default"
          res[iface][:router] = parts[1]
        end
    end
    ::File.foreach("/etc/sysconfig/network/#{entry}") do |line|
      line = line.chomp.strip.split('#')[0] # strip comments
      next if line.nil? or ( line.length == 0 ) # skip blank lines
      parts = line.split('=',2)
      k=parts[0]
      v=parts[1][/\A['"](.*)["']\z/m,1]  # Remove start/end quotes from the string
      v=parts[1] if v.nil?
      case k
      when "STARTMODE"
        res[iface][:auto] = true when v == "auto"
      when "BOOTPROTO" then res[iface][:config] = v
      when "IPADDR"
        res[iface][:ipaddress] = v
      when "NETMASK"
        res[iface][:netmask] = v
      when "BROADCAST"
        res[iface][:broadcast] = v

      # bonds:
      when "BONDING_MODULE_OPTS"
        res[iface][:bond_opts] = v
      when "BONDING_MASTER" 
        next unless v == "yes"
        res[iface][:mode] = "team"
      when /^BONDING_SLAVE_/
        res[iface][:interface_list] ||= []
        res[iface][:interface_list] << v

      # bridges:
      when "BRIDGE"
        next unless v == "yes"
        res[iface][:mode] = "bridge"
      when "BRIDGE_PORTS"
        res[iface][:interface_list] = v.split
        v.split.each do |i|
          res[i]=Hash.new unless res[i]
          res[i][:bridge]=iface
        end

      # VLANs:
      when "ETHERDEVICE"
        res[iface][:mode] = "vlan"
        res[iface][:vlan] ||= iface.split('.',2)[1].to_i
        res[iface][:interface_list]=[v]
      when "VLAN_ID"
        res[iface][:vlan] ||= v.to_i
      end
    end
    if res[iface][:config] == "none"
      res[iface][:config] = if res[iface][:ipaddress]
                              "static"
                            else
                              "manual"
                            end
    end
    res[iface][:auto] = false unless res[iface][:auto]
  end
  sort_interfaces(res)
end

def local_redhat_interfaces
  res = {}
  ::Dir.entries("/etc/sysconfig/network-scripts").sort.each do |entry|
    next unless entry =~ /^ifcfg/
    next if entry == "ifcfg-lo"
    iface = entry.split('-',2)[1]
    res[iface] ||= Hash.new
    ::File.foreach("/etc/sysconfig/network-scripts/#{entry}") do |line|
      line = line.chomp.strip.split('#')[0] # strip comments
      next if line.nil? or ( line.length == 0 ) # skip blank lines
      parts = line.split('=',2)
      k=parts[0]
      v=parts[1][/\A"(.*)"\z/m,1]  # Remove start/end quotes from the string
      v=parts[1] if v.nil?
      case k
      when "DEVICE" then res[iface][:interface]=v
      when "ONBOOT" 
        res[iface][:auto] = true when v == "yes"
      when "BOOTPROTO" then res[iface][:config] = v
      when "IPADDR"
        res[iface][:ipaddress] = v
      when "NETMASK" then res[iface][:netmask] = v
      when "BROADCAST" then res[iface][:broadcast] = v
      when "BONDING_OPTS" then res[iface][:bond_opts] = v
      when "GATEWAY" then res[iface][:router] = v
      when "MASTER" 
        res[iface][:master] = v
        res[v] ||= Hash.new
        res[v][:mode] = "team"
        res[v][:interface_list] ||= Array.new
        res[v][:interface_list].push(iface)
      when "SLAVE"
        res[iface][:slave] = true if v == "yes"
      when "BRIDGE"
        res[iface][:bridge] = v
        res[v] ||= Hash.new
        res[v][:mode] = "bridge"
        res[v][:interface_list] ||= Array.new 
        res[v][:interface_list].push(iface)
      when "VLAN"
        res[iface][:mode] = "vlan"
        res[iface][:vlan] = iface.split('.',2)[1].to_i
        res[iface][:interface_list]=[iface.split('.',2)[0]]
      end
    end
    if res[iface][:config] == "none"
      res[iface][:config] = if res[iface][:ipaddress]
                              "static"
                            else
                              "manual"
                            end
    end
    res[iface][:auto] = false unless res[iface][:auto]
  end
  sort_interfaces(res)
end

def crowbar_interfaces()
  conduit_map = Barclamp::Inventory.build_node_map(node)
  Chef::Log.info("Conduit mapping for this node:  #{conduit_map.inspect}")
  res = Hash.new
  # seems that we can only have 1 bonding mode is possible per machine
  machine_team_mode = nil
  ## find most prefered network to use a default gw
  max_pref = 10000
  # name of network prefered as default route - default admin net.
  net_pref = "admin"
  node["crowbar"]["network"].each { |name, network | 
    r_pref = 10000
    r_pref= Integer(network["router_pref"]) if network["router_pref"]
    Chef::Log.debug("eval router from #{name}, pref #{r_pref}")
    if (r_pref < max_pref)
      max_pref = r_pref
      net_pref = name
    end
  }
  Chef::Log.info("will allow routers from #{net_pref}")
  node["crowbar"]["network"].each do |netname, network|
    next if netname == "bmc"
    allow_gw = (netname == net_pref)

    conduit = network["conduit"]
    intf, interface_list, tm = Barclamp::Inventory.lookup_interface_info(node, conduit, conduit_map)
    if intf.nil?
      Chef::Log.fatal("No conduit for interface: #{conduit}")
      Chef::Log.fatal("Refusing to do so.")
      raise ::RangeError.new("No conduit to interface map for #{conduit}")
    end

    if intf =~ /^bond/
      tm = team_mode if tm.nil? 
      machine_team_mode = tm if machine_team_mode.nil?
      if (!machine_team_mode.nil? and !machine_team_mode == tm)
          # once a bonding mode has been selected for the machine, don't let others...
	  Chef::Log.warn("CONFLICTING TEAM MODES: for conduit #{conduit}")
      end
      res[intf] ||= Hash.new
      res[intf][:interface_list] = interface_list
      unless interface_list && ! interface_list.empty?
        raise ::RangeError.new("No slave interfaces for #{intf}")
      end
      res[intf][:mode] = "team"
      res[intf][:interface] = intf
      case node[:platform]
      when "ubuntu","debian"
        # No-op
      when "centos","redhat","suse"
        res[intf][:bond_opts] = "mode=#{tm} miimon=100"
      end
      # Since we are making a team out of these devices, blow away whatever
      # config we may have had for the slaves.
      res[intf][:interface_list].each do |i|
        res[i]=Hash.new
        res[i][:interface]=i
        res[i][:auto]=true
        res[i][:config]="manual"
        res[i][:slave]=true
        res[i][:master]=intf
      end
      interface_list = [ intf ]
    end

    # Handle vlans first.
    if network["use_vlan"]
      intf = "#{intf}.#{network["vlan"]}"
      res[intf] ||= Hash.new
      res[intf][:interface] = intf
      res[intf][:auto] = true
      res[intf][:vlan] = network["vlan"]
      res[intf][:mode] = "vlan"
      res[intf][:interface_list] = interface_list
      res[intf][:interface_list].each do |i|
        unless res[i]
          res[i] = Hash.new
          res[i][:interface] = i
          res[i][:auto] = true
          res[i][:config] = "manual" if res[i][:ipaddress].nil?
        end
      end
    else
      res[intf] ||= Hash.new
      res[intf][:interface] = intf
      res[intf][:auto] = true
    end
    # If we were asked to make a bridge, do it second.
    if network["add_bridge"]
      # We have to make up a bridge name here
      res[intf][:bridge]=if res[intf][:vlan] 
                           "br#{res[intf][:vlan]}"
                         else
                           "br#{intf}"
                         end
      # That base interface now has a manual config
      res[intf][:config]="manual"
      base_if=intf
      intf=res[intf][:bridge]
      res[intf] ||= Hash.new
      res[intf][:interface] = intf
      res[intf][:interface_list] = [ base_if ]
      res[intf][:auto] = true
      res[intf][:mode]="bridge"
    end
    if network["address"] and network["address"] != "0.0.0.0"
      res[intf][:config] = "static"
      res[intf][:ipaddress] = network["address"]
      res[intf][:netmask] = network["netmask"]
      res[intf][:broadcast] = network["broadcast"]
      res[intf][:router] = network["router"] if network["router"] && allow_gw
    else
      res[intf][:config] = "manual"
    end
  end  ## crowbar/network loop
  team_mode = machine_team_mode
  node["network"]["teaming"]["mode"] = team_mode
  sort_interfaces(res)
end

package "bridge-utils"

## Make sure that ip6tables is off.
#bash "Make sure ip6tables is off" do
#  code "/sbin/chkconfig ip6tables off"
#  only_if "/sbin/chkconfig --list ip6tables | grep -q on"
#end
#
## Make sure that ip6tables service is off
#bash "Make sure ip6tables service is off" do
#  code "service ip6tables stop"
#  not_if "service ip6tables status | grep -q stopped"
#end

bash "load 8021q module" do
  code "/sbin/modprobe 8021q"
  not_if { ::File.exists?("/sys/module/8021q") }
end

delay = false
old_interfaces = case node[:platform]
                 when "debian","ubuntu"
                   local_debian_interfaces
                 when "centos","redhat"
                   local_redhat_interfaces
                 when "suse"
                   local_suse_interfaces
                 end
new_interfaces = crowbar_interfaces
interfaces_to_up={}

case node[:platform]
when "ubuntu","debian"
  package "vlan"
  package "ifenslave-2.6"

  utils_line "8021q" do
    action :add
    file "/etc/modules"
  end

  if node["network"]["mode"] == "team"
    # make sure to pick up any updates
    team_mode = node["network"]["teaming"]["mode"]
    utils_line "bonding mode=#{team_mode} miimon=100" do
      action :add
      regexp_exclude "bonding mode=.*"
      file "/etc/modules"
    end
    bash "load bonding module" do
      code "/sbin/modprobe bonding mode=#{team_mode} miimon=100"
      not_if { ::File.exists?("/sys/module/bonding") }
    end
  end
when "centos","redhat"
  package "vconfig"

  if node["network"]["mode"] == "team"
    new_interfaces.keys.each do |i|
      next unless new_interfaces[i][:mode] == "team"
      utils_line "alias #{i} bonding" do
        action :add
        file "/etc/modprobe.conf"
      end
    end
  end
end

def deorder(i)
  i.reject{|k,v|k == :order or v.nil? or (v.respond_to?(:empty?) and v.empty?)}
end

def only_router_changed(a,b)
  deorder(a.reject{|k,v| k == :router}) == deorder(b.reject{|k,v| k== :router})
end

Chef::Log.info("Current interfaces:\n#{old_interfaces.inspect}\n")
Chef::Log.info("New interfaces:\n#{new_interfaces.inspect}\n")

if (not new_interfaces) or new_interfaces.empty?
  Chef::Log.fatal("Crowbar instructed us to tear down all our interfaces!")
  Chef::Log.fatal("Refusing to do so.")
  raise ::RangeError.new("Not enough active network interfaces.")
end

# Third, rewrite the network configuration to match the new config.
case node[:platform]
when "ubuntu","debian"
  template "/etc/network/interfaces" do
    source "interfaces.erb"
    variables :interfaces => new_interfaces.values.sort{|a,b| 
      a[:order] <=> b[:order]
    }
  end
when "centos","redhat"
  new_interfaces.values.each do |iface|
    template "/etc/sysconfig/network-scripts/ifcfg-#{iface[:interface]}" do
      source "redhat-cfg.erb"
      variables :iface => iface
    end
  end
when "suse"
  new_interfaces.values.each do |iface|
    template "/etc/sysconfig/network/ifcfg-#{iface[:interface]}" do
      source "suse-cfg.erb"
      variables :iface => iface
    end
    template "/etc/sysconfig/network/ifroute-#{iface[:interface]}" do
      source "suse-route.erb"
      variables :iface => iface
    end
  end
end

# First, tear down any interfaces that are going to be deleted in 
# reverse order in which they appear in the current /etc/network/interfaces
(old_interfaces.keys - new_interfaces.keys).sort {|a,b| 
  old_interfaces[b][:order] <=> old_interfaces[a][:order]}.each do |i|
  next if i.nil? or i == ""
  Chef::Log.info("Removing #{old_interfaces[i]}\n")
  bash "ifdown #{i} for removal" do
    code "ifdown #{i}"
    ignore_failure true
  end
  case node[:platform]
  when "ubuntu","debian"
    # No-op
  when "centos","redhat"
    file "/etc/sysconfig/network-scripts/ifcfg-#{i}" do
      action :delete
    end
  end
end

# Second, examine each interface that exists in both the old and the
# new configuration to see what changed, and take appropriate action.
(old_interfaces.keys & new_interfaces.keys).sort {|a,b|
  new_interfaces[a][:order] <=> new_interfaces[b][:order]}.each do |i|
  case
  when deorder(old_interfaces[i]) == deorder(new_interfaces[i])
    # The only thing that changed is the proposed position in the interfaces
    # file.  Don't do anything with this interface.
    Chef::Log.info("#{i} did not change, skipping.")
  when only_router_changed(old_interfaces[i], new_interfaces[i])
    Chef::Log.info("Default route through #{i} changed, handling specially.")
    if old_interfaces[i][:router]
      bash "Remove default route through #{i}" do
        code "ip route del default via #{old_interfaces[i][:router]} dev #{i}"
        only_if "ip route show dev #{i} |grep -q default"
      end
    end
    if new_interfaces[i][:router]
      bash "Add default route through #{i}" do
        code "ip route add default via #{new_interface[i][:router]} dev #{i}"
        not_if "ip route show dev #{i} |grep -q default"
      end
    end
  when old_interfaces[i][:config].start_with?("dhcp")
    Chef::Log.info("Taking ownership of #{i}")
    # We are going to transition an interface into being owned by Crowbar.
    # Kill any dhclients for this interface, and then take action
    # based on whether we are giving it an IP address or not.
    bash "kill dhclient3" do
      code "killall dhclient3 ; rm -rf /etc/dhclient*"
      only_if "pidof dhclient3"
    end
    bash "kill dhcpcd" do
      code "killall dhcpcd"
      only_if "pidof dhcpcd"
    end
    if new_interfaces[i][:config] == "static"
      # We are giving it a static IP.  Schedule the interface to be 
      # forced up with the new config, which should give it the new 
      # configuration without taking the link down.
      # We rely on our static network config being otherwise identical
      # to our DHCP config.
      interfaces_to_up[i] = "ifup #{i}"
    else
      # We are giving it a manual config.  Ifdown the interface, and then
      # schedule it to be ifup'ed based on whether or not :auto is true.
      interfaces_to_up[i] = "ifup #{i}" if new_interfaces[i][:auto]
    end
  else
    Chef::Log.info("Transitioning #{i}:\n#{old_interfaces[i].inspect}\n=>\n#{new_interfaces[i].inspect}\n")
    # The interface changed, and it is not a matter of taking ownership
    # from the OS.  ifdown it now, and schedule it to be ifup'ed if 
    # the new config is set to :auto.
    bash "ifdown #{i} for reconfigure" do
      code "ifdown #{i}"
      ignore_failure true
    end
    interfaces_to_up[i] = "ifup #{i}" if new_interfaces[i][:auto]
  end
end

# Fourth, bring up any new or changed interfaces
new_interfaces.values.sort{|a,b|a[:order] <=> b[:order]}.each do |i|
  next if i[:interface] == "bmc"
  case
  when (old_interfaces[i[:interface]].nil? and i[:auto])
    # This is a new interface.  Ifup it if it should be auto ifuped.
    bash "ifup new #{i[:interface]}" do
      code "ifup #{i[:interface]}"
      ignore_failure true
    end
  when interfaces_to_up[i[:interface]]
    # This is an interface that we had in common with old_interfaces that
    # did not have an identical configuration from the last time.
    # We need to bring it up according to the instructions left behind.
    bash "ifup reconfigured #{i[:interface]}" do
      code interfaces_to_up[i[:interface]]
      ignore_failure true
    end
  end
  # Only delay if we ifup'ed a real physical interface.
  delay = ::File.exists? "/sys/class/net/#{i}/device" unless delay
end

# If we need to sleep now, do it.
delay_time = delay ? node["network"]["start_up_delay"] : 0
Chef::Log.info "Sleeping for #{delay_time} seconds due new link coming up"
bash "network delay sleep" do
  code "sleep #{delay_time}"
  only_if { delay_time > 0 }
end

