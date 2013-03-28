commands=commands or {}

function commands.load(query,file)
	checktype({"string"},{file})
	if not file:find"%.[^/]+$" then
		file=file..".lua"
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
	for m in ipairs(unload_mod) do
		commands.rmmod(m)
	end
	send(query.network,"PRIVMSG",query.channel,("Rebooting"))
	for network in pairs(servers) do
		disconnect(network,query.nick.." issued a reboot from "..query.channel.."@"..query.network)
	end
	if config.pipe then
		stoppipeserv()
	end
	socket.sleep(2)
	os.execute("kill "..p.." && exec "..s.." <&0")
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

function commands.dns(query,address,verbose)
	checktype({"string"},{address})
	if address:match"%d+%.%d+%.%d+%.%d+" then
		if verbose=="verbose" then
			local data=assert(io.popen("host '"..address:gsub("[\\']","\\%1").."'")):read"*a"or""
			return data:gsub("%S+ domain name pointer ",address.." PTR "):gsub("\n"," || ")
		else
			return socket.dns.tohostname(query.params) or "error"
		end
	else
		if verbose=="verbose" then
			local data=assert(io.popen("host '"..address:gsub("[\\']","\\%1").."'")):read"*a"or""
			return data:gsub(" has address "," A "):gsub(" has IPv6 address "," AAAA "):gsub(" is an alias for "," CNAME "):gsub(" mail is handled by "," MX "):gsub("\n"," || ")
		else
			return socket.dns.toip(query.params) or "error"
		end
	end
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

function commands.remind(query,time,message)
	checktype({"number","string"},{time,message})
	if tonumber(time)>3600 then
		return "I doubt i will remember it by then..."
	end
	local finish=os.time()+time
	table.insert(events,function()
		if os.time()>finish then
			send(query.network,"PRIVMSG",query.channel,query.nick..": "..message)
			return true
		end
	end)
end

