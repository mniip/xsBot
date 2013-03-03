local function check(network,sender,_,recipient,text)
	if network==config.tty.channel[1] and recipient==config.tty.channel[2] then
		local file=assert(io.popen("("..text..") 2>&1"))
		local str=file:read"*a" or ""
		file:close()
		for line in str:gmatch"[^\n]+" do
			privmsg(network,recipient,"tty> "..line:gsub("[^ -\255]",function(a)return "^"..string.char(a:byte()+64)end))
		end
	end
end
local function load()
	on.privmsg=fappend(on.privmsg,check)
end
local function unload()
	on.privmsg=fdivide(on.privmsg,check)
end
return load,unload
