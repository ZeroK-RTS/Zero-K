function gadget:GetInfo()
	return {
		name      = "Empirical DPS",
		desc      = "Tool for determining real DPS values",
		author    = "Google Frog",
		date      = "12 Sep 2011",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false --  loaded by default?
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
	return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Spawn two units of opposing teams, set one to hold fire.

local last
local start, damage
local attackerUnitDefID

function gadget:UnitDamaged(unitID, unitDefID,  unitTeam, unitDamage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	local wd = WeaponDefs[weaponID]
	if wd then
	--	local aoe = wd.damageAreaOfEffect
	--	local dist = 0.09
	--	local edgeEff = wd.edgeEffectiveness
	--	local writeDamage = wd.customParams.shield_damage
	--	local theoryDamage = writeDamage*(aoe-dist)/(aoe + 0.01 - dist*edgeEff)
	--	local theoryDist = -unitDamage/writeDamage*(aoe + 0.01)+aoe
	--	Spring.Echo(wd.customParams.statsdamage)
	--	Spring.Echo(Spring.GetGameFrame())
	--	Spring.Echo(theoryDamage)
	--	Spring.Echo(aoe)
	--	Spring.Echo(edgeEff)
	--	Spring.Echo(theoryDist)
	end
	
	--Spring.SetUnitExperience(attackerID,0.001)
	local frame = Spring.GetGameFrame()
	attackerUnitDefID = attackerDefID
	-- delay
	if last then
		Spring.Echo("Last: ", frame - last, math.random())
	end
	last = frame
	-- dps
	if start then
		Spring.Echo(damage/(frame-start)*30)
		damage = damage + unitDamage
	else
		start = frame
		damage = unitDamage
	end
	Spring.Echo("Damage: ", damage, start)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local frame = Spring.GetGameFrame()
	if start then
		local name = attackerUnitDefID and (UnitDefs[attackerUnitDefID] or {}).humanName
		if name then
			Spring.Echo("Total DPS " .. name .. ": " .. UnitDefs[unitDefID].health/(frame - start)*30)
		else
			Spring.Echo("Total DPS: " .. UnitDefs[unitDefID].health/(frame - start)*30)
		end
		start = nil
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	damage = 0
	start = nil
end
