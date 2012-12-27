-module(networks).
-export([step/3, validate/1, g/1, json/3, network_json/2, network_json/8]).
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
    json:parse(Ip_ranges),
    "10",
    "192.168.124.1").


network_json(Name, Proposal_id, Conduit_id, Subnet, Dhcp_enabled, Ip_ranges, Router_pref, Router_ip) ->
  J = [
      {"name", Name},
      {"proposal_id", Proposal_id},
      {"conduit_id", Conduit_id},
      {"subnet", Subnet},
      {"dhcp_enabled", Dhcp_enabled},
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
  RangeTester = fun(Value) -> rangeTester(Value) end,
  try 
    {"dhcp_enabled",_DhcpEnabled} = lists:keyfind("dhcp_enabled", 1, JSON),
    {"proposal_id",_ProposalId} = lists:keyfind("proposal_id", 1, JSON),
    {"conduit_id",_ConduitId} = lists:keyfind("conduit_id", 1, JSON),

    {"subnet",_Subnet}  = lists:keyfind("subnet", 1, JSON), 
    {"cidr",_SubnetAddr}  = lists:keyfind("cidr", 1, _Subnet), 

    {"router",_Router}  = lists:keyfind("router", 1, JSON), 
    {"ip",_RouterIp}  = lists:keyfind("ip", 1, _Router), 
    {"cidr",_RouterAddr}  = lists:keyfind("cidr", 1, _RouterIp), 
    {"pref",_RouterPref}  = lists:keyfind("pref", 1, _Router), 

    {"ip_ranges",_IpRanges}  = lists:keyfind("ip_ranges", 1, JSON), 
    _RangeR = lists:map( RangeTester, _IpRanges),

    R = [bdd_utils:is_a(boolean, _DhcpEnabled),
         bdd_utils:is_a(dbid, _ProposalId),
         bdd_utils:is_a(dbid, _ConduitId),
         bdd_utils:is_a(cidr, _SubnetAddr),
         bdd_utils:is_a(ip, _RouterAddr),
         bdd_utils:is_a(number, _RouterPref),
         _RangeR,
         crowbar_rest:validate(JSON)
       ],
    FlatteR = lists:flatten(R),

    case bdd_utils:assert(FlatteR) of
      true -> true;
      false -> io:format("FAIL: JSON did not comply with object format ~p", [JSON]), false
    end
  catch
    X: Y -> io:format("ERROR: unable to parse returned network JSON: ~p:~p", [X, Y]),
            io:format("Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


% List networks
step(_Config, _Given, {step_when, _N, ["REST requests the list of networks"]}) ->
  bdd_restrat:step(_Config, _Given, {step_when, _N, ["REST requests the", g(path),"page"]});


% Add an ip range to a network
step(_Config, _Given, {step_when, _N, ["the ip range",Range,"is added to the network",Name]}) ->
  bdd_utils:log(_Config, trace, "the ip range ~p is added to the network ~p", [Range,Name]),
  JSON = network_json(Name, "{" ++ ?IP_RANGE ++ ", " ++ Range ++ "}"),
  bdd_utils:log(_Config, debug, "update JSON: ~p", [JSON]),
  Results = bdd_restrat:step(_Config, _Given, {step_when, _N, ["REST updates an object at",eurl:path(g(path),Name),"with",JSON]}),
  bdd_utils:log(_Config, debug, "update Results: ~p",[Results]),
  Results;


% Retrieve a network
step(_Config, _Given, {step_when, _N, ["REST requests the network",Name]}) ->
  bdd_utils:log(_Config, trace, "REST requests the network ~p", [Name]),
  bdd_restrat:step(_Config, _Given, {step_when, _N, ["REST requests the", eurl:path(g(path),Name),"page"]});


% Validate a network
step(_Config, Result, {step_then, _N, ["the network is properly formatted"]}) ->
  bdd_utils:log(_Config, trace, "the network is properly formatted, Result: ~p",[Result]),
  crowbar_rest:step(_Config, Result, {step_then, _N, ["the", networks, "object is properly formatted"]});


step(Config, _Result, {step_then, _N, ["there is not a network",Network]}) -> 
  crowbar_rest:get_id(Config, g(path), Network) == "-1".
