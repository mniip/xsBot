local function check(network,sender,_,recipient,text)
	text=text:lower()
	local words={}
	for word in text:gmatch"%w+" do
		table.insert(words,word:lower())
	end
	if words[1]==servers[network].nick:lower() then
		table.remove(words,1)
	end
	if words[#words]==servers[network].nick:lower() then
		table.remove(words)
	end
	local hsentences={hi_all=true,bye_all=false,ohai_all=true,hello_there=true,hi_there=true,ohai_there=true,hello_there=true,i_gtg=false,gotta_go=false,gtg=false,got_to_go=false,ohaider=true,goodbye_all=false,hi=true,hello=true}
	local sentence=table.concat(words,"_")
	if hsentences[sentence]~=nil then
		privmsg(network,recipient,(hsentences[sentence]and"Hi"or"Bye")..", "..splitnick(sender))
	end
end
local function load()
	on.privmsg=on.privmsg+check
end
local function unload()
	on.privmsg=on.privmsg/check
end
return load,unload
