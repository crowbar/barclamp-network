Feature: Networks
  In order to manage networks through the network API A remote program
  wants to be able to list, show, create, edit, and delete networks

  Scenario: Network List
    When I go to the "network\networks" page
    Then I should see {bdd:crowbar.i18n.barclamp_network.networks.index.title}
      And there should be no translation errors
