include "constants.lua"

local base = piece 'base' 

function script.AimWeapon1(heading, pitch) return true end

local function RemoveMissile()
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitNoDraw(unitID, true)
	Spring.SetUnitNoMinimap(unitID, true)
	Spring.SetUnitHealth(unitID, {paralyze=99999999})
	Spring.SetUnitCloak(unitID, 4)
	Spring.SetUnitStealth(unitID, true)	
	Spring.SetUnitBlocking(unitID,false,false,false)
	Sleep(2000)

	-- keep alive for stats
	Spring.SetUnitPosition(unitID,-9001, -9001)
	GG.DestroyMissile(unitID, unitDefID)
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
	Turn( base , x_axis, math.rad(-90) )
	Move( base , y_axis,  40)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, sfxNone)
	return 1
end
