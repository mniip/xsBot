local function getlocals(d)
	local function depth()
		i=1
		while debug.getinfo(i) do
			i=i+1
		end
		return i-1 --minus itself
	end
	local lvl,num={},{} --collect addresses of locals
	local i=d or 2
	while debug.getinfo(i) do
		local j=1
		while 1 do
			local k=debug.getlocal(i,j)
			if k==nil then
				break
			end
			lvl[k]=lvl[k] or i-depth()
			num[k]=num[k] or j --botommost shouldnt override topmost
			j=j+1
		end
		i=i+1
	end
	return setmetatable({},{__index=function(_,k)
		return lvl[k] and select(2,debug.getlocal(lvl[k]+depth(),num[k]))
	end,
	__newindex=function(_,k,v)
		if v and lvl[k] then --we cannot remove or add a local
			debug.setlocal(lvl[k]+depth(),num[k],v)
		end
	end})
end
function include(file)
	local f=assert(loadfile(file))
	local l=getlocals(3)
	setfenv(f,setmetatable({},{__index=function(_,k)local v=l[k] return v==nil and _G[k] or v end,__newindex=function(_,k,v)if l[k]==nil then _G[k]=v else l[k]=v end end}))
	f()
end
local l=setmetatable({},{__mode='k'})
local function fappend(f1,f2)
	local f=function(...)f1(...)f2(...)end
	l[f]={f1,f2}
	return f
end
local function fdivide(p,f)
	local function fd(p,f)
		if p==f then
			return
		end
		local m=l[p]
		if m then
			local nf1=fd(m[1],f)
			local nf2=fd(m[2],f)
			if nf1 then
				if nf2 then
					return fappend(nf1,nf2)
				else
					return nf1
				end
			else
				return nf2
			end
		else
			return p
		end
	end
	return fd(p,f)or function()end
end
local function flen(f)
	return l[f] and 2 or 1
end
local function fseparate(f,n)
	assert(n==1 or n==2)
	local p=l[f]
	if p then
		return p[n]
	else
		return n==1 and f or function()end
	end
end
debug.setmetatable(function()end,{__add=fappend,__div=fdivide,__len=flen,__pow=fseparate})
