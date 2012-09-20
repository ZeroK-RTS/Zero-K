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
	Sleep(100)
	Spring.MoveCtrl.Enable(unitID, true)
	local x,y,z = Spring.GetUnitPosition(unitID)
	Spring.MoveCtrl.SetPosition(unitID, x, -150, z)
	Spring.MoveCtrl.SetNoBlocking(unitID, true)
	Hide(base)
	GG.DestroyMissile(unitID, unitDefID)
	Sleep(15000)	-- hang around long enough for missile hit to count towards stats
	Spring.DestroyUnit(unitID, false, true)	--"reclaim the missile"
end

function script.Shot1()
	StartThread(RemoveMissile)
end

function script.AimFromWeapon1() return base end

function script.QueryWeapon1() return base end

function script.Create()
	Turn( base , x_axis, math.rad(-90) )
	Move( base , y_axis,  40)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, sfxNone)
	return 1
end
