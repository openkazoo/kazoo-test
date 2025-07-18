%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2017-2022, 2600Hz
%%% @doc
%%% @author Max Lay
%%% @end
%%%-----------------------------------------------------------------------------
-module(teletype_fax_outbound_smtp_error_to_email).

-export([
    init/0,
    handle_req/1
]).

-include("teletype.hrl").

-define(TEMPLATE_ID, <<"fax_outbound_smtp_error_to_email">>).

-define(TEMPLATE_MACROS,
    kz_json:from_list(
        [
            ?MACRO_VALUE(
                <<"date.utc">>,
                <<"date_called_utc">>,
                <<"Date (UTC)">>,
                <<"When did change happen (UTC)">>
            ),
            ?MACRO_VALUE(
                <<"date.local">>,
                <<"date_called_local">>,
                <<"Date (Local)">>,
                <<"When did change happen (Local time)">>
            ),
            ?MACRO_VALUE(
                <<"date.timezone">>, <<"date_called_timezone">>, <<"Timezone">>, <<"Timezone">>
            ),
            ?MACRO_VALUE(
                <<"date.timestamp">>, <<"date_called_timestamp">>, <<"Timestamp">>, <<"Timestamp">>
            ),
            ?MACRO_VALUE(
                <<"fax.from">>, <<"fax_from">>, <<"Fax From Email">>, <<"Fax From Email">>
            ),
            ?MACRO_VALUE(<<"fax.number">>, <<"fax_number">>, <<"Fax Number">>, <<"Fax Number">>),
            ?MACRO_VALUE(
                <<"fax.original_number">>,
                <<"fax_original_number">>,
                <<"Fax Original Number">>,
                <<"Originally dialed number">>
            ),
            ?MACRO_VALUE(<<"fax.to">>, <<"fax_to">>, <<" Fax To">>, <<"Destination Fax Number">>),
            ?MACRO_VALUE(<<"fax.errors">>, <<"fax_errors">>, <<"Fax Errors">>, <<"Fax Errors">>),
            ?MACRO_VALUE(<<"fax.error">>, <<"fax_error">>, <<"Error Reason">>, <<"Error Reason">>),
            ?MACRO_VALUE(<<"faxbox.id">>, <<"faxbox_id">>, <<"FaxBox ID">>, <<"FaxBox ID">>),
            ?MACRO_VALUE(<<"faxbox.name">>, <<"faxbox_name">>, <<"FaxBox Name">>, <<"FaxBox Name">>)
        ] ++
            ?FAX_OUTBOUND_MACROS ++
            ?USER_MACROS ++
            ?COMMON_TEMPLATE_MACROS
    )
).

-define(TEMPLATE_SUBJECT, <<"Error Sending Fax">>).
-define(TEMPLATE_CATEGORY, <<"fax">>).
-define(TEMPLATE_NAME, <<"Unable Processing Email-To-Fax">>).

-define(TEMPLATE_TO, ?CONFIGURED_EMAILS(?EMAIL_ORIGINAL)).
-define(TEMPLATE_FROM, teletype_util:default_from_address()).
-define(TEMPLATE_CC, ?CONFIGURED_EMAILS(?EMAIL_SPECIFIED, [])).
-define(TEMPLATE_BCC, ?CONFIGURED_EMAILS(?EMAIL_SPECIFIED, [])).
-define(TEMPLATE_REPLY_TO, teletype_util:default_reply_to()).

-spec init() -> 'ok'.
init() ->
    kz_util:put_callid(?MODULE),
    teletype_templates:init(?TEMPLATE_ID, [
        {'macros', ?TEMPLATE_MACROS},
        {'subject', ?TEMPLATE_SUBJECT},
        {'category', ?TEMPLATE_CATEGORY},
        {'friendly_name', ?TEMPLATE_NAME},
        {'to', ?TEMPLATE_TO},
        {'from', ?TEMPLATE_FROM},
        {'cc', ?TEMPLATE_CC},
        {'bcc', ?TEMPLATE_BCC},
        {'reply_to', ?TEMPLATE_REPLY_TO}
    ]),
    teletype_bindings:bind(<<"outbound_smtp_fax_error">>, ?MODULE, 'handle_req').

-spec handle_req(kz_json:object()) -> template_response().
handle_req(JObj) ->
    handle_req(JObj, kapi_notifications:fax_outbound_smtp_error_v(JObj)).

-spec handle_req(kz_json:object(), boolean()) -> template_response().
handle_req(_, 'false') ->
    lager:debug("invalid data for ~s", [?TEMPLATE_ID]),
    teletype_util:notification_failed(?TEMPLATE_ID, <<"validation_failed">>);
