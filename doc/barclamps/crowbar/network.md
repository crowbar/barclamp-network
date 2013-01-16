### Network Barclamp ###
### Rules ###
* External or Public network: When this is reference, the definition is the network that is not internall to the this solution.  it could be an internet routerable IP, Private Lab, or even Corporate network.
* router_pref: When this is used it must unique to each network.  No two or more networks can have teh same number, even if they are on the same vlan.
* router_pref: the lowest number is used to set the default route on the host in quesiton

### Sections ###
* Storage
 * Used by the Swift System to handle all interactions between Swift nodes and Swift-Proxy.
 * External Access: Ineternal Only.  Highly recommended to not have external connectivity as it has all the storage data on it.
 * Router and  router_pref are optional
 * Ranges - requires section "host"
     * "host" - used to assign IP addresses to each of the Swift nodes.
 * No special rules.
* Public
 * Used by nova-compute, nova-controller, admin, and swift-proxy to access the external network
 * External Access - Yes this is how the nodes will talk beyond the Solution
 * router and router_pref - Required.? router_pref must be the lowest number of all.
 * Ranges - requires the sections "host" and "dhcp"
     * "host" used to assign an IP to each node
     * "dhcp" reserved but must be defined
 * Rules - router_pref must be the lowest defined
* Nova_floating
 * Used by nova to create the floating network in the nova database
 * External Access - Yes
 * No additional?- router and router_pref must not be defined
 * Ranges - requires section on "host"
     * "host" used to assign an IP to each node
 * Rules 
     * Network must be a logical subnet of the public range
     * Subnet is a logical subnet of the public range
     * Example - Public is 192.168.123.0/24 and nova floating then can be 192.168.123.64/26 or 192.168.123.128/26
* Nova_fixed
 * Used by nova to create the private(backend) network in the nova database
 * External Access - None
 * No additional - router and router_pref should not be defined, but if Public will always win
 * Ranges - requires "host" and? "dhcp"
     * "host" used to assign an IP to each node
     * "dhcp"? is used to create the nova database
 * Rules - No special rules
* Bmc
 * Used by each computer to setup? IPMI configurable device
 * External Access - Possible
 * router and router_pref are optional items 
 * Ranges - requires only "host"
 * Rules - if it is separate from the "admin" network then bmc_vlan must be the same network
* Bmc_vlan
 * Used by the admin node to control the IPMI configurable devices
 * External Access - Not required but helpful
 * No additional sections
 * Ranges "host"? used to give the admin node access to the BMC's
 * Rules - Must be the same subnet as the BMC
* Admin
 * Used by all each computer to communication with the Crowbar Server and for all Nova work
 * External Access - Not required but helpful
 * router and router_pref are required
 * Ranges - requires "host", "dhcp", "switch", and "admin"
 * Rules - no special rules

### Stanza ###
 *  conduit - Name of the conduit this network is to use.? 
      *  When more than one network can uses the same conduit, the interfaces can become dual homed depending on the add_bridge and use_vlan
 * vlan - the Vlan Number assigned to that network.? This comes into play when the use_vlan is set to 'true'.
 *  use_vlan - 'true' or 'false'
     * When set to true, the node will be configure to use 802.1q vlan tagging.? A like rule will need to be created on the switch to accept the tagged packet.
 * add_bridge - 'true' or 'false'
     * When set to 'true', the node will bridge the network.? 
         *  SPECIAL RULE:? When this is true and VM's are being used on the bridge network Team Mode must be set to allow this.? Team mode 6 (Adaptive Load Balancing and team mode 1 (Round Robin) are known to cause failures
 * subnet - this is the actual subnet, for example. 192.168.124.0, 192.168.123.128
 * netmask - this is the Netmask for the network subnet. Please see Nova-Floating for it special requirements
 * broadcast - network broadcast
 * router - This is the router IP for this particular network
 * router_pref - This is like a route metric the lower number becomes your default route
 * ranges - the different ranges you want to use in general "host" is required.
