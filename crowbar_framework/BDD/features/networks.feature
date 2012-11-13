Feature: Networks
  In order to manage networks through the network API A remote program
  wants to be able to list, show, create, edit, and delete networks

  Scenario: Retrieve a network created during setup via the network API
    Given there is a network "bdd_net"
    When REST requests the network "bdd_net"
    Then the network is properly formatted
    Finally REST removes the network "bdd_net"

  Scenario: Retrieve the list of networks via the network API
    Given there is a network "bdd_net"
    When REST requests the list of networks
    Then the object id list is properly formatted
    Finally REST removes the network "bdd_net"
  
  Scenario: Delete a network via the network API
    Given there is a network "bdd_net"
    When REST removes the network "bdd_net"
    Then there is not a network "bdd_net"
