-ifndef(ACDC_STATS_HRL).

-define(ARCHIVE_MSG, 'time_to_archive').
-define(CLEANUP_MSG, 'time_to_cleanup').

-define(VALID_STATUSES, [<<"waiting">>, <<"handled">>, <<"abandoned">>, <<"processed">>]).
-define(VALID_AGENT_STATUSES, [<<"handled">>, <<"processed">>, <<"missed">>]).

-define(STATS_QUERY_LIMITS_ENABLED,
    kapps_config:get_is_true(?CONFIG_CAT, <<"stats_query_limits_enabled">>, 'true')
).
-define(MAX_RESULT_SET, kapps_config:get_integer(?CONFIG_CAT, <<"max_result_set">>, 25)).

%% Wiggle room for queries in case the AMQP message is delayed a little
-define(QUERY_WINDOW_WIGGLE_ROOM_S, 5).

-record(agent_miss, {
    agent_id :: kz_term:api_binary(),
    miss_reason :: kz_term:api_binary(),
    miss_timestamp = kz_time:current_tstamp() :: pos_integer()
}).
-type agent_miss() :: #agent_miss{}.
-type agent_misses() :: [agent_miss()].

%% call_id::queue_id
-record(call_stat, {
    id :: kz_term:api_binary() | '_',
    call_id :: kz_term:api_binary() | '_',
    account_id :: kz_term:api_binary() | '$1' | '_',
    queue_id :: kz_term:api_binary() | '$2' | '_',

    % the handling agent
    agent_id :: kz_term:api_binary() | '$3' | '_',

    entered_timestamp = kz_time:current_tstamp() :: pos_integer() | '$1' | '$5' | '_',
    abandoned_timestamp :: kz_term:api_integer() | '$2' | '_',
    handled_timestamp :: kz_term:api_integer() | '$3' | '_',
    processed_timestamp :: kz_term:api_integer() | '_',

    hung_up_by :: kz_term:api_binary() | '_',

    entered_position :: kz_term:api_integer() | '_',
    exited_position :: kz_term:api_integer() | '_',

    abandoned_reason :: kz_term:api_binary() | '_',
    is_callback = 'false' :: boolean() | '_',
    misses = [] :: agent_misses() | '_',

    status :: kz_term:api_binary() | '$1' | '$2' | '$4' | '_',
    caller_id_name :: kz_term:api_binary() | '_',
    caller_id_number :: kz_term:api_binary() | '_',
    caller_priority :: kz_term:api_integer() | '_',
    required_skills = [] :: kz_term:ne_binaries() | '_',
    is_archived = 'false' :: boolean() | '$2' | '$3' | '_'
}).
-type call_stat() :: #call_stat{}.

-record(call_summary_stat, {
    id :: kz_term:api_binary() | '_',
    account_id :: kz_term:api_binary() | '$1',
    queue_id :: kz_term:api_binary() | '$2' | '_',
    call_id :: kz_term:api_binary() | '_',
    status :: kz_term:api_binary() | '$3' | '_',
    entered_position :: kz_term:api_integer() | '_',
    wait_time :: kz_term:api_integer() | '_',
    talk_time :: kz_term:api_integer() | '_',
    timestamp :: kz_term:api_integer() | '_',
    is_archived = 'false' :: boolean() | '$1' | '$2' | '_'
}).
-type call_summary_stat() :: #call_summary_stat{}.

-record(agent_call_stat, {
    id :: kz_term:api_binary() | '_',
    account_id :: kz_term:api_binary() | '$1',
    queue_id :: kz_term:api_binary() | '_',
    agent_id :: kz_term:api_binary() | '_',
    call_id :: kz_term:api_binary() | '_',
    status :: kz_term:api_binary() | '_',
    talk_time :: kz_term:api_integer() | '_',
    timestamp :: kz_term:api_integer() | '_'
}).
-type agent_call_stat() :: #agent_call_stat{}.

-define(STATUS_STATUSES, [
    <<"logged_in">>,
    <<"logged_out">>,
    <<"ready">>,
    <<"connecting">>,
    <<"connected">>,
    <<"wrapup">>,
    <<"paused">>,
    <<"outbound">>,
    <<"inbound">>
]).
-record(status_stat, {
    id :: kz_term:api_binary() | '_',
    agent_id :: kz_term:api_binary() | '$2' | '_',
    account_id :: kz_term:api_binary() | '$1' | '_',
    status :: kz_term:api_binary() | '$4' | '_',
    timestamp :: kz_term:api_pos_integer() | '$1' | '$3' | '$5' | '_',
    wait_time :: kz_term:api_integer() | '_',
    pause_time :: kz_term:api_integer() | '_',
    pause_alias :: kz_term:api_binary() | '_',
    callid :: kz_term:api_binary() | '_',
    caller_id_name :: kz_term:api_binary() | '_',
    caller_id_number :: kz_term:api_binary() | '_',
    is_archived = 'false' :: boolean() | '$1' | '$2' | '_'
}).
-type status_stat() :: #status_stat{}.

-define(ACDC_STATS_HRL, 'true').
-endif.
