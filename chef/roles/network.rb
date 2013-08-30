name "network"
description "Network role - Setups the network"
run_list("recipe[network]")
# These attributes are for scaffolding purposes ONLY!
# Once the crowbar framework side of things is functional, they
# need to go away.
host_name = %x{hostname}
default_attributes()
override_attributes()
