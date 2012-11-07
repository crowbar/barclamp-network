-module(networks).
-export([step/3, validate/1]).


rangeTester(_Range) -> 
  { _Index, _Content } = _Range,

  {"name",_IpRangeName}  = lists:keyfind("name", 1, _Content),
  {"start_address",_IpRangeStartAddress}  = lists:keyfind("start_address", 1, _Content),
  {"cidr",_IpRangeStartAddr}  = lists:keyfind("cidr", 1, _IpRangeStartAddress),
  {"end_address",_IpRangeEndAddress}  = lists:keyfind("end_address", 1, _Content),
  {"cidr",_IpRangeEndAddr}  = lists:keyfind("cidr", 1, _IpRangeEndAddress),

  [bdd_utils:is_a(string, _IpRangeName),
      bdd_utils:is_a(ip, _IpRangeStartAddr),
      bdd_utils:is_a(ip, _IpRangeEndAddr)].


validate(JSON) ->
  RangeTester = fun(Value) -> rangeTester(Value) end,
  try JSON of
    J ->
        {"created_at", _CreatedAt} = lists:keyfind("created_at", 1, JSON),
        {"updated_at",_UpdatedAt} = lists:keyfind("updated_at", 1, JSON), 
        {"dhcp_enabled",_DhcpEnabled} = lists:keyfind("dhcp_enabled", 1, JSON),
        {"id",_Id} = lists:keyfind("id", 1, JSON),
        {"proposal_id",_ProposalId} = lists:keyfind("proposal_id", 1, JSON),
        {"conduit_id",_ConduitId} = lists:keyfind("conduit_id", 1, JSON),
        {"name",_Name} = lists:keyfind("name", 1, JSON), 

        {"subnet",_Subnet}  = lists:keyfind("subnet", 1, JSON), 
        {"cidr",_SubnetAddr}  = lists:keyfind("cidr", 1, _Subnet), 

        {"router",_Router}  = lists:keyfind("router", 1, JSON), 
        {"ip",_RouterIp}  = lists:keyfind("ip", 1, _Router), 
        {"cidr",_RouterAddr}  = lists:keyfind("cidr", 1, _RouterIp), 
        {"pref",_RouterPref}  = lists:keyfind("pref", 1, _Router), 

        {"ip_ranges",_IpRanges}  = lists:keyfind("ip_ranges", 1, JSON), 
        _RangeR = lists:map( RangeTester, _IpRanges),

        R = [bdd_utils:is_a(boolean, _DhcpEnabled),
             bdd_utils:is_a(dbid, _Id),
             bdd_utils:is_a(dbid, _ProposalId),
             bdd_utils:is_a(dbid, _ConduitId),
             bdd_utils:is_a(name, _Name),
             bdd_utils:is_a(cidr, _SubnetAddr),
             bdd_utils:is_a(ip, _RouterAddr),
             bdd_utils:is_a(number, _RouterPref),
             _RangeR
           ],
        FlatteR = lists:flatten(R),

        case bdd_utils:assert(FlatteR)of
          true -> true;
          false -> io:format("FAIL: JSON did not comply with object format ~p~n", [JSON]), false
        end
  catch
    X: Y -> io:format("ERROR: unable to parse returned network JSON: ~p:~p~n", [X, Y]),
		false
	end. 


step(_Config, _Given, {step_when, _N, ["REST requests the network",Name]}) ->
  bdd_restrat:step(_Config, _Given, {step_when, _N, ["REST requests the", eurl:path("2.0/crowbar/2.0/network/networks",Name),"page"]});

step(_Config, Result, {step_then, _N, ["the network is properly formatted"]}) ->
  crowbar_rest:step(_Config, Result, {step_then, _N, ["the", networks, "object is properly formatted"]}).
