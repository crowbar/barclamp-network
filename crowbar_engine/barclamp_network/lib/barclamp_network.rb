require "barclamp_network/engine"

module BarclampNetwork

  TABLE_PREFIX = "bc_net_"

  
  def self.table_name_prefix
    TABLE_PREFIX
  end

  # Leave this in place for now until we decide on a better way to
  # dynamically create a role per network.
  module Role
    module NetworkAdmin
      def on_todo(nr)
        NodeRole.transaction do
          d = nr.sysdata
          addresses = (d["crowbar"]["network"]["admin"]["addresses"] rescue nil)
          return if addresses && !addresses.empty?
          d["crowbar"] ||= Hash.new
          d["crowbar"]["network"] ||= Hash.new
          d["crowbar"]["network"]["admin"] ||= Hash.new
          d["crowbar"]["network"]["admin"]["addresses"] = nr.node.admin ? ["192.168.124.10/24"] : ["192.168.124.81/24"]
          nr.sysdata = d
          nr.save!
        end
      end
    end
  end
end
