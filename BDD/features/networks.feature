Feature: Networks
  In order to manage networks through the network API A remote program
  wants to be able to list, show, create, edit, and delete networks

  Scenario: Network List
    When I go to the "network\networks" page
    Then I should see {bdd:crowbar.i18n.barclamp_network.networks.index.title}
      And there should be no translation errors

 Scenario: Network List to Item
    Given I am on the "network\networks" page
      And REST creates a {object:network} named "bdd_test"
    When I click on the "bdd_test" link
    Then I should see "bdd_test"
      And there should be no translation errors

  Scenario: Nodes List
    When REST gets the {object:network} list
    Then the list should have an object with key "name" value {lookup:network.name}

  Scenario: REST JSON check
    Given REST creates a {object:network} "admin"
    When REST gets the {object:network} {lookup:network.name}
    Then the {object:network} is properly formatted
    
  Scenario: REST Get 404
    When REST gets the {object:network} "thisdoesnotexist"
    Then I get a {integer:404} error

  Scenario: Interfaces List
    When I go to the "network\interfaces" page
    Then I should see {bdd:crowbar.i18n.barclamp_network.interfaces.index.title}
      And there should be no translation errors

  Scenario: Interface Add to List
    Given I add an Interface "bdd_test" with map "foo | bar"
    When I got to the "network\interfaces" page
    Then I should see an input box with "bdd_test"
      And I should see an input box with "foo | bar"
