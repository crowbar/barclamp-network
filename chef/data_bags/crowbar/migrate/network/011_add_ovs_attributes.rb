def upgrade(ta, td, a, d)
  a["networks"]["nova_floating"]["add_ovs_bridge"] = ta["networks"]["nova_floating"]["add_ovs_bridge"]
  a["networks"]["nova_floating"]["bridge_name"] = ta["networks"]["nova_floating"]["bridge_name"]
  a["networks"]["nova_fixed"]["add_ovs_bridge"] = ta["networks"]["nova_fixed"]["add_ovs_bridge"]
  a["networks"]["nova_fixed"]["bridge_name"] = ta["networks"]["nova_fixed"]["bridge_name"]

  return a, d
end

def downgrade(ta, td, a, d)
  a["networks"]["nova_floating"].delete "add_ovs_bridge"
  a["networks"]["nova_floating"].delete "bridge_name"
  a["networks"]["nova_fixed"].delete "add_ovs_bridge"
  a["networks"]["nova_fixed"].delete "bridge_name"

  return a, d
end
