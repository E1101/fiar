% This file is licensed to you under the Apache License,
% Version 2.0 (the "License"); you may not use this file
% except in compliance with the License.  You may obtain
% a copy of the License at
% 
% http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing,
% software distributed under the License is distributed on an
% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
% KIND, either express or implied.  See the License for the
% specific language governing permissions and limitations
% under the License.

%% @doc Third excercise: .
%%    == Required Knowledge ==
%%    <ul>
%%    <li>Modules and functions</li>
%%    <li>List functions</li>
%%    <li>Basic Erlang Structures</li>
%%    <li>Pattern Matching</li>
%%    <li>Gen Server</li>
%%    <li>Supervisor</li>
%%    <li>Application module</li>
%%    </ul>
%%
%%    == Problem Statement ==
%%    All calls into the system should go through the fiar module
%%    including but not limited to:
%%    <dl>
%%    <dt>start() -> ok.</dt>
%%    <dt>stop() -> ok.</dt>
%%    <dt>start_match() -> ok.</dt>
%%    <dt>stop_match() -> ok.</dt>
%%    </dl>

-module (fiar_server_SUITE).
-author('euen@inakanetworks.com').

-type config() :: [{atom(), term()}].
-export([start/1]).
-export([all/0, init_per_testcase/2, end_per_testcase/2]).
-export([get_matches/1]).

%% @private
-spec all() -> [atom()].
all() -> [Fun || {Fun, 1} <- module_info(exports), Fun =/= module_info].

init_per_testcase(_, Config) ->
  {ok, _} = application:ensure_all_started(shotgun),
  ok = fiar:start(),
  Config.

end_per_testcase(_, Config) ->
  fiar:stop(),
  Config.

-spec start(config()) -> ok.
start(_Config) ->
  Headers = #{<<"content-type">> => <<"application/json">>},
  Body = jiffy:encode(#{player1 => "Juan", player2 => "Fede"}),
  {ok, #{status_code := 200, body := _}} = api_call(post, "/matches", Headers, Body).

%% @doc start returns an empty board
-spec get_matches(config()) -> ok.
get_matches(_Config) ->
  Headers = #{<<"content-type">> => <<"application/json">>},
  {ok, #{status_code := 200, body := RespBody}} = api_call(get, "/matches", Headers),
  true = is_list(jiffy:decode(RespBody)).

api_call(Method, Url, Headers) ->
    api_call(Method, Url, Headers, "").

api_call(Method, Url, Headers, Body) ->
  {ok, Pid} = shotgun:open("localhost", 8080),
  Response = case Method of
                 post ->
                     shotgun:post(Pid, Url, Headers, Body, #{});
                 get ->
                     shotgun:get(Pid, Url, Headers, #{});
                 put ->
                     shotgun:put(Pid, Url, Headers, Body, #{})
             end,
  shotgun:close(Pid),
  Response.