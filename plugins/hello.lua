local function check(network,sender,_,recipient,text)
	text=text:lower()
	local word1,word2=text:match"^%s*(%w+)[, ]+(%w+)%W*$"
	if word1 then
		if (word1=="hi" or word1=="hello" or word1=="ohai")and(word2=="all" or word2=="there" or word2==servers[network].nick:lower()) then
			privmsg(network,recipient,word1..", "..splitnick(sender))
		end
	end
end
local function load()
	on.privmsg=fappend(on.privmsg,check)
end
local function unload()
	on.privmsg=fdivide(on.privmsg,check)
end
return load,unload