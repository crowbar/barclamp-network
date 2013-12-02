Feature: Network Role
  In order to setup networks, the Operator 
  wants to be able to handle network configuration activities

  Scenario: Node set IP address from hint
    Given there is a {object:node} "bdd-hint-ip2.data.edu" hinted "ip" as "192.168.124.126"
      And parameter "node" is "bdd-hint-ip2.data.edu"
      And there are no pending Crowbar runs for {o:node} "bdd-hint-ip2.data.edu"
    When REST requests the "network/api/v2/networks/admin/allocations" page with parameter "node"
    Then Array matches "192\.168\.124\.126\/([0-9]{2})" 
    Finally there are no pending Crowbar runs for {o:node} "bdd-hint-ip2.data.edu"
      And REST removes the {object:node} "bdd-hint-ip2.data.edu"
