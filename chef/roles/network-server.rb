name "network-server"
description "Network role - Setups the network"
run_list()
# These attributes are for scaffolding purposes ONLY!
# Once the crowbar framework side of things is functional, they
# need to go away.
host_name = %x{hostname}
default_attributes()
override_attributes()
