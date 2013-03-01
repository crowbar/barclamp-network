
name "network"
description "Network role - Setups the network"
run_list("recipe[network]")
# These attributes are for scaffolding purposes ONLY!
# Once the crowbar framework side of things is functional, they
# need to go away.
host_name = %x{hostname}
default_attributes({ "network" => {
    "start_up_delay" => 30,
    "mode" => "single",
    "teaming" => {
      "mode" => 6
    },
    "conduit_map" => [
                      {
                        "pattern" => ".*/.*/.*",
                        "conduit_list" => {
                          "intf0" => {
                            "if_list" => [
                                          "1g1"
                                         ]
                          },
                          "intf1" => {
                            "if_list" => [
                                          "1g1"
                                         ]
                          },
                          "intf2" => {
                            "if_list" => [
                                          "1g1"
                                         ]
                          }
                        }
                      }
                     ],
    "networks" => {
      "admin" => {
        "conduit" => "intf0",
        "vlan" => 100,
        "use_vlan" => false,
        "add_bridge" => false,
        "subnet" => "192.168.124.0/24",
        "dhcp_enabled" => false,
        "router" => "192.168.124.1",
        "router_pref" => 10, 
        "ranges" => {
          "admin" => { "start" => "192.168.124.10", "end" => "192.168.124.11" },
          "dhcp" => { "start" => "192.168.124.21", "end" => "192.168.124.80" },
          "host" => { "start" => "192.168.124.81", "end" => "192.168.124.160" },
          "switch" => { "start" => "192.168.124.241", "end" => "192.168.124.250" }
        }
      }
    },
    "config" => { "environment" => "network-base-config" }
  },
  "crowbar" => {
    "network" => {
      "admin" => {
        "subnet" => "192.168.124.0",
        "add_bridge" => false,
        "router_pref" => 10,
        "router" => "192.168.124.1",
        "address" => "192.168.124.10",
        "ranges" => {
          "switch" => { "start" => "192.168.124.241", "end" => "192.168.124.250" },
          "admin" => { "start" => "192.168.124.10", "end" => "192.168.124.11" },
          "dhcp" => { "start" => "192.168.124.21", "end" => "192.168.124.80" },
          "host" => { "start" => "192.168.124.81", "end" => "192.168.124.160" } },
        "netmask" => "255.255.255.0",
        "use_vlan" => false,
        "conduit" => "intf0",
        "usage" => "admin",
        "vlan" => 100,
        "broadcast" => "192.168.124.255",
        "node" => "#{host_name}"
      }
    }
  }
})
override_attributes()

