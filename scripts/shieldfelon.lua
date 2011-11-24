local spGetUnitShieldState = Spring.GetUnitShieldState
local spSetUnitShieldState = Spring.SetUnitShieldState
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
local l_foot = piece "l_foot"

local r_thigh = piece "r_thigh"
local r_leg = piece "r_leg"
local r_foot = piece "r_foot"

local lbarrel, rbarrel = piece("lbarrel", "rbarrel")
local lpilot, rpilot = piece("lpilot", "rpilot")

smokePiece = {pelvis, torso}

local shotPieces = {
	{lpilot, rpilot},
	shield
}
local gun_1 = 0

-- constants
local DRAIN = 75
local SHIELD_RADIUS = 100
local SPEED = 1.2

--signals
local SIG_Walk = 1

function script.Create()
	StartThread(SmokeUnit)
end

local function Walk()
	SetSignalMask( SIG_Walk )
    
    while ( true ) do
        local speedmult = (1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0))*SPEED
		
        Move(pelvis, y_axis, 6.2, 4*speedmult)
        
        Turn( l_thigh, x_axis, -1.3, 1.4*speedmult )
		Turn( l_leg, x_axis, 0.4, 1.4*speedmult )
		Turn( l_foot, x_axis, 0.8, 1*speedmult )
        
		Turn( r_thigh, x_axis, -0.15, 0.9*speedmult )
		Turn( r_leg, x_axis, 0.8, 0.6*speedmult )
		Turn( r_foot, x_axis, -0.65, 1.5*speedmult )
		
		Sleep( 500/speedmult )
        
		Move(pelvis, y_axis, 8.2, 4*speedmult)
		
        Turn( l_thigh, x_axis, -0.6, 1.4*speedmult )
		Turn( l_leg, x_axis, 0.5, 1*speedmult)
		Turn( l_foot, x_axis, 0.1, 1.4*speedmult )
        
		Turn( r_thigh, x_axis, -0.6, 0.9*speedmult )
		Turn( r_leg, x_axis, -0.3, 2.2*speedmult )
		Turn( r_foot, x_axis, 0.3, 1.9*speedmult )
		
		Sleep( 500/speedmult )
		
		Move(pelvis, y_axis, 6, 4*speedmult)
		
        Turn( l_thigh, x_axis, -0.15, 0.9*speedmult )
		Turn( l_leg, x_axis, 0.8, 0.6*speedmult )
		Turn( l_foot, x_axis, -0.65, 1.5*speedmult )
        
		Turn( r_thigh, x_axis, -1.3, 1.4*speedmult )
		Turn( r_leg, x_axis, 0.4, 1.4*speedmult )
		Turn( r_foot, x_axis, 0.8, 1*speedmult )
		
		Sleep( 500/speedmult )
		
		Move(pelvis, y_axis, 8.2, 4*speedmult)
        
        Turn( l_thigh, x_axis, -0.6, 0.9*speedmult )
		Turn( l_leg, x_axis, -0.3, 2.2*speedmult )
		Turn( l_foot, x_axis, 0.3, 1.9*speedmult )
        
        Turn( r_thigh, x_axis, -0.6, 1.4*speedmult )
		Turn( r_leg, x_axis, 0.5, 1*speedmult)
		Turn( r_foot, x_axis, 0.1, 1.4*speedmult )
		
		Sleep(  500/speedmult )
	end
end

local function StopWalk()
	Move(pelvis, y_axis, 0, 8)
	
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

function script.QueryWeapon(num) 
	if num == 1 then return shotPieces[num][gun_1 + 1] end
	return shotPieces[num] 
end

function script.AimFromWeapon(num) return shot1 end

function script.AimWeapon(num, heading, pitch)
	if num == 2 then 
        return false 
    end
	-- use only for single weapon design plz
	--Turn(shotcent, y_axis, heading)
	--Turn(shotcent, x_axis, -pitch + math.rad(90))
	--Move(shot1, y_axis, math.sin(pitch)*-SHIELD_RADIUS)
	--Move(shot1, x_axis, math.sin(heading)*SHIELD_RADIUS)
	--Move(shot1, z_axis, math.cos(heading)*SHIELD_RADIUS)
	return true
end

function script.BlockShot(num)
    if num == 2 then
        return false
    end
    local shieldPow = select(2, spGetUnitShieldState(unitID))
    if shieldPow > DRAIN then
        spSetUnitShieldState(unitID, shieldPow - DRAIN)
        return false
    else
        return true
    end
end

function script.FireWeapon(num)
	if num == 1 then
		gun_1 = 1 - gun_1
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		Explode(lbarrel, sfxNone)
		Explode(rbarrel, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(pelvis, sfxNone)
		Explode(torso, sfxShatter)
		Explode(lbarrel, sfxShatter)
		Explode(rbarrel, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(pelvis, sfxSmoke + sfxFire)
		Explode(torso, sfxShatter)
		Explode(lbarrel, sfxSmoke + sfxFire + sfxExplode)
		Explode(rbarrel, sfxSmoke + sfxFire + sfxExplode)		
		return 2 -- corpsetype
	end
end
