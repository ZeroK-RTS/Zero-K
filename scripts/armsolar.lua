local GetUnitStates = Spring.GetUnitStates

local base = piece 'base' 
local dish1 = piece 'dish1' 
local dish2 = piece 'dish2' 
local dish3 = piece 'dish3' 
local dish4 = piece 'dish4' 

local bomberWeaponDefs = {
	[WeaponDefNames["corshad_shield_check"].id] = true,
}

include "constants.lua"

smokePiece = {base}

local SIG_Activate = 2
local SIG_Defensive = 4

-- don't ask daddy difficult questions like "Why does it armor at the START of the animation?"
local function Open()
	Signal(SIG_Activate)
	SetSignalMask(SIG_Activate)
	Turn( dish1 , x_axis, math.rad(-75), math.rad(60) )
	Turn( dish2 , x_axis, math.rad(75), math.rad(60) )
	Turn( dish3 , z_axis, math.rad(75), math.rad(60) )
	Turn( dish4 , z_axis, math.rad(-75), math.rad(60) )
	WaitForTurn(dish1, z_axis)
	WaitForTurn(dish2, z_axis)
	WaitForTurn(dish3, x_axis)
	WaitForTurn(dish4, x_axis)
	Spring.SetUnitArmored(unitID,false)
	--SetUnitValue(COB.ARMORED,1)	
end

local function Close()
	Signal(SIG_Activate)
	SetSignalMask(SIG_Activate)
	Spring.SetUnitArmored(unitID,true)
	SetUnitValue(COB.ARMORED,1)
	Turn( dish1 , x_axis, 0, math.rad(120) )
	Turn( dish2 , x_axis, 0, math.rad(120) )
	Turn( dish3 , z_axis, 0, math.rad(120) )
	Turn( dish4 , z_axis, 0, math.rad(120) )
	WaitForTurn(dish1, z_axis)
	WaitForTurn(dish2, z_axis)
	WaitForTurn(dish3, x_axis)
	WaitForTurn(dish4, x_axis)
end

function script.Activate()
	StartThread(Open)
end

function script.Deactivate()
	StartThread(Close)
end

function script.Create()
	StartThread(SmokeUnit)
	Turn( base , y_axis, math.rad(45) )	
end

local function DefensiveManeuver()
	Signal(SIG_Defensive)
	SetSignalMask(SIG_Defensive)
	SetUnitValue(COB.ACTIVATION, 0)
	Sleep(8000)
	SetUnitValue(COB.ACTIVATION, 1)
end

function HitByWeaponGadget()
	StartThread(DefensiveManeuver)
end

--[[
-- this happens before PreDamaged
function script.HitByWeapon(x, z, weaponDefID, damage)
	if damage > 1 and not bomberWeaponDefs[weaponDefID] then
		StartThread(DefensiveManeuver)
	end
end
--]]


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .50 then
		Explode(dish1, sfxNone)
		Explode(dish2, sfxNone)
		Explode(dish3, sfxNone)
		Explode(dish4, sfxNone)
		Explode(base, sfxNone)
		return 1
	elseif severity <= .99  then
		Explode(dish1, sfxFall)
		Explode(dish2, sfxFall)
		Explode(dish3, sfxFall)
		Explode(dish4, sfxFall)
		Explode(base, sfxNone)
		return 2
	else
		Explode(dish1, sfxSmoke  + sfxFire  + sfxExplode )
		Explode(dish2, sfxSmoke  + sfxFire  + sfxExplode )
		Explode(dish3, sfxSmoke  + sfxFire  + sfxExplode )
		Explode(dish4, sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxShatter + sfxExplode )
		return 2
	end
end
