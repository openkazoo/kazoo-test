%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2012-2020, 2600Hz
%%% @doc
%%% @author James Aimonetti
%%% @author Daniel Finke
%%% This Source Code Form is subject to the terms of the Mozilla Public
%%% License, v. 2.0. If a copy of the MPL was not distributed with this
%%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%%
%%% @end
%%%-----------------------------------------------------------------------------
-module(acdc_agents_sup).

-behaviour(supervisor).

-include("acdc.hrl").

-define(SERVER, ?MODULE).

%% API
-export([
    start_link/0,
    new/1, new/2, new/4,
    new_thief/2,
    stop_agent/2,
    workers/0,
    find_acct_supervisors/1,
    find_agent_supervisor/2,
    status/0,
    agents_running/0,
    restart_acct/1,
    restart_agent/2
]).

%% Supervisor callbacks
-export([init/1]).

-define(CHILD_ID(AccountId, AgentId), <<AccountId/binary, "-", AgentId/binary>>).
-define(THIEF_ID(AccountId, QueueId, CallId),
    <<"thief-", AccountId/binary, "-", QueueId/binary, "-", CallId/binary>>
).
-define(CHILD(Id, Args), ?SUPER_NAME_ARGS_TYPE(Id, 'acdc_agent_sup', Args, 'transient')).
-define(INITIAL_CHILDREN, []).

%%%=============================================================================
%%% API functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Starts the supervisor.
%% @end
%%------------------------------------------------------------------------------
-spec start_link() -> kz_types:startlink_ret().
start_link() ->
    supervisor:start_link({'local', ?SERVER}, ?MODULE, []).

-spec status() -> 'ok'.
status() ->
    lists:foreach(fun acdc_agent_sup:status/1, workers()),
    'ok'.

-spec new(kz_json:object()) -> kz_types:sup_startchild_ret().
new(JObj) ->
    AccountId = kz_doc:account_id(JObj),
    AgentId = kz_doc:id(JObj),
    start_agent(AccountId, AgentId, JObj).

-spec new(kz_term:ne_binary(), kz_term:ne_binary()) -> kz_types:sup_startchild_ret().
new(AccountId, AgentId) ->
    {'ok', JObj} = kz_datamgr:open_doc(kz_util:format_account_id(AccountId, 'encoded'), AgentId),
    start_agent(AccountId, AgentId, JObj).

-spec new(kz_term:ne_binary(), kz_term:ne_binary(), kz_json:object(), kz_term:ne_binaries()) ->
    kz_types:sup_startchild_ret().
new(AccountId, AgentId, AgentJObj, Queues) ->
    start_agent(AccountId, AgentId, AgentJObj, [Queues]).

-spec new_thief(kapps_call:call(), kz_term:ne_binary()) -> kz_types:sup_startchild_ret().
new_thief(Call, QueueId) ->
    AccountId = kapps_call:account_id(Call),
    CallId = kapps_call:call_id(Call),
    Id = ?THIEF_ID(AccountId, QueueId, CallId),
    supervisor:start_child(?MODULE, ?CHILD(Id, [Call, QueueId])).

-spec stop_agent(kz_term:ne_binary(), kz_term:ne_binary()) -> kz_types:sup_deletechild_ret().
stop_agent(AccountId, AgentId) ->
    Id = ?CHILD_ID(AccountId, AgentId),
    case supervisor:terminate_child(?SERVER, Id) of
        'ok' ->
            lager:info("stopping agent ~s(~s)", [AgentId, AccountId]),
            supervisor:delete_child(?SERVER, Id);
        E ->
            lager:info("no supervisor for agent ~s(~s) to stop", [AgentId, AccountId]),
            E
    end.

-spec workers() -> kz_term:pids().
workers() -> [Pid || {_, Pid, 'supervisor', [_]} <- supervisor:which_children(?SERVER)].

-spec restart_acct(kz_term:ne_binary()) -> [kz_types:sup_startchild_ret()].
restart_acct(AccountId) ->
    [
        restart_agent(AccountId, AgentId)
     || {_, {AccountId1, AgentId, _}} <- agents_running(),
        AccountId =:= AccountId1
    ].

