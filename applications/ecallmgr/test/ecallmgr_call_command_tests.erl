%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2021, 2600Hz
%%% @doc Execute call commands
%%% @author James Aimonetti
%%% @author Karl Anderson
%%% @end
%%%-----------------------------------------------------------------------------
-module(ecallmgr_call_command_tests).

-spec test() -> 'ok'.

-include_lib("eunit/include/eunit.hrl").

-spec all_conference_flags_test() -> any().
all_conference_flags_test() ->
    JObj = kz_json:from_list([
        {<<"Mute">>, 'true'},
        {<<"Deaf">>, 'true'},
        {<<"Moderator">>, 'true'}
    ]),
    ?assertEqual(
        <<"+flags{mute,moderator,deaf}">>, ecallmgr_call_command:get_conference_flags(JObj)
    ).

-spec two_conference_flags_test() -> any().
two_conference_flags_test() ->
    JObj = kz_json:from_list([
        {<<"Mute">>, 'true'},
        {<<"Moderator">>, 'true'}
    ]),
    ?assertEqual(<<"+flags{mute,moderator}">>, ecallmgr_call_command:get_conference_flags(JObj)).

-spec one_conference_flag_test() -> any().
one_conference_flag_test() ->
    JObj = kz_json:from_list([{<<"Mute">>, 'true'}]),
    ?assertEqual(<<"+flags{mute}">>, ecallmgr_call_command:get_conference_flags(JObj)).

-spec no_conference_flags_test() -> any().
no_conference_flags_test() ->
    JObj = kz_json:new(),
    ?assertEqual(<<>>, ecallmgr_call_command:get_conference_flags(JObj)).

-spec tones_test() -> any().
tones_test() ->
    Tones =
        [
            kz_json:from_list([
                {<<"Frequencies">>, [1000, <<"2000">>]},
                {<<"Duration-ON">>, 30000},
                {<<"Duration-OFF">>, <<"1000">>}
            ]),
            kz_json:from_list([
                {<<"Frequencies">>, [1000, <<"2000">>, 3000, <<"4000">>]},
                {<<"Duration-ON">>, <<"30000">>},
                {<<"Duration-OFF">>, 1000},
                {<<"Volume">>, 25},
                {<<"Repeat">>, 3}
            ])
        ],
    ?assertEqual(
        {<<"playback">>,
            "tone_stream://%(30000,1000,1000,2000);v=25;l=3;%(30000,1000,1000,2000,3000,4000)"},
        ecallmgr_call_command:tones_app(Tones)
    ).
