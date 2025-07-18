%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2013-2020, 2600Hz
%%% @doc Helpers for cli commands
%%% @author James Aimonetti
%%%
%%% @author James Aimonetti
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(acdc_maintenance).

-export([
    current_calls/1, current_calls/2,
    current_statuses/1,
    current_queues/1,
    current_agents/1,
    logout_agents/1,
    logout_agent/2,
    agent_presence_id/2,
    migrate_to_acdc_db/0, migrate_to_acdc_db/1,
    migrate/0,
    refresh/0,
    refresh_account/1,
    flush_call_stat/1,
    queues_summary/0, queues_summary/1,
    queue_summary/2,
    queues_detail/0, queues_detail/1,
    queue_detail/2,
    queues_restart/1,
    queue_restart/2,

    agents_summary/0, agents_summary/1,
    agent_summary/2,
    agents_detail/0, agents_detail/1,
    agent_detail/2,
    agent_login/2,
    agent_logout/2,
    agent_pause/2, agent_pause/3,
    agent_resume/2,
    agent_queue_login/3,
    agent_queue_logout/3
]).

-export([register_views/0]).

-include("acdc.hrl").

-spec logout_agents(kz_term:ne_binary()) -> 'ok'.
logout_agents(AccountId) ->
    ?PRINT("Sending notices to logout agents for ~s", [AccountId]),
    AccountDb = kz_util:format_account_id(AccountId, 'encoded'),
    {'ok', AgentView} = kz_datamgr:get_all_results(AccountDb, <<"agents/crossbar_listing">>),
    _ = [logout_agent(AccountId, kz_doc:id(Agent)) || Agent <- AgentView],
    'ok'.

-spec logout_agent(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
logout_agent(AccountId, AgentId) ->
    io:format("Sending notice to log out agent ~s (~s)~n", [AgentId, AccountId]),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_logout/1).

-define(KEYS, [<<"Waiting">>, <<"Handled">>]).

-spec current_statuses(kz_term:text()) -> 'ok'.
current_statuses(AccountId) ->
    {'ok', Agents} = acdc_agent_util:most_recent_statuses(AccountId),
    case kz_json:values(Agents) of
        [] ->
            io:format("No agent statuses found for ~s~n", [AccountId]);
        As ->
            io:format("Agent Statuses for ~s~n", [AccountId]),
            io:format(
                "~4s | ~35s | ~12s | ~20s |~n",
                [<<>>, <<"Agent-ID">>, <<"Status">>, <<"Timestamp">>]
            ),
            log_current_statuses(As, 1)
    end.

log_current_statuses([], _) ->
    'ok';
log_current_statuses([A | As], N) ->
    log_current_status(A, N),
    log_current_statuses(As, N + 1).

log_current_status(A, N) ->
    [K | _] = kz_json:get_keys(A),
    V = kz_json:get_value(K, A),
    TS = kz_json:get_integer_value(<<"timestamp">>, V),
    io:format("~4b | ~35s | ~12s | ~20s |~n", [
        N,
        kz_json:get_value(<<"agent_id">>, V),
        kz_json:get_value(<<"status">>, V),
        kz_time:pretty_print_datetime(TS)
    ]).

-spec current_queues(kz_term:ne_binary()) -> 'ok'.
current_queues(AccountId) ->
    case acdc_agents_sup:find_acct_supervisors(AccountId) of
        [] ->
            io:format("no agent processes found for ~s~n", [AccountId]);
        Agents ->
            io:format("Agent Queue Assignments for Account ~s~n", [AccountId]),
            log_current_queues(Agents)
    end.

log_current_queues(Agents) ->
    io:format(" ~35s | ~s~n", [<<"Agent ID">>, <<"Queue IDs">>]),
    lists:foreach(fun log_current_queue/1, Agents).
log_current_queue(AgentSup) ->
    AgentL = acdc_agent_sup:listener(AgentSup),
    io:format(" ~35s | ~s~n", [
        acdc_agent_listener:id(AgentL),
        kz_binary:join(acdc_agent_listener:queues(AgentL))
    ]).

-spec current_agents(kz_term:ne_binary()) -> 'ok'.
current_agents(AccountId) ->
    case acdc_queues_sup:find_acct_supervisors(AccountId) of
        [] ->
            io:format("no queue processes found for ~s~n", [AccountId]);
        Queues ->
            io:format("Queue Agent Assignments for Account ~s~n", [AccountId]),
            log_current_agents(Queues)
    end.
