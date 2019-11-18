function gadget:GetInfo()
  return {
    name      = "AirTransport_SeaPickup",
    desc      = "Allow air transport to use amphibious' floatation gadget to pickup unit at sea",
    author    = "msafwan (xponen)",
    date      = "22.12.2013", --29.4.2014
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--  «COMMON»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  «SYNCED»  ------------------------------------------------------------------
--------------------------------------------------------------------------------

--Speed-ups
local spGetUnitDefID    = Spring.GetUnitDefID;
local spValidUnitID		= Spring.ValidUnitID
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spSetUnitMoveGoal = Spring.SetUnitMoveGoal
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetCommandQueue = Spring.GetCommandQueue
local spGetUnitPosition = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spGetUnitIsTransporting = Spring.GetUnitIsTransporting
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGiveOrderArrayToUnitArray = Spring.GiveOrderArrayToUnitArray

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- commands

include("LuaRules/Configs/customcmds.h.lua")
local floatDefs = include("LuaRules/Configs/float_defs.lua")

local extendedloadCmdDesc = {
  id      = CMD_EXTENDED_LOAD, --defined in customcmds.h.lua
  type    =	CMDTYPE.ICON_UNIT_OR_AREA , --have unitID or mapPos + radius
  name    = 'extendloadunit',
  --hidden  = true,
  cursor  = 'Loadunits',
  action  = 'extendloadunit',
  tooltip = 'Load unit into transport, call amphibious to surface if possible.',
}

local extendedunloadCmdDesc = {
  id      = CMD_EXTENDED_UNLOAD, --defined in customcmds.h.lua
  type    =	CMDTYPE.ICON_MAP , --have mapPos
  name    = 'extendunloadunit',
  --hidden  = true,
  cursor  = 'Unloadunits',
  action  = 'extendunloadunit',
  tooltip = 'Unload unit from transport, drop amphibious to water if possible.',
}

local sinkCommand = {
	[CMD.MOVE] = true,
	[CMD_RAW_MOVE] = true,
	[CMD.GUARD] = true,
	[CMD.FIGHT] = true,
	[CMD.PATROL] = true,
	[CMD_WAIT_AT_BEACON] = true,
}

local dropableUnits = {
	--all floatable unit will be dropped when regular unload fail (such as when unloading at sea), but some can't float but is amphibious,
	--this list additional units that should be dropped.
	[UnitDefNames["amphcon"].id] = true, --clam
	[UnitDefNames["amphraid"].id] = true, --duck
	[UnitDefNames["striderantiheavy"].id] = true, --ultimatum
	[UnitDefNames["shieldshield"].id] = true, --aspis
	[UnitDefNames["cloakjammer"].id] = true, --eraser
	[UnitDefNames["striderdetriment"].id] = true, --striderdetriment
}

if UnitDefNames["factoryamph"] then
	local buildOptions = UnitDefNames["factoryamph"].buildOptions
	for i=1, #buildOptions do
		local unitDefID = buildOptions[i]
		dropableUnits[unitDefID] = true
	end
end

for i=1, #UnitDefs do
	if (UnitDefs[i].customParams.level) then
		dropableUnits[i] = true
	end
end

local transportPhase = {}
local giveLOAD_order = {}
local giveDROP_order = {}
local maintainFloat = {}
local maintainFloatCount = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function IsUnitAllied(unitID1,unitID2)
	if spGetUnitAllyTeam(unitID1) == spGetUnitAllyTeam(unitID2) then
		return true
	else
		return false
	end
end

local function IsUnitIdle(unitID)
	local cmdID = Spring.GetUnitCurrentCommand(unitID)
	local moving = cmdID and sinkCommand[cmdID]
	return not moving
end

local function GetCommandLenght(unitID)
	local cmds
	local lenght = 0
	lenght = spGetCommandQueue(unitID,0) or 0
	return lenght, cmds
end

-- warning: causes recursion?
local function ClearUnitCommandQueue(unitID,cmds)
	cmds = cmds or spGetCommandQueue(unitID, -1)
	for i=1,#cmds do
		spGiveOrderToUnit(unitID,CMD.REMOVE,{cmds[i].tag},0)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  gadgetHandler:RegisterCMDID(CMD_EXTENDED_LOAD);
  gadgetHandler:RegisterCMDID(CMD_EXTENDED_UNLOAD);
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD.UNLOAD_UNITS] = true, [CMD.LOAD_UNITS] = true,}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD.LOAD_UNITS) and (not transportPhase[unitID] or transportPhase[unitID]:sub(1,19)~= "INTERNAL_LOAD_UNITS") then  --detected LOAD command not originated from this gadget
		if not cmdParams[2] then --not area transport
			if not spValidUnitID(cmdParams[1]) then --not loading unit
				return true --let spring handle
			end
			local targetDefID = spGetUnitDefID(cmdParams[1])
			if floatDefs[targetDefID] then --targeted unit could utilize float gadget (unit_impulsefloat.lua)
				local cmds
				local index = 0
				index,cmds = GetCommandLenght(unitID)
				 --LOAD command was not part of a queue, clear current queue (this create the normal behaviour when SHIFT modifier is not used)
				if not cmdOptions.shift then
					ClearUnitCommandQueue(unitID,cmds)
					transportPhase[unitID] = nil
					index = 0
				end
				
				GG.DelegateOrder(unitID,CMD.INSERT,{index,CMD_EXTENDED_LOAD,CMD.OPT_SHIFT,cmdParams[1]}, CMD.OPT_ALT) --insert LOAD-Extension command at current index in queue
				--"PHASE A"--
				--Spring.Echo("A")
				return false --replace LOAD with LOAD-Extension command
			end
		else --is an area-transport
			local haveWater = false
			local halfRadius = cmdParams[4]*0.5
			if spGetGroundHeight(cmdParams[1],cmdParams[3]) < 0
			or spGetGroundHeight(cmdParams[1]+halfRadius,cmdParams[3]) < 0
			or spGetGroundHeight(cmdParams[1],cmdParams[3]+halfRadius) < 0
			or spGetGroundHeight(cmdParams[1]-halfRadius,cmdParams[3]) < 0
			or spGetGroundHeight(cmdParams[1],cmdParams[3]-halfRadius) < 0
			then
				haveWater = true
			end
			if haveWater then
				local cmds
				local index = 0
				index,cmds = GetCommandLenght(unitID)
				--LOAD command was not part of a queue, clear current queue (this create the normal behaviour when SHIFT modifier is not used)
				if not cmdOptions.shift then
					ClearUnitCommandQueue(unitID,cmds)
					transportPhase[unitID] = nil
					index = 0
				end
				GG.DelegateOrder(unitID,CMD.INSERT,{index,CMD_EXTENDED_LOAD,CMD.OPT_SHIFT,unpack(cmdParams)}, CMD.OPT_ALT)
				return false
			end
		end
	end
	if (cmdID == CMD.UNLOAD_UNITS) then
		local cmds
		local index = 0
		index,cmds = GetCommandLenght(unitID)
		if not cmdOptions.shift then
			ClearUnitCommandQueue(unitID,cmds)
			transportPhase[unitID] = nil
			index = 0
		end
		GG.DelegateOrder(unitID, CMD.INSERT,{index,CMD.UNLOAD_UNITS,CMD.OPT_SHIFT,unpack(cmdParams)}, CMD.OPT_ALT)
		GG.DelegateOrder(unitID, CMD.INSERT,{index+1,CMD_EXTENDED_UNLOAD,CMD.OPT_SHIFT,unpack(cmdParams)}, CMD.OPT_ALT)
		return false
	end
	return true
