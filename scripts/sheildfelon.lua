
include "constants.lua"

-- pieces
local base = piece "base"
local pelvis = piece "pelvis"
local torso = piece "torso"
local shield = piece "shield"

-- weapons
local shot1 = piece "shot1"
local shot2 = piece "shot2"
local shot3 = piece "shot3"
local shot4 = piece "shot4"

--left leg
local l_thigh = piece "l_thigh"
local l_leg = piece "l_leg"
local l_foot = piece "r_foot"

--right leg
local r_thigh = piece "r_thigh"
local r_leg = piece "r_leg"
local r_foot = piece "l_foot"

smokePiece = {pelvis, torso}

--variables
local shieldpower = 1

--effects
local smokeblast = 1024

--signals
local SIG_Walk = 1

function script.Create()
	StartThread(SmokeUnit)
end

local function Walk()
	SetSignalMask( SIG_Walk )
	while ( true ) do
		Move(base, y_axis, 3.6, 4)
		
		Turn( l_thigh, x_axis, 0.6, 1.33 )
		Turn( l_leg, x_axis, 0.6, 1.16 )
		
		Turn( r_thigh, x_axis, -1, 1.66 )
		Turn( r_leg, x_axis, -0.4, 2 )
		Turn( r_foot, x_axis, -0.8, 1.33 )
		
		Sleep( 570 )
		Move(base, y_axis, 0, 10)
		
		Turn( r_thigh, x_axis, -1, 0.66 )
		Turn( r_leg, x_axis, 0.4, 2 )
		Turn( r_foot, x_axis, 0, 1.16 )
		
		Sleep( 570 )
		
		Move(base, y_axis, 3.6, 4)
		
		Turn( l_thigh, x_axis, -1, 1.66 )
		Turn( l_leg, x_axis, -0.4, 2 )
		Turn( l_foot, x_axis, -0.8, 1.33 )
		
		Turn( r_thigh, x_axis, 0.6, 1.33 )
		Turn( r_leg, x_axis, 0.6, 1.16 )
		
		Sleep( 570 )
		
		Move(base, y_axis, 0, 10)
		
		Turn( l_thigh, x_axis, -1, 0.66 )
		Turn( l_leg, x_axis, 0.4, 2 )
		Turn( l_foot, x_axis, 0, 1.16 )
		
		Sleep(  570 )
	end
end

local function StopWalk()
	Move(base, y_axis, 0, 12)
	
	Turn( l_thigh, x_axis, 0, 2 )
	Turn( l_leg, x_axis, 0, 2 )
	Turn( l_foot, x_axis, 0, 2 )
	
	Turn( r_thigh, x_axis, 0, 2 )
	Turn( r_leg, x_axis, 0, 2 )
	Turn( r_foot, x_axis, 0, 2 )
end

function script.StartMoving()
	StartThread( Walk )
end

function script.StopMoving()
	Signal( SIG_Walk )
	StartThread( StopWalk )
end

function script.QueryWeapon1() return shield end

function script.AimFromWeapon1() return shield end

function script.AimWeapon1() return true end


function script.QueryWeapon2() return shot1 end

function script.AimFromWeapon2() return shot1 end

function script.AimWeapon2()
	if (GetUnitValue(COB.SHIELD_POWER) < 5000000) then return false end
	return true
	end

function script.FireWeapon2()
	shieldpower = Spring.UnitScript.GetUnitValue(COB.SHIELD_POWER)
	Spring.UnitScript.SetUnitValue( COB.SHIELD_POWER, (shieldpower-2000000))
	end


function script.QueryWeapon3() return shot2 end

function script.AimFromWeapon3() return shot2 end

function script.AimWeapon3()
	if (GetUnitValue(COB.SHIELD_POWER) < 5000000) then return false end
	return true
	end
	
function script.FireWeapon3()
	shieldpower = Spring.UnitScript.GetUnitValue(COB.SHIELD_POWER)
	Spring.UnitScript.SetUnitValue( COB.SHIELD_POWER, (shieldpower-500000))
	end

	
function script.QueryWeapon4() return shot3 end

function script.AimFromWeapon4() return shot3 end

function script.AimWeapon4()
	if (GetUnitValue(COB.SHIELD_POWER) < 5000000) then return false end
	return true
	end
	
function script.FireWeapon4()
	shieldpower = Spring.UnitScript.GetUnitValue(COB.SHIELD_POWER)
	Spring.UnitScript.SetUnitValue( COB.SHIELD_POWER, (shieldpower-500000))
	end
	
	
function script.QueryWeapon5() return shot4 end

function script.AimFromWeapon5() return shot4 end

function script.AimWeapon5()
	if (GetUnitValue(COB.SHIELD_POWER) < 5000000) then return false end
	return true
	end
	
function script.FireWeapon5()
	shieldpower = Spring.UnitScript.GetUnitValue(COB.SHIELD_POWER)
	Spring.UnitScript.SetUnitValue( COB.SHIELD_POWER, (shieldpower-500000))
	end
	
	
function script.QueryWeapon6() return shot5 end

function script.AimFromWeapon6() return shot5 end

function script.AimWeapon6()
	if (GetUnitValue(COB.SHIELD_POWER) < 5000000) then return false end
	return true
	end
	
function script.FireWeapon6()
	shieldpower = Spring.UnitScript.GetUnitValue(COB.SHIELD_POWER)
	Spring.UnitScript.SetUnitValue( COB.SHIELD_POWER, (shieldpower-500000))
	end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(torso, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(base, sfxShatter)
		Explode(pelvis, sfxSmoke + sfxFire)
		Explode(torso, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
