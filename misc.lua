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
