--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Repair Speed Changer",
      desc      = "Changes the repair speed for units that are in combat",
      author    = "Google Frog",
      date      = "11 December 2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true  
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- CONFIG

local REPAIR_PENALTY = 6 -- effective 6x cost
local TIME_SINCE_DAMAGED = 300


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local combatUnits = {}
local uncombatTimes = {}

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, fullDamage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)

	if (attackerDefID and 
		UnitDefs[attackerDefID].customParams and 
		UnitDefs[attackerDefID].customParams.nofriendlyfire and
		attackerID ~= unitID and
		Spring.AreTeamsAllied(unitTeam, attackerTeam)) then
		return
	end

	local newDone = Spring.GetGameFrame() + TIME_SINCE_DAMAGED

	if combatUnits[unitID] then
		uncombatTimes[combatUnits[unitID].done][unitID] = nil
		combatUnits[unitID].done = newDone
		if not uncombatTimes[newDone] then
			uncombatTimes[newDone] = {}
		end
		uncombatTimes[newDone][unitID] = true
	else
		if not uncombatTimes[newDone] then
			uncombatTimes[newDone] = {}
		end
		local bt = UnitDefs[unitDefID].buildTime
		uncombatTimes[newDone][unitID] = true
		combatUnits[unitID] = {done = newDone, bt = bt}
		if select(5,Spring.GetUnitHealth(unitID)) == 1 then
			Spring.SetUnitCosts(unitID, {buildTime = bt*REPAIR_PENALTY})
		end
	end
	
end


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if combatUnits[unitID] then
		Spring.SetUnitCosts(unitID, {buildTime = combatUnits[unitID].bt*REPAIR_PENALTY})
	end
end

function gadget:GameFrame(n)
	if uncombatTimes[n] then
		for unitID,_ in pairs(uncombatTimes[n]) do
			if Spring.ValidUnitID(unitID) then
				Spring.SetUnitCosts(unitID, {buildTime = combatUnits[unitID].bt})
			end
			combatUnits[unitID] = nil
		end
		uncombatTimes[n] = false
	end
end

function gadget:AllowUnitBuildStep(builderID, teamID, unitID, unitDefID, step) 
	if step < 0 and combatUnits[unitID] and select(5,Spring.GetUnitHealth(unitID)) == 1 then
		Spring.SetUnitCosts(unitID, {buildTime = combatUnits[unitID].bt})
	end
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if combatUnits[unitID] then
		uncombatTimes[combatUnits[unitID].done][unitID] = nil
		combatUnits[unitID] = nil
	end
end

