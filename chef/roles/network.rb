name "network"
description "Network role - Setups the network"
run_list  "recipe[network]","recipe[network::fast_nics_tune]"

