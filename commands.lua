commands={}
function commands.load(query)
	local file=query.params
	if not query.params:find"%.[^/]+$" then
		file=query.params..".lua"
	end
	local succ,err=pcall(dofile,file)
	if succ then
		return file.." loaded successfully"
	else
		error(err,2)
	end
end
function commands.reboot(query)
	stoppipeserv()
	local p=io.open"/proc/self/stat":read"*a":match"%d+"
	local s,m="",1
	while arg[m-1] do m=m-1 end
	local i=m
	while arg[i] do
		s=s..' "'..arg[i]..'"'
		i=i+1
	end
	log"reloading"
	send(query.network,"PRIVMSG",query.channel,("Killing %s; Running `%s`"):format(p,s))
	for network in pairs(servers) do
		disconnect(network)
	end
	socket.sleep(2)
	os.execute("kill "..p.." &&"..s)
end
commands["%"]=function(query)
	local func,err=loadstring(query.params)
	if func then
		local ret={pcall(func)}
		local succ=ret[1]
		return tolua(select(2,unpack(ret)))
	else
		error(err,2)
	end
end
commands[""]=function(query)
	local f=io.open(".tmp","w")
	f:write(query.params)
	f:close()
	local sh=io.popen"ulimit -v 10000;ulimit -t 5;systrace -t lua .tmp 2>&1"
	local s=sh and sh:read"*a" or ""
	return s:gsub("\n"," | ")
end
function commands.dns(query)
	return socket.dns.toip(query.params) or "idfk"
end
function commands.list(query)
	local t={}
	for k in pairs(commands) do
		local s='"'..k..'"'
		if allowed(query.network,query.channel,query.sender,k) then
			s="\31"..s.."\31"
		end
		table.insert(t,s)
	end
	return table.concat(t,", ")
end
function commands.ping()
	return ({"Could not resolve host","Timeout exceeded the limit"})[math.random(1,2)]
end
function commands.echo(query)
	send(query.network,"PRIVMSG",query.channel,"\15"..query.params)
end
