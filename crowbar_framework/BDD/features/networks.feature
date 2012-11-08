Feature: Networks
  In order to manage networks through the network API A remote program
  wants to be able to list, show, create, edit, and delete networks

  Scenario: %Retrieve the list of networks via the network API
    When REST requests the list of networks
    Then the object id list is properly formatted
  
  Scenario: Retrieve a network via the network API
    When REST requests the network "admin"
    Then the network is properly formatted

  Scenario: Delete a network via the network API
    When REST removes the network "admin"
    Then there is not a network "admin"
