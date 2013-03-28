local sed_data={}
local function check(network,sender,_,recipient,text)
	if sed_data[recipient] then
		local search,replace=text:match"^s/([^/]*)/([^/]*)/$"
		local user
		if search then
			user=splitnick(sender)
		else
			user,search,replace=text:match"^u/([^/]-)/([^/]*)/([^/]*)/$"
		end
		if user then
			local data=sed_data[recipient][user:lower()]
			if data then
				local n=0
				for s,e in data:gmatch(search) do
					n=n+1
				end
				if n>20 then
					privmsg(network,recipient,splitnick(sender)..": Your pattern matched too many times")
				else
					privmsg(network,recipient,"<"..user.."> "..data:gsub(search,replace))
				end
			end
		end
	end
	if not search then
		sed_data[recipient]=sed_data[recipient]or{}
		sed_data[recipient][splitnick(sender):lower()]=text
	end
end
local function load()
	on.privmsg=on.privmsg+check
end
local function unload()
	on.privmsg=on.privmsg/check
end
return load,unload
