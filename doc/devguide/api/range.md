### Range API

The Range API is used to manage networks.  It must be a child of a specific network.

#### Range CRUD

Lists the current ranges for a network.

**Input:**

<table border=1>
<tr><th> Verb </th><th> URL </th><th> Options </th><th> Returns </th><th> Comments </th></tr>
<tr><td> GET  </td><td>network/api/v2/networks/[network]/ranges</td><td>N/A</td><td>JSON array of ranges</td><td></td></tr>
<tr><td> GET  </td><td>network/api/v2/networks/[network]/ranges/[range]</td><td></td><td>Details of the network in JSON format</td><td></td></tr>
<tr><td> POST  </td><td>network/api/v2/networks/[network]/ranges</td><td> json definition (see Node Show) </td><td> must be a legal object </td></tr>
<tr><td> PUT  </td><td>network/api/v2/networks/[network]/ranges/[range]</td><td></td><td></td><td></td></tr>
</table>

You cannot delete a range at this time.  You must delete the entire network.
