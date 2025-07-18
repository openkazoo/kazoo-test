%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2010-2022, 2600Hz
%%% @doc
%%% @end
%%%-----------------------------------------------------------------------------
-module(kz_fixturedb_util).

%% Driver callbacks
-export([format_error/1]).

%% API
-export([
    open_json/2,
    doc_path/2,
    open_attachment/3,
    att_path/3,
    open_view/3,
    view_path/3,

    docs_dir/1,
    views_dir/1,

    update_doc/1,
    update_revision/1,

    encode_query_filename/2,

    get_default_fixtures_db/1,

    %% utilities for calling from shell
    get_doc_path/2,
    get_view_path/3,
    get_att_path/3,
    get_doc_path/3,
    get_view_path/4,
    get_att_path/4,

    add_view_to_index/3,
    add_att_to_index/3,
    add_view_to_index/4,
    add_att_to_index/4,

    update_pvt_doc_hash/0, update_pvt_doc_hash/1,

    start_me/0, start_me/1,
    stop_me/1,

    db_to_disk/1, db_to_disk/2,
    view_index_to_disk/3
]).

-include("kz_fixturedb.hrl").

%%%=============================================================================
%%% Driver callbacks
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec format_error(any()) -> any().
format_error('timeout') -> 'timeout';
format_error('conflict') -> 'conflict';
format_error('not_found') -> 'not_found';
format_error('db_not_found') -> 'db_not_found';
format_error(Other) -> Other.

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec open_json(db_map(), kz_term:ne_binary()) -> doc_resp().
open_json(Db, DocId) ->
    read_json(doc_path(Db, DocId)).

