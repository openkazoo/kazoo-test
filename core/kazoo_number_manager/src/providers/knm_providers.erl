%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2016-2022, 2600Hz
%%% @doc Handle prepend feature
%%% @author Peter Defebvre
%%% @author Pierre Fenoll
%%% @author Karl Anderson
%%% @end
%%%-----------------------------------------------------------------------------
-module(knm_providers).

-include("knm.hrl").

-export([save/1]).
-export([delete/1]).
-export([
    available_features/1,
    available_features/2,
    service_name/2
]).
-export([e911_caller_name/2]).
-export([features_denied/1]).
-export([
    reseller_allowed_features/1,
    system_allowed_features/0
]).
-export([activate_feature/2]).
-export([
    deactivate_features/2,
    deactivate_feature/2
]).

-export([settings/1, settings/2]).

-export([setup_account_context/1, setup_account_context/2]).
-export([setup_number_context/1, setup_number_context/2]).

-define(CNAM_PROVIDER(AccountId),
    kapps_account_config:get_from_reseller(
        AccountId, ?KNM_CONFIG_CAT, <<"cnam_provider">>, <<"knm_cnam_notifier">>
    )
).

-define(E911_PROVIDER(AccountId),
    kapps_account_config:get_from_reseller(
        AccountId, ?KNM_CONFIG_CAT, <<"e911_provider">>, <<"knm_dash_e911">>
    )
).

-define(SYSTEM_PROVIDERS, kapps_config:get_ne_binaries(?KNM_CONFIG_CAT, <<"providers">>)).

-define(DEPRECATED_FEATURES, [<<"im">>]).
-define(REMOVED_DENIED_FEATURES, [<<"knm_sms">>, <<"knm_mms">>]).
-define(PROVIDERS_WITH_AVAILABLE, [<<"sms">>, <<"mms">>]).

-define(PP(NeBinaries), kz_util:iolist_join($,, NeBinaries)).

-ifdef(TEST).
-record(feature_parameters, {
    is_local = false :: boolean(),
    is_admin = false :: boolean(),
    assigned_to :: kz_term:api_ne_binary(),
    used_by :: kz_term:api_ne_binary(),
    allowed_features = [] :: kz_term:ne_binaries(),
    denied_features = [] :: kz_term:ne_binaries(),
    context = #{} :: map(),
    %% TEST-only
    num :: kz_term:ne_binary()
}).
-else.
-record(feature_parameters, {
    is_local = false :: boolean(),
    is_admin = false :: boolean(),
    assigned_to :: kz_term:api_ne_binary(),
    used_by :: kz_term:api_ne_binary(),
    allowed_features = [] :: kz_term:ne_binaries(),
    denied_features = [] :: kz_term:ne_binaries(),
    context = #{} :: map()
}).
-endif.
-type feature_parameters() :: #feature_parameters{}.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec save(knm_numbers:collection()) -> knm_numbers:collection().
save(Number) ->
    do_exec(Number, 'save').

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec delete(knm_numbers:collection()) -> knm_numbers:collection().
delete(Number) ->
    do_exec(Number, 'delete').

%%------------------------------------------------------------------------------
%% @doc Settings for features.
%% @end
%%------------------------------------------------------------------------------
-spec settings(knm_phone_number:knm_phone_number()) -> kz_json:object().
settings(PhoneNumber) ->
    settings(PhoneNumber, available_features(PhoneNumber)).

%%------------------------------------------------------------------------------
%% @doc Settings for features.
%% @end
%%------------------------------------------------------------------------------
-spec settings(knm_phone_number:knm_phone_number(), kz_term:ne_binaries()) -> kz_json:object().
settings(PhoneNumber, Features) ->
    AccountId = knm_phone_number:assigned_to(PhoneNumber),
    Fun = fun(Feature) ->
        Module = provider_module(Feature, AccountId),
        JObj = knm_gen_provider:settings(Module, PhoneNumber),
        case kz_json:is_empty(JObj) of
            true -> false;
            false -> {true, {Feature, JObj}}
        end
    end,
    kz_json:from_list(lists:filtermap(Fun, Features)).

