local function check(network,sender,_,recipient,text)
	if text:match"^~%d" then
		local id=text:match"^~(%d+)"
		privmsg(network,recipient,commands.ptsave(nil,id))
	end
end
local function load()
	function commands.ptsave(query,id)
		checktype({"number"},{id})
		local id=tonumber(id)
		local data=http("powdertoy.co.uk/Browse/View.json?ID="..id)
		if data then
			local j=json.decode(data:match"{.*$")
			return ("Save %d is \"%s\" by %s; published on %s; has %d-%d=%d votes; http://tpt.io/~%d"):format(j.ID,j.Name,j.Username,os.date("%d.%m.%Y at %H:%M:%S",j.Date),j.ScoreUp,j.ScoreDown,j.Score,j.ID)
		else
			return "Save doesnt exist"
		end
	end	
	on.privmsg=fappend(on.privmsg,check)
end
local function unload()
	commands.ptsave=nil
	on.privmsg=fdivide(on.privmsg,check)
end
return load,unload
