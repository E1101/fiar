-module (fiar_match_repo).

-type status() :: {won_by, fiar_match:player()}
                | drawn
                | {next_player, fiar_match:player()}.
-export_type([status/0]).

-export([start/2, get_match/2, play/3, status/2, get_matches/1]).

start(User1, User2) ->
  Player1 = fiar_user:get_id(User1),
  Player2 = fiar_user:get_id(User2),
  Match = fiar_match:new(Player1, Player2),
  lager:info("Match Previous to save: ~p", [Match]),
  StoredMatch = sumo:persist(fiar_match, Match),
  fiar_match:get_id(StoredMatch).

play(Mid, Col, User) ->
  Match = get_match(Mid, User),
  UserId = fiar_user:get_id(User),
  case fiar_match:get_player(Match) of
    UserId -> ok;
    _OtherPlayer -> throw(invalid_player)
  end,
  Status = fiar_match:get_status(Match),
  case Status of
    on_course -> 
      try
        State = fiar_match:get_state(Match),
        {Reply, NewStatus, NewState} =
          case fiar_core:play(Col, State) of
            {Result, St} -> {Result, Status, St};
            Result -> {Result, new_status(Result, State), State}
          end,
          NewMatch0 = fiar_match:set_status(Match, NewStatus),
          NewMatch2 = fiar_match:set_state(NewMatch0, NewState),
          NewMatch3 = fiar_match:set_updated_at(NewMatch2),
          sumo:persist(fiar_match, NewMatch3),
          Reply
      catch
        _:Ex -> throw(Ex)
      end;
    Status -> throw({match_finished, Status})
  end.

status(Mid, User) ->
  Match = get_match(Mid, User),
  Status = fiar_match:get_status(Match),
  case Status of
    on_course -> {next_player, fiar_match:get_player(Match)};
    won_by_player1 -> {won_by, fiar_match:get_player1(Match)};
    won_by_player2 -> {won_by, fiar_match:get_player2(Match)};
    drawn -> drawn;
    Status -> throw({invalid_status, Status})
  end.

%% @private
new_status(won, State) ->
  case fiar_core:get_current_chip(State) of
    1 -> won_by_player1;
    2 -> won_by_player2
  end;
new_status(drawn, _State) -> drawn.

get_match(Mid, User) ->
  case sumo:find(fiar_match, Mid) of
    notfound -> throw({notfound, Mid});
    M ->
      UserId = fiar_user:get_id(User),
      case fiar_match:is_player(UserId, M) of
        true -> M;
        false -> throw({notfound, Mid})
      end
  end.

get_matches(User) ->
  MatchesAsP1 = sumo:find_by(fiar_match, [{player1, fiar_user:get_id(User)}]),
  MatchesAsP2 = sumo:find_by(fiar_match, [{player2, fiar_user:get_id(User)}]),
  MatchesAsP1 ++ MatchesAsP2.