%%------------------------------------------------------------------------------
%% @doc List features a number is allowed by its reseller to enable.
%% @end
%%------------------------------------------------------------------------------
-spec available_features(knm_phone_number:knm_phone_number()) -> kz_term:ne_binaries().
available_features(PhoneNumber) ->
    Features = list_available_features(feature_parameters(PhoneNumber)),
    AccountId = knm_phone_number:assigned_to(PhoneNumber),
    Fun = fun(Feature) ->
        case lists:member(Feature, ?PROVIDERS_WITH_AVAILABLE) of
            false ->
                true;
            true ->
                Module = provider_module(Feature, AccountId),
                knm_gen_provider:available(Module, PhoneNumber)
        end
    end,
    lists:filter(Fun, Features).

-spec available_features(kz_json:object(), map()) -> kz_term:ne_binaries().
available_features(JObj, Context) ->
    Ctx = setup_number_context(JObj, Context),
    Params = feature_parameters_from_context(Ctx),
    Features = list_available_features(Params),
    filter_available_features(Features, Ctx).

%%------------------------------------------------------------------------------
%% @doc The name of the billable service associated with a feature.
%% @end
%%------------------------------------------------------------------------------
-spec service_name(kz_term:ne_binary(), kz_term:ne_binary()) -> kz_term:ne_binary().
-ifdef(TEST).
service_name(?FEATURE_E911, _AccountId) ->
    service_name(?E911_PROVIDER(_AccountId));
service_name(?FEATURE_CNAM, _AccountId) ->
    service_name(?CNAM_PROVIDER(_AccountId));
service_name(Feature, _) ->
    service_name(Feature).
-else.
service_name(?FEATURE_E911, AccountId) ->
    service_name(?E911_PROVIDER(AccountId));
service_name(?FEATURE_CNAM, AccountId) ->
    service_name(?CNAM_PROVIDER(AccountId));
service_name(Feature, _) ->
    service_name(Feature).
-endif.

%%------------------------------------------------------------------------------
%% @doc Util function to get E911 caller name defaults.
%% @end
%%------------------------------------------------------------------------------
-spec e911_caller_name(knm_number:knm_number(), kz_term:api_ne_binary()) -> kz_term:ne_binary().
-ifdef(TEST).
e911_caller_name(_Number, ?NE_BINARY = Name) -> Name;
e911_caller_name(_Number, 'undefined') -> ?E911_NAME_DEFAULT.
-else.
e911_caller_name(_Number, ?NE_BINARY = Name) ->
    Name;
e911_caller_name(Number, 'undefined') ->
    AccountId = knm_phone_number:assigned_to(knm_number:phone_number(Number)),
    case kzd_accounts:fetch_name(AccountId) of
        'undefined' -> ?E911_NAME_DEFAULT;
        Name -> kz_binary:pad(Name, 3, <<" ">>)
    end.
-endif.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec service_name(kz_term:ne_binary()) -> kz_term:ne_binary().
service_name(<<"knm_dash_e911">>) -> ?LEGACY_DASH_E911;
service_name(<<"knm_telnyx_e911">>) -> ?LEGACY_TELNYX_E911;
service_name(<<"knm_vitelity_e911">>) -> ?LEGACY_VITELITY_E911;
service_name(<<"knm_cnam_notifier">>) -> <<"cnam">>;
service_name(<<"knm_telnyx_cnam">>) -> <<"telnyx_cnam">>;
service_name(<<"knm_vitelity_cnam">>) -> <<"vitelity_cnam">>;
service_name(Feature) -> Feature.

