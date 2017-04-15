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

delayedXPLossTable = {} --we store xp losses and unit ids here when we need to delay the math to the next frame

function gadget:Initialize()
	--Spring.Echo("remove Kill XP gadget loaded")
end

function gadget:Destroy()
	--Spring.Echo("remove Kill XP gadget unloaded")
end

function gadget: UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam) 

	if (attackerID == nil) then
		return
	end

	if not (unitTeam == attackerTeam) then 
	
		local xpKillValue = (1 * 0.1 * (UnitDefs[unitDefID].power / UnitDefs[attackerDefID].power))			
		local prevXP = Spring.GetUnitExperience(attackerID)
		local result = prevXP-xpKillValue		

		if (result < 0) then --if we end up reducing xp below zero, we need to delay the math to the next frame			
			if (delayedXPLossTable[attackerID] == nil) then 
				delayedXPLossTable[attackerID] = xpKillValue
			else
				-- i was unable to construct a test case for this, essentially what is required is that a unit
				-- gets the final shot on one than more unit during the exact same frame while doing next to no damage
				-- where at least the last 2 of those xp gains/losses would put the unit below zero xp						
				delayedXPLossTable[attackerID] = delayedXPLossTable[attackerID] + xpKillValue
			end			
		else
			Spring.SetUnitExperience(attackerID, (result))
			-- at this point, the unit (hopefully) is exactly xpKillValue below the target value, 
			-- the engine will add that amount after this gadget has run
		end		
	end
end 

function gadget: GameFrame (frame)

	for attackerID, xpLoss in pairs(delayedXPLossTable) do		
		local prevXP = Spring.GetUnitExperience(attackerID)		
		Spring.SetUnitExperience(attackerID, (prevXP-xpLoss))		
		delayedXPLossTable[attackerID] = nil
	end
end
