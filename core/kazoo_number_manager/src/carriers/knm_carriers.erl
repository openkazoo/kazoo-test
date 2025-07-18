%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2022, 2600Hz
%%% @doc
%%% @author Peter Defebvre
%%% @author Pierre Fenoll
%%% @end
%%%-----------------------------------------------------------------------------
-module(knm_carriers).

-include_lib("kazoo_stdlib/include/kazoo_json.hrl").
-include("knm.hrl").

-compile({no_auto_import, [apply/3]}).

-export([
    check/1,
    available_carriers/1,
    all_modules/0,
    info/3,
    default_carriers/0,
    default_carrier/0,
    acquire/1,
    disconnect/1,

    prefix/1, prefix/2,
    dialcode/1,
    country/1,
    offset/1,
    blocks/1,
    account_id/1,
    reseller_id/1,

    is_number_billable/1,
    is_local/1
]).

-ifdef(TEST).
-define(CARRIER_MODULES(AccountId),
    (fun
        (?CHILD_ACCOUNT_ID) ->
            %% CHILD_ACCOUNT_ID is not a reseller but that's okay
            [?CARRIER_LOCAL, <<"knm_bandwidth2">>];
        (_) ->
            ?CARRIER_MODULES
    end)(
        AccountId
    )
).
-else.
-define(CARRIER_MODULES(AccountId),
    kapps_account_config:get_ne_binaries(
        AccountId, ?KNM_CONFIG_CAT, <<"carrier_modules">>, ?CARRIER_MODULES
    )
).
-endif.

-define(CARRIER_MODULES,
    kapps_config:get_ne_binaries(?KNM_CONFIG_CAT, <<"carrier_modules">>, ?DEFAULT_CARRIER_MODULES)
).

-define(DEFAULT_CARRIER_MODULE,
    kapps_config:get_binary(?KNM_CONFIG_CAT, <<"available_module_name">>, ?CARRIER_LOCAL)
).

-define(DEFAULT_CARRIER_MODULES, [?DEFAULT_CARRIER_MODULE]).

-ifdef(TEST).
-type option() ::
    {'quantity', pos_integer()}
    | {'carriers', kz_term:ne_binaries()}
    | {'phonebook_url', kz_term:ne_binary()}
    | {'tollfree', boolean()}
    | {'prefix', kz_term:ne_binary()}
    | {'country', knm_util:country_iso3166a2()}
    | {'offset', non_neg_integer()}
    | {'blocks', boolean()}
    | {'account_id', kz_term:ne_binary()}
    | {'reseller_id', kz_term:ne_binary()}.
-else.
-type option() ::
    {'quantity', pos_integer()}
    | {'prefix', kz_term:ne_binary()}
    | {'dialcode', kz_term:ne_binary()}
    | {'country', knm_util:country_iso3166a2()}
    | {'offset', non_neg_integer()}
    | {'blocks', boolean()}
    | {'account_id', kz_term:ne_binary()}
    | {'reseller_id', kz_term:ne_binary()}.
-endif.
-type options() :: [option()].
-export_type([option/0, options/0]).