log_current_agents(Queues) ->
    io:format(" ~35s | Strat | P | ~s~n", [<<"Queue ID">>, <<"Agent IDs">>]),
    lists:foreach(fun log_current_agent/1, Queues).
log_current_agent(QueueSup) ->
    QueueM = acdc_queue_sup:manager(QueueSup),
    {_AccountId, QueueId, Strategy} = acdc_queue_manager:config(QueueM),
    io:format(" ~35s | ~5s~s~n~n", [
        QueueId,
        Strategy,
        agents(Strategy, QueueM)
    ]).

agents(S, QueueM) when S =:= 'rr' orelse S =:= 'all' ->
    lists:foldr(
        fun({P, Agents}, Acc) ->
            <<" | ", ((P * -1) + 16#30), " | ",
                (kz_binary:join(Agents, io_lib:format("~n~51s", [" "])))/binary,
                (list_to_binary(io_lib:format("~n~44s", [" "])))/binary, Acc/binary>>
        end,
        <<>>,
        acdc_queue_manager:agents(QueueM)
    );
agents(S, QueueM) when S =:= 'sbrr' ->
    lists:foldr(
        fun({P, Agents}, Acc) ->
            <<" | ", ((P * -1) + 16#30), " | ", (agents_with_skills(Agents, QueueM))/binary,
                (list_to_binary(io_lib:format("~n~44s", [" "])))/binary, Acc/binary>>
        end,
        <<>>,
        acdc_queue_manager:agents(QueueM)
    ).

agents_with_skills(Agents, QueueM) ->
    SkillMap = acdc_queue_manager:skill_map(QueueM),

    lists:foldl(
        fun(Agent, Acc) ->
            <<Agent/binary, " | ", (agent_skills(Agent, SkillMap))/binary,
                (list_to_binary(io_lib:format("~n~51s", [" "])))/binary, Acc/binary>>
        end,
        <<>>,
        Agents
    ).

agent_skills(Agent, SkillMap) ->
    kz_binary:join(
        lists:usort(
            lists:flatten(
                maps:keys(maps:filter(fun(_, V) -> sets:is_element(Agent, V) end, SkillMap))
            )
        ),
        $,
    ).

-spec current_calls(kz_term:ne_binary()) -> 'ok'.
current_calls(AccountId) ->
    Req = [
        {<<"Account-ID">>, AccountId}
        | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
    ],
    get_and_show(AccountId, <<"all">>, Req).

-spec current_calls(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
current_calls(AccountId, QueueId) when is_binary(QueueId) ->
    Req = [
        {<<"Account-ID">>, AccountId},
        {<<"Queue-ID">>, QueueId}
        | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
    ],
    get_and_show(AccountId, QueueId, Req);
current_calls(AccountId, Props) ->
    Req = [
        {<<"Account-ID">>, AccountId}
        | Props ++ kz_api:default_headers(?APP_NAME, ?APP_VERSION)
    ],
    get_and_show(AccountId, <<"custom">>, Req).

get_and_show(AccountId, QueueId, Req) ->
    kz_util:put_callid(<<"acdc_maint.", AccountId/binary, ".", QueueId/binary>>),
    case
        kz_amqp_worker:call(
            Req,
            fun kapi_acdc_stats:publish_current_calls_req/1,
            fun kapi_acdc_stats:current_calls_resp_v/1
        )
    of
        {_, []} ->
            io:format("no call stats returned for account ~s (queue ~s)~n", [AccountId, QueueId]);
        {'ok', JObjs} ->
            io:format("call stats for account ~s (queue ~s)~n", [AccountId, QueueId]),
            show_call_stat_cat(?KEYS, JObjs);
        {'error', _E} ->
            io:format("failed to lookup call stats for account ~s (queue ~s): ~p~n", [
                AccountId, QueueId, _E
            ])
    end.

show_call_stat_cat([], _) ->
    'ok';
show_call_stat_cat([K | Ks], Resp) ->
    case kz_json:get_value(K, Resp) of
        'undefined' ->
            show_call_stat_cat(Ks, Resp);
        V ->
            ?PRINT("~nCalls ~s~n", [K]),
            ?PRINT("~s", [
                lists:foldr(fun(F, Acc) -> print_field(F) ++ Acc end, [], ?CALL_INFO_FIELDS)
            ]),
            show_stats(V),
            show_call_stat_cat(Ks, Resp)
    end.

show_stats([]) ->
    'ok';
show_stats([S | Ss]) ->
    Vs = [{K, V} || {K, V} <- kz_json:to_proplist(S), lists:member(K, ?CALL_INFO_FIELDS)],
    ?PRINT("~s", [lists:foldr(fun(F, Acc) -> print_value(F) ++ Acc end, [], Vs)]),
    show_stats(Ss).

print_value({_, []}) ->
    io_lib:format(" ~20s |", [" "]);
print_value({<<"entered_timestamp">>, V}) ->
    io_lib:format(" ~20s |", [kz_time:pretty_print_datetime(V)]);
print_value({<<"queue_id">>, V}) ->
    io_lib:format(" ~32s |", [V]);
print_value({<<"call_id">>, V}) ->
    io_lib:format(" ~32s |", [V]);
print_value({_, V}) when is_binary(V) ->
    io_lib:format(" ~20s |", [V]);
print_value({_, V}) ->
    io_lib:format(" ~20.B |", [V]).

print_field(<<"agent_id">> = V) ->
    io_lib:format(" ~32s |", [V]);
print_field(<<"queue_id">> = V) ->
    io_lib:format(" ~32s |", [V]);
print_field(<<"call_id">> = V) ->
    io_lib:format(" ~32s |", [V]);
print_field(Else) ->
    io_lib:format(" ~20s |", [Else]).

-spec refresh() -> 'ok'.
refresh() ->
    case kz_datamgr:get_all_results(?KZ_ACDC_DB, <<"acdc/accounts_listing">>) of
        {'ok', []} ->
            lager:debug("no accounts configured for acdc");
        {'ok', Accounts} ->
            _ = [refresh_account(kz_json:get_value(<<"key">>, Acct)) || Acct <- Accounts],
            lager:debug("refreshed accounts");
        {'error', 'not_found'} ->
            lager:debug("acdc db not found"),
            lager:debug(
                "consider running ~s:migrate() to enable acdc for already-configured accounts", [
                    ?MODULE
                ]
            );
        {'error', _E} ->
            lager:debug("failed to query acdc db: ~p", [_E])
    end.

-spec refresh_account(kz_term:ne_binary()) -> 'ok'.
refresh_account(Acct) ->
    AccountDb = kz_util:format_account_id(Acct, 'encoded'),
    kz_datamgr:revise_views_from_folder(AccountDb, 'acdc'),
    io:format("revised acdc views for ~s~n", [AccountDb]),
    MoDB = acdc_stats_util:db_name(Acct),
    refresh_account(MoDB, kazoo_modb:maybe_create(MoDB)),
    lager:debug("refreshed: ~s", [MoDB]).

refresh_account(MoDB, 'true') ->
    lager:debug("created ~s", [MoDB]),
    kz_datamgr:revise_views_from_folder(MoDB, 'acdc');
refresh_account(MoDB, 'false') ->
    case kz_datamgr:db_exists(MoDB) of
        'true' ->
            lager:debug("exists ~s", [MoDB]),
            kz_datamgr:revise_views_from_folder(MoDB, 'acdc');
        'false' ->
            lager:debug("modb ~s was not created", [MoDB])
    end.

-spec migrate() -> 'ok'.
migrate() ->
    migrate_to_acdc_db().

-spec migrate_to_acdc_db() -> 'ok'.
migrate_to_acdc_db() ->
    {'ok', Accounts} = kz_datamgr:all_docs(?KZ_ACDC_DB),
    _ = [maybe_remove_acdc_account(kz_doc:id(Account)) || Account <- Accounts],
    io:format("removed any missing accounts from ~s~n", [?KZ_ACDC_DB]),
    lists:foreach(fun migrate_to_acdc_db/1, kapps_util:get_all_accounts('raw')),
    io:format("migration complete~n").

-spec maybe_remove_acdc_account(kz_term:ne_binary()) -> 'ok'.
maybe_remove_acdc_account(<<"_design/", _/binary>>) ->
    'ok';
maybe_remove_acdc_account(AccountId) ->
    case kzd_accounts:fetch(AccountId) of
        {'ok', _} ->
            'ok';
        {'error', 'not_found'} ->
            {'ok', JObj} = kz_datamgr:open_cache_doc(?KZ_ACDC_DB, AccountId),
            {'ok', _Del} = kz_datamgr:del_doc(?KZ_ACDC_DB, JObj),
            io:format("account ~p not found in ~s, removing from ~s~n", [
                AccountId, ?KZ_ACCOUNTS_DB, ?KZ_ACDC_DB
            ])
    end.

-spec migrate_to_acdc_db(kz_term:ne_binary()) -> 'ok'.
migrate_to_acdc_db(AccountId) ->
    migrate_to_acdc_db(AccountId, 3).

-spec migrate_to_acdc_db(kz_term:ne_binary(), non_neg_integer()) -> 'ok'.
migrate_to_acdc_db(AccountId, 0) ->
    io:format("retries exceeded, skipping account ~s~n", [AccountId]);
migrate_to_acdc_db(AccountId, Retries) ->
    case
        kz_datamgr:get_results(
            ?KZ_ACDC_DB,
            <<"acdc/accounts_listing">>,
            [{'key', AccountId}]
        )
    of
        {'ok', []} ->
            maybe_migrate(AccountId);
        {'ok', _} ->
            'ok';
        {'error', 'not_found'} ->
            io:format("acdc db not found (or view is missing, restoring then trying again)~n", []),
            acdc_init:init_db(),
            timer:sleep(250),
            migrate_to_acdc_db(AccountId, Retries - 1);
        {'error', _E} ->
            io:format("failed to check acdc db for account ~s: ~p~n", [AccountId, _E]),
            timer:sleep(250),
            migrate_to_acdc_db(AccountId, Retries - 1)
    end.

-spec maybe_migrate(kz_term:ne_binary()) -> 'ok'.
maybe_migrate(AccountId) ->
    AccountDb = kz_util:format_account_id(AccountId, 'encoded'),
    case kz_datamgr:get_results(AccountDb, <<"queues/crossbar_listing">>, [{'limit', 1}]) of
        {'ok', []} ->
            'ok';
        {'ok', [_ | _]} ->
            io:format("account ~s has queues, adding to acdc db~n", [AccountId]),
            Doc = kz_doc:update_pvt_parameters(
                kz_json:from_list([{<<"_id">>, AccountId}]),
                ?KZ_ACDC_DB,
                [
                    {'account_id', AccountId},
                    {'type', <<"acdc_activation">>}
                ]
            ),
            kz_datamgr:ensure_saved(?KZ_ACDC_DB, Doc),
            io:format("saved account ~s to acdc db~n", [AccountId]);
        {'error', _E} ->
            io:format("failed to query queue listing for account ~s: ~p~n", [AccountId, _E])
    end.

-spec agent_presence_id(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_presence_id(AccountId, AgentId) ->
    case acdc_agents_sup:find_agent_supervisor(AccountId, AgentId) of
        'undefined' ->
            io:format("agent ~s(~s) not logged in or not found~n", [AgentId, AccountId]);
        SupPid ->
            PresenceId = acdc_agent_listener:presence_id(acdc_agent_sup:listener(SupPid)),
            io:format("agent ~s(~s) is using presence ID ~s~n", [AgentId, AccountId, PresenceId])
    end.

-spec flush_call_stat(kz_term:ne_binary()) -> 'ok'.
flush_call_stat(CallId) ->
    case acdc_stats:find_call(CallId) of
        'undefined' ->
            io:format("nothing found for call ~s~n", [CallId]);
        Call ->
            _ = acdc_stats:call_abandoned(
                kz_json:get_value(<<"Account-ID">>, Call),
                kz_json:get_value(<<"Queue-ID">>, Call),
                CallId,
                ?ABANDON_INTERNAL_ERROR
            ),
            io:format("setting call to 'abandoned'~n", [])
    end.

-spec queues_summary() -> 'ok'.
queues_summary() ->
    kz_util:put_callid(?MODULE),
    show_queues_summary(acdc_queues_sup:queues_running()).

-spec queues_summary(kz_term:ne_binary()) -> 'ok'.
queues_summary(AccountId) ->
    kz_util:put_callid(?MODULE),
    show_queues_summary(
        [
            Q
         || {_, {QAccountId, _, _}} = Q <- acdc_queues_sup:queues_running(),
            QAccountId =:= AccountId
        ]
    ).

-spec queue_summary(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
queue_summary(AccountId, QueueId) ->
    kz_util:put_callid(?MODULE),
    show_queues_summary(
        [
            Q
         || {_, {QAccountId, QQueueId, _}} = Q <- acdc_queues_sup:queues_running(),
            QAccountId =:= AccountId,
            QQueueId =:= QueueId
        ]
    ).

-spec show_queues_summary([{pid(), {kz_term:ne_binary(), kz_term:ne_binary()}}]) -> 'ok'.
show_queues_summary([]) ->
    'ok';
show_queues_summary([{P, {AccountId, QueueId, Strategy}} | Qs]) ->
    ?PRINT("  Supervisor: ~p Acct: ~s Queue: ~s Strategy: ~s~n", [P, AccountId, QueueId, Strategy]),
    show_queues_summary(Qs).

-spec queues_detail() -> 'ok'.
queues_detail() ->
    acdc_queues_sup:status().

-spec queues_detail(kz_term:ne_binary()) -> 'ok'.
queues_detail(AccountId) ->
    kz_util:put_callid(?MODULE),
    Supervisors = acdc_queues_sup:find_acct_supervisors(AccountId),
    lists:foreach(fun acdc_queue_sup:status/1, Supervisors).

-spec queue_detail(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
queue_detail(AccountId, QueueId) ->
    case acdc_queues_sup:find_queue_supervisor(AccountId, QueueId) of
        'undefined' -> lager:info("no queue ~s in account ~s", [QueueId, AccountId]);
        Pid -> acdc_queue_sup:status(Pid)
    end.

-spec queues_restart(kz_term:ne_binary()) -> 'ok'.
queues_restart(AccountId) ->
    kz_util:put_callid(?MODULE),
    case acdc_queues_sup:find_acct_supervisors(AccountId) of
        [] ->
            lager:info("there are no running queues in ~s", [AccountId]);
        Pids ->
            F = fun(Pid) -> maybe_stop_then_start_queue(AccountId, Pid) end,
            lists:foreach(F, Pids)
    end.

-spec queue_restart(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
queue_restart(AccountId, QueueId) ->
    kz_util:put_callid(?MODULE),
    case acdc_queues_sup:find_queue_supervisor(AccountId, QueueId) of
        'undefined' ->
            lager:info("queue ~s in account ~s not running", [QueueId, AccountId]);
        Pid ->
            maybe_stop_then_start_queue(AccountId, QueueId, Pid)
    end.

-spec maybe_stop_then_start_queue(kz_term:ne_binary(), pid()) -> 'ok'.
maybe_stop_then_start_queue(AccountId, Pid) ->
    {AccountId, QueueId} = acdc_queue_manager:config(acdc_queue_sup:manager(Pid)),
    maybe_stop_then_start_queue(AccountId, QueueId, Pid).

-spec maybe_stop_then_start_queue(kz_term:ne_binary(), kz_term:ne_binary(), pid()) -> 'ok'.
maybe_stop_then_start_queue(AccountId, QueueId, Pid) ->
    case supervisor:terminate_child('acdc_queues_sup', Pid) of
        'ok' ->
            lager:info("stopped queue supervisor ~p", [Pid]),
            maybe_start_queue(AccountId, QueueId);
        {'error', 'not_found'} ->
            lager:info("queue supervisor ~p not found", [Pid]);
        {'error', _E} ->
            lager:info("failed to terminate queue supervisor ~p: ~p", [_E])
    end.

maybe_start_queue(AccountId, QueueId) ->
    case acdc_queues_sup:new(AccountId, QueueId) of
        {'ok', 'undefined'} ->
            lager:info("tried to start queue but it asked to be ignored");
        {'ok', Pid} ->
            lager:info("started queue back up in ~p", [Pid]);
        {'error', 'already_present'} ->
            lager:info("queue is already present (but not running)");
        {'error', {'already_running', Pid}} ->
            lager:info("queue is already running in ~p", [Pid]);
        {'error', _E} ->
            lager:info("failed to start queue: ~p", [_E])
    end.

-spec agents_summary() -> 'ok'.
agents_summary() ->
    kz_util:put_callid(?MODULE),
    show_agents_summary(acdc_agents_sup:agents_running()).

-spec agents_summary(kz_term:ne_binary()) -> 'ok'.
agents_summary(AccountId) ->
    kz_util:put_callid(?MODULE),
    show_agents_summary(
        [
            A
         || {_, {AAccountId, _, _}} = A <- acdc_agents_sup:agents_running(),
            AAccountId =:= AccountId
        ]
    ).

-spec agent_summary(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_summary(AccountId, AgentId) ->
    kz_util:put_callid(?MODULE),
    show_agents_summary(
        [
            Q
         || {_, {AAccountId, AAgentId, _}} = Q <- acdc_agents_sup:agents_running(),
            AAccountId =:= AccountId,
            AAgentId =:= AgentId
        ]
    ).

-spec show_agents_summary([{pid(), acdc_agent_listener:config()}]) -> 'ok'.
show_agents_summary([]) ->
    'ok';
show_agents_summary([{P, {AccountId, AgentId, _AMQPQueue}} | Qs]) ->
    ?PRINT("  Supervisor: ~p Acct: ~s Agent: ~s", [P, AccountId, AgentId]),
    show_agents_summary(Qs).

-spec agents_detail() -> 'ok'.
agents_detail() ->
    kz_util:put_callid(?MODULE),
    ?PRINT("~s", [
        lists:foldr(
            fun(F, Acc) -> print_field(F) ++ Acc end,
            [],
            [<<"agent_id">>, <<"status">>] ++ ?AGENT_INFO_FIELDS
        )
    ]),
    acdc_agents_sup:status().

-spec agents_detail(kz_term:ne_binary()) -> 'ok'.
agents_detail(AccountId) ->
    kz_util:put_callid(?MODULE),
    Supervisors = acdc_agents_sup:find_acct_supervisors(AccountId),
    ?PRINT("Acct: ~s", [AccountId]),
    ?PRINT("~s", [
        lists:foldr(
            fun(F, Acc) -> print_field(F) ++ Acc end,
            [],
            [<<"agent_id">>, <<"status">>] ++ ?AGENT_INFO_FIELDS
        )
    ]),
    lists:foreach(fun acdc_agent_sup:status/1, Supervisors).

-spec agent_detail(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_detail(AccountId, AgentId) ->
    kz_util:put_callid(?MODULE),
    case acdc_agents_sup:find_agent_supervisor(AccountId, AgentId) of
        'undefined' -> lager:info("no agent ~s in account ~s", [AgentId, AccountId]);
        Pid -> acdc_agent_sup:status(Pid)
    end.

-spec agent_login(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_login(AccountId, AgentId) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_login/1),
    lager:info("published login update for agent").

-spec agent_logout(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_logout(AccountId, AgentId) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_logout/1),
    lager:info("published logout update for agent").

-spec agent_pause(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_pause(AccountId, AgentId) ->
    Timeout = kapps_config:get_integer(?CONFIG_CAT, <<"default_agent_pause_timeout">>, 600),
    agent_pause(AccountId, AgentId, Timeout).

-spec agent_pause(kz_term:ne_binary(), kz_term:ne_binary(), pos_integer()) -> 'ok'.
agent_pause(AccountId, AgentId, Timeout) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId},
            {<<"Time-Limit">>, binary_to_integer(Timeout)}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_pause/1),
    lager:info("published pause for agent").

-spec agent_resume(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_resume(AccountId, AgentId) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_resume/1),
    lager:info("published resume for agent").

-spec agent_queue_login(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_queue_login(AccountId, AgentId, QueueId) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId},
            {<<"Queue-ID">>, QueueId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_login_queue/1),
    lager:info("published login update for agent").

-spec agent_queue_logout(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
agent_queue_logout(AccountId, AgentId, QueueId) ->
    kz_util:put_callid(?MODULE),
    Update = props:filter_undefined(
        [
            {<<"Account-ID">>, AccountId},
            {<<"Agent-ID">>, AgentId},
            {<<"Queue-ID">>, QueueId}
            | kz_api:default_headers(?APP_NAME, ?APP_VERSION)
        ]
    ),
    kz_amqp_worker:cast(Update, fun kapi_acdc_agent:publish_logout_queue/1),
    lager:info("published logout update for agent").

-spec register_views() -> 'ok'.
register_views() ->
    kz_datamgr:register_views_from_folder(?APP).
