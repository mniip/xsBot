local function check(network,sender,_,recipient,text)
	if network==config.tty.channel[1] and recipient==config.tty.channel[2] then
		local file=io.open(".in","w")
		file:write(((text.."\n"):gsub("%^(.)",function(a)return a=="\n" and "" or (a=="^" and a or string.char(a:byte()%32))end)))
		file:close()
	end
end
local function read()
	local f=io.open".out"
	local s=f:read"*a"
	f:close()
	f=io.open(".out","w")
	f:write()
	f:close()
	if s then
		for l in s:gmatch"[^\r\n]+" do
			privmsg(config.tty.channel[1],config.tty.channel[2],(l:gsub("[^ -\255]",function(a)return a=="\t" and "        " or "^"..string.char(a:byte()+64)end)))
		end
	end
end
local function load()
	os.execute"rm -f .in .out\nmkfifo .in\ntouch .out"
	os.execute"(while [ -e .in ];do cat .in;done)|(while [ -e .in ];do ssh -t -t localhost;done)|(while [ -e .in ];do cat>>.out;done) &"
	table.insert(events,read)
	on.privmsg=on.privmsg+check
end
local function unload()
	os.execute"rm -f .in .out"
	for i,v in ipairs(events) do
		if v==read then
			table.remove(events,i)
			break
		end
	end
	on.privmsg=on.privmsg/check
end
return load,unload
