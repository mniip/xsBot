socket=require"socket"
pipecmd={}
function pipecmd.msg(_,client)
	local network,channel,message=client:receive"*l",client:receive"*l",client:receive"*l"
	if network and channel and message then
		privmsg(network,channel,message)
	end
end
function pipecmd.stat(_,client)
	local network=client:receive"*l"
	if network then
		send(network,"LUSERS")
		local t=os.time()+1
		loop(function(network,raw,sender,num,recp,...)
			if os.time()>t then
				return false
			end
			if sender then
				if num>"250" and num<"267" then
					client:send(table.concat({...}," ").."\n")
					if num=="266" then
						return false
					else
						return true
					end
				end
			end
		end)
		client:send":\n"
		send(network,"MAP")
		t=os.time()+1
		loop(function(network,raw,sender,num,recp,data)
			if os.time()>t then
				return false
			end
			if sender then
				if num=="006" then
					client:send(data.."\n")
					return true
				end
				if num=="007" then
					return false
				end
			end
		end)
	end
end
function pipecmd.git(_,client)
	local data=client:receive"*a"
	local json=require"json"
	for _,commit in ipairs(json.decode(data).commits) do
		for _,channel in ipairs(config.git.channels) do
			privmsg(channel[1],channel[2],("Git commit by %s (%s pushed): %s [*%s][+%s][-%s]"):format(commit.author.name,commit.committer.name,commit.message,table.concat(commit.modified,"][*"),table.concat(commit.added,"][+"),table.concat(commit.removed,"][-")))
		end
	end
	local oldtime={}
	for file,time in io.popen"stat -c %n:%Y *":read"*a":gmatch"(^[^:]*):(.*)$" do
		oldtime[file]=time
	end
	os.execute"git fetch origin -q && git merge origin/master -q"
	local files={}
	for file,time in io.popen"stat -c %n:%Y *":read"*a":gmatch"(^[^:]*):(.*)$" do
		if time>oldtime[file]or 0 then
			files[file]=true
		end
	end
	if files["init.lua"] then
		log"init changed: rebooting"
		commands.reboot({nick="git-reload",channel="",network="github"})
	end
	for k in pairs(files) do
		if k:match"%.lua$" then
			log(k.." changed: reloading")
			commands.load(k:match"^(.*)%.lua$")
		end
	end
	if files["xsbot.lua"] then
		log"loop possibly changed: breaking"
		_break()
	end
end
