on={}
on["001"]=function(network)
	for _,command in pairs(config.servers[network].autorun) do
		send(network,command)
	end
	for channel in pairs(config.servers[network].channels) do
		send(network,"JOIN",channel)
	end
end
function on.error(network)
	servers[network].socket:close()
	servers[network]=nil
end
function on.nick(network,sender,_,nick)
	if lower(splitnick(sender))==lower(servers[network].nick) then
		servers[network].nick=nick
	end
end
function on.ping(network,_,_,data)
	send(network,"PONG",data)
end
function on.privmsg(network,sender,_,recipient,text)
	for _,v in ipairs(config.servers[network].ignore) do
		if sender:match(v) then
			return
		end
	end
	if lower(recipient)==lower(servers[network].nick) then
		recipient=splitnick(sender)
	end
	if text:match"^\1.*\1$" then
		local cmd,params=text:match"^\1(%S*)%s*(.*)\1$"
		if cmd then
			local reply
			cmd=cmd:upper()
			if cmd=="PING" then
				reply="PING "..params
			elseif cmd=="VERSION" then
				reply="VERSION xsBot http://github.com/mniip/xsBot"
			end
			if reply then
				send(network,"NOTICE",splitnick(sender),"\1"..reply.."\1")
			end
		end
	end
	if text:match("^"..config.char) then
		local code=text:match("^"..config.char.."(.*)")
		local command,params=code:match"^(%S*)%s*(.-)%s*$"
		local param=params
		local args={}
		while #params>0 do
			local finish
			if params:sub(1,1)=="`" then
				params=params:sub(2)
				finish=(params:match"`()" or #params+1)-1
			else
				finish=(params:match"^%S*()" or #params)-1
			end
			table.insert(args,(params:sub(1,finish):gsub("`$","")))
			params=params:sub(finish+1):match"^%s*(.*)"
		end
		command=command:lower()
		if commands[command] then
			if allowed(network,recipient,sender,command) then
				local succ,ret=pcall(commands[command],{params=param,network=network,channel=recipient,sender=sender,nick=splitnick(sender),command=command},unpack(args))
				if succ then
					if ret then
						privmsg(network,recipient,("%s: %s"):format(splitnick(sender),tostring(ret):gsub("%s+"," ")))
					end
				else
					privmsg(network,recipient,("%s: [%s]: %s"):format(splitnick(sender),text,ret))
				end
			else
				privmsg(network,recipient,splitnick(sender)..": Permission denied")
			end
		else
			privmsg(network,recipient,splitnick(sender)..": No such command")
		end
	end
end
function on.kick(network,_,_,channel,recipient)
	if lower(recipient)==lower(servers[network].nick) then
		send(network,"JOIN",channel)
	end
end
