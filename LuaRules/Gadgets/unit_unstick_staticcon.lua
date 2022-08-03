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

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local handledUnits = IterableMap.New()

-- Config --
local UPDATE_RATE = 45
local debugMode = false

local buildRangesSq = {} -- [unitDefID] = buildDistance

for i = 1, #UnitDefs do -- Find static constructors
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
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spValidUnitID = Spring.ValidUnitID
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spValidFeatureID = Spring.ValidFeatureID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetFeaturePosition = Spring.GetFeaturePosition

local function GetDistanceSq(unitID, targetID, isReclaim)
	local x, _, z = spGetUnitPosition(unitID)
	local x2, z2
	if isReclaim then
		if spValidFeatureID(targetID) then
			x2, _, z2 = spGetFeaturePosition(targetID)
		elseif spValidUnitID(targetID) then 
			-- live reclaim
			x2, _, z2 = spGetUnitPosition(targetID)
		end
	else
		x2, _, z2 = spGetUnitPosition(targetID)
	end
	if not x2 then
		if debugMode then
			Spring.Echo("Target doesn't exist?")
		end
		return false
	end
	return (x2 - x)^2 + (z2 - z)^2
end

local function IsObjectCloseEnough(unitID, targetID, cmd) -- Note: build ranges are 2D usually.
	local isReclaim = (cmd == CMD_RECLAIM or cmd == CMD_RESURRECT)
	local distSq = GetDistanceSq(unitID, targetID, isReclaim)
	if not distSq then
		return false
	end
	local buildRange = buildRangesSq[spGetUnitDefID(unitID)]
	if debugMode then
		Spring.Echo(unitID, ": Distance: ", math.sqrt(distSq), " (Build Range: ", buildRange, ")")
	end
	return distSq <= buildRange
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

local function HandleUnit(unitID)
	if not spValidUnitID(unitID) then
		return
	end
	local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3, cmdParam4, cmdParam5 = spGetUnitCurrentCommand(unitID)
	if cmdParam1 and spValidFeatureID(cmdParam1 - Game.maxUnits) then
		cmdParam1 = cmdParam1 - Game.maxUnits
	end
	if debugMode then
		Spring.Echo(unitID .. ": ", cmdID, cmdParam1, cmdParam2)
	end
	if cmdID and cmdParam1 and (spValidFeatureID(cmdParam1) or spValidUnitID(cmdParam1)) then
		if debugMode then
			Spring.Echo(unitID .. ": Valid command, checking distance.")
		end
		if not IsObjectCloseEnough(unitID, cmdParam1, cmdID) then
			if debugMode then 
				Spring.Echo(unitID .. ": Command dropped (Out of Range)")
			end
			spGiveOrderToUnit(unitID, CMD_REMOVE, cmdTag, 0)
			if cmdParam5 and cmdParam5 ~= buildRangesSq[spGetUnitDefID(unitID)] then 
				-- this was an area command added by the user.
				if debugMode then 
					Spring.Echo(unitID, cmdID, cmdParam1, cmdParam2)
				end
				-- reissue the command (just in case)
				spGiveOrderToUnit(unitID, CMD_INSERT, {0, cmdID, CMD.OPT_SHIFT, cmdParam2, cmdParam3, cmdParam4, cmdParam5}, CMD.OPT_ALT)
			end
		end
	end

	if debugMode and not (cmdID and cmdParam1 and (spValidFeatureID(cmdParam1) or spValidUnitID(cmdParam1))) then
		Spring.Echo("No action needed for " .. unitID)
	end
end

function gadget:GameFrame(n)
	IterableMap.ApplyFraction(handledUnits, UPDATE_RATE, n%UPDATE_RATE, HandleUnit)
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if buildRangesSq[unitDefID] then
		if debugMode then 
			Spring.Echo(unitID .. ": Added to check loop.")
		end
		IterableMap.Add(handledUnits, unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if buildRangesSq[unitDefID] then
		IterableMap.Remove(handledUnits, unitID)
	end
end

function gadget:UnitReverseBuilt(unitID, unitDefID)
	if buildRangesSq[unitDefID] then
		IterableMap.Remove(handledUnits, unitID)
	end
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
		if not inBuild then
			gadget:UnitFinished(unitID, unitDefID)
		end
	end
end
