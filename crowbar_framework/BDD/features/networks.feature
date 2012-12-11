Feature: Networks
  In order to manage networks through the network API A remote program
  wants to be able to list, show, create, edit, and delete networks

  Scenario: Update a network
    Given REST creates the {object:networks} "bdd_net"
    When the ip range "\"dhcp\":{\"start\":\"192.168.124.21\",\"end\":\"192.168.124.80\"}" is added to the network "bdd_net"
    Then the network is properly formatted
    Finally REST deletes the {object:networks} "bdd_net"
  
  Scenario: Create a network
    When REST creates the {object:networks} "bdd_net"
    Then the network is properly formatted
    Finally REST deletes the {object:networks} "bdd_net"

  Scenario: Show a network
    Given REST creates the {object:networks} "bdd_net"
    When REST requests the network "bdd_net"
    Then the network is properly formatted
    Finally REST deletes the {object:networks} "bdd_net"

  Scenario: Retrieve the list of networks
    Given REST creates the {object:networks} "bdd_net"
    When REST requests the list of networks
    Then the object id list is properly formatted
    Finally REST deletes the {object:networks} "bdd_net"
  
  Scenario: Delete a network
    Given REST creates the {object:networks} "bdd_net"
    When REST deletes the {object:networks} "bdd_net"
    Then there is not a network "bdd_net"

  Scenario: Allocate an IP to a node
    Given REST creates the {object:networks} "bdd_net"
      And there is a {object:node} "node.net.com"
    When an IP address is allocated to node "node.net.com" on {object:networks} "bdd_net" from range "host"
    Then the net info response is properly formatted
    Finally REST deletes the {object:networks} "bdd_net"
      And REST removes {object:node} "node.net.com"

  Scenario: Deallocate an IP from a node
    Given REST creates the {object:networks} "bdd_net"
      And there is a {object:node} "node.net.com"
      And an IP address is allocated to node "node.net.com" on {object:networks} "bdd_net" from range "host"
    When an IP address is deallocated from node "node.net.com" on {object:networks} "bdd_net"
    Then REST call returned success
    Finally REST deletes the {object:networks} "bdd_net"
      And REST removes {object:node} "node.net.com"
