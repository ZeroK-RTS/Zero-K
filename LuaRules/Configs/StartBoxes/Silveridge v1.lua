local boxFuncs = VFS.Include("LuaRules/Configs/StartBoxes/helpers.lua")

if math.random() < 0.5 then
	return boxFuncs.EastWestBoxes(2100)
end
return boxFuncs.NorthSouthBoxes(1325)
