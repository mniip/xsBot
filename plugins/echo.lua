local l,n={},{}
local function check(network,sender,_,recipient,text)
	local cec=config.echo.channel
	local i=(network==cec[1][1] and recipient==cec[1][2] and 2)or(network==cec[2][1] and recipient==cec[2][2] and 1)
	if i then
		l[sender]=l[sender]or os.time()
		if l[sender]==os.time() then
			n[sender]=(n[sender]or 0)+1
		else
			l[sender],n[sender]=os.time(),0
		end
		if n[sender]>2 then
			send(network,"NOTICE",sender,"Your message to "..recipient.." was throttled")
		else
			privmsg(config.echo.channel[i][1],config.echo.channel[i][2],recipient.."@"..network..": <"..splitnick(sender).."> "..text)
		end
	end
end
local function join(network,sender,_,channel)
	local cec=config.echo.channel
	local i=(network==cec[1][1] and channel==cec[1][2] and 2)or(network==cec[2][1] and channel==cec[2][2] and 1)
	if i then
		privmsg(config.echo.channel[i][1],config.echo.channel[i][2],channel.."@"..network..": "..splitnick(sender).." has joined")
	end
end
local function part(network,sender,_,msg)
	local cec=config.echo.channel
	local i=(network==cec[1][1] and channel==cec[1][2] and 2)or(network==cec[2][1] and channel==cec[2][2] and 1)
	if i then
		privmsg(config.echo.channel[i][1],config.echo.channel[i][2],channel.."@"..network..": "..splitnick(sender).." has left: "..msg)
	end
end
local function load()
	on.privmsg=on.privmsg+check
end
local function unload()
	on.privmsg=on.privmsg/check
end
return load,unload
