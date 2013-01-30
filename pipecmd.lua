socket=require"socket"
pipecmd={}
function pipecmd.msg(_,client)
	local network,channel,message=client:receive"*l",client:receive"*l",client:receive"*l"
	if network and channel and message then
		send(network,"PRIVMSG",channel,message)
	end
end
