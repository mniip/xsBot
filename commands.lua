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
