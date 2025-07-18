%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2021, 2600Hz
%%% @doc
%%% @author Karl Anderson
%%% @end
%%%-----------------------------------------------------------------------------
-module(cf_temporal_route_tests).

-include("callflow.hrl").
-include("module/cf_temporal_route.hrl").

-ifdef(PROPER).
-include_lib("proper/include/proper.hrl").
-endif.

-spec test() -> ok.
-include_lib("eunit/include/eunit.hrl").

-define(SORTED_WDAYS, [
    <<"monday">>,
    <<"tuesday">>,
    <<"wednesday">>,
    <<"thursday">>,
    <<"friday">>,
    <<"saturday">>,
    <<"sunday">>
]).

-define(JAN, 1).
-define(FEB, 2).
-define(MAR, 3).
-define(APR, 4).
-define(MAY, 5).
-define(JUN, 6).
-define(JUL, 7).
-define(AUG, 8).
-define(SEP, 9).
-define(OCT, 10).
-define(NOV, 11).
-define(DEC, 12).

-ifdef(PROPER).
proper_test_() ->
    {"Runs " ?MODULE_STRING " PropEr tests", [
        {atom_to_list(F), fun() ->
            ?assert(
                proper:quickcheck(?MODULE:F(), [
                    {'to_file', 'user'},
                    {'numtests', 500}
                ])
            )
        end}
     || {F, 0} <- ?MODULE:module_info('exports'),
        F > 'prop_',
        F < 'prop`'
    ]}.
-endif.

-spec sort_wdays_test_() -> any().
sort_wdays_test_() ->
    Shuffled = kz_term:shuffle_list(?SORTED_WDAYS),
    ?_assertEqual(?SORTED_WDAYS, cf_temporal_route:sort_wdays(Shuffled)).

-spec daily_recurrence_test_() -> any().
daily_recurrence_test_() ->
    %% basic increment
    [
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2011, ?JAN, 1}}, {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2011, ?JUN, 1}}, {2011, ?JUN, 1}
            )
        ),
        %%  increment over month boundary
        ?_assertEqual(
            {2011, ?FEB, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2011, ?JAN, 1}}, {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2011, ?JUN, 1}}, {2011, ?JUN, 30}
            )
        ),
        %% increment over year boundary
        ?_assertEqual(
            {2011, ?JAN, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2010, ?JAN, 1}}, {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2010, ?JUN, 1}}, {2010, ?DEC, 31}
            )
        ),
        %% leap year (into)
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2008, ?JAN, 1}}, {2008, ?FEB, 28}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2008, ?JAN, 1}}, {2008, ?FEB, 28}
            )
        ),
        %% leap year (over)
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2008, ?JAN, 1}}, {2008, ?FEB, 29}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2008, ?JAN, 1}}, {2008, ?FEB, 29}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2008, ?JAN, 1}}, {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2009, ?JAN, 1}}, {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, start_date = {2010, ?JAN, 1}}, {2011, ?JAN, 1}
            )
        ),
        %% even step (small)
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 29}
            )
        ),
        %% odd step (small)
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 7, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 7, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 7, start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 7, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 7, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 29}
            )
        ),
        %% even step (large)
        ?_assertEqual(
            {2011, ?FEB, 18},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 48, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 48, start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 19},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 48, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 1}
            )
        ),
        %% odd step (large)
        ?_assertEqual(
            {2011, ?MAR, 27},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 85, start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 85, start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?AUG, 25},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 85, start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 1}
            )
        ),
        %% current date on (interval)
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 5}
            )
        ),
        %% current date after (interval)
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 6}
            )
        ),
        %% shift start date
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?FEB, 1}},
                {2011, ?FEB, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {2011, ?FEB, 2}},
                {2011, ?FEB, 3}
            )
        ),
        %% long span
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {1983, ?APR, 11}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"daily">>, interval = 4, start_date = {1983, ?APR, 11}},
                {2011, ?APR, 11}
            )
        )
    ].

