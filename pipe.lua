socket=require"socket"
include"pipecmd.lua"
pipe={}
function startpipeserv(port)
	pipe.port=port
	local c
	local succ,err
	while not succ do
		c=socket.tcp()
		succ,err=c:bind("localhost",port)
		if not succ then
			socket.sleep(1)
		end
	end
	c:listen(2)
	c:settimeout(0)
	pipe.socket=c
end
function stoppipeserv()
	if pipe then
		pipe.socket:close()
	end
end
function checkpipe()
	if pipe.socket then
		local client,err=pipe.socket:accept()
		if client then
			client:settimeout(100)
			local command=client:receive"*l"
			if command then
				command=command:lower()
				print(("Pipe: %s"):format(command))
				if pipecmd[command] then
					local succ,err=pcall(pipecmd[command],command,client)
					if not succ then
						log(err)
					end
				end
			end
			client:close()
		elseif err~="timeout" then
			print(("Pipe: %s"):format(err))
		end
	end
end
