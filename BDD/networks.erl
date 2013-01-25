% Copyright 2013, Dell 
% 
% Licensed under the Apache License, Version 2.0 (the "License"); 
% you may not use this file except in compliance with the License. 
% You may obtain a copy of the License at 
% 
%  eurl://www.apache.org/licenses/LICENSE-2.0 
% 
% Unless required by applicable law or agreed to in writing, software 
% distributed under the License is distributed on an "AS IS" BASIS, 
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
% See the License for the specific language governing permissions and 
% limitations under the License. 
% 
-module(networks).
-export([step/3, validate/1, validate_base_net_info/1, validate_net_info/1, g/1, json/3, network_json/2, network_json/9]).
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
    {"subnet",Subnet}  = lists:keyfind("subnet", 1, JSON), 
    {"router",Router}  = lists:keyfind("router", 1, JSON), 
    {"ip",RouterIp}  = lists:keyfind("ip", 1, Router), 

    {"ip_ranges",IpRanges}  = lists:keyfind("ip_ranges", 1, JSON), 
    RangeR = lists:map( RangeTester, IpRanges),

    R = [bdd_utils:is_a(JSON, boolean, dhcp_enabled),
         bdd_utils:is_a(JSON, boolean, use_vlan),
         bdd_utils:is_a(JSON, dbid, proposal_id),
         bdd_utils:is_a(JSON, dbid, conduit_id),
         bdd_utils:is_a(Subnet, cidr, cidr),
         bdd_utils:is_a(RouterIp, ip, cidr),
         bdd_utils:is_a(Router, number, pref),
         RangeR,
         crowbar_rest:validate_core(JSON)
       ],
    FlatteR = lists:flatten(R),

    case bdd_utils:assert(FlatteR) of
      true -> true;
      false -> bdd_utils:log(warn, "JSON did not comply with object format ~p", [JSON]),
        false
    end
  catch
    X: Y -> bdd_utils:log(warn, "Unable to parse returned network JSON: ~p:~p", [X, Y]),
            bdd_utils:log(warn, "Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


validate_base_net_info(JSON) ->
  bdd_utils:log(debug, "validate_base_net_info: JSON: ~p", [JSON]),
  try 
    R = [bdd_utils:is_a(JSON, name, conduit),
         bdd_utils:is_a(JSON, ip, netmask),
         bdd_utils:is_a(JSON, name, node),
         bdd_utils:is_a(JSON, ip, router),
         bdd_utils:is_a(JSON, ip, subnet),
         bdd_utils:is_a(JSON, ip, broadcast),
         bdd_utils:is_a(JSON, name, usage),
         bdd_utils:is_a(JSON, boolean, use_vlan),
         bdd_utils:is_a(JSON, empty, vlan) orelse bdd_utils:is_a(JSON, number, vlan),
         bdd_utils:is_a(JSON, number, router_pref) orelse bdd_utils:is_a(JSON, empty, router_pref)
       ],

    bdd_utils:log(debug, "validate_base_net_info: R: ~p", [R]),

    case bdd_utils:assert(R) of
      true -> true;
      false -> bdd_utils:log(warn, "JSON did not comply with object format ~p", [JSON]),
        false
    end
  catch
    X: Y -> bdd_utils:log(warn, "Unable to parse returned network JSON: ~p:~p", [X, Y]),
            bdd_utils:log(warn, "Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


validate_net_info(JSON) ->
  bdd_utils:log(debug, "validate_net_info: JSON: ~p", [JSON]),
  try 
    R = [bdd_utils:is_a(JSON, ip, address),
          validate_base_net_info(JSON)
       ],

    bdd_utils:log(debug, "validate_net_info: R: ~p", [R]),

    case bdd_utils:assert(R) of
      true -> true;
      false -> bdd_utils:log(warn, "JSON did not comply with object format ~p", [JSON]),
        false
    end
  catch
    X: Y -> bdd_utils:log(warn, "Unable to parse returned network JSON: ~p:~p", [X, Y]),
            bdd_utils:log(warn, "Stacktrace: ~p", [erlang:get_stacktrace()]),
    false
	end. 


% List networks
step(Config, Given, {step_when, _N, ["REST requests the list of networks"]}) ->
  bdd_restrat:step(Config, Given, {step_when, _N, ["REST requests the", g(path),"page"]});


% Add an ip range to a network
step(Config, Given, {step_when, N, ["the ip range",Range,"is added to the network",Name]}) ->
  bdd_utils:log(Config, trace, "the ip range ~p is added to the network ~p", [Range,Name]),
  JSON = network_json(Name, "{" ++ ?IP_RANGE ++ ", " ++ Range ++ "}"),
  bdd_utils:log(Config, debug, "update JSON: ~p", [JSON]),
  Results = bdd_restrat:step(Config, Given, {step_when, N, ["REST updates an object at",eurl:path(g(path),Name),"with",JSON]}),
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
  bdd_restrat:get_id(Config, g(path), Network) == "-1";


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
  validate_net_info(Result);


% Ip address deallocation
step(Config, _Given, {step_when, _N, ["an IP address is deallocated from node",Node,"on",Object,Network]}) ->
  bdd_utils:log(Config, trace, "an IP address is deallocated from node ~p on network ~p", [Node, Network]),
  URL = eurl:uri(Config, eurl:path(apply(Object, g, [path]), "-1/deallocate_ip/" ++ Network ++ "/" ++ eurl:encode(Node))),
  {Code,Result} = eurl:delete(Config, URL),
  bdd_restrat:ajax_return(URL, delete, Code, Result);


step(Config, _Given, {step_when, _N, ["an interface is enabled on node",Node,"on",Object,Network]}) ->
  bdd_utils:log(Config, trace, "an interface is enabled on node ~p on network ~p", [Node, Network]),
  URI = eurl:path(apply(Object, g, [path]), "-1/enable_interface"),
  J = [
        {"network_id", Network},
        {"node_id", Node}
      ],
  JSON = json:output(J),
  Result = eurl:post(Config, URI, JSON),
  json:parse(Result);


step(_Config, Results, {step_then, _N, ["the enable interface net info response is properly formatted"]}) ->
  [Result | _] = Results,
  validate_base_net_info(Result).