-spec restart_agent(kz_term:ne_binary(), kz_term:ne_binary()) -> kz_types:sup_startchild_ret().
restart_agent(AccountId, AgentId) ->
    Id = ?CHILD_ID(AccountId, AgentId),
    case supervisor:terminate_child(?SERVER, Id) of
        'ok' ->
            lager:info("restarting agent ~s(~s)", [AgentId, AccountId]),
            supervisor:restart_child(?SERVER, Id);
        E ->
            lager:info("no supervisor for agent ~s(~s) to restart", [AgentId, AccountId]),
            E
    end.

-spec find_acct_supervisors(kz_term:ne_binary()) -> kz_term:pids().
find_acct_supervisors(AccountId) -> [S || S <- workers(), is_agent_in_acct(S, AccountId)].

-spec is_agent_in_acct(pid(), kz_term:ne_binary()) -> boolean().
is_agent_in_acct(Super, AccountId) ->
    case catch acdc_agent_listener:config(acdc_agent_sup:listener(Super)) of
        {'EXIT', _} -> 'false';
        {AccountId, _, _} -> 'true';
        _ -> 'false'
    end.

-spec agents_running() -> [{pid(), acdc_agent_listener:config()}].
agents_running() ->
    [{W, catch acdc_agent_listener:config(acdc_agent_sup:listener(W))} || W <- workers()].

-spec find_agent_supervisor(kz_term:api_binary(), kz_term:api_binary()) -> kz_term:api_pid().
find_agent_supervisor(AccountId, AgentId) -> find_agent_supervisor(AccountId, AgentId, workers()).

-spec find_agent_supervisor(kz_term:api_binary(), kz_term:api_binary(), kz_term:pids()) ->
    kz_term:api_pid().
find_agent_supervisor(AccountId, AgentId, _) when
    AccountId =:= 'undefined';
    AgentId =:= 'undefined'
->
    lager:debug("failed to get good data: ~s ~s", [AccountId, AgentId]),
    'undefined';
find_agent_supervisor(AccountId, AgentId, []) ->
    lager:debug("supervisor for agent ~s(~s) not found", [AgentId, AccountId]),
    'undefined';
find_agent_supervisor(AccountId, AgentId, [Super | Rest]) ->
    case catch acdc_agent_listener:config(acdc_agent_sup:listener(Super)) of
        {'EXIT', _E} -> find_agent_supervisor(AccountId, AgentId, Rest);
        {AccountId, AgentId, _} -> Super;
        _E -> find_agent_supervisor(AccountId, AgentId, Rest)
    end.

%%%=============================================================================
%%% Supervisor callbacks
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Whenever a supervisor is started using `supervisor:start_link/[2,3]',
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%% @end
%%------------------------------------------------------------------------------
-spec init(any()) -> kz_types:sup_init_ret().
init([]) ->
    RestartStrategy = 'one_for_one',
    MaxRestarts = 1,
    MaxSecondsBetweenRestarts = 1,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    {'ok', {SupFlags, ?INITIAL_CHILDREN}}.

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc Start a new agent supervisor child. There can only be one child per
%% account ID/agent ID pair.
%% @end
%%------------------------------------------------------------------------------
-spec start_agent(kz_term:ne_binary(), kz_term:ne_binary(), kz_json:object()) ->
    kz_types:sup_startchild_ret().
start_agent(AccountId, AgentId, AgentJObj) ->
    start_agent(AccountId, AgentId, AgentJObj, []).

-spec start_agent(kz_term:ne_binary(), kz_term:ne_binary(), kz_json:object(), [any()]) ->
    kz_types:sup_startchild_ret().
start_agent(AccountId, AgentId, AgentJObj, ExtraArgs) ->
    Id = ?CHILD_ID(AccountId, AgentId),
    case
        supervisor:start_child(?SERVER, ?CHILD(Id, [AccountId, AgentId, AgentJObj] ++ ExtraArgs))
    of
        {'error', 'already_present'} = E ->
            lager:debug("agent ~s(~s) already present", [AgentId, AccountId]),
            E;
        {'error', {'already_started', Pid}} = E ->
            lager:debug("agent ~s(~s) already started here: ~p", [AgentId, AccountId, Pid]),
            E;
        StartChildRet ->
            StartChildRet
    end.
