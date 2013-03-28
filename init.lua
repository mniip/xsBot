#!/usr/bin/lua
json=require"json"
require"logic"
servers={}
unload_mod={}
include"config.lua"
include"pipe.lua"
include"misc.lua"
include"commands.lua"
include"handlers.lua"
include"xsbot.lua"
for k,v in pairs(config.servers) do
	connect(k,v.server,v.port)
end
if config.pipe then
	startpipeserv(config.pipe.port)
end
for _,v in ipairs(config.autoload) do
	commands.insmod(nil,v)
end
while true do
	loop_level=1
	loop(function()end)
end
