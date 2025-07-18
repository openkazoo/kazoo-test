%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc
%%% @author Karl Anderson
%%% @author James Aimonetti
%%% @end
%%%-----------------------------------------------------------------------------
-module(cf_util_tests).

-spec test() -> ok.
-include_lib("eunit/include/eunit.hrl").

-spec alpha_to_dialpad_test_() -> any().
alpha_to_dialpad_test_() ->
    [
        ?_assertEqual(<<"222">>, cf_util:alpha_to_dialpad(<<"abc">>)),
        ?_assertEqual(<<"23456789">>, cf_util:alpha_to_dialpad(<<"behknqux">>)),
        ?_assertEqual(<<"23456789">>, cf_util:alpha_to_dialpad(<<"BeHkNqUx">>)),
        ?_assertEqual(<<"23456789">>, cf_util:alpha_to_dialpad(<<"1BeH@k(N$q-u+x=">>))
    ].

-spec alpha_to_dialpad_nonascii_test_() -> any().
alpha_to_dialpad_nonascii_test_() ->
    [
        ?_assertEqual(<<"8378">>, cf_util:alpha_to_dialpad(<<"teÕst">>)),
        ?_assertEqual(<<"8378896">>, cf_util:alpha_to_dialpad(<<"testÕÀ«©§two">>)),
        ?_assertEqual(<<"">>, cf_util:alpha_to_dialpad(<<"Ì¸ûî">>))
    ].
