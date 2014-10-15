def upgrade ta, td, a, d
  a['networks'].delete('nova_fixed')
  a['networks'].delete('nova_floating')

  return a, d
end

def downgrade ta, td, a, d

  ['floating', 'fixed'].each do |name|
    db = ProposalObject.find_data_bag_item "crowbar/#{name}_network"
    unless db.nil?
      network = "nova_#{name}"
      a['networks'][network] = db['network']
      a['networks'][network]['add_bridge'] = ta['networks'][network]['add_bridge']
      a['networks'][network]['router_pref'] = ta['networks'][network]['router_pref']
      a['networks'][network].delete('external')
      db.destroy
    end
  end

  Chef::Search::Query.new.search(:node) do |node|
    if node[:crowbar_wall][:network][:nets]['fixed']
      node[:crowbar_wall][:network][:nets]['nova_fixed'] = node[:crowbar_wall][:network][:nets]['fixed']
      node[:crowbar_wall][:network][:nets].delete('fixed')
      node.save
    end
  end

  return a, d
end
