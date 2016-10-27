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

local function CopyMoveThenUnload(transportID, unitID)
	local cmdQueue = Spring.GetCommandQueue(unitID)
	if not cmdQueue then
		return
	end
	local commandLocations = {}
	local queueToRemove = {}
	for i = 1, #cmdQueue do
		local cmd = cmdQueue[i]
		if cmd.id == CMD_MOVE then
			commandLocations[#commandLocations + 1] = cmd.params
			commandCopied = true
		elseif cmd.id ~= CMD_SET_WANTED_MAX_SPEED then
			break
		end
		queueToRemove[#queueToRemove + 1] = cmd.tag
	end
	
	if #commandLocations == 0 then
		return
	end
	local commands = {}
	for i = 1, #commandLocations - 1 do
		commands[i] = {CMD.MOVE, commandLocations[i], CMD.OPT_SHIFT}
	end
	commandLocations[#commandLocations][4] = 100
	commands[#commandLocations] = {CMD.UNLOAD_UNITS, commandLocations[#commandLocations], CMD.OPT_SHIFT}
	
	Spring.GiveOrderArrayToUnitArray({transportID}, commands)
	Spring.GiveOrderToUnit(unitID, CMD.REMOVE, queueToRemove, {})
end

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
						if ud.transportMass > 330 then
							heavyTrans[#heavyTrans + 1] = unitID
						else
							lightTrans[#lightTrans + 1] = unitID
						end
					end
				end
			else
				if (ud.mass > 330) or (ud.xsize > 8) or (ud.zsize > 8) then
					heavy[#heavy + 1] = unitID
				else
					light[#light + 1] = unitID
				end
			end
		end
	end
	
	-- Assign transports to units
	local lightEnd = math.min(#light, #lightTrans)
	for i = 1, lightEnd do 
		Spring.GiveOrderToUnit(lightTrans[i], CMD.LOAD_UNITS, {light[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(light[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
		CopyMoveThenUnload(lightTrans[i], light[i])
	end
	
	local heavyEnd = math.min(#heavy, #heavyTrans)
	for i = 1, heavyEnd do 
		Spring.GiveOrderToUnit(heavyTrans[i], CMD.LOAD_UNITS, {heavy[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(heavy[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
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
			Spring.GiveOrderToUnit(light[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
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