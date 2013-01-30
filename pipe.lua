socket=require"socket"
pipe={}
function startpipeserv(port)
	pipe.port=port
	local c=socket.tcp()
	assert(c:bind("*",port))
	c:listen(2)
	c:settimeout(0)
	pipe.socket=c
end
function checkpipe()
	if pipe.socket then
		local client,err=pipe.socket:accept()
		if client then
			client:settimeout(100)
			local s=client:receive"*l"
			print"pipe:"
			if s then
				print(s)
				local func=loadstring(s)
				if func then
					pcall(func)
				end
			end
			client:close()
		end
	end
end