-spec list_available_features(feature_parameters()) -> kz_term:ne_binaries().
list_available_features(Parameters) ->
    ?LOG_DEV("is admin? ~s", [Parameters#feature_parameters.is_admin]),
    Allowed = cleanse_features(list_allowed_features(Parameters)),
    Denied = cleanse_features(list_denied_features(Parameters)),
    Available = [
        Feature
     || Feature <- Allowed,
        not lists:member(Feature, Denied)
    ],
    ?LOG_DEV("available features: ~s", [?PP(Available)]),
    Available.

-spec cleanse_features(kz_term:ne_binaries()) -> kz_term:ne_binaries().
cleanse_features(Features) ->
    lists:usort([legacy_provider_to_feature(Feature) || Feature <- Features]).

-spec is_local(knm_phone_number:knm_phone_number()) -> boolean().
is_local(PN) ->
    ModuleName = knm_phone_number:module_name(PN),
    ?CARRIER_LOCAL =:= ModuleName orelse
        ?CARRIER_MDN =:= ModuleName orelse
        lists:member(?FEATURE_LOCAL, knm_phone_number:features_list(PN)).

-spec feature_parameters(knm_phone_number:knm_phone_number()) -> feature_parameters().
-ifdef(TEST).
feature_parameters(PhoneNumber) ->
    FP = feature_parameters(
        is_local(PhoneNumber),
        knm_phone_number:is_admin(PhoneNumber),
        knm_phone_number:assigned_to(PhoneNumber),
        knm_phone_number:used_by(PhoneNumber),
        knm_phone_number:features_allowed(PhoneNumber),
        knm_phone_number:features_denied(PhoneNumber),
        #{}
    ),
    FP#feature_parameters{num = knm_phone_number:number(PhoneNumber)}.
-else.
feature_parameters(PhoneNumber) ->
    feature_parameters(
        is_local(PhoneNumber),
        knm_phone_number:is_admin(PhoneNumber),
        knm_phone_number:assigned_to(PhoneNumber),
        knm_phone_number:used_by(PhoneNumber),
        knm_phone_number:features_allowed(PhoneNumber),
        knm_phone_number:features_denied(PhoneNumber),
        #{}
    ).
-endif.

-spec feature_parameters(
    boolean(),
    boolean(),
    kz_term:api_ne_binary(),
    kz_term:api_ne_binary(),
    kz_term:ne_binaries(),
    kz_term:ne_binaries(),
    map()
) -> feature_parameters().
feature_parameters(IsLocal, IsAdmin, AssignedTo, UsedBy, Allowed, Denied, Context) ->
    #feature_parameters{
        is_local = IsLocal,
        is_admin = IsAdmin,
        assigned_to = AssignedTo,
        used_by = UsedBy,
        allowed_features = Allowed,
        denied_features = Denied,
        context = Context
    }.

-spec feature_parameters_from_context(map()) -> feature_parameters().
feature_parameters_from_context(Context) ->
    #feature_parameters{
        is_local = maps:get(is_local, Context, true),
        is_admin = maps:get(is_admin, Context, false),
        assigned_to = maps:get(assigned_to, Context, undefined),
        used_by = maps:get(used_by, Context, undefined),
        allowed_features = maps:get(allowed_features, Context, []),
        denied_features = maps:get(denied_features, Context, []),
        context = Context
    }.

-spec list_allowed_features(feature_parameters()) -> kz_term:ne_binaries().
list_allowed_features(Parameters) ->
    case number_allowed_features(Parameters) of
        [] -> reseller_allowed_features(Parameters);
        NumberAllowed -> NumberAllowed
    end.

-spec reseller_allowed_features(kz_term:api_binary() | feature_parameters()) ->
    kz_term:ne_binaries().
reseller_allowed_features(#feature_parameters{
    assigned_to = 'undefined',
    context = #{allowed := Features}
}) ->
    Features;
