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

  validate :check_network_sanity

  attr_protected :id, :name
  attr_accessible :description, :order, :conduit
  has_many :ranges, :dependent => :destroy, :class_name => "BarclampNetwork::Range"
  has_one  :router, :dependent => :destroy, :class_name => "BarclampNetwork::Router"
  belongs_to :deployment

  # We need a wrapper around create! that also creates the proper role
  # for the specific network we are creating.
  def self.make_network(args)
    allowed_keys = { :name => true, :deployment_id => true,
      :vlan => true, :use_vlan => true, :team_mode => true,
      :use_team => true, :conduit => true }
    c_ranges = args.delete(:ranges)
    c_ranges = JSON.parse(c_ranges) if c_ranges.kind_of?(String)
    c_router = args.delete(:router)
    c_router = JSON.parse(c_router) if c_router.kind_of?(String)
    res = create!(args.delete_if{|k,v|!allowed_keys[k]})
    begin
      if c_ranges.nil? || c_ranges.empty?
        raise ArgumentError.new("A network must have at least one range!")
      end
      c_ranges.each do |range|
        r = BarclampNetwork::Range.new(:network_id => res.id,
                                       :name => range["name"])
        r.first = range["first"]
        r.last = range["last"]
        r.save!
      end
      if c_router
        BarclampNetwork::Router.create!(:network_id => res.id,
                                        :pref => c_router["pref"],
                                        :address => c_router["address"])
      end

      bc = Barclamp.where(:name => "network").first
      Role.transaction do
        r = Role.find_or_create_by_name(:name => "network-#{args[:name]}",
                                        :jig_name => Rails.env == "production" ? "chef" : "test",
                                        :barclamp_id => bc.id)
        r.update_attributes(:description => I18n.t('automatic_by', :name=>bc.name),
                            :template => '{}',
                            :library => false,
                            :implicit => false,
                            :bootstrap => (res.name == "admin"),
                            :discovery => (res.name == "admin")
                          )
        r.save!
        RoleRequire.create!(:role_id => r.id, :requires => "network-server")
        if Rails.env == "production"
          RoleRequire.create!(:role_id => r.id, :requires => "deployer-client")
        end
      end
    rescue Exception => e
      res.destroy rescue nil
      raise e
    end
    res
  end

  def template_cleaner(a)
    a.reject do |k,v|
      k.to_s == "id" || k.to_s.match(/_id$/)
    end
  end
  
  def to_template
    res = template_cleaner(attributes)
    res[:ranges] = ranges.map{|r|template_cleaner(r.attributes)}
    if router
      res[:router] = template_cleaner(n.router.attributes)
    end
    res.to_json
  end

  def role
    bc = Barclamp.where(:name => "network").first
    Role.where(:name => "network-#{name}", :barclamp_id => bc.id).first
  end

  def allocations
    ranges.map{|range| range.allocations}.flatten
  end

  def node_allocations(node)
    ranges.order("name").map do |range|
      range.allocations.where(:node_id => node.id).map do |a|
        a.address.to_s
      end.sort
    end.flatten
  end

  def make_node_role(node)
    nr = nil
    NodeRole.transaction do
      nr = NodeRole.where(:node_id => node.id, :role_id => role.id).first ||
        role.add_to_node_in_snapshot(node,snap)
      nr.sysdata = { "crowbar" => { "network" => { name => {"addresses" => node_allocations(node)}}}}
    end
    nr
  end

  private

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
