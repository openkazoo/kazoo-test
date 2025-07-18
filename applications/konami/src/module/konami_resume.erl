%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2022, 2600Hz
%%% @doc Reconnect the two legs of the call, if possible
%%% Data = {
%%% }
%%%
%%% @author James Aimonetti
%%% @end
%%%-----------------------------------------------------------------------------
-module(konami_resume).

-export([
    handle/2,
    number_builder/1
]).

-include("konami.hrl").

-spec handle(kz_json:object(), kapps_call:call()) ->
    {'continue', kapps_call:call()}.
handle(_Data, Call) ->
    lager:debug("reconnecting ~s and ~s", [
        kapps_call:call_id(Call),
        kapps_call:other_leg_call_id(Call)
    ]),
    kapps_call_command:pickup(kapps_call:other_leg_call_id(Call), <<"now">>, Call),
    {'continue', Call}.

-spec number_builder(kz_json:object()) -> kz_json:object().
number_builder(DefaultJObj) ->
    io:format("Let's configure a 'resume' metaflow~n", []),

    {'ok', [Number]} = io:fread("What number should invoke 'resume'? ", "~d"),

    K = [<<"numbers">>, kz_term:to_binary(Number)],

    case number_builder_check(kz_json:get_value(K, DefaultJObj)) of
        'undefined' -> kz_json:delete_key(K, DefaultJObj);
        NumberJObj -> kz_json:set_value(K, NumberJObj, DefaultJObj)
    end.

-spec number_builder_check(kz_term:api_object()) -> kz_term:api_object().
number_builder_check('undefined') ->
    metaflow_jobj(kz_json:new());
number_builder_check(NumberJObj) ->
    io:format("  Existing config for this number: ~s~n", [kz_json:encode(NumberJObj)]),
    io:format("  e. Edit Number~n", []),
    io:format("  d. Delete Number~n", []),
    {'ok', [Option]} = io:fread("What would you like to do: ", "~s"),
    number_builder_check_option(NumberJObj, Option).

-spec number_builder_check_option(kz_json:object(), string()) -> kz_term:api_object().
number_builder_check_option(NumberJObj, "e") ->
    metaflow_jobj(NumberJObj);
number_builder_check_option(_NumberJObj, "d") ->
    'undefined';
number_builder_check_option(NumberJObj, _Option) ->
    io:format("invalid selection~n", []),
    number_builder_check(NumberJObj).

-spec metaflow_jobj(kz_json:object()) -> kz_json:object().
metaflow_jobj(NumberJObj) ->
    kz_json:set_values(
        [
            {<<"module">>, <<"resume">>},
            {<<"data">>, kz_json:new()}
        ],
        NumberJObj
    ).
