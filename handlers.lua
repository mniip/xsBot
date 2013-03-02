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
	server[network].socket:close()
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
	if lower(recipient)==lower(servers[network].nick) then
		recipient=splitnick(sender)
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
						send(network,"PRIVMSG",recipient,("%s: %s"):format(splitnick(sender),tostring(ret):gsub("%s+"," ")))
					end
				else
					send(network,"PRIVMSG",recipient,("%s: [%s]: %s"):format(splitnick(sender),text,ret))
				end
			else
				send(network,"PRIVMSG",recipient,"Permission denied")
			end
		else
			send(network,"PRIVMSG",recipient,"No such command")
		end
	end
end
