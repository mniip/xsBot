socket=require"socket"
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
	servers[network].socket:send(s:sub(1,512))
end
function log(s)
	print(s)
end
function connect(network)
	local address,port=config.servers[network].server,config.servers[network].port
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
events={}
function loop(func)
	loop_level=loop_level+1
	local l=loop_level
	while loop_level==l do
		for i=#events,1,-1 do
			if select(2,pcall(events[i])) then
				table.remove(events,i)
			end
		end
		for k,v in pairs(servers) do
			local c=v.socket
			local s,err=c:receive"*l"
			if err then
					if err~="timeout" then
					disconnect(c)
					connect(k)
				end
			else
				local succ,err=pcall(handle,k,s,func)
				if not succ then
					log(err)
				end
				if err==false then
					loop_level=l-1
					return
				end
			end
		end
		checkpipe()
		socket.sleep(config.sleep)
	end
	loop_level=l-1
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
function handle(network,s,func)
	local t=parse(s)
	local _,r=pcall(func,network,s,unpack(t))
	if r==false then
		return false
	elseif r==nil then
		log(network.."> "..s)
	end
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
		servers[network].nick=config.servers[network].nick
	end
end