%%------------------------------------------------------------------------------
%% @doc Normalize then query the various providers for available numbers.
%% @end
%%------------------------------------------------------------------------------
-spec check(kz_term:ne_binaries()) -> kz_json:object().
check(Numbers) ->
    Nums = lists:usort([knm_converters:normalize(Num) || Num <- Numbers]),
    lager:info("attempting to check ~p ", [Nums]),
    {_, OKs, KOs} =
        lists:foldl(fun check_fold/2, {Nums, #{}, #{}}, available_carriers([])),
    kz_json:from_map(maps:merge(KOs, OKs)).

check_fold(_, {[], _, _} = Acc) ->
    Acc;
check_fold(Module, {Nums, OKs0, KOs0}) ->
    {OKs, KOs} = check_numbers(Module, Nums),
    OKNums = maps:keys(OKs0),
    {Nums -- OKNums, maps:merge(OKs, OKs0), maps:merge(maps:without(OKNums, KOs), KOs0)}.

check_numbers(Module, Nums) ->
    try apply(Module, check_numbers, [Nums]) of
        {'ok', JObj} -> {kz_json:to_map(JObj), #{}};
        {error, _} -> {#{}, maps:from_list([{Num, <<"error">>} || Num <- Nums])}
    catch
        _:_ ->
            kz_util:log_stacktrace(),
            {#{}, maps:from_list([{Num, <<"error">>} || Num <- Nums])}
    end.

%%------------------------------------------------------------------------------
%% @doc Create a list of all carrier modules available to a subaccount.
%% @end
%%------------------------------------------------------------------------------
-spec available_carriers(options()) -> kz_term:atoms().
-ifdef(TEST).
available_carriers(Options) ->
    case props:get_value('carriers', Options) of
        Cs = [_ | _] -> keep_only_reachable(Cs);
        _ -> get_available_carriers(Options)
    end.
-else.
available_carriers(Options) ->
    get_available_carriers(Options).
-endif.

-spec get_available_carriers(options()) -> kz_term:atoms().
get_available_carriers(Options) ->
    case
        account_id(Options) =:= 'undefined' orelse
            reseller_id(Options) =:= 'undefined'
    of
        'true' ->
            keep_only_reachable(?CARRIER_MODULES);
        'false' ->
            ResellerId = reseller_id(Options),
            First = [?CARRIER_RESERVED, ?CARRIER_RESERVED_RESELLER, ?CARRIER_LOCAL],
            keep_only_reachable(First ++ (?CARRIER_MODULES(ResellerId) -- First))
    end.

-spec default_carriers() -> kz_term:atoms().
default_carriers() ->
    keep_only_reachable(?DEFAULT_CARRIER_MODULES).

-spec default_carrier() -> kz_term:ne_binary().
default_carrier() ->
    ?DEFAULT_CARRIER_MODULE.

%%------------------------------------------------------------------------------
%% @doc List all carrier modules.
%% @end
%%------------------------------------------------------------------------------
-spec all_modules() -> kz_term:ne_binaries().
all_modules() ->
    [
        <<"knm_bandwidth">>,
        <<"knm_bandwidth2">>,
        <<"knm_didww">>,
        <<"knm_flowroute">>,
        <<"knm_inteliquent">>,
        <<"knm_inum">>,
        <<"knm_inventory">>,
        <<"knm_it_vocal">>,
        <<"knm_level3">>,
        <<"knm_local">>,
        <<"knm_managed">>,
        <<"knm_mdn">>,
        <<"knm_o1">>,
        <<"knm_other">>,
        <<"knm_peerless">>,
        <<"knm_reserved">>,
        <<"knm_reserved_reseller">>,
        <<"knm_simwood">>,
        <<"knm_telnyx">>,
        <<"knm_thinq">>,
        <<"knm_verizon">>,
        <<"knm_vitelity">>,
        <<"knm_voip_innovations">>,
        <<"knm_voxbone">>,
        <<"knm_windstream">>,
        <<"knm_ziron">>
    ].

%%------------------------------------------------------------------------------
%% @doc Get information on the available carriers
%% @end
%%------------------------------------------------------------------------------
-spec info(kz_term:api_ne_binary(), kz_term:api_ne_binary(), kz_term:api_ne_binary()) ->
    kz_json:object().
info(AuthAccountId, AccountId, ResellerId) ->
    AvailableCarriers = available_carriers([
        {'account_id', AccountId},
        {'reseller_id', ResellerId}
    ]),
    Acc0 = #{?CARRIER_INFO_MAX_PREFIX => 15},
    Map = lists:foldl(fun info_fold/2, Acc0, AvailableCarriers),
    kz_json:from_map(
        Map#{
            ?CARRIER_INFO_USABLE_CARRIERS => usable_carriers(),
            ?CARRIER_INFO_USABLE_CREATION_STATES => allowed_creation_states(AuthAccountId)
        }
    ).

-spec info_fold(module(), map()) -> map().
info_fold(Module, Info = #{?CARRIER_INFO_MAX_PREFIX := MaxPrefix}) ->
    try apply(Module, 'info', []) of
        #{?CARRIER_INFO_MAX_PREFIX := Lower} when
            is_integer(Lower), Lower < MaxPrefix
        ->
            Info#{?CARRIER_INFO_MAX_PREFIX => Lower};
        _ ->
            Info
    catch
        _E:_R ->
            kz_util:log_stacktrace(),
            Info
    end.

-spec usable_carriers() -> kz_term:ne_binaries().
usable_carriers() ->
    Modules =
        all_modules() --
            [
                ?CARRIER_RESERVED,
                ?CARRIER_RESERVED_RESELLER
            ],
    [CarrierName || <<"knm_", CarrierName/binary>> <- Modules].

-spec allowed_creation_states(kz_term:api_ne_binary()) -> kz_term:ne_binaries().
-ifdef(TEST).
allowed_creation_states(AccountId = ?RESELLER_ACCOUNT_ID) ->
    AccountJObj = kzd_accounts:set_allow_number_additions(?RESELLER_ACCOUNT_DOC, true),
    Options = [{<<"auth_by_account">>, AccountJObj}],
    knm_number:allowed_creation_states(Options, AccountId);
allowed_creation_states(AccountId) ->
    knm_number:allowed_creation_states(AccountId).
-else.
allowed_creation_states(AccountId) ->
    knm_number:allowed_creation_states(AccountId).
-endif.

%%------------------------------------------------------------------------------
%% @doc Buy a number from its carrier module
%% @end
%%------------------------------------------------------------------------------
-spec acquire
    (knm_number:knm_number()) -> knm_number:knm_number();
    (knm_numbers:collection()) -> knm_numbers:collection().
acquire(T0 = #{todo := Ns}) ->
    F = fun(N, T) ->
        case knm_number:attempt(fun acquire/1, [N]) of
            {'ok', NewN} -> knm_numbers:ok(NewN, T);
            {'error', R} -> knm_numbers:ko(N, R, T)
        end
    end,
    lists:foldl(F, T0, Ns);
acquire(Number) ->
    PhoneNumber = knm_number:phone_number(Number),
    Module = knm_phone_number:module_name(PhoneNumber),
    DryRun = knm_phone_number:dry_run(PhoneNumber),
    acquire(Number, Module, DryRun).

-spec acquire(knm_number:knm_number(), kz_term:api_ne_binary(), boolean()) ->
    knm_number:knm_number().
acquire(Number, 'undefined', _DryRun) ->
    knm_errors:carrier_not_specified(Number);
acquire(Number, _Mod, 'true') ->
    Number;
acquire(Number, ?NE_BINARY = Mod, 'false') ->
    case 'false' =:= kz_module:ensure_loaded(Mod) of
        'false' ->
            apply(Mod, 'acquire_number', [Number]);
        'true' ->
            lager:info("carrier '~s' does not exist, skipping", [Mod]),
            Number
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec disconnect
    (knm_number:knm_number()) -> knm_number:knm_number();
    (knm_numbers:collection()) -> knm_numbers:collection().
disconnect(T0 = #{todo := Ns}) ->
    F = fun(N, T) ->
        case knm_number:attempt(fun disconnect/1, [N]) of
            {'ok', NewN} ->
                knm_numbers:ok(NewN, T);
            {'error', R} ->
                Num = knm_phone_number:number(knm_number:phone_number(N)),
                knm_numbers:ko(Num, R, T)
        end
    end,
    lists:foldl(F, T0, Ns);
disconnect(Number) ->
    Module = knm_phone_number:module_name(knm_number:phone_number(Number)),
    try apply(Module, 'disconnect_number', [Number]) of
        Result -> Result
    catch
        'error':_ ->
            lager:debug("nonexistent carrier module ~p, allowing disconnect", [Module]),
            Number
    end.

-spec prefix(options()) -> kz_term:ne_binary().
prefix(Options) ->
    props:get_ne_binary_value('prefix', Options).

-spec prefix(options(), kz_term:ne_binary()) -> kz_term:ne_binary().
prefix(Options, Default) ->
    props:get_ne_binary_value('prefix', Options, Default).

-spec dialcode(options()) -> kz_term:ne_binary().
dialcode(Options) ->
    props:get_ne_binary_value('dialcode', Options).

-spec country(options()) -> knm_util:country_iso3166a2().
country(Options) ->
    case props:get_ne_binary_value('country', Options, ?KNM_DEFAULT_COUNTRY) of
        <<_:8, _:8>> = Country ->
            Country;
        _Else ->
            lager:debug("~p is not iso3166a2, using default"),
            ?KNM_DEFAULT_COUNTRY
    end.

-spec offset(options()) -> non_neg_integer().
offset(Options) ->
    props:get_integer_value('offset', Options, 0).

-spec blocks(options()) -> boolean().
blocks(Options) ->
    props:get_value('blocks', Options).

-spec account_id(options()) -> kz_term:api_ne_binary().
account_id(Options) ->
    props:get_value('account_id', Options).

-spec reseller_id(options()) -> kz_term:api_ne_binary().
reseller_id(Options) ->
    props:get_value('reseller_id', Options).

%%------------------------------------------------------------------------------
%% @doc Returns whether carrier handles numbers local to the system.
%% @end
%%------------------------------------------------------------------------------
-spec is_number_billable(knm_phone_number:knm_phone_number()) -> boolean().
is_number_billable(PhoneNumber) ->
    Carrier = knm_phone_number:module_name(PhoneNumber),
    try
        apply(Carrier, 'is_number_billable', [PhoneNumber])
    catch
        'error':_R -> 'true'
    end.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Returns whether carrier handles numbers local to the system.
%%
%% <div class="notice">A non-local (foreign) carrier module makes HTTP requests.</div>
%% @end
%%------------------------------------------------------------------------------
-spec is_local(kz_term:ne_binary()) -> boolean().
is_local(Carrier) ->
    try
        apply(Carrier, 'is_local', [])
    catch
        _E:_R ->
            kz_util:log_stacktrace(),
            'true'
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec apply(module() | kz_term:ne_binary() | knm_number:knm_number(), atom(), list()) -> any().
apply(Module, FName, Args) when is_atom(Module), Module =/= 'undefined' ->
    lager:debug("contacting carrier ~s for ~s", [Module, FName]),
    erlang:apply(Module, FName, Args);
apply(?NE_BINARY = Carrier, FName, Args) ->
    Module = erlang:binary_to_atom(Carrier, 'utf8'),
    apply(Module, FName, Args);
apply(Number, FName, Args) ->
    Carrier = knm_phone_number:module_name(knm_number:phone_number(Number)),
    apply(Carrier, FName, Args).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec keep_only_reachable([kz_term:ne_binary()]) -> kz_term:atoms().
keep_only_reachable(ModuleNames) ->
    ?LOG_DEBUG("resolving carrier modules: ~p", [ModuleNames]),
    [
        Module
     || M <- ModuleNames,
        (Module = kz_module:ensure_loaded(M)) =/= 'false'
    ].
