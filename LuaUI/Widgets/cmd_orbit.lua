function widget:GetInfo()
	return {
		name      = "Orbit Command",
		desc      = "Captures area guard commands and turns them into orbit commands (circle around a unit)",
		author    = "Google Frog",
		date      = "11 August 2015",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetSelectedUnits = Spring.GetSelectedUnits
local spWorldToScreenCoords = Spring.WorldToScreenCoords
local spTraceScreenRay = Spring.TraceScreenRay

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local FACING_SIZE = math.pi*2/7 -- size of the directional facing

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local function GiveFacingOrder(targetID, cx, cz, radius, options)
	local mx, my = Spring.GetMouseState()
	local _, pos = spTraceScreenRay(mx, my, true)
	if not pos then
		return
	end
	
	local facing = -Spring.GetHeadingFromVector(pos[1] - cx, pos[3] - cz)/2^15*math.pi + math.pi*9/2
	local selUnits = spGetSelectedUnits()
	
	local unitCount = #selUnits
	
	if unitCount == 0 then
		return
	end
	
	if options.ctrl then
		facing = facing + Spring.GetUnitHeading(targetID)/2^15*math.pi
	end
	
	if unitCount == 1 then
		Spring.GiveOrderToUnit(selUnits[1], CMD_ORBIT, {targetID, radius, facing}, options)
	else
		unitCount = unitCount - 1
		for i = 1, #selUnits do
			local offset = (2*(i-1)/unitCount - 1)*FACING_SIZE
			Spring.GiveOrderToUnit(selUnits[i], CMD_ORBIT, {targetID, radius, facing + offset}, options)
		end
	end
	
	options.shift = true
	spGiveOrderToUnitArray(selUnits, CMD_ORBIT_DRAW, {targetID}, options)
	
	return true
end

function widget:CommandNotify(cmdID, params, options)
	if (cmdID == CMD_AREA_GUARD) and (#params == 4) then
		local cx, cy, cz = params[1], params[2], params[3]
		local pressX, pressY = spWorldToScreenCoords(cx, cy, cz)
		local cType, targetID = spTraceScreenRay(pressX, pressY)
		
		if (cType == "unit") then
			if options.alt and GiveFacingOrder(targetID, cx, cz, params[4], options) then
				return true
			end
			
			local selUnits = spGetSelectedUnits()
			spGiveOrderToUnitArray(selUnits, CMD_ORBIT, {targetID, params[4], -1}, options)
			options.shift = true
			spGiveOrderToUnitArray(selUnits, CMD_ORBIT_DRAW, {targetID}, options)
			return true
		end
	end
end