handle_req(JObj, 'true') ->
    lager:debug("valid data for ~s, processing...", [?TEMPLATE_ID]),

    %% Gather data for template
    DataJObj = kz_json:normalize(JObj),
    AccountId = kz_json:get_value(<<"account_id">>, DataJObj),

    case teletype_util:is_notice_enabled(AccountId, JObj, ?TEMPLATE_ID) of
        'false' ->
            teletype_util:notification_disabled(DataJObj, ?TEMPLATE_ID);
        'true' ->
            teletype_util:send_update(DataJObj, <<"pending">>),
            process_req(DataJObj)
    end.

-spec process_req(kz_json:object()) -> template_response().
process_req(DataJObj) ->
    Macros = build_macros(DataJObj),

    RenderedTemplates = teletype_templates:render(?TEMPLATE_ID, Macros, DataJObj),

    {'ok', TemplateMetaJObj} = teletype_templates:fetch_notification(
        ?TEMPLATE_ID, kapi_notifications:account_id(DataJObj)
    ),

    Subject = teletype_util:render_subject(
        kz_json:find(<<"subject">>, [DataJObj, TemplateMetaJObj], ?TEMPLATE_SUBJECT),
        Macros
    ),

    EmailsJObj =
        case teletype_util:is_preview(DataJObj) of
            'true' ->
                DataJObj;
            'false' ->
                kz_json:set_value(
                    <<"to">>,
                    [kz_json:get_ne_binary_value(<<"fax_from_email">>, DataJObj)],
                    DataJObj
                )
        end,

    Emails = teletype_util:find_addresses(EmailsJObj, TemplateMetaJObj, ?TEMPLATE_ID),

    case teletype_util:send_email(Emails, Subject, RenderedTemplates) of
        'ok' -> teletype_util:notification_completed(?TEMPLATE_ID);
        {'error', Reason} -> teletype_util:notification_failed(?TEMPLATE_ID, Reason)
    end.

-spec build_macros(kz_json:object()) -> kz_term:proplist().
build_macros(DataJObj) ->
    [Error | _] = Errors = kz_json:get_list_value(<<"errors">>, DataJObj),

    [
        {<<"account">>, teletype_util:account_params(DataJObj)},
        %% backward compatibility
        {<<"account_id">>, kz_json:get_ne_binary_value(<<"account_id">>, DataJObj)},
        {<<"date">>,
            teletype_util:fix_timestamp(
                kz_json:get_integer_value(<<"timestamp">>, DataJObj), DataJObj
            )},
        %% backward compatibility
        {<<"errors">>, Errors},
        %% backward compatibility
        {<<"error">>, Error},
        %% backward compatibility
        {<<"from_email">>, kz_json:get_ne_binary_value(<<"fax_from_email">>, DataJObj)},
        {<<"fax">>, get_fax_data(DataJObj)},
        {<<"faxbox">>, get_faxbox_data(DataJObj)},
        {<<"system">>, teletype_util:system_params()},
        %% backward compatibility
        {<<"to_email">>, kz_json:get_ne_binary_value(<<"fax_to_email">>, DataJObj)},
        {<<"user">>, get_user_data(DataJObj)}
    ].

-spec get_fax_data(kz_json:object()) -> kz_term:proplist() | 'undefined'.
get_fax_data(DataJObj) ->
    [Error | _] = Errors = kz_json:get_list_value(<<"errors">>, DataJObj),
    props:filter_empty(
        [
            {<<"from">>, kz_json:get_ne_binary_value(<<"fax_from_email">>, DataJObj)},
            {<<"number">>, kz_json:get_ne_binary_value(<<"number">>, DataJObj)},
            {<<"original_number">>, kz_json:get_ne_binary_value(<<"original_number">>, DataJObj)},
            {<<"to">>, kz_json:get_ne_binary_value(<<"fax_to_email">>, DataJObj)},
            {<<"errors">>, Errors},
            {<<"error">>, Error}
        ]
    ).

-spec get_faxbox_data(kz_json:object()) -> kz_term:proplist() | 'undefined'.
get_faxbox_data(DataJObj) ->
    props:filter_empty(
        [
            {<<"id">>, kz_json:get_ne_binary_value(<<"faxbox_id">>, DataJObj)},
            {<<"name">>, kz_json:get_ne_binary_value(<<"faxbox_name">>, DataJObj)}
        ]
    ).

-spec get_user_data(kz_json:object()) -> kz_term:proplist().
get_user_data(DataJObj) ->
    OwnerId = kz_json:get_ne_binary_value(<<"owner_id">>, DataJObj),
    case teletype_util:open_doc(<<"user">>, OwnerId, DataJObj) of
        {'ok', JObj} -> teletype_util:user_params(JObj);
        {'error', _Reason} -> []
    end.
