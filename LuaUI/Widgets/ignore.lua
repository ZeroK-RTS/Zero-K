function widget:GetInfo()
	return {
		name	= "In-game Ignore",
		desc	= "Adds ignore/unignore commands.",
		author	= "Shaman",
		date	= "8-1-2016",
		license	= "PD",
		layer	= 0,
		enabled	= true,
	}
end

local function ProcessString(str)
	local strtbl = {}
	for w in string.gmatch(str, "%S+") do
		strtbl[#strtbl+1] = w
	end
	return strtbl
end


function widget:SetConfigData(data)
	data = data or {}
	for ignoree,_ in pairs(data) do
		widgetHandler:Ignore(ignoree)
	end
end
