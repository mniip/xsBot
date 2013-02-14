socket=require"socket"
dofile"pipecmd.lua"
pipe={}
function startpipeserv(port)
	pipe.port=port
	local c
	local succ,err
	while not succ do
		c=socket.tcp()
		succ,err=c:bind("localhost",port)
		print(err)
	end
	c:listen(2)
	c:settimeout(0)
	pipe.socket=c
end
function checkpipe()
	if pipe.socket then
		local client,err=pipe.socket:accept()
		if client then
			client:settimeout(1)
			local command=client:receive"*l"
			if command then
				command=command:lower()
				print(("Pipe: %s"):format(command))
				if pipecmd[command] then
					pcall(pipecmd[command],command,client)
				end
			end
			client:close()
		elseif err~="timeout" then
			print(("Pipe: %s"):format(err))
		end
	end
end
