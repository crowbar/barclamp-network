### Network API

The network API is used to manage networks.

#### Network CRUD

Lists the current networks.

**Input:**

<table border=1>
<tr><th> Verb </th><th> URL </th><th> Options </th><th> Returns </th><th> Comments </th></tr>
<tr><td> GET  </td><td>network/api/v2/networks</td><td>N/A</td><td>JSON array of network IDs</td><td></td></tr>
<tr><td> GET  </td><td>network/api/v2/networks/[network]</td><td>id is the network ID or name.</td><td>Details of the network in JSON format</td><td></
<tr><td> POST  </td><td>network/api/v2/networks</td><td> json definition (see Node Show) </td><td> must be a legal object </td></tr>
<tr><td> PUT  </td><td>network/api/v2/networks/[network]</td><td></td><td></td><td></td></tr>
<tr><td> DELETE  </td><td>network/api/v2/networks/[network]</td><td> Database ID or name </td><td>HTTP error code 200 on success</td><td></td></tr>
</table>


> There are helpers on the POST method that allow you to create ranges and routers when you create the network. 

Sample:
    {
      "name":       "networkname",
      "deployment": "deploymentname",
      "vlan":       your_vlan,
      "use_vlan":   true or false,
      "team_mode":  teaming mode,
      "use_team":   true or false,
      "use_bridge": true or false
      "conduit":    "1g0,1g1", // or whatever you want to use as a conduit for this network
      "ranges": [
         { "name": "name", "first": "192.168.124.10/24", "last": "192.168.124.245/24" }
      ],
      "router": {
         "pref": 255, // or whatever pref you want.  Lowest on a host will win.
         "address": "192.168.124.1/24"
      }
    }

#### Network Actions: IP Allocate

Allocates a free IP address in a network.

<table border=1>
<tr><th> Verb </th><th> URL </th><th> Options </th><th> Returns </th><th> Comments </th></tr>
<tr><td>POST</td><td>network/api/v2/networks/[id]/allocate_ip</td><td> Database ID or name of the network barclamp </td><td>HTTP error code 200 on success</td><td></td></tr>
</table>


#### Network Actions: IP Deallocate

Deallocates a used IP address in a network.

<table border=1>
<tr><th> Verb </th><th> URL </th><th> Options </th><th> Returns </th><th> Comments </th></tr>
<tr><td>DELETE</td><td>network/api/v2/networks/deallocate_ip/[network_id]/[node_id]</td><td>id: Database ID or name of proposal<br>network_id: Database ID or name of network<br>node_id: Database ID or name of node</td><td>HTTP error code 200 on success</td><td></td></tr>
</table>