reseller_allowed_features(#feature_parameters{assigned_to = 'undefined'}) ->
    system_allowed_features();
reseller_allowed_features(#feature_parameters{context = #{allowed := Features}} = _Params) ->
    Features;
reseller_allowed_features(#feature_parameters{assigned_to = AccountId} = _Params) ->
    reseller_allowed_features(AccountId);
reseller_allowed_features(AccountId) ->
    case ?FEATURES_ALLOWED_RESELLER(AccountId) of
        'undefined' ->
            system_allowed_features();
        Providers ->
            ?LOG_DEV("allowed features set on reseller for ~s: ~s", [AccountId, ?PP(Providers)]),
            Providers
    end.

-spec system_allowed_features() -> kz_term:ne_binaries().
system_allowed_features() ->
    Features =
        lists:usort(
            case ?SYSTEM_PROVIDERS of
                'undefined' -> ?FEATURES_ALLOWED_SYSTEM(?DEFAULT_FEATURES_ALLOWED_SYSTEM);
                Providers -> ?FEATURES_ALLOWED_SYSTEM(Providers)
            end
        ),
    ?LOG_DEV("allowed features from system config: ~s", [?PP(Features)]),
    Features.

-spec number_allowed_features(feature_parameters()) -> kz_term:ne_binaries().
-ifdef(TEST).
number_allowed_features(#feature_parameters{num = ?TEST_OLD5_1_NUM}) ->
    AllowedFeatures = [
        ?FEATURE_CNAM,
        ?FEATURE_E911,
        ?FEATURE_FORCE_OUTBOUND,
        ?FEATURE_RENAME_CARRIER
    ],
    ?LOG_DEV("allowed features set on number document: ~s", [?PP(AllowedFeatures)]),
    AllowedFeatures;
number_allowed_features(#feature_parameters{num = ?TEST_VITELITY_NUM}) ->
    AllowedFeatures = [
        ?FEATURE_CNAM,
        ?FEATURE_E911,
        ?FEATURE_FORCE_OUTBOUND,
        ?FEATURE_PREPEND,
        ?FEATURE_RENAME_CARRIER
    ],
    ?LOG_DEV("allowed features set on number document: ~s", [?PP(AllowedFeatures)]),
    AllowedFeatures;
number_allowed_features(#feature_parameters{num = ?TEST_TELNYX_NUM}) ->
    AllowedFeatures = [
        ?FEATURE_CNAM,
        ?FEATURE_E911,
        ?FEATURE_FAILOVER,
        ?FEATURE_FORCE_OUTBOUND,
        ?FEATURE_PREPEND,
        ?FEATURE_RINGBACK,
        ?FEATURE_RENAME_CARRIER
    ],
    ?LOG_DEV("allowed features set on number document: ~s", [?PP(AllowedFeatures)]),
    AllowedFeatures;
number_allowed_features(#feature_parameters{allowed_features = AllowedFeatures}) ->
    ?LOG_DEV("allowed features set on number document: ~s", [?PP(AllowedFeatures)]),
    AllowedFeatures.
-else.
number_allowed_features(#feature_parameters{allowed_features = AllowedFeatures}) ->
    ?LOG_DEV("allowed features set on number document: ~s", [?PP(AllowedFeatures)]),
    AllowedFeatures.
-endif.

-spec list_denied_features(feature_parameters()) -> kz_term:ne_binaries().
list_denied_features(Parameters) ->
    case number_denied_features(Parameters) of
        [] ->
            reseller_denied_features(Parameters) ++
                used_by_denied_features(Parameters);
        NumberDenied ->
            NumberDenied
    end ++
        maybe_deny_admin_only_features(Parameters).

-spec reseller_denied_features(feature_parameters()) -> kz_term:ne_binaries().
reseller_denied_features(#feature_parameters{assigned_to = 'undefined'}) ->
    ?LOG_DEV("denying external features for unassigned number"),
    ?EXTERNAL_NUMBER_FEATURES;
reseller_denied_features(
    #feature_parameters{
        assigned_to = AccountId,
        context = #{denied := Denied}
    } = Parameters
) ->
    case Denied of
        'undefined' ->
            local_denied_features(Parameters);
        Providers ->
            ?LOG_DEV("denied features set on reseller for ~s: ~s", [AccountId, ?PP(Providers)]),
            Providers
    end;
reseller_denied_features(#feature_parameters{assigned_to = AccountId} = Parameters) ->
    case ?FEATURES_DENIED_RESELLER(AccountId) of
        'undefined' ->
            local_denied_features(Parameters);
        Providers ->
            ?LOG_DEV("denied features set on reseller for ~s: ~s", [AccountId, ?PP(Providers)]),
            Providers
    end.

-spec local_denied_features(feature_parameters()) -> kz_term:ne_binaries().
local_denied_features(#feature_parameters{is_local = 'false'}) ->
    [];
local_denied_features(#feature_parameters{
    is_local = 'true',
    context = #{local_feature_override := true}
}) ->
    [];
local_denied_features(#feature_parameters{
    is_local = 'true',
    context = #{local_feature_override := false}
}) ->
    Features = ?EXTERNAL_NUMBER_FEATURES,
    ?LOG_DEV("denying external features for local number: ~s", [?PP(Features)]),
    Features;
local_denied_features(#feature_parameters{is_local = 'true'}) ->
    case ?LOCAL_FEATURE_OVERRIDE of
        'true' ->
            ?LOG_DEV("not denying external features on local number due to override"),
            [];
        'false' ->
            Features = ?EXTERNAL_NUMBER_FEATURES,
            ?LOG_DEV("denying external features for local number: ~s", [?PP(Features)]),
            Features
    end.

-spec used_by_denied_features(feature_parameters()) -> kz_term:ne_binaries().
used_by_denied_features(#feature_parameters{used_by = <<"trunkstore">>}) ->
    [];
used_by_denied_features(#feature_parameters{used_by = UsedBy}) ->
    Features = [?FEATURE_FAILOVER],
    ?LOG_DEV("denying external features for number used by ~s: ~s", [UsedBy, ?PP(Features)]),
    Features.

-spec number_denied_features(feature_parameters()) -> kz_term:ne_binaries().
-ifdef(TEST).
number_denied_features(#feature_parameters{num = ?TEST_TELNYX_NUM}) ->
    DeniedFeatures = [
        ?FEATURE_PORT,
        ?FEATURE_FAILOVER
    ],
    ?LOG_DEV("denied features set on number document: ~s", [?PP(DeniedFeatures)]),
    DeniedFeatures;
number_denied_features(#feature_parameters{num = ?BW_EXISTING_DID}) ->
    DeniedFeatures = [?FEATURE_E911],
    ?LOG_DEV("denied features set on number document: ~s", [?PP(DeniedFeatures)]),
    DeniedFeatures;
number_denied_features(#feature_parameters{denied_features = DeniedFeatures}) ->
    ?LOG_DEV("denied features set on number document: ~s", [?PP(DeniedFeatures)]),
    DeniedFeatures.
-else.
number_denied_features(#feature_parameters{denied_features = DeniedFeatures}) ->
    ?LOG_DEV("denied features set on number document: ~s", [?PP(DeniedFeatures)]),
    DeniedFeatures.
-endif.

-spec maybe_deny_admin_only_features(feature_parameters()) -> kz_term:ne_binaries().
maybe_deny_admin_only_features(#feature_parameters{is_admin = true}) ->
    [];
maybe_deny_admin_only_features(#feature_parameters{is_admin = false}) ->
    Features = ?ADMIN_ONLY_FEATURES,
    ?LOG_DEV("allowing admin-only features: ~s", [?PP(Features)]),
    Features.

-spec legacy_provider_to_feature(kz_term:ne_binary()) -> kz_term:ne_binary().
legacy_provider_to_feature(<<"wnm_", Rest/binary>>) -> legacy_provider_to_feature(Rest);
legacy_provider_to_feature(<<"knm_", Rest/binary>>) -> legacy_provider_to_feature(Rest);
legacy_provider_to_feature(<<"cnam_notifier">>) -> ?FEATURE_CNAM;
legacy_provider_to_feature(?LEGACY_DASH_E911) -> ?FEATURE_E911;
legacy_provider_to_feature(<<"port_notifier">>) -> ?FEATURE_PORT;
legacy_provider_to_feature(<<"telnyx_cnam">>) -> ?FEATURE_CNAM;
legacy_provider_to_feature(?LEGACY_TELNYX_E911) -> ?FEATURE_E911;
legacy_provider_to_feature(<<"vitelity_cnam">>) -> ?FEATURE_CNAM;
legacy_provider_to_feature(?LEGACY_VITELITY_E911) -> ?FEATURE_E911;
legacy_provider_to_feature(Else) -> Else.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec requested_modules(knm_number:knm_number()) -> kz_term:ne_binaries().
requested_modules(Number) ->
    PhoneNumber = knm_number:phone_number(Number),
    AccountId = knm_phone_number:assigned_to(PhoneNumber),
    Doc = knm_phone_number:doc(PhoneNumber),
    RequestedFeatures = [
        Key
     || Key <- ?FEATURES_ROOT_KEYS,
        'undefined' =/= kz_json:get_value(Key, Doc)
    ],
    ?LOG_DEV("asked on public fields: ~s", [?PP(RequestedFeatures)]),
    ExistingFeatures = knm_phone_number:features_list(PhoneNumber),
    ?LOG_DEV("previously allowed: ~s", [?PP(ExistingFeatures)]),
    %% ?FEATURE_LOCAL is never user-writable thus must not be included.
    Features = (RequestedFeatures ++ ExistingFeatures) -- [?FEATURE_LOCAL],
    provider_modules(Features, AccountId).

-spec allowed_modules(knm_number:knm_number()) -> kz_term:ne_binaries().
allowed_modules(Number) ->
    PhoneNumber = knm_number:phone_number(Number),
    AccountId = knm_phone_number:assigned_to(PhoneNumber),
    provider_modules(available_features(PhoneNumber), AccountId).

-spec provider_modules(kz_term:ne_binaries(), kz_term:api_ne_binary()) -> kz_term:ne_binaries().
provider_modules(Features, MaybeAccountId) ->
    lists:usort(
        [
            provider_module(Feature, MaybeAccountId)
         || Feature <- Features
        ]
    ).

-spec provider_module(kz_term:ne_binary(), kz_term:api_ne_binary()) -> kz_term:ne_binary().
provider_module(?FEATURE_CNAM, ?MATCH_ACCOUNT_RAW(AccountId)) ->
    cnam_provider(AccountId);
provider_module(?FEATURE_CNAM_INBOUND, AccountId) ->
    provider_module(?FEATURE_CNAM, AccountId);
provider_module(?FEATURE_CNAM_OUTBOUND, AccountId) ->
    provider_module(?FEATURE_CNAM, AccountId);
provider_module(?FEATURE_E911, ?MATCH_ACCOUNT_RAW(AccountId)) ->
    e911_provider(AccountId);
provider_module(?FEATURE_PREPEND, _) ->
    <<"knm_prepend">>;
provider_module(?FEATURE_SMS, _) ->
    <<"knm_sms">>;
provider_module(?FEATURE_MMS, _) ->
    <<"knm_mms">>;
provider_module(?FEATURE_PORT, _) ->
    <<"knm_port_notifier">>;
provider_module(?FEATURE_FAILOVER, _) ->
    <<"knm_failover">>;
provider_module(?FEATURE_RENAME_CARRIER, _) ->
    ?PROVIDER_RENAME_CARRIER;
provider_module(?FEATURE_FORCE_OUTBOUND, _) ->
    ?PROVIDER_FORCE_OUTBOUND;
provider_module(Other, _) ->
    ?LOG_DEV("unmatched feature provider ~p, allowing", [Other]),
    Other.

-ifdef(TEST).
e911_provider(?RESELLER_ACCOUNT_ID) -> <<"knm_telnyx_e911">>;
e911_provider(AccountId) -> ?E911_PROVIDER(AccountId).
-else.
e911_provider(AccountId) -> ?E911_PROVIDER(AccountId).
-endif.

-ifdef(TEST).
cnam_provider(?RESELLER_ACCOUNT_ID) -> <<"knm_telnyx_cnam">>;
cnam_provider(AccountId) -> ?CNAM_PROVIDER(AccountId).
-else.
cnam_provider(AccountId) -> ?CNAM_PROVIDER(AccountId).
-endif.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-type exec_action() :: 'save' | 'delete'.

-spec do_exec(knm_numbers:collection(), exec_action()) -> knm_numbers:collection().
do_exec(T0 = #{'todo' := Ns}, Action) ->
    F = fun(N, T) ->
        case knm_number:attempt(fun exec/2, [N, Action]) of
            {'ok', NewN} -> knm_numbers:ok(NewN, T);
            {'error', R} -> knm_numbers:ko(N, R, T)
        end
    end,
    lists:foldl(F, T0, Ns).

-spec exec(knm_number:knm_number(), exec_action()) -> knm_number:knm_number().
exec(Number, Action = 'delete') ->
    RequestedModules = requested_modules(Number),
    ?LOG_DEV("deleting feature providers: ~s", [?PP(RequestedModules)]),
    exec(Number, Action, RequestedModules);
exec(N, Action = 'save') ->
    N1 = remove_deprecated_features(N),
    {NewN, AllowedModules, DeniedModules0} = maybe_rename_carrier_and_strip_denied(N1),
    DeniedModules = DeniedModules0 -- ?REMOVED_DENIED_FEATURES,
    case DeniedModules =:= [] of
        'true' ->
            exec(NewN, Action, AllowedModules);
        'false' ->
            ?LOG_DEV("denied feature providers: ~s", [?PP(DeniedModules)]),
            knm_errors:unauthorized()
    end.

-spec remove_deprecated_features(knm_number:knm_number()) -> knm_number:knm_number().
remove_deprecated_features(Number) ->
    PN = knm_number:phone_number(Number),
    Features = knm_phone_number:features(PN),
    case lists:any(fun(K) -> kz_json:is_defined(K, Features) end, ?DEPRECATED_FEATURES) of
        true ->
            lager:info("removing deprecated features from ~s", [knm_phone_number:number(PN)]),
            PN1 = knm_phone_number:set_features(
                PN, kz_json:delete_keys(?DEPRECATED_FEATURES, Features)
            ),
            knm_number:set_phone_number(Number, PN1);
        false ->
            Number
    end.

-spec maybe_rename_carrier_and_strip_denied(knm_number:knm_number()) ->
    {knm_number:knm_number(), kz_term:ne_binaries(), kz_term:ne_binaries()}.
maybe_rename_carrier_and_strip_denied(N) ->
    {AllowedRequests, DeniedRequests} = split_requests(N),
    ?LOG_DEV("allowing feature providers: ~s", [?PP(AllowedRequests)]),
    case lists:member(?PROVIDER_RENAME_CARRIER, AllowedRequests) of
        'false' ->
            {N, AllowedRequests, DeniedRequests};
        'true' ->
            N1 = exec(N, 'save', [?PROVIDER_RENAME_CARRIER]),
            N2 = remove_denied_features(N1),
            {NewAllowed, NewDenied} = split_requests(N2),
            ?LOG_DEV("allowing feature providers: ~s", [?PP(NewAllowed)]),
            {N2, NewAllowed, NewDenied}
    end.

-spec remove_denied_features(knm_number:knm_number()) -> knm_number:knm_number().
remove_denied_features(N) ->
    PN = knm_number:phone_number(N),
    NewPN = knm_phone_number:remove_denied_features(PN),
    knm_number:set_phone_number(N, NewPN).

-spec features_denied(knm_phone_number:knm_phone_number()) -> kz_term:ne_binaries().
features_denied(PN) ->
    cleanse_features(list_denied_features(feature_parameters(PN))).

-spec split_requests(knm_number:knm_number()) -> {kz_term:ne_binaries(), kz_term:ne_binaries()}.
split_requests(Number) ->
    RequestedModules = requested_modules(Number),
    ?LOG_DEV("requested feature providers: ~s", [?PP(RequestedModules)]),
    AllowedModules = allowed_modules(Number),
    ?LOG_DEV("allowed providers: ~s", [?PP(AllowedModules)]),
    F = fun(Feature) -> lists:member(Feature, AllowedModules) end,
    lists:partition(F, RequestedModules).

-spec exec(knm_number:knm_number(), exec_action(), kz_term:ne_binaries()) ->
    knm_number:knm_number().
exec(Number, _, []) ->
    Number;
exec(Number, Action, [Provider | Providers]) ->
    case apply_action(Number, Action, Provider) of
        'false' -> exec(Number, Action, Providers);
        {'true', UpdatedNumber} -> exec(UpdatedNumber, Action, Providers)
    end.

-spec apply_action(knm_number:knm_number(), exec_action(), kz_term:ne_binary()) ->
    {'true', any()} | 'false'.
apply_action(Number, Action, Provider) ->
    case kz_module:ensure_loaded(Provider) of
        'false' ->
            ?LOG_DEV("provider ~s is unknown, skipping", [Provider]),
            'false';
        Module ->
            ?LOG_DEV("attempting ~s:~s/1", [Module, Action]),
            Ret = erlang:apply(Module, Action, [Number]),
            {'true', Ret}
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-type set_feature() :: {kz_term:ne_binary(), kz_json:object()}.

-spec activate_feature(knm_number:knm_number(), set_feature() | kz_term:ne_binary()) ->
    knm_number:knm_number().
activate_feature(Number, Feature = ?NE_BINARY) ->
    activate_feature(Number, {Feature, kz_json:new()});
activate_feature(Number, FeatureToSet = {?NE_BINARY, _}) ->
    do_activate_feature(Number, FeatureToSet).

-spec do_activate_feature(knm_number:knm_number(), set_feature()) ->
    knm_number:knm_number().
do_activate_feature(Number, {Feature, FeatureData}) ->
    PhoneNumber = knm_number:phone_number(Number),
    ?LOG_DEV(
        "adding feature ~s to ~s",
        [Feature, knm_phone_number:number(PhoneNumber)]
    ),
    PN = knm_phone_number:set_feature(PhoneNumber, Feature, FeatureData),
    knm_number:set_phone_number(Number, PN).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec deactivate_feature(knm_number:knm_number(), kz_term:ne_binary()) -> knm_number:knm_number().
deactivate_feature(Number, Feature) ->
    PhoneNumber = knm_number:phone_number(Number),
    Features = knm_phone_number:features(PhoneNumber),
    PN = knm_phone_number:set_features(PhoneNumber, kz_json:delete_key(Feature, Features)),
    knm_number:set_phone_number(Number, PN).

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec deactivate_features(knm_number:knm_number(), kz_term:ne_binaries()) ->
    knm_number:knm_number().
deactivate_features(Number, Features) ->
    PhoneNumber = knm_number:phone_number(Number),
    ExistingFeatures = knm_phone_number:features(PhoneNumber),
    PN = knm_phone_number:set_features(
        PhoneNumber, kz_json:delete_keys(Features, ExistingFeatures)
    ),
    knm_number:set_phone_number(Number, PN).

-spec setup_account_context(kz_term:ne_binary()) -> map().
setup_account_context(AccountId) ->
    setup_account_context(AccountId, false).

-spec setup_account_context(kz_term:ne_binary(), boolean()) -> map().
setup_account_context(AccountId, Admin) ->
    Allowed = reseller_allowed_features(AccountId),
    #{
        allowed => Allowed,
        local_feature_override => ?LOCAL_FEATURE_OVERRIDE,
        denied => ?FEATURES_DENIED_RESELLER(AccountId),
        admin_only => ?ADMIN_ONLY_FEATURES,
        with_available => ?PROVIDERS_WITH_AVAILABLE,
        is_admin => Admin,
        modules => maps:from_list([
            {Feature, provider_module(Feature, AccountId)}
         || Feature <- Allowed
        ]),
        account_id => AccountId
    }.

-spec setup_number_context(kz_json:object(), map()) -> map().
setup_number_context(JObj, Context) ->
    maps:merge(Context, setup_number_context(JObj)).

-spec setup_number_context(kz_json:object()) -> map().
setup_number_context(JObj) ->
    #{
        assigned_to => kz_json:get_ne_binary_value(<<"assigned_to">>, JObj),
        used_by => kz_json:get_ne_binary_value(<<"used_by">>, JObj),
        features_allowed => kz_json:get_list_value(<<"features_allowed">>, JObj, []),
        features_denied => kz_json:get_list_value(<<"features_denied">>, JObj, []),
        is_local => lists:member(?FEATURE_LOCAL, kz_json:get_list_value(<<"features">>, JObj, [])),
        carrier => kz_json:get_ne_binary_value(<<"pvt_module_name">>, JObj),
        state => kz_json:get_ne_binary_value(<<"state">>, JObj)
    }.

%%------------------------------------------------------------------------------
%% @doc List features a number is allowed by its reseller to enable.
%% @end
%%------------------------------------------------------------------------------
-spec filter_available_features(kz_term:ne_binaries(), map()) -> kz_term:ne_binaries().
filter_available_features(Features, #{with_available := []}) ->
    Features;
filter_available_features(Features, #{
    with_available := Check,
    account_id := AccountId,
    carrier := Carrier,
    state := State
}) ->
    Fun = fun(Feature) ->
        case lists:member(Feature, Check) of
            false -> true;
            true -> knm_gen_provider:available(Feature, Carrier, State, AccountId)
        end
    end,
    lists:filter(Fun, Features);
filter_available_features(Features, _) ->
    Features.
