VFS.Include("LuaRules/Utilities/numberfunctions.lua") -- math.HSLtoRGB

local staticTable = {1,1,1,1} -- to reduce allocs
function GetGridColor(efficiency, drawAlpha)
	if efficiency == 0 then
		staticTable[1] = 1
		staticTable[2] = 0.25
		staticTable[3] = 1
	else
		local h
		if efficiency < 3.5 then
			h = 190 -- 5760 / (3.5 + 2)^2
		else
			h = 5760 / (efficiency + 2)^2
		end
		staticTable[1], staticTable[2], staticTable[3] = math.HSLtoRGB(h / 255, 1, 0.5)
	end

	staticTable[4] = drawAlpha

	return staticTable
end

return GetGridColor
