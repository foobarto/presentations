defmodule MyServer do
	def simple_server(socket) do
		case :gen_tcp.recv(socket, 0) do
			{:ok, data} ->
            	:my_server.send(data)
            	simple_server(socket)
        	{:error, :closed} ->
            	:ok
		end	
	end

	def listen(port, handler) do
		:my_server.listen(port, handler)
	end	

	def simple_listen(port) do
		listen(port, fn socket -> simple_server(socket) end)
	end
end