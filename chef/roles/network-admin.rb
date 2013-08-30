name "network-admin"
description "Manages the admin network."
run_list("recipe[network]")
host_name = %x{hostname}
default_attributes()
override_attributes()
