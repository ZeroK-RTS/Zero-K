-- this should work based on the assumption that xp gains from the engine always execute before gadgets
-- untested

function gadget:GetInfo()
	return {
		name = "RemoveKillXP",
		desc = "remove xp from killing blows",
		author = "Klon",
		date = "Nov 10, 2014",
		license = "GNU GPL, v2 or later",
		layer = -4, 
		enabled = true 
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

function gadget:Initialize()
end

function gadget:Destroy()
end

function gadget: UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam) 

	if (attackerID == nil) then
		return
	end

	if not (unitTeam == attackerTeam) then 
		local xpKillValue = 1 * 0.1 * (UnitDefs[unitDefID].power / UnitDefs[attackerDefID].power))
		-- '1' should be replaced with expMultiplier, dont know if that engine constant can be accessed?
		local prevXP = Spring.GetUnitExperience(attackerID)
		Spring.SetUnitExperience(attackerID, (prevXP - xpKillValue))
	end
end 


