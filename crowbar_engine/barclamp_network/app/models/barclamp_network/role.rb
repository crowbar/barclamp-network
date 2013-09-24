class BarclampNetwork::Role < Role


  def network
    BarclampNetwork::Network.where(:name => "#{name.split('-',2)[-1]}").first
  end

  # Our template == the template that our matching network definition has.
  # For now, just hashify the stuff we care about[:ranges]
  def template
    "{\"crowbar\": {\"network\": {\"#{network.name}\": #{network.to_template} } } }"
  end

  def jig_role(name)
    chef_role = Chef::Role.new
    chef_role.name(name)
    chef_role.description("#{name}: Automatically created by Crowbar")
    chef_role.run_list(Chef::RunList.new("recipe[network]"))
    chef_role.save
    true
  end

  def on_proposed(nr)
    NodeRole.transaction do
      d = nr.sysdata
      addresses = (d["crowbar"]["network"][network.name]["addresses"] rescue nil)
      return if addresses && !addresses.empty?
      addr_range = nr.role.network.ranges.where(:name => nr.node.admin ? "admin" : "host").first
      addr_range.allocate(nr.node)
    end
  end
end