-spec weekly_recurrence_test_() -> any().
weekly_recurrence_test_() ->
    %% basic increment
    [
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"wensday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),

        %%  increment over month boundary
        ?_assertEqual(
            {2011, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 26}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"wensday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 27}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 30}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 31}
            )
        ),

        %%  increment over year boundary
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"wensday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 30}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2010, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 26}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 27}
            )
        ),

        %%  leap year (into)
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2008, ?JAN, 1}},
                {2008, ?FEB, 28}
            )
        ),

        %%  leap year (over)
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2008, ?JAN, 1}},
                {2008, ?FEB, 28}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2008, ?JAN, 1}},
                {2008, ?FEB, 29}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2008, ?JAN, 1}},
                {2008, ?MAR, 1}
            )
        ),

        %% current date on (simple)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"wensday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 6}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 7}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),

        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2008, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2009, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2010, ?JAN, 2}},
                {2011, ?JAN, 1}
            )
        ),

        %% multiple DOWs
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wensday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>,
                        <<"sunday">>
                    ],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wensday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>
                    ],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [
                        <<"tuesday">>, <<"wensday">>, <<"thursday">>, <<"friday">>, <<"saturday">>
                    ],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [<<"wensday">>, <<"thursday">>, <<"friday">>, <<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [<<"thursday">>, <<"friday">>, <<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [<<"friday">>, <<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),

        %% last DOW of an active week
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    wdays = [
                        <<"monday">>, <<"tuesday">>, <<"wensday">>, <<"thursday">>, <<"friday">>
                    ],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 8}
            )
        ),

        %% even step (small)
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?DEC, 25}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),

        %%     SIDE NOTE: No event engines seem to agree on this case, so I am doing what makes sense to me
        %%                and google calendar agrees (thunderbird and outlook be damned!)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% odd step (small)
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?DEC, 25}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),

        %%     SIDE NOTE: No event engines seem to agree on this case, so I am doing what makes sense to me
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% even step (large)
        ?_assertEqual(
            {2011, ?JUN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?DEC, 25}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),

        %%     SIDE NOTE: No event engines seem to agree on this case, so I am doing what makes sense to me
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 24,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% odd step (large)
        ?_assertEqual(
            {2011, ?SEP, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 37,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),

        %%     SIDE NOTE: No event engines seem to agree on this case, so I am doing what makes sense to me
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 36,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 36,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 36,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% multiple DOWs with step (currently on start)
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 6}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 7}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 9}
            )
        ),

        %% multiple DOWs with step (start in past)
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 10}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 11}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 12}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 13}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 15}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 16}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 17}
            )
        ),

        %% multiple DOWs over month boundary
        ?_assertEqual(
            {2011, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 29}
            )
        ),

        %% multiple DOWs over year boundary
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 2,
                    wdays = [<<"monday">>, <<"wensday">>, <<"friday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),

        %% current date on (interval)
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?DEC, 25}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 6}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 7}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 3,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% shift start date
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?FEB, 8}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?MAR, 15}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?APR, 22}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?MAY, 29}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 5,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUL, 8}
                },
                {2011, ?JAN, 1}
            )
        ),

        %% long span
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 4,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 4,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?APR, 11}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wednesday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>,
                        <<"sunday">>
                    ],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 9}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"tuesday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 10}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"wednesday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 11}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"thursday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 12}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"friday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 13}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"saturday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"sunday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 15}
            )
        ),

        %% multiple days long span
        ?_assertEqual(
            {2018, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wednesday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>,
                        <<"sunday">>
                    ],
                    start_date = {1983, ?APR, 11}
                },
                {2018, ?JAN, 15}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wednesday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>,
                        <<"sunday">>
                    ],
                    start_date = {2018, ?JAN, 1}
                },
                {2018, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [
                        <<"monday">>,
                        <<"tuesday">>,
                        <<"wednesday">>,
                        <<"thursday">>,
                        <<"friday">>,
                        <<"saturday">>,
                        <<"sunday">>
                    ],
                    start_date = {2018, ?JAN, 1}
                },
                {2018, ?JAN, 15}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"monday">>],
                    start_date = {2018, ?JAN, 1}
                },
                {2018, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"monday">>],
                    start_date = {2018, ?JAN, 2}
                },
                {2018, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2018, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>,
                    interval = 1,
                    wdays = [<<"tuesday">>],
                    start_date = {2018, ?JAN, 2}
                },
                {2018, ?JAN, 15}
            )
        ),

        %% increment over the week boundaries with shifting DOTW
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"monday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),

        %% increment over week boundary with incrementing start date first rule is tuesday
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"tuesday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),

        %% increment over Wednesday first day
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 2}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 3}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 4}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 5}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 6}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 7}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"weekly">>, wdays = [<<"wednesday">>], start_date = {2011, ?JAN, 8}
                },
                {2011, ?JAN, 3}
            )
        ),

        %% increment over Thursday first day
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"thursday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),

        %% increment over Friday first day
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"friday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),

        %% increment over Saturday first day
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"saturday">>], start_date = {2011, ?JAN, 9}},
                {2011, ?JAN, 3}
            )
        ),

        %% increment over Sunday first day
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 2}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 3}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 4}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 5}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 6}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 7}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 8}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 9}},
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"weekly">>, wdays = [<<"sunday">>], start_date = {2011, ?JAN, 10}},
                {2011, ?JAN, 3}
            )
        )
    ].

