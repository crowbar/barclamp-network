-module(networks).
-export([step/3, validate/1, validate_allocate_response/1, g/1, json/3, network_json/2, network_json/9]).
-define(IP_RANGE, "\"host\": {\"start\":\"192.168.124.61\", \"end\":\"192.168.124.169\"}").


% This method is used to define constants
g(Item) ->
  case Item of
    path -> "2.0/crowbar/2.0/network/networks";
    _ -> crowbar:g(Item)
  end.


json(Name, _Description, _Order) ->
  network_json(Name, "{" ++ ?IP_RANGE ++ "}").


network_json(Name, Ip_ranges) ->
  network_json(
    Name,
    "",
    "intf0",
    "192.168.124.0/24",
    "false",
    "false",
    json:parse(Ip_ranges),
    "10",
    "192.168.124.1").


network_json(Name, Proposal_id, Conduit_id, Subnet, Dhcp_enabled, Use_vlan, Ip_ranges, Router_pref, Router_ip) ->
  J = [
      {"name", Name},
      {"proposal_id", Proposal_id},
      {"conduit_id", Conduit_id},
      {"subnet", Subnet},
      {"dhcp_enabled", Dhcp_enabled},
      {"use_vlan", Use_vlan},
      {"ip_ranges", Ip_ranges},
      {"router_pref", Router_pref},
      {"router_ip", Router_ip}
    ],
  json:output(J).


rangeTester(_Range) -> 
  {"name",_IpRangeName}  = lists:keyfind("name", 1, _Range),
  {"start_address",_IpRangeStartAddress}  = lists:keyfind("start_address", 1, _Range),
  {"cidr",_IpRangeStartAddr}  = lists:keyfind("cidr", 1, _IpRangeStartAddress),
  {"end_address",_IpRangeEndAddress}  = lists:keyfind("end_address", 1, _Range),
  {"cidr",_IpRangeEndAddr}  = lists:keyfind("cidr", 1, _IpRangeEndAddress),

  [bdd_utils:is_a(string, _IpRangeName),
      bdd_utils:is_a(ip, _IpRangeStartAddr),
      bdd_utils:is_a(ip, _IpRangeEndAddr)].


