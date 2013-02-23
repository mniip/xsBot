on={}
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
					send(network,"PRIVMSG",recipient,("%s: %s"):format(splitnick(sender),tostring(ret or "Result empty"):gsub("%s+"," ")))
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
	if text:match"^~%d" then
		local id=text:match"^~(%d+)"
		local data=http("powdertoy.co.uk/Browse/View.json?ID="..id)
		if data then
			local j=json.decode(data:match"{.*$")
			send(network,"PRIVMSG",recipient,("Save %d is \"%s\" by %s; published on %s; has %d-%d=%d votes; http://tpt.io/~%d"):format(j.ID,j.Name,j.Username,os.date("%d.%m.%Y at %H:%M:%S",j.Date),j.ScoreUp,j.ScoreDown,j.Score,j.ID))
		else
			send(network,"PRIVMSG",recipient,"Save doesnt exist")
		end
	end
end
