def upgrade ta, td, a, d
  a['networks']['nova_floating']['router'] = a['networks']['public']['router']
  a['networks']['nova_floating']['router_pref'] = ta['networks']['nova_floating']['router_pref']
  return a, d
end


def downgrade ta, td, a, d
  a['networks']['nova_floating'].delete('router')
  a['networks']['nova_floating'].delete('router_pref')
  return a, d
end

