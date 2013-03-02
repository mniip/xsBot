local sed_data={}
local function check(network,sender,_,recipient,text)
	local search,replace
	if sed_data[recipient] and sed_data[recipient][splitnick(sender)] then
		search,replace=text:match"^s/([^/]*)/([^/]*)/$"
		if search then
			privmsg(network,recipient,"<"..splitnick(sender).."> "..sed_data[recipient][splitnick(sender)]:gsub(search,replace))
		end
	end
	if not search then
		sed_data[recipient]=sed_data[recipient]or{}
		sed_data[recipient][splitnick(sender)]=text
	end
end
local function load()
	on.privmsg=fappend(on.privmsg,check)
end
local function unload()
	on.privmsg=fdivide(on.privmsg,check)
end
return load,unload