end

function gadget:CommandFallback(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag)
	if cmdID == CMD_EXTENDED_LOAD then
		if (transportPhase[unitID] and transportPhase[unitID]:sub(1,19)== "INTERNAL_LOAD_UNITS") then
			return true,true --remove this command
		end
		if not cmdParams[2] then --is not area-transport
			local cargoID = cmdParams[1]
			if not spValidUnitID(cargoID) then --target dead
				return true,true --remove this command
			end
			if GG.HoldStillForTransport_HoldFloat and IsUnitAllied(cargoID,unitID) then --is not targeting enemy
				local isHolding = GG.HoldStillForTransport_HoldFloat(cargoID) --check & call targeted unit to hold its float
				if not isHolding and transportPhase[unitID]~="ALREADY_CALL_UNIT_ONCE" and IsUnitIdle(cargoID) then --target have not float yet, and this is our first call, and targeted unit is idle enough for a float
					GG.WantToTransport_FloatNow(cargoID)
					local x,y,z = spGetUnitPosition(cargoID)
					spSetUnitMoveGoal(unitID, x,y,z, 500)
					transportPhase[unitID] = "ALREADY_CALL_UNIT_ONCE"
				end
			end
			local _,y = spGetUnitPosition(cargoID)
			if y >= -20 then --unit is above water
				--"PHASE B"--
				--Spring.Echo("B")
				local isRepeat = Spring.Utilities.GetUnitRepeat(unitID)
				local options = isRepeat and CMD.OPT_INTERNAL or CMD.OPT_SHIFT
				transportPhase[unitID] = "INTERNAL_LOAD_UNITS " .. cargoID
				giveLOAD_order[#giveLOAD_order+1] = {unitID,CMD.INSERT,{1,CMD.LOAD_UNITS,options,cargoID}, CMD.OPT_ALT}
				-- return true,true --remove this command
				return true,false --hold this command (removed in next frame after giveLOAD_order have inserted command (this avoid unit trigger UnitIdle)
			end
		else
			local units = spGetUnitsInCylinder(cmdParams[1],cmdParams[3],cmdParams[4])
			if #units == 0 then
				return true,true --remove this command
			end
			local haveFloater = false
			for i=1, #units do
				local potentialCargo = units[i]
				if GG.HoldStillForTransport_HoldFloat and IsUnitAllied(potentialCargo,unitID) then
					local isHolding = GG.HoldStillForTransport_HoldFloat(potentialCargo)
					if not isHolding and IsUnitIdle(potentialCargo) then
						GG.WantToTransport_FloatNow(potentialCargo)
					end
				end
				local _,y = spGetUnitPosition(potentialCargo)
				if y >= -20 then
					haveFloater = true
				end
			end
			if transportPhase[unitID]~="ALREADY_CALL_UNIT_ONCE" then
				spSetUnitMoveGoal(unitID, cmdParams[1],cmdParams[2],cmdParams[3],cmdParams[4]) --get into area-transport circle
				transportPhase[unitID] = "ALREADY_CALL_UNIT_ONCE"
			end
			if haveFloater then
				local isRepeat = Spring.Utilities.GetUnitRepeat(unitID)
				local options = isRepeat and CMD.OPT_INTERNAL or CMD.OPT_SHIFT
				transportPhase[unitID] = "INTERNAL_LOAD_UNITS " .. cmdParams[1]+cmdParams[3]
				giveLOAD_order[#giveLOAD_order+1] = {unitID,CMD.INSERT,{1,CMD.LOAD_UNITS,options,unpack(cmdParams)}, CMD.OPT_ALT}
				-- return true,true --remove this command
				return true,false --hold this command (removed in next frame after giveLOAD_order have inserted command (this avoid unit trigger UnitIdle)
			end
		end
		return true,false --remove this command
	elseif cmdID == CMD_EXTENDED_UNLOAD and cmdParams and cmdParams[3] then
		if (transportPhase[unitID] and transportPhase[unitID]== "INTERNAL_UNLOAD_UNITS") then
			return true,true --remove this command
		end
		local cargo = spGetUnitIsTransporting(unitID)
		if cargo and #cargo==1 then
			if transportPhase[unitID] ~= "ALREADY_CALL_UNITDROP_ONCE" then
				spSetUnitMoveGoal(unitID,cmdParams[1],cmdParams[2],cmdParams[3],64)
				transportPhase[unitID] = "ALREADY_CALL_UNITDROP_ONCE"
			end
			local x,_,z = spGetUnitPosition(unitID)
			local distance = math.sqrt((x-cmdParams[1])^2 + (z-cmdParams[3])^2)
			local vx,_,vz = spGetUnitVelocity(unitID)
			if distance > 64 or vx > 1 or vz > 1 then --wait until reach destination and until slow enough
				return true, false  --hold this command
			end
			local gy = spGetGroundHeight(x,z)
			local cargoDefID = spGetUnitDefID(cargo[1])
			if gy < 0 and (UnitDefs[cargoDefID].customParams.commtype or floatDefs[cargoDefID] or dropableUnits[cargoDefID]) then
				transportPhase[unitID] = "INTERNAL_UNLOAD_UNITS"
				giveDROP_order[#giveDROP_order+1] = {unitID,CMD.INSERT,{1,CMD_ONECLICK_WEAPON,CMD.OPT_INTERNAL}, CMD.OPT_ALT}
				-- Spring.Echo("E")
				--"PHASE E"--
				return true,false --hold this command (removed in next frame after giveLOAD_order have inserted command (this avoid unit trigger UnitIdle)
			end
		end
		return true,true --remove this command
	end
	return false --ignore
end

function gadget:GameFrame(f)
	if f%16 == 11 then --the same frequency as command check in "unit_impulsefloat_toggle.lua" (which is at f%16 == 12)
		if maintainFloatCount > 0 then
			local i=1
			while i<=maintainFloatCount do --not yet iterate over whole entry
				local transportID = maintainFloat[i][1]
				local transporteeList = maintainFloat[i][2]
				local haveFloater = false
				for j = 1, #transporteeList do
					local potentialCargo = transporteeList[j]
					if GG.HoldStillForTransport_HoldFloat and IsUnitAllied(potentialCargo,transportID) and GG.HoldStillForTransport_HoldFloat(potentialCargo) then
						haveFloater = true
					end
				end
				local cmdID = Spring.GetUnitCurrentCommand(transportID)
				if cmdID then
					if cmdID == CMD.LOAD_UNITS and haveFloater then
						i = i + 1 --go to next entry
					else
						-- delete current entry, replace it with final entry, and loop again
						maintainFloat[i] = maintainFloat[maintainFloatCount]
						maintainFloat[maintainFloatCount] = nil
						maintainFloatCount = maintainFloatCount -1
						--Spring.Echo("D")
						--"PHASE D"--
					end
				else
					-- delete current entry, replace it with final entry, and loop again
					maintainFloat[i] = maintainFloat[maintainFloatCount]
					maintainFloat[maintainFloatCount] = nil
					maintainFloatCount = maintainFloatCount -1
				end
			end
		end
	end
	if #giveLOAD_order > 0 then
		for i = 1, #giveLOAD_order do
			local order = giveLOAD_order[i]
			local transportID = order[1]
			if Spring.ValidUnitID(transportID) and transportPhase[transportID] == "INTERNAL_LOAD_UNITS " .. order[3][4] + (order[3][6] or 0) then
				spGiveOrderToUnit(unpack(order))
				local transporteeList
				if not order[3][5] then
					transporteeList = {order[3][4]}
				else
					transporteeList = spGetUnitsInCylinder(order[3][4],order[3][6],order[3][7])
				end
				maintainFloatCount = maintainFloatCount + 1
				maintainFloat[maintainFloatCount] = {transportID,transporteeList}
				--Spring.Echo("C")
				--"PHASE C"--
			end
			transportPhase[transportID] = nil --clear a blocking tag
		end
		giveLOAD_order = {}
	end
	if #giveDROP_order >0 then
		for i = 1, #giveDROP_order do
			spGiveOrderToUnit(unpack(giveDROP_order[i]))
			-- Spring.Echo("F")
			--PHASE F--
		end
		giveDROP_order = {}
	end
end

--------------------------------------------------------------------------------
--  «SYNCED»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
--  «UNSYNCED»  ----------------------------------------------------------------
--------------------------------------------------------------------------------
include("LuaRules/Configs/customcmds.h.lua")

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_EXTENDED_LOAD, CMD.LOAD_UNITS, {0,0.6,0.6,1},true)
	Spring.SetCustomCommandDrawData(CMD_EXTENDED_UNLOAD, CMD.UNLOAD_UNITS, {0.6,0.6,0,1})
	gadgetHandler:RemoveGadget()
end

--------------------------------------------------------------------------------
--  «UNSYNCED»  ----------------------------------------------------------------
--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------
--  «COMMON»  ------------------------------------------------------------------
--------------------------------------------------------------------------------
