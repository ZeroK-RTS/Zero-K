local GetUnitStates = Spring.GetUnitStates

local base = piece 'base' 
local dish1 = piece 'dish1' 
local dish2 = piece 'dish2' 
local dish3 = piece 'dish3' 
local dish4 = piece 'dish4' 

local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitHealth = Spring.GetUnitHealth

include "constants.lua"

local smokePiece = {base}

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
	StartThread(SmokeUnit, smokePiece)
	Turn( base , y_axis, math.rad(45) )	
end

local force_close_time = tonumber(UnitDef.customParams.force_close) * 1000

local function DefensiveManeuver()
	Signal(SIG_Defensive)
	SetSignalMask(SIG_Defensive)
	SetUnitValue(COB.ACTIVATION, 0)
	spSetUnitRulesParam(unitID, "force_close", 1)
	Sleep(force_close_time)
	spSetUnitRulesParam(unitID, "force_close", 0)
	SetUnitValue(COB.ACTIVATION, 1)
end

function HitByWeaponGadget()
	local buildProgress = select(5, spGetUnitHealth(unitID))
	if (buildProgress == 1) then
		StartThread(DefensiveManeuver)
	end
end

local noFFWeaponDefs = {}
for wdid = 1, #WeaponDefs do
	local wd = WeaponDefs[wdid]
	if wd.customParams and wd.customParams.nofriendlyfire then
		noFFWeaponDefs[wdid] = true
	end
end

-- this happens before PreDamaged but only in 97.0+
function script.HitByWeapon(x, z, weaponDefID, damage)
	if damage > 1 and not (weaponDefID and noFFWeaponDefs[weaponDefID]) then
		StartThread(DefensiveManeuver)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .50 then
		Explode(dish1, sfxSmoke  + sfxFire  + sfxExplode )
		Explode(dish2, sfxNone)
		Explode(dish3, sfxNone)
		Explode(dish4, sfxNone)
		Explode(base, sfxNone)
		return 1
	elseif severity <= .99  then
		Explode(dish1, sfxSmoke  + sfxFire  + sfxExplode )
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
