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

class BarclampNetwork::Network < ActiveRecord::Base

  validate        :check_network_sanity
  after_create    :add_role
  after_save      :auto_prefix
  before_destroy  :remove_role

  attr_protected :id
  attr_accessible :name, :v6prefix, :description, :order, :conduit
  attr_accessible :deployment_id, :vlan, :use_vlan, :team_mode, :use_team, :use_bridge

  validates_format_of :v6prefix, :with=>/auto|([a-f0-9]){1,4}:([a-f0-9]){1,4}:([a-f0-9]){1,4}:([a-f0-9]){1,4}/, :message => I18n.t("db.v6prefix", :default=>"Invalid IPv6 prefix."), :allow_nil=>true

  has_many :ranges, :dependent => :destroy, :class_name => "BarclampNetwork::Range"
  has_many :allocations, :through => :ranges, :class_name => "BarclampNetwork::Allocation"
  has_one  :router, :dependent => :destroy, :class_name => "BarclampNetwork::Router"

  belongs_to :deployment

  def self.make_global_v6prefix
    prefix_array = []
    raw_prefix_array = (["fc".hex] + IO.read("/dev/random",5).unpack("C5"))
    3.times do |i|
      a = raw_prefix_array.pop
      a += (raw_prefix_array.pop << 8)
      prefix_array << a
    end
    prefix_array.reverse.map{|a|sprintf('%04x',a)}.join(':')
  end

  def template_cleaner(a)
    res = {}
    a.each do |k,v|
      next if k.to_s == "id" || k.to_s.match(/_id$/)
      res[k] = v.kind_of?(Hash) ? template_cleaner(v) : v
    end
    res
  end

  def to_template
    res = template_cleaner(attributes)
    res[:ranges] = ranges.map{|r|template_cleaner(r.attributes)}
    if router
      res[:router] = template_cleaner(n.router.attributes)
    end
    res
  end

  def role
    bc = Barclamp.where(:name => "network").first
    Role.where(:name => "network-#{name}", :barclamp_id => bc.id).first
  end

  def node_allocations(node)
    res = allocations.node(node).map do |a|
      a.address
    end
    res << node.auto_v6_address(self) if v6prefix
    res.sort
  end

  def make_node_role(node)
    nr = nil
    NodeRole.transaction do
      # do we have an existing NR?
      nr = NodeRole.where(:node_id => node.id, :role_id => role.id).first
      # if not, we have to create one
      if nr.nil?
        # we need to find a reasonable snapshot - use the current system head
        snap = Deployment.system_root.first.head
        nr = role.add_to_node_in_snapshot(node,snap)
      end
    end
    nr
  end

  private

  # for auto, we add an IPv6 prefix
  def auto_prefix
    # Add our IPv6 prefix.
    if (name == "admin" and v6prefix.nil?) || (v6prefix == "auto")
      BarclampNetwork::Setting.transaction do
        # this config code really needs to move to Crowbar base
        cluster_prefix = BarclampNetwork::Setting["v6prefix"]
        if cluster_prefix.nil?
          cluster_prefix = BarclampNetwork::Network.make_global_v6prefix
          BarclampNetwork::Setting["v6prefix"] = cluster_prefix
        end
        write_attribute("v6prefix",sprintf("#{cluster_prefix}:%04x",id))
        save!
      end
    end
  end

  # every network needs to have a matching role
  def add_role
    role_name = "network-#{name}"
    unless Role.find_key role_name
      bc = Barclamp.find_key "network"
      Role.transaction do
        r = Role.find_or_create_by_name(:name => role_name,
                                        :type => "BarclampNetwork::Role",   # force
                                        :jig_name => Rails.env.production? ? "chef-solo" : "test",
                                        :barclamp_id => bc.id,
                                        :description => I18n.t('automatic_by', :name=>name),
                                        :template => '{}',    # this will be replaced by the role
                                        :library => false,
                                        :implicit => true,
                                        :bootstrap => (self.name.eql? "admin"),
                                        :discovery => (self.name.eql? "admin")  )
        RoleRequire.create!(:role_id => r.id, :requires => "network-server")
        RoleRequire.create!(:role_id => r.id, :requires => "deployer-client") if Rails.env == "production"
        RoleRequire.create!(:role_id => r.id, :requires => "crowbar-installed-node") unless name == "admin"
        # attributes for jig configuraiton
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_addresses",
                         :description => "#{name} network addresses assigned to a node",
                         :map => "crowbar/network/#{name}/addresses")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_targets",
                         :description => "#{name} network addresses to be used as ping test targets",
                         :map => "crowbar/network/#{name}/targets")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_conduit",
                         :description => "#{name} network conduit map for this node",
                         :map => "crowbar/network/#{name}/conduit")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_resolved_conduit",
                         :description => "#{name} network interfaces used on this node",
                         :map => "crowbar/network/#{name}/resolved_interfaces")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_vlan",
                         :description => "#{name} network vlan tag",
                         :map => "crowbar/network/#{name}/vlan")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_team_mode",
                         :description => "#{name} network bonding mode",
                         :map => "crowbar/network/#{name}/team_mode")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_use_vlan",
                         :description => "Whether the #{name} network should use a tagged VLAN interface",
                         :map => "crowbar/network/#{name}/use_vlan")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_use_team",
                         :description => "Whether the #{name} network should bond its interfaces",
                         :map => "crowbar/network/#{name}/use_team")
        ::Attrib.create!(:role_id => r.id,
                         :barclamp_id => bc.id,
                         :name => "#{role_name}_use_bridge",
                         :description => "Whether #{name} network should create a bridge for other barclamps to use",
                         :map => "crowbar/network/#{name}/use_bridge")
        # attributes for hint
        ::Attrib.create!(:role_id => r.id,
           :barclamp_id => bc.id,
           :name => "hint-#{role_name}-v4addr",
           :description => "Hint for #{name} network to assign v4 IP address",
           :map => "v4addr")
      end
    end
  end

  def remove_role
    raise 'delete of network/network-role only allowed in developer mode for testing' unless Rails.env.development?
    rid = self.id
    Role.destroy_all :name=>"network-#{name}"
    Attrib.destroy_all :role_id => rid
  end

  def check_network_sanity

    # First, check the conduit to be sure it is sane.
    intf_re =  /^([-+?]?)(\d{1,3}[mg])(\d+)$/
    if conduit.nil? || conduit.empty?
      errors.add("Network #{name}: Conduit definition cannot be empty")
    end
    intfs = conduit.split(",").map{|intf|intf.strip}
    ok_intfs, failed_intfs = intfs.partition{|intf|intf_re.match(intf)}
    unless failed_intfs.empty?
      errors.add("Network #{name}: Invalid abstract interface names in conduit: #{failed_intfs.join(", ")}")
    end
    matches = intfs.map{|intf|intf_re.match(intf)}
    tmpl = matches[0]
    if ! matches.all?{|i|(i[1] == tmpl[1]) && (i[2] == tmpl[2])}
      errors.add("Network #{name}: Not all abstract interface names have the same speed and flags: #{conduit}")
    end

    # Conduit is sane, check to see that it satisfies the overlap constraints for interacting
    # with other networks.
    # Either all the interfaces in a conduit must overlap perfectly, or none of them can.
    ifhash = Hash.new
    intfs.each{ |i| ifhash[i] = true }

    BarclampNetwork::Network.all.each do |net|
      # A conduit definition can overlap with another conduit definition either perfectly or not at all.
      nethash = Hash.new
      net.conduit.split(",").map{|i|i.strip}.each do |i|
        nethash[i] = true
      end
      next if nethash == ifhash
      nethash.keys.each do |k|
        next unless ifhash[k]
        errors.add("Network #{name}: Conduit mapping overlaps with #{net.name} at abstract interface #{k}}")
      end
    end

    # Check to see that requested VLAN information makes sense.
    if use_vlan && !(1..4095).member?(vlan)
      errors.add("Network #{name}: VLAN #{vlan} not sane")
    end

    # Check to see if our requested teaming makes sense.
    if use_team
      if intfs.length < 2
        errors.add("Network #{name}: Want bonding, but requested conduit #{conduit} has one member")
      elsif intfs.length > 8
        errors.add("Network #{name}: Want bonding, but requested conduit #{conduit} has too many members")
      end
      errors.add("Network #{name}: Invalid bonding mode") unless (0..6).member?(team_mode)
    else
      # Conduit can only contain one abstract interface if we don't want bonding.
      unless intfs.length == 1
        errors.add("Network #{name}: Do not want bonding, but requested conduit #{conduit} has multiple members")
      end
    end

    # Should be obvious, but...
    unless name && !name.empty?
      errors.add("Cannot create a network without a name")
    end

    # We also must have a deployment
    unless deployment
      errors.add("Cannot create a network without binding it to a deployment")
    end

  end
end
