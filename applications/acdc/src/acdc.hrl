-ifndef(ACDC_HRL).
-include_lib("kazoo_stdlib/include/kz_types.hrl").
-include_lib("kazoo_stdlib/include/kz_log.hrl").
-include_lib("kazoo_stdlib/include/kz_databases.hrl").
-include_lib("kazoo/include/kz_api_literals.hrl").
-include("acdc_config.hrl").

-define(APP, acdc).
-define(APP_NAME, (atom_to_binary(?APP, utf8))).
-define(APP_VERSION, <<"4.0.0">>).
-define(CONFIG_CAT, ?APP_NAME).

-define(CACHE_NAME, 'acdc_cache').

-define(ABANDON_TIMEOUT, <<"member_timeout">>).
-define(ABANDON_EXIT, <<"member_exit">>).
-define(ABANDON_HANGUP, <<"member_hangup">>).
-define(ABANDON_EMPTY, <<"member_exit_empty">>).
-define(ABANDON_INTERNAL_ERROR, <<"INTERNAL ERROR">>).

-define(PRESENCE_GREEN, <<"terminated">>).
-define(PRESENCE_RED_FLASH, <<"early">>).
-define(PRESENCE_RED_SOLID, <<"confirmed">>).

-define(ENDPOINT_UPDATE_REG(AccountId, EPId), {'p', 'l', {'endpoint_update', AccountId, EPId}}).
-define(ENDPOINT_CREATED(EP), {'endpoint_created', EP}).
-define(ENDPOINT_EDITED(EP), {'endpoint_edited', EP}).
-define(ENDPOINT_DELETED(EP), {'endpoint_deleted', EP}).

-define(OWNER_UPDATE_REG(AccountId, OwnerId), {'p', 'l', {'owner_update', AccountId, OwnerId}}).

-define(NEW_CHANNEL_REG(AccountId, User), {'p', 'l', {'new_channel', AccountId, User}}).
-define(NEW_CHANNEL_TO(CallId, Number, Name), {{'call_to', Number, Name}, CallId}).
-define(NEW_CHANNEL_FROM(CallId, Number, Name, MemberCallId), {
    {'call_from', Number, Name}, CallId, MemberCallId
}).

-define(DESTROYED_CHANNEL_REG(AccountId, User), {'p', 'l', {'destroyed_channel', AccountId, User}}).
-define(DESTROYED_CHANNEL(CallId, HangupCause), {'call_down', CallId, HangupCause}).

-type deliveries() :: [gen_listener:basic_deliver()].

-type announcements_pids() :: #{kz_term:ne_binary() => pid()}.

-type fsm_state_name() ::
    'wait'
    | 'sync'
    | 'ready'
    | 'ringing'
    | 'ringing_callback'
    | 'awaiting_callback'
    | 'answered'
    | 'wrapup'
    | 'paused'
    | 'outbound'.

-type agent_priority() :: -128..128.

%% Check for cleanup every 5 minutes
-define(CLEANUP_PERIOD, kapps_config:get_integer(?CONFIG_CAT, <<"cleanup_period_ms">>, 360000)).

-define(CLEANUP_WINDOW, ?ACDC_CLEANUP_WINDOW).

%% Archive every 60 seconds
-define(ARCHIVE_PERIOD, kapps_config:get_integer(?CONFIG_CAT, <<"archive_period_ms">>, 60000)).

-define(ARCHIVE_WINDOW, ?ACDC_ARCHIVE_WINDOW).

-define(RESOURCE_TYPES_HANDLED, [<<"audio">>, <<"video">>]).

-define(PRINT(Str), ?PRINT(Str, [])).
-define(PRINT(Fmt, Args), begin
    lager:info(Fmt, Args),
    io:format(Fmt ++ "\n", Args)
end).

-define(AGENT_INFO_FIELDS,
    kapps_config:get(
        ?CONFIG_CAT,
        <<"agent_info_fields">>,
        [<<"presence_id">>, <<"first_name">>, <<"last_name">>, <<"username">>, <<"email">>]
    )
).

-define(CALL_INFO_FIELDS,
    kapps_config:get(
        ?CONFIG_CAT,
        <<"call_info_fields">>,
        [
            <<"call_id">>,
            <<"queue_id">>,
            <<"entered_timestamp">>,
            <<"entered_position">>,
            <<"caller_id_name">>,
            <<"caller_id_number">>,
            <<"required_skills">>
        ]
    )
).
-define(ACDC_HRL, 'true').
-endif.
