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
	return level>=(config.level[lower(command)] or 1/0)
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
	c:settimeout(1)
	if not c:connect(url:match"^[^/]+",80) then
		return
	end
	c:send("GET "..url:match"/.*$".." HTTP/1.1\nConnection: close\nHost: "..url:match"^[^/]+".."\n\n")
	local d=c:receive"*a"
	return d and d:match"\n\r?\n\r?(.*)$"
end
function _break()
	loop_level=loop_level-1
end
function whois(network,nick)
	local hostname
	send(network,"WHO",nick)
	loop(function(_,_,num,_,_,ident,host,_,nick)
		if num=="352" then
			hostname=nick.."!"..ident.."@"..host
			return false
		end
	end)
	return hostname
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
	return tonumber(assert(io.popen"date +%s.%N"):read"*a")
end
do
	local l=setmetatable({},{__mode='k'})
	function fappend(f1,f2)
		local f=function(...)f1(...)f2(...)end
		l[f]={f1,f2}
		return f
	end
	function fdivide(p,f)
		local function fd(p,f)
			if p==f then
				return
			end
			local m=l[p]
			if m then
				local nf1=fd(m[1],f)
				local nf2=fd(m[2],f)
				if nf1 then
					if nf2 then
						return fappend(nf1,nf2)
					else
						return nf1
					end
				else
					return nf2
				end
			else
				return p
			end
		end
		return fd(p,f)or function()end
	end
	local last_used={}
	local function timedsend(network,channel,text)
		last_used[network]=last_used[network]or nstime()-1
		while last_used[network]>nstime()-0.33 do
			socket.sleep(0.11)
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
