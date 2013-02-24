socket=require"socket"
pipecmd={}
function pipecmd.msg(_,client)
	local network,channel,message=client:receive"*l",client:receive"*l",client:receive"*l"
	if network and channel and message then
		send(network,"PRIVMSG",channel,message)
	end
end
function pipecmd.stat(_,client)
	local network=client:receive"*l"
	if network then
		send(network,"LUSERS")
		local t=os.time()+1
		while os.time()<=t do
			local s=servers[network].socket:receive()
			if s then
				local succ,err=pcall(handle,network,s)
				if not succ then
					log(err)
				end
				local sender,num,recp,data=s:match"^:(%S+)%s+(%d+)%s+(%S+)%s+(.*)$"
				if sender then
					if num>"250" and num<"267" then
						client:send(data.."\n")
					end
					if num=="266" then
						break
					end
				end
			end
		end
		client:send":\n"
		send(network,"MAP")
		t=os.time()+1
		while os.time()<=t do
			local s=servers[network].socket:receive()
			if s then
				local succ,err=pcall(handle,network,s)
				if not succ then
					log(err)
				end
				local sender,num,recp,data=s:match"^:(%S+)%s+(%d+)%s+(%S+)%s+(.*)$"
				if sender then
					if num=="006" then
						client:send(data.."\n")
					end
					if num=="007" then
						break
					end
				end
			end
		end
	end
end
function pipecmd.git(_,client)
	local data=client:receive"*a"
	local json=require"json"
	for _,commit in ipairs(json.decode(data).commits) do
		send("freenode","PRIVMSG","#powder-bots",("Git commit by %s (%s pushed): %s [*%s][+%s][-%s]"):format(commit.author.name,commit.committer.name,commit.message,table.concat(commit.modified,"][*"),table.concat(commit.added,"][+"),table.concat(commit.removed,"][-")))
	end
end
