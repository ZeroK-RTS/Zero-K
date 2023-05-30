include "constants.lua"

local base = piece 'base'
local launched = false
local unitDefName = UnitDefs[unitDefID].name

function script.AimWeapon(heading, pitch)
	return true
end

local function RemoveMissile()
	GG.MissileSilo.DestroyMissile(unitID, unitDefID)
	Spring.SetUnitRulesParam(unitID, "do_not_save", 1)
	
	local _, maxHealth = Spring.GetUnitHealth(unitID)
	if unitDefName == "missileslow" then
		Move(base, x_axis, -3)
		Move(base, z_axis, -5)
	elseif unitDefName == "napalmmissile" then
		Move(base, x_axis, 6)
		Move(base, z_axis, -3)
		Move(base, y_axis, 36)
	elseif unitDefName == "empmissile" then
		Move(base, x_axis, 0.1)
		Move(base, z_axis, -2)
		Move(base, y_axis, 27)
	elseif unitDefName == "tacnuke" then
		Move(base, x_axis, -0.5)
		Move(base, z_axis, 2)
		Move(base, y_axis, 8)
	elseif unitDefName == "seismic" then
		Move(base, x_axis, 3.5)
		Move(base, y_axis, 27)
	end
	
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
	if unitDefName == "missileslow" then
		Move(base, z_axis, 40)
	else
		Move(base, y_axis, 40)
	end
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
