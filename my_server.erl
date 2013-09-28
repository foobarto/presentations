-module(my_server).
-export([listen/2, simple_server/1, send/1]).

% defining TCP_OPTIONS macro
-define(TCP_OPTIONS, [binary, {packet, 0}, 
		{active, false}, {reuseaddr, true}]).

start_registry() ->
	io:format("starting registry~n"),
	register(socket_mgr, self()),
	registry([]).

registry(Sockets) ->
	io:format("registry listening~n"),
	receive
		{connected, Pid, Socket} ->
			io:format("new connection, Pid ~p~n", [Pid]),
			erlang:monitor(process, Pid),	
			registry([{Pid, Socket}|Sockets]);
		{'DOWN', _Ref, process, DeadPid, _Reason} ->
			io:format("connection lost, DeadPid ~p~n", [DeadPid]),
			registry(proplists:delete(DeadPid, Sockets));
		{send, Msg} ->
			lists:map(
				fun({_Pid, Socket}) -> gen_tcp:send(Socket, Msg) end,
				Sockets),
			registry(Sockets);
		_ -> registry(Sockets)
	end.

send(Msg) ->
	io:format("Sending Msg ~p~n", [Msg]),
	lists:map(fun(Node) -> {socket_mgr, Node} ! {send, Msg} end, [node() | nodes()]).

listen(Port, Handler) ->
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    io:format("spawning registry~n"),
    spawn(fun() -> start_registry() end),
    io:format("starting connection accept loop~n"),
    accept(LSocket, Handler).

accept(LSocket, Handler) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    Pid = spawn(fun() -> Handler(Socket) end),
    socket_mgr ! {connected, Pid, Socket},
    accept(LSocket, Handler).

simple_server(Socket) ->
	io:format("echo server started~n"),
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
        	io:format("Data received ~p~n", [Data]),
            send(Data),
            simple_server(Socket);
        {error, closed} ->
        	io:format("echo connection closed"),
            ok
    end.
% savvy?