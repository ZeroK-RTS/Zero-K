if not (gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
	return {
		name      = "Static Con Unsticker",
		desc      = "Ensures static constructors do not get stuck on tasks outside their build range",
		author    = "Shaman",
		date      = "2022-04-20",
		license   = "PD",
		layer     = 0,
		enabled   = true,
	}
end

local delay = 15
local debug = false

local handled = {} -- [f] = {[1] = unitID}
local buildRangesSq = {} -- [unitDefID] = buildDistance

for i = 1, #UnitDefs do
	local def = UnitDefs[i]
	if def.isBuilder and def.customParams.like_structure then
		buildRangesSq[i] = def.buildDistance^2
	end
end

-- Speedups --
local CMD_INSERT = CMD.INSERT
local CMD_REPAIR = CMD.REPAIR
local CMD_RECLAIM = CMD.RECLAIM
local CMD_RESURRECT = CMD.RESURRECT
local CMD_REMOVE = CMD.REMOVE
local spEcho = Spring.Echo
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spValidUnitID = Spring.ValidUnitID
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spValidFeatureID = Spring.ValidFeatureID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetFeaturePosition = Spring.GetFeaturePosition
--local EMPTY = {}

local function DebugEcho(str)
	spEcho("[unit_unstick_staticcon]: " .. str)
end

local function GetDistance(unitID, targetID, isReclaim)
	local x, _, z = spGetUnitPosition(unitID)
	local x2, z2
	if isReclaim then
		if spValidFeatureID(targetID) then
			x2, _, z2 = spGetFeaturePosition(targetID)
		elseif spValidUnitID(targetID) then -- live reclaim
			x2, _, z2 = spGetUnitPosition(targetID)
		end
	else
		x2, _, z2 = spGetUnitPosition(targetID)
	end
	if not x2 then
		if debug then DebugEcho("Target doesn't exist?") end
		return 9999
	end
	return ((x2 - x) * (x2 - x)) + ((z2 - z) * (z2 - z))
end

local function IsObjectCloseEnough(unitID, targetID, cmd) -- Note: build ranges are 2D usually.
	local isReclaim = (cmd == CMD_RECLAIM or cmd == CMD_RESURRECT)
	local dist = GetDistance(unitID, targetID, isReclaim)
	local buildRange = buildRangesSq[spGetUnitDefID(unitID)]
	if debug then
		DebugEcho(unitID, ": Distance: ", dist, " (Build Range: ", buildRange, ")")
	end
	return dist <= buildRange
end

--[[Some documentation with regards to this HandleUnit function:
When patrol orders for cons encounters reclaim or repair, it sends the following cmd params:
[1] = unitID / featureID
[2] = the patroler's X position
[3] = the patroler's Y position
[4] = the patroler's Z position
[5] = the patroler's buildrange

A normal user added single unit reclaim would have only look like this:
[1] = Unit / FeatureID

OR (after finding a feature)
[1] = unitID / featureID
[2] = center X
[3] = center Y
[4] = center Z
[5] = radius
]]

local function HandleUnit(unitID, f)
	if not spValidUnitID(unitID) then
		return
	end
	local _, _, unbuilt = spGetUnitIsStunned(unitID)
	if unbuilt then -- if caretaker is reversed built, UnitFinished should retrigger to readd it, though nobody really unbuilds caretakers.
		if debug then DebugEcho(unitID .. ": Exited drop (Reverse Built)") end
		return
	end
	local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3, cmdParam4, cmdParam5 = spGetUnitCurrentCommand(unitID)
	if cmdParam1 and spValidFeatureID(cmdParam1 - Game.maxUnits) then
		cmdParam1 = cmdParam1 - Game.maxUnits
	end
	if debug then DebugEcho(unitID .. ": " .. tostring(cmdID) .. ", " .. tostring(cmdParam1) .. ", " .. tostring(cmdParam2)) end
	if cmdID and cmdParam1 and (spValidFeatureID(cmdParam1) or spValidUnitID(cmdParam1)) then
		if debug then DebugEcho(unitID .. ": Valid command, checking distance.") end
		if not IsObjectCloseEnough(unitID, cmdParam1, cmdID) then
			if debug then DebugEcho(unitID .. ": Command dropped (Out of Range)") end
			spGiveOrderToUnit(unitID, CMD_REMOVE, cmdTag, 0)
			if cmdParam5 and cmdParam5 ~= buildRangesSq[spGetUnitDefID(unitID)] then -- this was an area command added by the user.
				if debug then DebugEcho(unitID, cmdID, cmdParam1, cmdParam2) end
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, cmdID, CMD.OPT_SHIFT, cmdParam2, cmdParam3, cmdParam4, cmdParam5}, CMD.OPT_ALT) -- reissue the command (just in case)
			end
		end
	elseif debug then
		DebugEcho("Invalid command handled for " .. unitID)
	end
	handled[f + delay] = handled[f + delay] or {} -- check back in 15 frames.
	handled[f + delay][#handled[f + delay] + 1] = unitID
end

function gadget:GameFrame(f)
	if handled[f] then
		for i = 1, #handled[f] do
			if debug then DebugEcho("Check " .. handled[f][i]) end
			HandleUnit(handled[f][i], f)
		end
		handled[f] = nil
	end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if buildRangesSq[unitDefID] then
		if debug then DebugEcho(unitID .. ": Added to check loop.") end
		local f = spGetGameFrame() + delay
		handled[f] = handled[f] or {}
		handled[f][#handled[f] + 1] = unitID
	end
end