validate(JSON) ->
  bdd_utils:log(debug, "validate: JSON: ~p", [JSON]),
  RangeTester = fun(Value) -> rangeTester(Value) end,
  try 
    {"dhcp_enabled",DhcpEnabled} = lists:keyfind("dhcp_enabled", 1, JSON),
    {"use_vlan",UseVlan} = lists:keyfind("use_vlan", 1, JSON),
    {"proposal_id",ProposalId} = lists:keyfind("proposal_id", 1, JSON),
    {"conduit_id",ConduitId} = lists:keyfind("conduit_id", 1, JSON),

    {"subnet",Subnet}  = lists:keyfind("subnet", 1, JSON), 
    {"cidr",SubnetAddr}  = lists:keyfind("cidr", 1, Subnet), 

    {"router",Router}  = lists:keyfind("router", 1, JSON), 
    {"ip",RouterIp}  = lists:keyfind("ip", 1, Router), 
    {"cidr",RouterAddr}  = lists:keyfind("cidr", 1, RouterIp), 
    {"pref",RouterPref}  = lists:keyfind("pref", 1, Router), 

    {"ip_ranges",IpRanges}  = lists:keyfind("ip_ranges", 1, JSON), 
    RangeR = lists:map( RangeTester, IpRanges),

    R = [bdd_utils:is_a(boolean, DhcpEnabled),
         bdd_utils:is_a(boolean, UseVlan),
         bdd_utils:is_a(dbid, ProposalId),
         bdd_utils:is_a(dbid, ConduitId),
         bdd_utils:is_a(cidr, SubnetAddr),
         bdd_utils:is_a(ip, RouterAddr),
         bdd_utils:is_a(number, RouterPref),
         RangeR,
         crowbar_rest:validate_core(JSON)
       ],
    FlatteR = lists:flatten(R),

    case bdd_utils:assert(FlatteR) of
      true -> true;
      false -> io:format("FAIL: JSON did not comply with object format ~p", [JSON]),
        false
    end
  catch
    X: Y -> io:format("ERROR: unable to parse returned network JSON: ~p:~p", [X, Y]),
            io:format("Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


validate_allocate_response(JSON) ->
  bdd_utils:log(debug, "validate_allocate_response: JSON: ~p", [JSON]),
  try 
    {"conduit",ConduitName} = lists:keyfind("conduit", 1, JSON),
    bdd_utils:log(debug, "conduit: ~p", [ConduitName]),
    {"netmask",Netmask} = lists:keyfind("netmask", 1, JSON),
    bdd_utils:log(debug, "netmask: ~p", [Netmask]),
    {"node",Node} = lists:keyfind("node", 1, JSON),
    bdd_utils:log(debug, "node: ~p", [Node]),
    {"address",Address} = lists:keyfind("address", 1, JSON),
    bdd_utils:log(debug, "address: ~p", [Address]),
    {"router",RouterAddr} = lists:keyfind("router", 1, JSON),
    bdd_utils:log(debug, "router: ~p", [RouterAddr]),
    {"subnet",SubnetAddr} = lists:keyfind("subnet", 1, JSON),
    bdd_utils:log(debug, "subnet: ~p", [SubnetAddr]),
    {"broadcast",Broadcast} = lists:keyfind("broadcast", 1, JSON),
    bdd_utils:log(debug, "broadcast: ~p", [Broadcast]),
    {"usage",Usage} = lists:keyfind("usage", 1, JSON),
    bdd_utils:log(debug, "usage: ~p", [Usage]),
    {"use_vlan",UseVlan} = lists:keyfind("use_vlan", 1, JSON),
    bdd_utils:log(debug, "use_vlan: ~p", [UseVlan]),
    {"vlan",Vlan} = lists:keyfind("vlan", 1, JSON),
    bdd_utils:log(debug, "vlan: ~p", [Vlan]),
    {"router_pref",RouterPref}  = lists:keyfind("router_pref", 1, JSON),
    bdd_utils:log(debug, "router_pref: ~p", [RouterPref]),

    R = [bdd_utils:is_a(name, ConduitName),
         bdd_utils:is_a(ip, Netmask),
         bdd_utils:is_a(name, Node),
         bdd_utils:is_a(ip, Address),
         bdd_utils:is_a(ip, RouterAddr),
         bdd_utils:is_a(ip, SubnetAddr),
         bdd_utils:is_a(ip, Broadcast),
         bdd_utils:is_a(name, Usage),
         bdd_utils:is_a(boolean, UseVlan),
         bdd_utils:is_a(empty, Vlan) orelse bdd_utils:is_a(number, Vlan),
         bdd_utils:is_a(empty, RouterPref) orelse bdd_utils:is_a(number, RouterPref)
       ],

    bdd_utils:log(debug, "validate_allocate_response: R: ~p", [R]),

    case bdd_utils:assert(R) of
      true -> true;
      false -> io:format("FAIL: JSON did not comply with object format ~p", [JSON]),
        false
    end
  catch
    X: Y -> io:format("ERROR: unable to parse returned network JSON: ~p:~p", [X, Y]),
            io:format("Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


% List networks
step(Config, Given, {step_when, _N, ["REST requests the list of networks"]}) ->
  bdd_restrat:step(Config, Given, {step_when, _N, ["REST requests the", g(path),"page"]});


% Add an ip range to a network
step(Config, Given, {step_when, _N, ["the ip range",Range,"is added to the network",Name]}) ->
  bdd_utils:log(Config, trace, "the ip range ~p is added to the network ~p", [Range,Name]),
  JSON = network_json(Name, "{" ++ ?IP_RANGE ++ ", " ++ Range ++ "}"),
  bdd_utils:log(Config, debug, "update JSON: ~p", [JSON]),
  Results = bdd_restrat:step(Config, Given, {step_when, _N, ["REST updates an object at",eurl:path(g(path),Name),"with",JSON]}),
  bdd_utils:log(Config, debug, "update Results: ~p",[Results]),
  Results;


% Retrieve a network
step(Config, Given, {step_when, _N, ["REST requests the network",Name]}) ->
  bdd_utils:log(Config, trace, "REST requests the network ~p", [Name]),
  bdd_restrat:step(Config, Given, {step_when, _N, ["REST requests the", eurl:path(g(path),Name),"page"]});


% Validate a network
step(Config, Result, {step_then, _N, ["the network is properly formatted"]}) ->
  bdd_utils:log(Config, trace, "the network is properly formatted, Result: ~p",[Result]),
  crowbar_rest:step(Config, Result, {step_then, _N, ["the", networks, "object is properly formatted"]});


step(Config, _Result, {step_then, _N, ["there is not a network",Network]}) -> 
  crowbar_rest:get_id(Config, g(path), Network) == "-1";


% Ip address allocation
step(Config, Global, {step_given, _N, ["an IP address is allocated to node",Node,"on",Object,Network,"from range",Range]}) ->
  step(Config, Global, {step_when, _N, ["an IP address is allocated to node",Node,"on",Object,Network,"from range",Range]});


step(Config, _Given, {step_when, _N, ["an IP address is allocated to node",Node,"on",Object,Network,"from range",Range]}) ->
  bdd_utils:log(Config, trace, "an IP address is allocated to node ~p on network ~p from range ~p", [Node, Network, Range]),
  URI = eurl:path(apply(Object, g, [path]), "-1/allocate_ip"),
  J = [
        {"network_id", Network},
        {"node_id", Node},
        {"range", Range}
      ],
  JSON = json:output(J),
  Result = eurl:post(Config, URI, JSON),
  json:parse(Result);


step(_Config, Results, {step_then, _N, ["the net info response is properly formatted"]}) ->
  [Result | _] = Results,
  validate_allocate_response(Result);


% Ip address deallocation
step(Config, _Given, {step_when, _N, ["an IP address is deallocated from node",Node,"on",Object,Network]}) ->
  bdd_utils:log(Config, trace, "an IP address is deallocated from node ~p on network ~p", [Node, Network]),
  URL = eurl:uri(Config, eurl:path(apply(Object, g, [path]), "-1/deallocate_ip/" ++ Network ++ "/" ++ eurl:encode(Node))),
  eurl:delete(Config, URL).
