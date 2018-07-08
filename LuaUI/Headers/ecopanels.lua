local min = math.min
local floor = math.floor
local rep = string.rep
local abs = math.abs

local FLOW_PER_ARROW = 5
local MAX_ARROWS = 6

VFS.Include("LuaUI/Headers/colors.h.lua") -- for WhiteStr

local function PrettyFormat(input, positiveColourStr, negativeColourStr)
	--[[ FIXME: would ideally replace the ones in the respective widgets,
	but passing the colors would be a massive pain in the ass. Maybe remove
	the colorblind strings since there is already a colorblind shader. ]]

	local leadingString = positiveColourStr .. "+"
	if input < 0 then
		leadingString = negativeColourStr .. "-"
	end
	input = abs(input)

	if input < 0.05 then
		return WhiteStr .. "±0.0"
	elseif input < 100 then
		return leadingString .. ("%.1f"):format(input) .. WhiteStr
	elseif input < 10^3 - 0.5 then
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^4 then
		return leadingString .. ("%.2f"):format(input/1000) .. "k" .. WhiteStr
	elseif input < 10^5 then
		return leadingString .. ("%.1f"):format(input/1000) .. "k" .. WhiteStr
	else
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	end
end

local function GetFlowStr (flow, asArrows, posColor, negColor)
	if not asArrows then
		return PrettyFormat(flow, posColor, negColor)
	elseif flow > 0 then
		return posColor .. rep('>', min(floor( flow / FLOW_PER_ARROW + 0.5), MAX_ARROWS))
	else
		return negColor .. rep('<', min(floor(-flow / FLOW_PER_ARROW + 0.5), MAX_ARROWS))
	end
end

return GetFlowStr, PrettyFormat