function commands.help(query,func)
	if not func then
		return "Usage: help <function>"
	end
	for line in io.lines"help.txt" do
		if line:sub(1,#func+1):lower()==func:lower().."\t" then
			return ("Usage: \2%s %s\2 | %s"):format(line:match"^([^\t]*)\t([^\t]*)\t(.*)$")
		end
	end
	return "Nothing useful found"
end

function commands.insmod(query,file)
	checktype({"string"},{file})
	assert(not unload_mod[file],"Module "..file.." already loaded")
	local func=assert(loadfile("plugins/"..file..".lua"))
	local loader
	loader,unload_mod[file]=func()
	loader()
	return "Module "..file.." loaded"
end

function commands.rmmod(query,file)
	checktype({"string"},{file})
	assert(unload_mod[file],"Module "..file.." wasn't loaded")
	unload_mod[file]()
	unload_mod[file]=nil
	return "Module "..file.." unloaded"
end

function commands.upmod(query,file)
	return commands.rmmod(query,file)..". "..commands.insmod(query,file)
end

function commands.lsmods(query)
	local t={}
	for k in pairs(unload_mod) do
		table.insert(t,tostring(k))
	end
	return table.concat(t,", ")
end

function commands.isup(query,host,port)
	port=port or 80
	checktype({"string","number"},{host,port})
	local sock=socket.connect(host,tonumber(port))
	if sock then
		sock:close()
		return "Seems up"
	end
	return "Seems like down"
end

function commands.lua(query)
	local code=query.params
	local sandbox=[[
local output=""
local env={fempty=fempty,fproxy=fproxy,xpcall=xpcall,tostring=tostring,unpack=unpack,require=require,next=next,assert=assert,tonumber=tonumber,rawequal=rawequal,rawset=rawset,pcall=pcall,newproxy=newproxy,type=type,select=select,gcinfo=gcinfo,pairs=pairs,rawget=rawget,ipairs=ipairs,_VERSION=_VERSION,error=error}
env._G=env
env.string={sub=string.sub,upper=string.upper,len=string.len,gfind=string.gfind,rep=string.rep,find=string.find,match=string.match,char=string.char,dump=string.dump,gmatch=string.gmatch,reverse=string.reverse,byte=string.byte,format=string.format,gsub=string.gsub,lower=string.lower}
env.math={log=math.log,max=math.max,acos=math.acos,huge=math.huge,ldexp=math.ldexp,pi=math.pi,cos=math.cos,tanh=math.tanh,pow=math.pow,deg=math.deg,tan=math.tan,cosh=math.cosh,sinh=math.sinh,random=math.random,randomseed=math.randomseed,frexp=math.frexp,ceil=math.ceil,floor=math.floor,rad=math.rad,abs=math.abs,sqrt=math.sqrt,modf=math.modf,asin=math.asin,min=math.min,mod=math.mod,fmod=math.fmod,log10=math.log10,atan2=math.atan2,exp=math.exp,sin=math.sin,atan=math.atan}
env.coroutine={resume=coroutine.resume,yield=coroutine.yield,status=coroutine.status,wrap=coroutine.wrap,create=coroutine.create,running=coroutine.running}
env.os={date=os.date,difftime=os.difftime,time=os.time,clock=os.clock}
env.table={setn=table.setn,insert=table.insert,getn=table.getn,foreachi=table.foreachi,maxn=table.maxn,foreach=table.foreach,concat=table.concat,sort=table.sort,remove=table.remove,unpack=unpack}
env.io={}
env.io.write=function(...)
	for _,v in ipairs{...} do
		output=output..tostring(v)
	end
end
env.print=function(...)
	for _,v in ipairs{...} do
		output=output..tostring(v).." "
	end
end
env.loadstring=function(...)
	local func,err=loadstring(...)
	if func then
		setfenv(func,env)
	end
	return func,err
end
dofile"logic.lua"
local file=io.open".tmp"
local code=file:read"*a":gsub("^=","return ")
file:close()
local func,err=loadstring("return "..code)
if not func then
	func,err=loadstring(code)
end
if not func then
	print("Syntax error: "..err)
	os.exit()
end
setfenv(func,env)
local coro=coroutine.create(func)
local calls=0
debug.sethook(coro,function()if collectgarbage"count">4000 then error"Memory limit exceeded" elseif calls>100000 then error"Time limit exceeded" end calls=calls+1 end,"",100)
local returned={coroutine.resume(coro)}
collectgarbage"collect"
if returned[1] then
	table.remove(returned,1)
	output=output:gsub("[^ -\255]",".")
	if #output>200 then
		output=output:sub(1,200).."\2(...)\15"
	end
	if #output>0 then
		print("Output: "..output)
	end
	if next(returned) then
		print(unpack(returned))
	end
else
	print("Runtime error: "..tostring(returned[2]))
end]]
	local file=io.open(".sandbox.lua","w")
	file:write(sandbox)
	file:close()
	file=io.open(".tmp","w")
	file:write(code)
	file:close()
	file=io.popen"ulimit -v 10000 && ulimit -t 5 && lua .sandbox.lua 2>&1"
	local ret=file:read"*a"
	os.remove".sandbox.lua"
	os.remove".tmp"
	return ret
end

function commands.base(query,from,to,number)
	checktype({"number","number","string"},{from,to,number})
	local f,t=math.floor(tonumber(from)),math.floor(tonumber(to))
	assert(f>1 and t>1,"Base should be at least 2")
	assert(f<=1000000 and t<=1000000,"Base should be at most 1000000")
	local fd={}
	if f<37 then
		for c in number:gmatch"." do
			if c:match"[0-9]" then
				table.insert(fd,c:byte(1)-48)
			elseif c:match"[A-Za-z]" then
				table.insert(fd,c:byte(1)%32+9)
			else
				error("Character '"..c.."' (#"..#fd..") is invalid")
			end
			if fd[1]>=f then
				error("Character '"..c.."' (#"..#fd..") is invalid")
			end
		end
	else
		local a=number:gsub("%([0-9]+%)","")
		if #a~=0 then
			error("What is '"..a:sub(1,1).."' doing here?")
		end
		for g in number:gmatch"%(([0-9]+)%)" do
			table.insert(fd,tonumber(g))
			if fd[1]>=f then
				error("Group '"..g.."' (#"..#fd..") is invalid")
			end
		end
	end
	while fd[1]==0 do
		table.remove(fd,1)
	end
	local td={0}
	while #fd>0 do
		for i,v in ipairs(td) do
			td[i]=v*f
		end
		td[1]=td[1]+table.remove(fd,1)
		for i,v in ipairs(td) do
			td[i],td[i+1]=v%t,math.floor(v/t)+(td[i+1]or 0)
			if td[i+1]==0 then
				td[i+1]=nil
			end
		end
	end
	while td[#td]==0 do
		table.remove(td,#td)
	end
	if #td==0 then
		table.insert(td,0)
	end
	local o=""
	if t<37 then
		for i,v in ipairs(td) do
			if v<10 then
				o=v..o
			else
				o=string.char(v+55)..o
			end
		end
	else
		for i,v in ipairs(td) do
			o="("..v..")"..o
		end
	end
	return o
end

commands["false"]=function(query)
	local p,v,e,a,r,o,t,i,b={},{}
	a=function(v)assert(#p<1000,"Stack overflow")table.insert(p,1,v)end
	r=function()return table.remove(p,1)or error"Stack underflow"end
	local out=""
	o=function(v)out=out..v end
	b=function()io.stdin:flush()io.stdout:flush()end
	t={
		["+"]=function()a(r()+r())end,
		["-"]=function()a(-(r()-r()))end,
		["*"]=function()a(r()*r())end,
		["/"]=function()a(math.floor(1/(r()/r())))end,
		["_"]=function()a(-r())end,
		["="]=function()a(r()==r()and 1 or 0)end,
		[">"]=function()a(r()>r()and 1 or 0)end,
		["&"]=function()a((r()~=0 and r()~=0)and 1 or 0)end,
		["|"]=function()a((r()~=0 or r()~=0)and 1 or 0)end,
		["~"]=function()a(r()==0 and 1 or 0)end,
		["$"]=function()local v=r()a(v)a(v)end,
		["%"]=r,
		["\\"]=function()local v,u=r(),r()a(v)a(u)end,
		["@"]=function()local v,u,x=r(),r(),r()a(u)a(v)a(x)end,
		O=function()a(p[r()+1])end,
		[":"]=function()v[r()]=r()end,
		[";"]=function()a(v[r()])end,
		["!"]=function()e(r())end,
		["?"]=function()local v=r()if r()~=0 then e(v)end end,
		["#"]=function()local v,u=r(),r()e(u)while r()~=0 do e(v)e(u)end end,
		["."]=function()o(r())end,
		[","]=function()o(string.char(r()))end,
		B=b
	}
	local instr=0
	e=function(s)
		while #s>0 do
			instr=instr+1
			if instr+1>100000 then
				error"Time limit exceeded"
			end
			local c=s:sub(1,1)
			local n,l=2
			if c=="[" then
				l,n=s:match"(%b[])()"
				n=n or error"Unmatched ["
				a(l:sub(2,-2))
			elseif c:match"[0-9]" then
				l,n=s:match"([0-9]+)()"
				n=n or error'Unmatched "'
				a(l)
			elseif c=='"' then
				l,n=s:match'"([^"]*)"()'
				o(l)
			elseif c:match"[a-z]" then
				a(c:byte(1)-96)
			elseif c:match"%S" then
				(t[c] or error("What is '"..c.."'?"))()
			end
			s=s:sub(n)
		end
	end
	e(query.params)
	out=out:gsub("[^ -\255]",".")
	if #out>200 then
		out=out:sub(1,200).."\2(...)\15"
	end
	local st=table.concat(p," , ")
	if #st>200 then
		st=st:sub(1,200).."\2(...)\15"
	end
	return out.." \2|\15 "..st
end

function commands.mode(query,mode,...)
	setmode(query.network,query.channel,mode,...)
end
function commands.md5(query)
	local name=os.tmpname()
	local file=io.open(name,"w")
	file:write(query.params)
	file:close()
	file=io.popen("md5sum '"..name.."'")
	local hash=file:read"*l":match"^%S+"
	file:close()
	os.remove(name)
	return hash
end
function commands.takeover()
	return "foo"..nil
end
