%% group controller
-module(gc).
-export([start/1,loop/2]).

-record(state, {last_active_member}).

start(Pid)->
  ?MODULE:loop([Pid], #state{}).

%% this is the main loop of the group controller. it as 3 functions:
%%     - add a user
%%     - delete a user
%%     - send Data
%% it maintains a list of Pids and a state-record
loop(Pids, State) ->
  receive
    {add_pid, Pid} ->
      Pids1 = lists:umerge(Pids,[Pid]),
      Pids2 = lists:filter(fun(Pid_) -> erlang:is_process_alive(Pid_) end, Pids1),
      io:format("list ~p now has pids: ~p~nand State: ~p~n",[self(),Pids1,State]),
      loop(Pids2, State);
    {del_pid, Pid} ->
      Pids1 = lists:delete(Pid, Pids),
      loop(Pids1, State);
    {dispatch, [Un | Data]} ->
      case State#state.last_active_member == Un of
        true ->
          State1 = State;
        false ->
          State1 = State#state{last_active_member=Un}
      end,
      %io:format("list ~p now has pids: ~p~nand State: ~p~n",[self(), Pids, State1]),
      Fun = fun(SocketPid) ->
                case State1 == State of
                  false -> 
                    SocketPid ! {send, io_lib:format("{\"last_active_user\":~p}",[Un])};
                  true ->
                    ok
                end,
                SocketPid ! {send,Data}
            end,
      lists:foreach(Fun,Pids),
      loop(Pids, State1);
    M ->
      io:format("received non-sense: ~p~n",[M]),
      loop(Pids, State)
  end.