-spec monthly_every_recurrence_test_() -> [any()].
monthly_every_recurrence_test_() ->
    %% basic increment (also crosses month boundary)
    [
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 10}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 17}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 24}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 11}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 18}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 12}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 19}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 26}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 6}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 13}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 20}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 27}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 7}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 21}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 15}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 22}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 9}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 16}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 23}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 30}
            )
        ),
        %% increment over year boundary
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 27}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 30}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 26}
            )
        ),
        %% leap year (into)
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 28}
            )
        ),
        %% leap year (over)
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 28}
            )
        ),
        %% current date on (simple)
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 10}
                },
                {2011, ?JAN, 11}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 17}
                },
                {2011, ?JAN, 19}
            )
        ),
        %% current date after (simple)
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 10}
                },
                {2011, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 17}
                },
                {2011, ?JAN, 21}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?FEB, 1}
                },
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?MAR, 1}
                },
                {2011, ?JAN, 12}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?APR, 1}
                },
                {2011, ?JAN, 20}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?MAY, 1}
                },
                {2011, ?JAN, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        %% even step (small)
        ?_assertEqual(
            {2011, ?MAR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 26}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 27}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 30}
            )
        ),
        %% odd step (small)
        ?_assertEqual(
            {2011, ?SEP, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 27}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 28}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 29}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 30}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 24}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 26}
            )
        ),
        %% current date on (interval)
        ?_assertEqual(
            {2011, ?MAY, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 10}
                },
                {2011, ?JAN, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 17}
                },
                {2011, ?JAN, 26}
            )
        ),
        %% current date after (interval)
        ?_assertEqual(
            {2011, ?MAY, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?FEB, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 10}
                },
                {2011, ?MAR, 14}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 4,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 17}
                },
                {2011, ?MAR, 21}
            )
        ),
        %% shift start date
        ?_assertEqual(
            {2011, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?FEB, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?MAR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?APR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?MAY, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% long span
        ?_assertEqual(
            {2011, ?MAR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"every">>,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        )
    ].

-spec monthly_last_recurrence_test_() -> any().
monthly_last_recurrence_test_() ->
    %% basic increment
    [
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic increment (mid year)
        ?_assertEqual(
            {2011, ?JUN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        %% increment over month boundary
        ?_assertEqual(
            {2011, ?FEB, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% increment over year boundary
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JAN, 1}
                },
                {2010, ?DEC, 31}
            )
        ),
        %% leap year
        ?_assertEqual(
            {2008, ?FEB, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?DEC, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?OCT, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?NOV, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?SEP, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?AUG, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% even step (small)
        ?_assertEqual(
            {2011, ?MAR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step (small)
        ?_assertEqual(
            {2011, ?APR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% even step (large)
        ?_assertEqual(
            {2014, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 36,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step (large)
        ?_assertEqual(
            {2014, ?FEB, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 37,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% shift start date
        ?_assertEqual(
            {2011, ?MAR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {2010, ?DEC, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2010, ?OCT, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {2010, ?NOV, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {2010, ?SEP, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {2010, ?AUG, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% long span
        ?_assertEqual(
            {2011, ?MAR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"tuesday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"wensday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"thursday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"friday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"saturday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"last">>,
                    wdays = [<<"sunday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        )
    ].

-spec monthly_every_ordinal_recurrence_test_() -> any().
monthly_every_ordinal_recurrence_test_() ->
    %% basic first
    [
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic second
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic third
        ?_assertEqual(
            {2011, ?JAN, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic fourth
        ?_assertEqual(
            {2011, ?JAN, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic fifth
        ?_assertEqual(
            {2011, ?JAN, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% on occurrence
        ?_assertEqual(
            {2011, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 10}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 17}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 24}
            )
        ),
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, ordinal = <<"fifth">>, wdays=[<<"monday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %% leap year first
        ?_assertEqual(
            {2008, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% leap year second
        ?_assertEqual(
            {2008, ?FEB, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% leap year third
        ?_assertEqual(
            {2008, ?FEB, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% leap year fourth
        ?_assertEqual(
            {2008, ?FEB, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% leap year fifth
        ?_assertEqual(
            {2008, ?MAR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"monday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2008, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 1}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?FEB, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?MAR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?APR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?MAY, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% even step first (small)
        ?_assertEqual(
            {2011, ?MAR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% even step second (small)
        ?_assertEqual(
            {2011, ?MAR, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% even step third (small)
        ?_assertEqual(
            {2011, ?MAR, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% even step fourth (small)
        ?_assertEqual(
            {2011, ?MAR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% even step fifth (small)
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=2, ordinal = <<"fifth">>, wdays=[<<"monday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        ?_assertEqual(
            {2011, ?MAR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 31},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=2, ordinal = <<"fifth">>, wdays=[<<"friday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=2, ordinal = <<"fifth">>, wdays=[<<"saturday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=2, ordinal = <<"fifth">>, wdays=[<<"sunday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %% odd step first (small)
        ?_assertEqual(
            {2011, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step second (small)
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step third (small)
        ?_assertEqual(
            {2011, ?APR, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step fourth (small)
        ?_assertEqual(
            {2011, ?APR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %% odd step fifth (small)
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=3, ordinal = <<"fifth">>, wdays=[<<"monday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=3, ordinal = <<"fifth">>, wdays=[<<"tuesday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=3, ordinal = <<"fifth">>, wdays=[<<"wensday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=3, ordinal = <<"fifth">>, wdays=[<<"thursday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        ?_assertEqual(
            {2011, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 3,
                    ordinal = <<"fifth">>,
                    wdays = [<<"saturday">>],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 31}
            )
        ),
        %%FIXME    ,?_assertEqual({2011, ?, ??}, cf_temporal_route:next_rule_date(#rule{cycle = <<"monthly">>, interval=3, ordinal = <<"fifth">>, wdays=[<<"sunday">>], start_date={2011,?JAN,1}}, {2011,?JAN,31}))
        %% shift start date
        ?_assertEqual(
            {2011, ?FEB, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    start_date = {2005, ?FEB, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    start_date = {2006, ?MAR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    start_date = {2007, ?APR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    start_date = {2008, ?MAY, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% long span
        ?_assertEqual(
            {2011, ?MAR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    interval = 5,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        )
    ].

-spec monthly_date_recurrence__basic_increment_test_() -> any().
monthly_date_recurrence__basic_increment_test_() ->
    %% basic increment
    [
        ?_assertEqual(
            {2011, ?JAN, D + 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [D + 1], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, D}
            )
        )
     || D <- lists:seq(1, 30)
    ] ++
        [
            ?_assertEqual(
                {2011, ?JUN, D + 1},
                cf_temporal_route:next_rule_date(
                    #rule{cycle = <<"monthly">>, days = [D + 1], start_date = {2011, ?JUN, 1}},
                    {2011, ?JUN, D}
                )
            )
         || D <- lists:seq(1, 29)
        ].

-spec monthly_date_recurrence_test_() -> any().
monthly_date_recurrence_test_() ->
    %% same day, before
    [
        ?_assertEqual(
            {2011, ?MAR, 25},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [25], start_date = {2011, ?JAN, 1}},
                {2011, ?MAR, 24}
            )
        ),
        %% increment over month boundary
        ?_assertEqual(
            {2011, ?FEB, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [1], start_date = {2011, ?JAN, 1}},
                {2011, ?JAN, 31}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [1], start_date = {2011, ?JUN, 1}},
                {2011, ?JUN, 30}
            )
        ),
        %% increment over year boundary
        ?_assertEqual(
            {2011, ?JAN, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [1], start_date = {2010, ?JAN, 1}},
                {2010, ?DEC, 31}
            )
        ),
        %% leap year (into)
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [29], start_date = {2008, ?JAN, 1}},
                {2008, ?FEB, 28}
            )
        ),
        %% leap year (over)
        ?_assertEqual(
            {2008, ?MAR, 1},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [1], start_date = {2008, ?JAN, 1}},
                {2008, ?FEB, 29}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [2], start_date = {2008, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [2], start_date = {2009, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{cycle = <<"monthly">>, days = [2], start_date = {2010, ?JAN, 1}},
                {2011, ?JAN, 1}
            )
        ),
        %% multiple dates
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 3}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 4}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 5}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 6}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 7}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 8}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 9}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 10}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 11}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 12}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 13}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 14}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 15}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 16}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 17}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 18}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 19}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 20}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 21}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 22}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 23}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 24}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 25}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>,
                    days = [5, ?OCT, 15, 20, 25],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 26}
            )
        ),
        %% even step (small)
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 2, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?MAY, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 2, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAR, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 2, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 2, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?AUG, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 2, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 2}
            )
        ),
        %% odd step (small)
        ?_assertEqual(
            {2011, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUL, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?OCT, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JUL, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?SEP, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 2}
            )
        ),
        %% even step (large)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 24, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 24, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 24, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 24, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 2}
            )
        ),
        %% odd step (large)
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 37, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2014, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 37, days = [2], start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 2}
            )
        ),
        ?_assertEqual(
            {2011, ?JUN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 37, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 1}
            )
        ),
        ?_assertEqual(
            {2014, ?JUL, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 37, days = [2], start_date = {2011, ?JUN, 1}
                },
                {2011, ?JUN, 2}
            )
        ),
        %% shift start date
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2007, ?MAY, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?MAR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2008, ?JUN, 2}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?JAN, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2009, ?JUL, 3}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?FEB, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 3, days = [2], start_date = {2010, ?AUG, 4}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% long span
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"monthly">>, interval = 4, days = [11], start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        )
    ].

-spec yearly_date_recurrence_test_() -> any().
yearly_date_recurrence_test_() ->
    %% basic increment
    [
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?FEB, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAR, 1}
            )
        ),
        %% same month, before
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 10}
            )
        ),
        %% increment over year boundary
        ?_assertEqual(
            {2012, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 11}
            )
        ),
        %% leap year (into)
        ?_assertEqual(
            {2008, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?FEB, days = [29], start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 28}
            )
        ),
        %% leap year (over)
        ?_assertEqual(
            {2009, ?FEB, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?FEB, days = [29], start_date = {2008, ?JAN, 1}
                },
                {2008, ?FEB, 29}
            )
        ),
        %% shift start date (no impact)
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2008, ?OCT, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2009, ?NOV, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>, month = ?APR, days = [11], start_date = {2010, ?DEC, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% even step (small)
        ?_assertEqual(
            {2013, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    month = ?APR,
                    days = [11],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 11}
            )
        ),
        ?_assertEqual(
            {2015, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    month = ?APR,
                    days = [11],
                    start_date = {2011, ?JAN, 1}
                },
                {2014, ?APR, 11}
            )
        ),
        %% odd step (small)
        ?_assertEqual(
            {2014, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 3,
                    month = ?APR,
                    days = [11],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 11}
            )
        ),
        ?_assertEqual(
            {2017, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 3,
                    month = ?APR,
                    days = [11],
                    start_date = {2011, ?JAN, 1}
                },
                {2016, ?APR, 11}
            )
        ),
        %% shift start dates
        ?_assertEqual(
            {2013, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 5,
                    month = ?APR,
                    days = [11],
                    start_date = {2008, ?OCT, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2014, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 5,
                    month = ?APR,
                    days = [11],
                    start_date = {2009, ?NOV, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2015, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 5,
                    month = ?APR,
                    days = [11],
                    start_date = {2010, ?DEC, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% long span
        ?_assertEqual(
            {2013, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 5,
                    month = ?APR,
                    days = [11],
                    start_date = {1983, ?APR, 11}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% multiple days
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    month = ?APR,
                    days = [11, 12, 13],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    month = ?APR,
                    days = [11, 12, 13],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 11}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    month = ?APR,
                    days = [11, 12, 13],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 12}
            )
        ),
        ?_assertEqual(
            {2012, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    month = ?APR,
                    days = [11, 12, 13],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 13}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    month = ?APR,
                    days = [11, 12, 13],
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 13}
            )
        )
    ].

-spec yearly_every_recurrence_test() -> any().
yearly_every_recurrence_test() ->
    %% TODO
    'ok'.

-spec yearly_last_recurrence_test() -> any().
yearly_last_recurrence_test() ->
    %% TODO
    'ok'.
-spec yearly_every_ordinal_recurrence_test_() -> any().
yearly_every_ordinal_recurrence_test_() ->
    %% basic first
    [
        ?_assertEqual(
            {2011, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic second
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic third
        ?_assertEqual(
            {2011, ?APR, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic fourth
        ?_assertEqual(
            {2011, ?APR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% basic fifth
        ?_assertEqual(
            {2012, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2014, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2015, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2012, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% same month, before
        ?_assertEqual(
            {2011, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 10}
            )
        ),
        %% current date on (simple)
        ?_assertEqual(
            {2011, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAR, 11}
            )
        ),
        ?_assertEqual(
            {2012, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?APR, 11}
            )
        ),
        %% current date after (simple)
        ?_assertEqual(
            {2012, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?JUN, 21}
            )
        ),
        %% shift start dates (no impact)
        ?_assertEqual(
            {2011, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2004, ?JAN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2005, ?FEB, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2006, ?MAR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2007, ?APR, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2008, ?MAY, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2009, ?JUN, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        ?_assertEqual(
            {2011, ?APR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2010, ?JUL, 1}
                },
                {2011, ?JAN, 1}
            )
        ),
        %% even step first (small)
        ?_assertEqual(
            {2013, ?APR, 1},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 2},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 3},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 4},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 5},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 6},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 7},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"first">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        %% even step second (small)
        ?_assertEqual(
            {2013, ?APR, 8},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 9},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 10},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 11},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 12},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 13},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 14},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"second">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        %% even step third (small)
        ?_assertEqual(
            {2013, ?APR, 15},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 16},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 17},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 18},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 19},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 20},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 21},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"third">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        %% even step fourth (small)
        ?_assertEqual(
            {2013, ?APR, 22},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 23},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 24},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 25},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 26},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 27},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 28},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fourth">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        %% basic fifth (small)
        ?_assertEqual(
            {2013, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"monday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2013, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"tuesday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2015, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"wensday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2015, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"thursday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2021, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"friday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2017, ?APR, 29},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"saturday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        ),
        ?_assertEqual(
            {2017, ?APR, 30},
            cf_temporal_route:next_rule_date(
                #rule{
                    cycle = <<"yearly">>,
                    interval = 2,
                    ordinal = <<"fifth">>,
                    wdays = [<<"sunday">>],
                    month = ?APR,
                    start_date = {2011, ?JAN, 1}
                },
                {2011, ?MAY, 1}
            )
        )
    ].
