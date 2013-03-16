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
			privmsg(config.tty.channel[1],config.tty.channel[2],(l:gsub("[^ -\255\27]",function(a)return a=="\t" and "        " or "^"..string.char(a:byte()+64)end):gsub("\27%[([^A-Za-z]-)([A-Za-z])",
			function(r,b)
				if b=="m" then
					if r=="" then
						return "\15"
					end
					local s=""
					local lc,lb="1","1"
					for a in r:gmatch"[^;]+" do
						if a=="0" then
							s=s.."\15"
						elseif a=="1" then
							s=s.."\2"
						elseif a=="4" or a=="24" then
							s=s.."\31"
						elseif a:sub(-2,-2)=="3" then
							lc=a:sub(2,2)
							s=s.."\3"..lc..","..lb
						elseif a:sub(-2,-2)=="4" then
							lb=a:sub(2,2)
							s=s.."\3"..lc..","..lb
						end
					end
					return s
				else
					return ""
				end
			end)))
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
