

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
	Spring.Echo("remove Kill XP gadget loaded")
end

function gadget:Destroy()
	Spring.Echo("remove Kill XP gadget unloaded")
end

function gadget: UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam) 

	if (attackerID == nil) then
		return
	end

	if not (unitTeam == attackerTeam) then 
		local xpKillValue = (1 * 0.1 * (UnitDefs[unitDefID].power / UnitDefs[attackerDefID].power))
		Spring.Echo ("unit xp value"..xpKillValue)
		
		local prevXP = Spring.GetUnitExperience(attackerID)
		local result = prevXP-xpKillValue
		
		Spring.Echo ("attacker previous xp:"..prevXP)
		Spring.Echo ("result:"..result)
		if (result < 0) then --if we end up reducing xp below zero, we need to delay the math to the next frame
			Spring.Echo ("delaying loss of:"..xpKillValue.."xp")
			if (delayedXPLossTable[attackerID] == nil) then 
				delayedXPLossTable[attackerID] = xpKillValue
			else
				-- i was unable to construct a test case for this, essentially what is required is that a unit
				-- gets the final shot on one than more unit during the exact same frame while doing next to no damage
				-- where at least the last 2 of those xp gains/losses would put the unit below zero xp				
				Spring.Echo ("adding:"..xpKillValue.."to existing stack of"..delayedXPLossTable[attackerID].."xp")
				delayedXPLossTable[attackerID] = delayedXPLossTable[attackerID] + xpKillValue
				Spring.Echo ("resulting in a stack of"..delayedXPLossTable[attackerID].."xp")

			end			
		else
			Spring.SetUnitExperience(attackerID, (result))
			-- at this point, the unit (hopefully) is exactly xpKillValue below the target value, 
			-- the engine will add that amount after this gadget has run
		end
		
		Spring.Echo ("preliminary result is"..Spring.GetUnitExperience(attackerID).."the engine should now add"..xpKillValue.."for a final result of"..Spring.GetUnitExperience(attackerID)+xpKillValue)
	end
end 

function GameFrame (frame)
	for attackerID, xpLoss in pairs(delayedXPLossTable) do
		Spring.Echo ("delayed xp loss executed for id"..attackerID.."Loss:"..xpLoss)
		local prevXP = Spring.GetUnitExperience(attackerID)
		Spring.Echo ("with prev xp:"..prevXP)
		Spring.SetUnitExperience(attackerID, (prevXP-xpLoss))
		Spring.Echo ("xp after frame:"..Spring.GetUnitExperience(attackerID))
		delayedXPLossTable[attackerID] = nil
	end
end
