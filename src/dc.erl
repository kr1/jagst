%% delicious tag-subscription controller
-module(dc).
-export([start/2, loop/2]).

-include("../include/jsonerl.hrl").
-include("../include/jagst_deli.hrl").

-record(state, {tags,
                items = []}).                 %this is the string for the tags sent to delicious (eg. "erlang" or "erlang+websockets" 

start(Pid, Tags)->
  ?MODULE:loop([Pid], #state{tags=Tags}).

%% this is the main loop of the deli controller. it as 3 actions:
%%     - add a user
%%     - delete a user
%%     - send Data
%% it maintains a list of Pids and a state-record
loop(Pids, State) ->
  receive
    {add_pid, Pid} ->
      Pids1 = lists:umerge(Pids,[Pid]),
      Pids2 = lists:filter(fun(Pid_) -> erlang:is_process_alive(Pid_) end, Pids1),
      %io:format("dc ~p has now pids: ~p~nand State: ~p~n",[self(),Pids1,State]),
      loop(Pids2, State);
    {del_pid, Pid} ->
      Pids1 = lists:delete(Pid, Pids),
      loop(Pids1, State);
    {send_items, SocketPid} ->
        io:format("should send Items to: ~p~n",[SocketPid]),
        Its = State#state.items,
        case Its of
            [] ->
                State1 = get_items(State);
            _ -> 
                State1 = State
        end,
        send_items([SocketPid],State1),
        loop(Pids, State1);
    print_pids ->
      io:format("Pids: ~p~n",[Pids]),
      loop(Pids, State);
    print_tags ->
      io:format("tags: ~p~n",[State#state.tags]),
      loop(Pids, State);
    M ->
      io:format("received non-sense: ~p~n",[M]),
      loop(Pids, State)
    after 15000 ->
      case length(Pids) of 
        0 ->
          exit;
        _ ->
          State1 = get_items(State),
          send_items(Pids, State1),
          loop(Pids, State1)
      end
  end.

get_items(State) ->
    Res = rss_helper:director(State#state.tags),
    case Res of
          error ->
              State;
          _ ->
              State#state{items = lists:map(fun(Rec) -> ?record_to_json(tagging, Rec) end, Res)}
    end.
    
send_items(Pids, State) ->     
    Fun = fun(SocketPid) ->
                lists:foreach(fun(It) ->
                                SocketPid ! {send, It}
                              end, lists:reverse(State#state.items))
          end,
    lists:foreach(Fun, Pids).
  