-spec open_attachment(db_map(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    {'ok', binary()} | {'error', 'not_found'}.
open_attachment(Db, DocId, AName) ->
    read_file(att_path(Db, DocId, AName)).

-spec open_view(db_map(), kz_term:ne_binary(), kz_data:options()) -> docs_resp().
open_view(Db, Design, Options) ->
    read_json(view_path(Db, Design, Options)).

-spec doc_path(db_map(), kz_term:ne_binary()) -> file:filename_all().
doc_path(#{server := #{url := Url}, name := DbName}, DocId) ->
    filename:join(
        kz_term:to_list(Url) ++ "/" ++ kz_term:to_list(DbName),
        ["docs/", kz_term:to_list(DocId), ".json"]
    ).

-spec att_path(db_map(), kz_term:ne_binary(), kz_term:ne_binary()) -> file:filename_all().
att_path(#{server := #{url := Url}, name := DbName}, DocId, AName) ->
    AttName = kz_binary:hexencode(crypto:hash(md5, <<DocId/binary, AName/binary>>)),
    filename:join(
        kz_term:to_list(Url) ++ "/" ++ kz_term:to_list(DbName),
        ["docs/", kz_term:to_list(AttName), ".att"]
    ).

-spec view_path(db_map(), kz_term:ne_binary(), kz_data:options()) -> file:filename_all().
view_path(#{server := #{url := Url}, name := DbName}, Design, Options) ->
    filename:join(
        kz_term:to_list(Url) ++ "/" ++ kz_term:to_list(DbName),
        ["views/", encode_query_filename(Design, Options)]
    ).

%% @doc The idea is to encode file name based on view options so you can
%% write JSON file specifically for each of your view queries
-spec encode_query_filename(kz_term:ne_binary(), kz_data:options()) -> kz_term:text().
encode_query_filename(Design, Options) ->
    encode_query_options(Design, ?DANGEROUS_VIEW_OPTS, Options, []).

-spec docs_dir(db_map()) -> kz_term:text().
docs_dir(#{server := #{url := Url}, name := DbName}) ->
    kz_term:to_list(<<Url/binary, "/", DbName/binary, "/docs">>).

-spec views_dir(db_map()) -> kz_term:text().
views_dir(#{server := #{url := Url}, name := DbName}) ->
    kz_term:to_list(<<Url/binary, "/", DbName/binary, "/views">>).

-spec update_doc(kz_json:object()) -> kz_json:object().
update_doc(JObj) ->
    Funs = [
        %% fun update_revision/1
        fun(J) -> kz_doc:set_document_hash(J, kz_doc:calculate_document_hash(J)) end
    ],
    lists:foldl(fun(F, J) -> F(J) end, JObj, Funs).

-spec update_revision(kz_json:object()) -> kz_json:object().
update_revision(JObj) ->
    case kz_json:get_value(<<"_rev">>, JObj) of
        'undefined' ->
            kz_doc:set_revision(JObj, <<"1-", (kz_binary:rand_hex(16))/binary>>);
        Rev ->
            [RevPos | _] = binary:split(Rev, <<"-">>),
            Rev2 = kz_term:to_integer(RevPos) + 1,
            kz_doc:set_revision(JObj, <<
                (kz_term:to_binary(Rev2))/binary, "-", (kz_binary:rand_hex(16))/binary
            >>)
    end.

%%%=============================================================================
%%% Handy functions to use from shell to managing files
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec start_me() -> pid().
start_me() ->
    start_me('false').

-spec start_me(boolean()) -> pid().
start_me(SilentLager) ->
    ?LOG_DEBUG(":: Starting up Kazoo FixtureDB"),
    {'ok', _} = application:ensure_all_started('kazoo_config'),
    {'ok', Pid} = kazoo_data_link_sup:start_link(),
    'ignore' = kazoo_data_bootstrap:start_link(),

    _ =
        case SilentLager of
            'true' ->
                _ = lager:set_loglevel('lager_console_backend', 'none'),
                _ = lager:set_loglevel('lager_file_backend', 'none'),
                lager:set_loglevel('lager_syslog_backend', 'none');
            'false' ->
                'ok'
        end,
    Pid.

-spec stop_me(pid()) -> 'ok'.
stop_me(Pid) ->
    _ = erlang:exit(Pid, 'normal'),
    _ = application:stop('kazoo_config'),
    ?LOG_DEBUG(":: Stopped Kazoo FixtureDB").

-spec get_doc_path(kz_term:ne_binary(), kz_term:ne_binary()) -> file:filename_all().
get_doc_path(DbName, DocId) ->
    Plan = kz_fixturedb_server:get_dummy_plan(),
    get_doc_path(Plan, DbName, DocId).

-spec get_doc_path(map(), kz_term:ne_binary(), kz_term:ne_binary()) -> file:filename_all().
get_doc_path(#{server := {_, Conn}} = _Plan, DbName, DocId) ->
    doc_path(kz_fixturedb_server:get_db(Conn, DbName), DocId).

-spec get_att_path(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    file:filename_all().
get_att_path(DbName, DocId, AName) ->
    Plan = kz_fixturedb_server:get_dummy_plan(),
    get_att_path(Plan, DbName, DocId, AName).

-spec get_att_path(map(), kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    file:filename_all().
get_att_path(#{server := {_, Conn}} = _Plan, DbName, DocId, AName) ->
    att_path(kz_fixturedb_server:get_db(Conn, DbName), DocId, AName).

-spec get_view_path(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:proplist()) ->
    file:filename_all().
get_view_path(DbName, Design, Options) ->
    Plan = kz_fixturedb_server:get_dummy_plan(),
    get_view_path(Plan, DbName, Design, Options).

-spec get_view_path(map(), kz_term:ne_binary(), kz_term:ne_binary(), kz_term:proplist()) ->
    file:filename_all().
get_view_path(#{server := {_, Conn}} = _Plan, DbName, Design, Options) ->
    view_path(kz_fixturedb_server:get_db(Conn, DbName), Design, Options).

-spec add_att_to_index(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    {'ok', binary()} | {'error', any()}.
add_att_to_index(DbName, DocId, AName) ->
    Plan = kz_fixturedb_server:get_dummy_plan(),
    add_att_to_index(Plan, DbName, DocId, AName).

-spec add_att_to_index(map(), kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    {'ok', binary()} | {'error', any()}.
add_att_to_index(#{server := {_, Conn}} = _Plan, DbName, DocId, AName) ->
    #{server := #{url := Url}} = Db = kz_fixturedb_server:get_db(Conn, DbName),
    AttPath = att_path(Db, DocId, AName),
    Row = kz_term:to_binary(
        io_lib:format("~s, ~s, ~s", [DocId, AName, filename:basename(AttPath)])
    ),
    Header = <<"doc_id, attachment_name, attachment_file_name">>,

    IndexPath = index_file_path("attachment", Url, DbName),
    case write_index_file(IndexPath, Header, Row) of
        {'ok', _} -> maybe_symlink_att_file(AName, AttPath, Row);
        {'error', _} = Error -> Error
    end.

-spec maybe_symlink_att_file(
    kz_term:ne_binary(), kz_term:ne_binary(), {'ok', binary()} | {'error', any()}
) -> {'ok', binary()} | {'error', any()}.
maybe_symlink_att_file(_, _, {'error', _} = Error) ->
    Error;
maybe_symlink_att_file(AName, AttPath, OK) ->
    case
        filelib:is_regular(filename:join([code:priv_dir('kazoo_fixturedb'), "media_files/", AName]))
    of
        'true' ->
            case file:make_symlink(<<"../../../media_files/", AName/binary>>, AttPath) of
                'ok' ->
                    ?DEV_LOG("created a sym-link for ~s to kazoo_fixturedb/priv/media_files/~s", [
                        filename:basename(AttPath), AName
                    ]);
                {'error', 'enotsup'} ->
                    ?DEV_LOG("creating sym-link is not supported by your platform");
                {'error', _Reason} ->
                    ?DEV_LOG("Existing ~p~nAttPath ~p", [
                        <<"../../../media_files/", AName/binary>>, AttPath
                    ]),
                    ?DEV_LOG(
                        "failed to create sym-link for attachment to kazoo_fixturedb/priv/media_files/~s: ~p",
                        [AName, _Reason]
                    ),
                    ?DEV_LOG("you have to create the attachment manually.")
            end,
            OK;
        'false' ->
            OK
    end.

-spec add_view_to_index(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:proplist()) ->
    {'ok', binary()} | {'error', any()}.
add_view_to_index(DbName, Design, Options) ->
    Plan = kz_fixturedb_server:get_dummy_plan(),
    add_view_to_index(Plan, DbName, Design, Options).

-spec add_view_to_index(map(), kz_term:ne_binary(), kz_term:ne_binary(), kz_term:proplist()) ->
    {'ok', binary()} | {'error', any()}.
add_view_to_index(#{server := {_, Conn}} = _Plan, DbName, Design, Options) ->
    #{server := #{url := Url}} = Db = kz_fixturedb_server:get_db(Conn, DbName),
    ViewPath = view_path(Db, Design, Options),
    Row = kz_term:to_binary(
        io_lib:format("~s, ~1000p, ~s", [Design, Options, filename:basename(ViewPath)])
    ),
    Header = <<"view_name, view_options, view_file_name">>,

    IndexPath = index_file_path("view", Url, DbName),
    case write_index_file(IndexPath, Header, Row) of
        {'ok', _} = OK -> OK;
        {'error', _} = Error -> Error
    end.

-spec index_file_path(kz_term:text(), kz_term:ne_binary(), kz_term:ne_binary()) -> kz_term:text().
index_file_path(Mode, Url, DbName) ->
    kz_term:to_list(Url) ++ "/" ++ kz_term:to_list(DbName) ++ "/" ++ Mode ++ "-index.csv".

-spec update_pvt_doc_hash() -> 'ok'.
update_pvt_doc_hash() ->
    Paths = filelib:wildcard(code:priv_dir('kazoo_fixturedb') ++ "/dbs/*/docs/*.json"),
    _ = [update_pvt_doc_hash(Path) || Path <- Paths],
    'ok'.

-spec update_pvt_doc_hash(kz_term:text() | kz_term:ne_binary()) -> 'ok' | {'error', any()}.
update_pvt_doc_hash(Path) ->
    case read_json(Path) of
        {'ok', JObj} ->
            NewJObj = kz_doc:set_document_hash(JObj, kz_doc:calculate_document_hash(JObj)),
            file:write_file(Path, kz_json:encode(NewJObj, ['pretty']));
        {'error', _} = Error ->
            Error
    end.

-spec get_default_fixtures_db(kz_term:ne_binary()) -> db_map().
get_default_fixtures_db(DbName) ->
    {'ok', Server} = kz_fixturedb_server:new_connection(#{}),
    kz_fixturedb_server:get_db(Server, DbName).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------
-spec read_json(file:filename_all()) ->
    {'ok', kz_json:object() | kz_json:objects()} | {'error', 'not_found'}.
read_json(Path) ->
    case read_file(Path) of
        {'ok', Bin} -> {'ok', kz_json:decode(Bin)};
        {'error', _} -> {'error', 'not_found'}
    end.

-spec read_file(file:filename_all()) -> {'ok', binary()} | {'error', 'not_found'}.
read_file(Path) ->
    case file:read_file(Path) of
        {'ok', _} = OK -> OK;
        {'error', _} -> {'error', 'not_found'}
    end.

-spec write_index_file(
    file:filename_all(),
    kz_term:ne_binary(),
    kz_term:ne_binary() | {'ok', binary()} | {'error', any()}
) ->
    {'ok', binary()} | {'error', any()}.
write_index_file(Path, Header, NewLine) when is_binary(NewLine) ->
    write_index_file(Path, NewLine, read_index_file(Path, Header, NewLine));
write_index_file(_, _, {'error', _} = Error) ->
    Error;
write_index_file(Path, NewLine, {'ok', IndexLines}) ->
    [Header | Lines] = binary:split(IndexLines, <<"\n">>, ['global']),
    ToWrite = [
        <<Header/binary, "\n">>
        | [
            <<L/binary, "\n">>
         || L <- lists:usort(Lines),
            kz_term:is_not_empty(L)
        ]
    ],
    case file:write_file(Path, ToWrite) of
        'ok' ->
            {'ok', NewLine};
        {'error', _Reason} = Error ->
            ?DEV_LOG("failed to write index file ~s: ~p", [Path, _Reason]),
            Error
    end.

-spec read_index_file(kz_term:ne_binary(), kz_term:ne_binary(), kz_term:ne_binary()) ->
    {'ok', binary()} | {'error', any()}.
read_index_file(Path, Header, NewLine) ->
    HSize = size(Header),
    case file:read_file(Path) of
        {'ok', <<>>} ->
            {'ok', <<Header/binary, "\n", NewLine/binary>>};
        {'ok', <<Header:HSize/binary, "\n">> = H} ->
            {'ok', <<H/binary, NewLine/binary>>};
        {'ok', Header} ->
            {'ok', <<Header/binary, "\n", NewLine/binary>>};
        {'ok', IndexBin} ->
            {'ok', <<IndexBin/binary, "\n", NewLine/binary>>};
        {'error', 'enoent'} ->
            {'ok', <<Header/binary, "\n", NewLine/binary>>};
        {'error', _Reason} = Error ->
            ?DEV_LOG("failed to open index file ~s: ~p", [Path, _Reason]),
            Error
    end.

-spec encode_query_options(kz_term:ne_binary(), list(), kz_data:options(), list()) ->
    kz_term:text().
encode_query_options(Design, [], _, []) ->
    DesignView = design_view(Design),
    kz_term:to_list(<<DesignView/binary, ".json">>);
encode_query_options(Design, [], _, Acc) ->
    DesignView = design_view(Design),
    QueryHash = kz_binary:hexencode(crypto:hash('md5', erlang:term_to_binary(Acc))),

    kz_term:to_list(<<DesignView/binary, "-", QueryHash/binary, ".json">>);
encode_query_options(Design, [Key | Keys], Options, Acc) ->
    case props:get_value(Key, Options, 'not_defined') of
        'not_defined' -> encode_query_options(Design, Keys, Options, Acc);
        Value -> encode_query_options(Design, Keys, Options, ["&", Key, "=", Value | Acc])
    end.

-spec design_view(kz_term:ne_binary()) -> kz_term:ne_binary().
design_view(Design) ->
    case binary:split(Design, <<"/">>) of
        [DesignName] -> DesignName;
        [DesignName, ViewName | _] -> <<DesignName/binary, "+", ViewName/binary>>
    end.

-spec db_to_disk(kz_term:ne_binary()) -> 'ok' | {'error', kz_datamgr:data_error()}.
db_to_disk(Database) ->
    db_to_disk(Database, fun kz_term:always_true/1).

-type filter_fun() :: fun((kz_json:object()) -> boolean()).
-spec db_to_disk(kz_term:ne_binary(), filter_fun()) -> 'ok' | {'error', kz_datamgr:data_error()}.
db_to_disk(Database, FilterFun) ->
    case kz_datamgr:db_exists(Database) of
        'true' -> db_to_disk_persist(Database, FilterFun);
        'false' -> {'error', 'not_found'}
    end.

db_to_disk_persist(Database, FilterFun) ->
    db_to_disk_persist(Database, FilterFun, get_page(Database, 'undefined')).

get_page(Database, 'undefined') ->
    query(Database, []);
get_page(Database, StartKey) ->
    query(Database, [{'startkey', StartKey}]).

query(Database, Options) ->
    kz_datamgr:paginate_results(Database, 'all_docs', ['include_docs' | Options]).

db_to_disk_persist(Database, FilterFun, {'ok', ViewResults, 'undefined'}) ->
    _ = filter_and_persist(Database, FilterFun, ViewResults),
    lager:info("finished persisting ~s", [Database]);
db_to_disk_persist(Database, FilterFun, {'ok', ViewResults, NextStartKey}) ->
    _ = filter_and_persist(Database, FilterFun, ViewResults),
    db_to_disk_persist(Database, FilterFun, get_page(Database, NextStartKey)).

filter_and_persist(Database, FilterFun, ViewResults) ->
    _ = [
        persist(Database, Document)
     || ViewResult <- ViewResults,
        Document <- [kz_json:get_json_value(<<"doc">>, ViewResult)],
        FilterFun(Document)
    ].

persist(Database, Document) ->
    Path = get_doc_path(Database, kz_doc:id(Document)),
    'ok' = filelib:ensure_dir(Path),

    lager:info("  persisting doc ~s to ~s", [kz_doc:id(Document), Path]),
    'ok' = file:write_file(Database, kz_json:encode(Document, ['pretty'])).

-spec view_index_to_disk(kz_term:ne_binary(), kz_term:ne_binary(), kz_datamgr:view_options()) ->
    'ok'.
view_index_to_disk(Database, ViewName, Options) ->
    Path = get_view_path(Database, ViewName, Options),
    'ok' = filelib:ensure_dir(Path),

    {'ok', Results} = kz_datamgr:get_results(Database, ViewName, Options),
    lager:info(" persisting view index ~s/~s to ~s", [Database, ViewName, Path]),
    'ok' = file:write_file(Path, kz_json:encode(Results, ['pretty'])).
