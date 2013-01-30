#!/usr/bin/lua
json=require"json"
dofile"config.lua"
dofile"pipe.lua"
servers={}
dofile"misc.lua"
dofile"commands.lua"
dofile"handlers.lua"
dofile"xsbot.lua"
for k,v in pairs(config.servers) do
	connect(k,v.server,v.port)
end
if config.pipe then
	startpipeserv(config.pipe.port)
end
loop(config.sleep)
