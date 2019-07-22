--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Transport Load Double Tap",
    desc      = "Matches selected tranaports and units when load is double pressed.",
    author    = "GoogleFrog",
    date      = "8 May 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")


local CMD_MOVE = CMD.MOVE
local CMD_SET_WANTED_MAX_SPEED = CMD.SET_WANTED_MAX_SPEED

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- From transport AI

local EMPTY_TABLE = {}
local MAX_UNITS = Game.maxUnits
local areaTarget -- used to match area command targets

local goodCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD_RAW_BUILD] = true,
	[CMD.SET_WANTED_MAX_SPEED or 70] = true,
	[CMD.GUARD] = true,
	[CMD.RECLAIM] = true,
	[CMD.REPAIR] = true,
	[CMD.RESURRECT] = true,
	[CMD_JUMP] = true,
}

local function ProcessCommand(unitID, cmdID, params)
	if not (goodCommand[cmdID] or cmdID < 0) then
		return false
	end
	local halting = not (cmdID == CMD.MOVE or cmdID == CMD_RAW_MOVE or cmdID == CMD.SET_WANTED_MAX_SPEED)
	if cmdID == CMD.SET_WANTED_MAX_SPEED then
		return true, halting
	end
	
	local targetOverride
	if #params == 5 and (cmdID == CMD.RESURRECT or cmdID == CMD.RECLAIM or cmdID == CMD.REPAIR) then
		areaTarget = {
			x = params[2],
			z = params[4],
			objectID = params[1]
		}
	elseif areaTarget and #params == 4 then
		if params[1] == areaTarget.x and params[3] == areaTarget.z then
			targetOverride = areaTarget.objectID
		end
		areaTarget = nil
	elseif areaTarget then
		areaTarget = nil
	end
	
	if not targetOverride then
		if #params == 3 or #params == 4 then
			return true, halting, params
		elseif not params[1] then
			return true, halting
		end
	end
	
	local moveParams = {1, 2, 3}
	if cmdID == CMD.RESURRECT or cmdID == CMD.RECLAIM then
		moveParams[1], moveParams[2], moveParams[3] = Spring.GetFeaturePosition((targetOverride or params[1] or 0) - MAX_UNITS)
	else
		moveParams[1], moveParams[2], moveParams[3] = Spring.GetUnitPosition(targetOverride or params[1])
	end
	return true, halting, moveParams
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CopyMoveThenUnload(transportID, unitID)
	local cmdQueue = Spring.GetCommandQueue(unitID, -1)
	if not cmdQueue then
		return
	end
	local commandLocations = {}
	local queueToRemove = {}
	
	areaTarget = nil
	
	for i = 1, #cmdQueue do
		local cmd = cmdQueue[i]
		
		local keepGoing, haltAtCommand, moveParams = ProcessCommand(unitID, cmd.id, cmd.params)
		if not keepGoing then
			break
		end
		
		if moveParams then
			commandLocations[#commandLocations + 1] = moveParams
		end
		
		if haltAtCommand then
			break
		else
			queueToRemove[#queueToRemove + 1] = cmd.tag
		end
	end
	
	if #commandLocations == 0 then
		return
	end
	local commands = {}
	for i = 1, #commandLocations - 1 do
		commands[i] = {CMD_RAW_MOVE, commandLocations[i], CMD.OPT_SHIFT}
	end
	commandLocations[#commandLocations][4] = 100
	commands[#commandLocations] = {CMD.UNLOAD_UNITS, commandLocations[#commandLocations], CMD.OPT_SHIFT}
	
	Spring.GiveOrderArrayToUnitArray({transportID}, commands)
	Spring.GiveOrderToUnit(unitID, CMD.REMOVE, queueToRemove, 0)
end

local valkMaxMass = UnitDefNames.gunshiptrans.transportMass
local valkMaxSize = UnitDefNames.gunshiptrans.transportSize * 2
local REVERSE_COMPAT = not Spring.Utilities.IsCurrentVersionNewerThan(104, 600)

local function DoSelectionLoad()
	-- Find the units which can transport and the units which are transports
	local selectedUnits = Spring.GetSelectedUnits()
	local lightTrans = {}
	local heavyTrans = {}
	local light = {}
	local heavy = {}
	
	for i = 1, #selectedUnits do
		local unitID = selectedUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = unitDefID and UnitDefs[unitDefID]
		if ud then
			if (ud.canFly or ud.cantBeTransported) then
				if ud.isTransport then
					local transportUnits = Spring.GetUnitIsTransporting(unitID)
					if transportUnits and #transportUnits == 0 then
						if ud.customParams.islighttransport then
							lightTrans[#lightTrans + 1] = unitID
						else
							heavyTrans[#heavyTrans + 1] = unitID
						end
					end
				end
			else
				if REVERSE_COMPAT then
					if (ud.mass > valkMaxMass) or (ud.xsize > valkMaxSize) or (ud.zsize > valkMaxSize) then
						heavy[#heavy + 1] = unitID
					else
						light[#light + 1] = unitID
					end
				else
					if ud.customParams.requireheavytrans then
						heavy[#heavy + 1] = unitID
					else
						light[#light + 1] = unitID
					end
				end
			end
		end
	end
	
	-- Assign transports to units
	local lightEnd = math.min(#light, #lightTrans)
	for i = 1, lightEnd do 
		Spring.GiveOrderToUnit(lightTrans[i], CMD.LOAD_UNITS, {light[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(light[i], CMD.WAIT, EMPTY_TABLE, CMD.OPT_RIGHT)
		CopyMoveThenUnload(lightTrans[i], light[i])
	end
	
	local heavyEnd = math.min(#heavy, #heavyTrans)
	for i = 1, heavyEnd do 
		Spring.GiveOrderToUnit(heavyTrans[i], CMD.LOAD_UNITS, {heavy[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(heavy[i], CMD.WAIT, EMPTY_TABLE, CMD.OPT_RIGHT)
		CopyMoveThenUnload(heavyTrans[i], heavy[i])
	end
	
	--Spring.Echo("light", #light)
	--Spring.Echo("heavy", #heavy)
	--Spring.Echo("lightTrans", #lightTrans)
	--Spring.Echo("heavyTrans", #heavyTrans)
	if #light > #lightTrans then
		local offset = #heavy - #lightTrans
		heavyEnd = math.min(#light, #heavyTrans + #lightTrans - #heavy)
		--Spring.Echo("offset", offset)
		for i = #lightTrans + 1, heavyEnd do 
			Spring.GiveOrderToUnit(heavyTrans[offset + i], CMD.LOAD_UNITS, {light[i]}, CMD.OPT_RIGHT)
			Spring.GiveOrderToUnit(light[i], CMD.WAIT, EMPTY_TABLE, CMD.OPT_RIGHT)
			CopyMoveThenUnload(heavyTrans[offset + i], light[i])
		end
	end
	Spring.SetActiveCommand(-1)
end

function widget:CommandNotify(cmdId)
	if cmdId == CMD_LOADUNITS_SELECTED then
		DoSelectionLoad()
		return true
	end
end
