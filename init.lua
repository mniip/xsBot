#!/usr/bin/lua
json=require"json"
dofile"xsbot.lua"
dofile"config.lua"
for k,v in pairs(config.servers) do
	connect(k,v.server,v.port)
end
if config.pipe then
	startpipeserv(config.pipe.port)
end
loop(config.sleep)
