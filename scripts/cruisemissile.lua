include "constants.lua"

local base = piece 'base'
local launched = false

function script.AimWeapon(heading, pitch)
	return true
end

local function RemoveMissile()
	GG.MissileSilo.DestroyMissile(unitID, unitDefID)
	Spring.SetUnitRulesParam(unitID, "do_not_save", 1)
	
	local _, maxHealth = Spring.GetUnitHealth(unitID)
	
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitNoDraw(unitID, true)
	Spring.SetUnitNoMinimap(unitID, true)
	Spring.SetUnitHealth(unitID, {paralyze = 99999999, health = maxHealth}) -- also heal to drop (now off-map) repair orders
	Spring.SetUnitCloak(unitID, 4)
	Spring.SetUnitStealth(unitID, true)
	Spring.SetUnitBlocking(unitID,false,false,false)
	Spring.SetUnitGroup(unitID, -1)
	launched = true
	Sleep(2000)

	-- keep alive for stats
	Spring.SetUnitPosition(unitID,-9001, -9001)
	-- Note that missiles intentionally remove their command 2s after firing
	-- instead of immediately. This is to give some command feedback (that the
	-- command actually was placed) and to show allies where the launch occurred.
	Spring.GiveOrderToUnit(unitID, CMD.STOP, 0, 0)
	
	Sleep(15000)
	Spring.DestroyUnit(unitID, false, true)
end

function script.Shot()
	StartThread(RemoveMissile)
end

function script.AimFromWeapon()
	return base
end

function script.QueryWeapon()
	return base
end

function script.Create()
	Turn(base, x_axis, math.rad(-90))
	Move(base, y_axis, 40)
end

function script.HitByWeapon(x, z, weaponDefID, damage)
	if launched then
		return 0
	end
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.NONE)
	return 1
end
