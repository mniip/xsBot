function splitnick(host)
	return host:match"^:?([^!]*)"
end
function lower(s)
	return s:lower():gsub("[{}|~]",{["{"]="[",["}"]="]",["|"]="\\",["~"]="^"})
end
function allowed(network,channel,host,command)
	local level,found=0
	for name,hostmasks in pairs(config.servers[network].hosts) do
		for _,hostmask in ipairs(hostmasks) do
			if lower(host):match(hostmask) then
				level=config.servers[network].channels[channel] and config.servers[network].channels[channel].access[name] or config.servers[network].access[name] or config.access[name]
				found=true
				break
			end
		end
		if found then
			break
		end
	end
	return (level or 0)>=(config.level[lower(command)] or 1/0)
end
function tolua(...)
	local s=""
	local t={...}
	for i,v in ipairs(t) do
		if type(v)=="table" then
			s=s.." {?}"
		elseif type(v)=="function" then
			s=s.." function"
		elseif type(v)=="string" then
			s=s..' "'..v..'"'
		else
			s=s.." "..tostring(v)
		end
		if i~=#t then
			s=s..","
		end
	end
	return s
end
function http(url)
	local c=socket.tcp()
	c:settimeout(3)
	if not c:connect(url:match"^[^/]+",80) then
		return
	end
	c:send("GET "..url:match"/.*$".." HTTP/1.1\nConnection: close\nHost: "..url:match"^[^/]+".."\n\n")
	local d=c:receive"*a"
	if not d then
		return
	end
	local o=d:match"\r?\n\r?\n(.*)$"
	if d:find"Transfer%-Encoding: chunked" then
		local s=""
		while assert(#s<100000,"LOL") do
			local n
			n,o=o:match"^\r?\n?\r?([a-fA-F0-9]+)\r?\n\r?(.*)$"
			n=tonumber("0x"..n)
			if n==0 then
				break
			end
			s,o=s..o:sub(1,n),o:sub(n+1)
		end
		return s
	end
	return o
end
function _break()
	loop_level=loop_level-1
end
function checktype(types,values)
	for i,v in ipairs(types) do
		if values[i]==nil then
			error("a "..v.." expected!")
		elseif v=="number" then
			if not tonumber(values[i]) then
				error('"'..tostring(values[i])..'" doesnt look like a number to me')
			end
		elseif type(values[i])~=v then
			error("a "..v.." expected, got "..type(values[i]))
		end
	end
end
function nstime()
	local file=assert(io.popen"date +%s.%N")
	local time=assert(tonumber(file:read"*a"))
	file:close()
	return time
end
do
	local last_used={}
	local function timedsend(network,channel,text)
		last_used[network]=last_used[network]or nstime()-1
		while last_used[network]>nstime()-config.servers[network].throttle do
			socket.sleep(config.servers[network].throttle/2)
		end
		send(network,"PRIVMSG",channel,text)
		last_used[network]=nstime()
	end
	function privmsg(network,channel,text)
		for i=1,#text,400 do
			timedsend(network,channel,text:sub(i,i+399))
		end
	end
end
function setmode(network,channel,mode,...)
	local args={...}
	local last="-"
	mode=mode:gsub("([+-])(.)",function(a,b)if #a>0 then last=a end return last..b end)
	for substr in mode:gmatch"[+-]?.[+-]?.?[+-]?.?[+-]?.?" do
		local subarg={}
		for i=1,4 do
			if #args>0 then
				table.insert(subarg,table.remove(args,1))
			end
		end
		send(network,"MODE",channel,substr,unpack(subarg))
	end
end
function whois(network,who)
	local users={}
	send(network,"WHO",who)
	loop(function(net,raw,sender,num,_,_,ident,host,server,nick,_,rname)
		if net==network then
			if num=="352" then
				table.insert(users,{ident=ident,host=host,server=server,nick=nick,rname=rname})
				return true
			elseif num=="315" then
				return false
			end
		end
	end)
	return users
end
