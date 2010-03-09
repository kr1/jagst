% ==========================================================================================================
% JAGST - Shows Websockets in action using the leightweight http server library misultin (>-|-|-(°>).
%
% 
% Copyright (C) 2010, Roberto Ostinelli <roberto@ostinelli.net>
% Copyright (C) 2010, Christian Woerner <christianworner[at{gmail}dot]com>
% All rights reserved.
%
% BSD License
% 
% Redistribution and use in source and binary forms, with or without modification, are permitted provided
% that the following conditions are met:
%
%  * Redistributions of source code must retain the above copyright notice, this list of conditions and the
%    following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
%    the following disclaimer in the documentation and/or other materials provided with the distribution.
%  * Neither the name of the authors nor the names of its contributors may be used to endorse or promote
%    products derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
% ==========================================================================================================
-module(jagst_ws_handler).
-export([start/1, stop/0,handle_deli_websocket/1,handle_schmotz_websocket/1]).

-include("../include/jsonerl.hrl").
-include("../include/jagst_deli.hrl").

% start misultin http server
start(Port) ->
	misultin:start_link([{port, Port}, {loop, fun(Req) -> handle_http(Req, Port) end}, {ws_loop, fun(Ws) -> handle_schmotz_websocket(Ws) end}]).

% stop the server
stop() ->
	misultin:stop().

% callback on request received
handle_http(Req, Port) ->	
	% output
	%{ok, Fi} = file:read_file("../data/site.html"),
    handle(Req:get(method), Req:resource([lowercase, urldecode]), Req,Port).
    
   
handle('GET', [], Req,Port) ->
    handle('GET', ["schmotz"], Req,Port);
handle('GET', ["schmotz"], Req,Port) ->
    {ok, Fi} = file:read_file("../static/schmotz.html"),
    File =  erlang:binary_to_list(Fi),    
    Req:ok([{"Content-Type", "text/html"}],[lists:flatten(io_lib:format(File,[integer_to_list(Port)]))]);
handle('GET', ["deli"], Req,Port) ->
    {ok, Fi} = file:read_file("../static/deli.html"),
    File =  erlang:binary_to_list(Fi),    
    Req:ok([{"Content-Type", "text/html"}],[lists:flatten(io_lib:format(File,[integer_to_list(Port)]))]);
handle('GET', ["static", Path], Req, _) ->
  Fi = io_lib:format("../static/~s",[Path]),
  %io:format("requesting this file:~s~n",[Fi]),
  Req:file(Fi);
handle(_, _, Req,_) ->
    Req:ok("Page not found.").

% callback on received websockets data
handle_deli_websocket(Ws) ->
    receive
        {browser, Data1} ->
          Data = jsonerl:decode(Data1),
          case Data of
            {{<<"tags">>, Tags2}} ->
              Tags1 = binary_to_list(Tags2),
              Tags = list_to_atom(Tags1),
              io:format("received request for: ~p~n",[Tags]),
              case lists:member(Tags,registered()) of
                true ->
                  Pid = whereis(Tags),
                  Pid ! {add_pid, Ws:get(socket_pid)},
                  Pid ! {send_items, Ws:get(socket_pid)};
                _ ->
                  Pid = spawn_link(dc, start, [Ws:get(socket_pid),Tags]),
                  Pid ! {send_items, Ws:get(socket_pid)},
                  io:format("start dc: ~p with Pid ~p~n",[Tags,Pid]),
                  register(Tags, Pid)
              end,
              case Ws:get(group_pid) == Pid of
                true ->
                  Ws1 = Ws;
                false ->
                  case is_pid(Ws:get(group_pid)) of
                    true ->
                      Ws:get(group_pid) ! {del_pid, Ws:get(socket_pid)};
                    false ->
                      ok
                  end,
                  Ws1 = misultin_ws:new(Ws:set({group_pid, Pid}), Ws:get(socket_pid))
              end,
              handle_deli_websocket(Ws1);
            M ->
              io:format("received meaningless: ~p~n",[M]),
              handle_deli_websocket(Ws)
          end;
        M ->
              io:format("received meaningless: ~p~n",[M]),
              handle_deli_websocket(Ws)
    after 240000 ->
        io:format("no activity~n"),
        handle_deli_websocket(Ws)
    end.

% callback on received websockets data
handle_schmotz_websocket(Ws) ->
	receive
        {browser, Data1} ->
          [H | Data] = Data1,
          case H of
            48 ->
                %io:format("sending ~p~n",[[Ws:get(un),Data]]),
                Ws:get(group_pid) ! {dispatch, [Ws:get(un)|Data]},
                handle_schmotz_websocket(Ws);
            49 ->
                Edata = jsonerl:decode(Data),
                io:format("Data: ~p~n",[Data]),
                case Edata of
                  {{<<"group">>, GroupName}} ->
                      Ws1 = handle_group(Ws, GroupName),
                      handle_schmotz_websocket(Ws1);
                  {{<<"username">>, Un1}} ->
                      Un = binary_to_list(Un1),
                      %io:format("user name: ~p, and registered:~p~n",[Un,Ws:get(un)]),
                      Ws1 = misultin_ws:new(Ws:set({un, Un}), Ws:get(socket_pid)),
                      %io:format("ws#socket: ~p, and SocketPid:~p~n",[Ws1:get(socket),Ws1:get(socket_pid)]),
                      Ws1:get(group_pid) ! {dispatch, [Ws1:get(un) | Un]},
                      handle_schmotz_websocket(Ws1);
%                   [X,Y] ->
%                       Ws:get(group_pid) ! {dispatch, io_lib:format("[~p,~p]",[X,Y])},
%                       handle_schmotz_websocket(Ws);
                  M ->
                      io:format("received meaningless: ~p~n",[M]),
                      handle_schmotz_websocket(Ws)
                end;
             H_ ->
                io:format("first char: ~p~n",[H_]),
                handle_schmotz_websocket(Ws)
                
             end;   %Ws:send(["received '", Data, "'"]),
        _Ignore ->
			handle_schmotz_websocket(Ws)
	after 240000 ->
		io:format("no activity~n"),
		handle_schmotz_websocket(Ws)
	end.

handle_group(Ws, Action) ->
    %Action = list_to_atom(GroupName),
    case Action of
      <<"get_group_list">> ->
        io:format("Asked group list!~n"),
        Ws;
      GroNa ->
        Target = list_to_atom(binary_to_list(GroNa)),
        case lists:member(Target,registered()) of
          true ->
            Pid = whereis(Target),
            Pid ! {add_pid, Ws:get(socket_pid)};
          _ ->
            Pid = spawn(gc, start, [Ws:get(socket_pid)]),
          io:format("start gc: ~p with Pid ~p~n",[Target,Pid]),
          register(Target, Pid)
        end,
        io:format("User joined the group: ~p~n",[GroNa]),
        misultin_ws:new(Ws:set({group_pid,Pid}), Ws:get(socket_pid))
    end.
