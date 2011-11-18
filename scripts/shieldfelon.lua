GetUnitShieldState = Spring.GetUnitShieldState
SetUnitShieldState = Spring.SetUnitShieldState
include "constants.lua"

-- pieces
local base = piece "base"
local pelvis = piece "pelvis"
local torso = piece "torso"
local shield = piece "shield"

local shotcent = piece "shotcent"
local shot1 = piece "shot1"
local shot2 = piece "shot2"
local shot3 = piece "shot3"
local shot4 = piece "shot4"
local shot5 = piece "shot5"

local l_thigh = piece "l_thigh"
local l_leg = piece "l_leg"
local l_foot = piece "r_foot"

local r_thigh = piece "r_thigh"
local r_leg = piece "r_leg"
local r_foot = piece "l_foot"

smokePiece = {pelvis, torso}

local shotPieces = {shield, shot1, shot2, shot3, shot4}

-- constants
local DRAIN = 20
local MIN_CHARGE = 50
local SHIELD_RADIUS = 100

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

function script.QueryWeapon(num) return shotPieces[num] end

function script.AimFromWeapon(num) return shotcent end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then return false end
	
	-- use only for single weapon design plz
	Turn(shotcent, y_axis, heading)
	Turn(shotcent, x_axis, -pitch + math.rad(90))
	--Move(shot1, y_axis, math.sin(pitch)*-SHIELD_RADIUS)
	--Move(shot1, x_axis, math.sin(heading)*SHIELD_RADIUS)
	--Move(shot1, z_axis, math.cos(heading)*SHIELD_RADIUS)
	

	return select(2, GetUnitShieldState(unitID)) > MIN_CHARGE
end

function script.FireWeapon(num)
	local shieldPow = select(2, GetUnitShieldState(unitID))
	SetUnitShieldState(unitID, shieldPow - DRAIN)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		Explode(shield, sfxShatter)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(torso, sfxShatter)
		Explode(shield, sfxFall)
		return 1 -- corpsetype
	else
		Explode(base, sfxShatter)
		Explode(pelvis, sfxSmoke + sfxFire)
		Explode(torso, sfxSmoke + sfxFire + sfxExplode)
		Explode(shield, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
