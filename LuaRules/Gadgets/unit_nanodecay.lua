-- $Id: unit_noselfpwn.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Nano Decay",
    desc      = "Nanoframes decay into thin air for chosen units.",
    author    = "CarRepairer",
    date      = "2009-5-12",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local spGetAllUnits			= Spring.GetAllUnits
local spGetUnitHealth		= Spring.GetUnitHealth
local spSetUnitHealth		= Spring.SetUnitHealth
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitCommands		= Spring.GetUnitCommands

local CMD_REPAIR    = CMD.REPAIR
local CMD_GUARD		= CMD.GUARD
local CMD_WAIT		= CMD.WAIT

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unfins, builderIDs = {}, {}

local decayers = {
	-- terraform blocks removed. 
}

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if decayers[unitDefID] then
		local cmd1 = GetFirstCommand(builderID)
		builderIDs[builderID] = {tag=cmd1.tag, buildee=unitID}
		unfins[unitID] = {active=5}
	end
end


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	unfins[unitID] = nil
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	unfins[unitID] = nil
end


function GetFirstCommand(unitID)
	local queue = spGetUnitCommands(unitID)
	return queue and queue[1]
end

function GetFirstTwoCommands(unitID)
	local queue = spGetUnitCommands(unitID)
	return queue and queue[1], queue and queue[1] and queue[2]
end

function gadget:GameFrame(n)

	if n%32 == 0 then
		local allUnits = spGetAllUnits()
		for _, unitID in ipairs(allUnits) do
			local unitDefID = spGetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			if ud and ud.builder then
				local cmd1, cmd2 = GetFirstTwoCommands(unitID)
				if cmd1 then
					local cmdToCheck = cmd1
					if cmd1.id == CMD_WAIT then
						cmdToCheck = cmd2
					end
					if cmdToCheck and (cmdToCheck.id == CMD_GUARD or cmdToCheck.id == CMD_REPAIR ) and unfins[cmdToCheck.params[1]] then
						unfins[cmdToCheck.params[1]].active = 5
					elseif builderIDs[unitID] then
						if builderIDs[unitID].tag == cmdToCheck.tag and unfins[builderIDs[unitID].buildee] then
							unfins[builderIDs[unitID].buildee].active = 5
						else
							builderIDs[unitID] = nil
						end
						
					end
				end
			end
		end
		
		for unitID, data in pairs(unfins) do
			unfins[unitID].active = unfins[unitID].active and unfins[unitID].active ~= 0 and unfins[unitID].active - 1 or nil
			
			if not unfins[unitID].active then
				local health, maxHealth, _, _, progress = spGetUnitHealth(unitID)
				local newprogress = progress - 0.0001
				spSetUnitHealth(unitID, {
					build  = newprogress,
				})
			end
		end
	end
	
	

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------