socket=require"socket"
json=require"json"
servers={}
dofile"misc.lua"
dofile"commands.lua"
dofile"handlers.lua"
function send(network,...)
	local t={...}
	local s=tostring(t[1])
	for i=2,#t do
		t[i]=tostring(t[i])
		if i==#t and i~=1 and t[i]:find"%s" then
			s=s.." :"..tostring(t[i])
		else
			s=s.." "..tostring(t[i])
		end
	end
	log(network.."> "..s)
	s=s.."\n"
	servers[network].socket:send(s)
end
function log(s)
	print(s)
end
function connect(network,address,port)
	if not servers[network] then
		if network=="default" then
			log"connect: ignoring default server"
		else
			servers[network]={}
			local c=socket.tcp()
			c:connect(address,port)
			c:settimeout(0)
			servers[network].socket=c
			servers[network].address=address
			servers[network].port=port
		end
	end
end
function disconnect(network)
	if servers[network] then
		send(network,"QUIT","Disconnecting")
		servers[network].socket:close()
		servers[network]=nil
	end
end
function loop(sleep)
	while 1 do
		for k,v in pairs(servers) do
			local c=v.socket
			local s,err=c:receive"*l"
			if err then
					if err~="timeout" then
					local address,port=v.address,v.port
					disconnect(c)
					connect(k,address,port)
				end
			else
				local succ,err=pcall(handle,k,s)
				if not succ then
					log(err)
				end
			end
		end
		socket.sleep(sleep)
	end
end
function parse(s)
	local t={}
	for i,param in s:gmatch"()(%S+)" do
		if param:sub(1,1)==":" then
			if #t==0 then
				t[0]=param
			else
				table.insert(t,s:sub(i+1))
				break
			end
		else
			table.insert(t,param)
		end
	end
	return t
end
function handle(network,s)
	log(network.."> "..s)
	local t=parse(s)
	if servers[network].nick then
		if on[t[1]:lower()] then
			local succ,err=pcall(on[t[1]:lower()],network,t[0],unpack(t))
			if not succ then
				log(err)
			end
		end
	else
		send(network,"USER",config.servers[network].ident,"*","*","xsBot")
		send(network,"NICK",config.servers[network].nick)
		for channel in pairs(config.servers[network].channels) do
			send(network,"JOIN",channel)
		end
		for _,command in pairs(config.servers[network].autorun) do
			send(network,command)
		end
		servers[network].nick=config.servers[network].nick
	end
end
