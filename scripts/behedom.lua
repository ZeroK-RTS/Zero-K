-- Should work!
--by Saktoth adapted from Chris Mackey

include "constants.lua"

-- pieces
local base = piece "base"

-- missile rack
local turret = piece "turret"
local pelvis = piece "pelvis"

local body = piece "body"

local lthigh = piece "lthigh"
local lleg = piece "lleg"
local lfoot = piece "lfoot"

local rthigh = piece "rthigh"
local rleg = piece "rleg"
local rfoot = piece "rfoot"

local exhaust1 = piece "exhaust1"
local exhaust2 = piece "exhaust2"

smokePiece = {body, pelvis}

local points = {
	{missile = m_1, exhaust = exhaust1},
	{missile = m_2, exhaust = exhaust2},
}

local missile = 1

--constants
local missilespeed = 850 --fixme
local mfront = 10 --fixme
local pause = 600

--effects
local smokeblast = 1024

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim  = 4

function script.Create()
	StartThread(SmokeUnit)
end

local function Walk()
	SetSignalMask( SIG_Walk )
	while ( true ) do -- needs major fixing. 
		Move(base, y_axis, 3.6, 6)
		
		Turn( lthigh, x_axis, 0.6, 2 )
		Turn( lleg, x_axis, 0.6, 1.75 )
		
		Turn( rthigh, x_axis, -1, 2.5 )
		Turn( rleg, x_axis, -0.4, 3 )
		Turn( lfoot, x_axis, -0.8, 2 )
		
		Sleep( 280 )
		Move(base, y_axis, 0, 5)
		
		Turn( rthigh, x_axis, -1, 1 )
		Turn( rleg, x_axis, 0.4, 3 )
		Turn( rfoot, x_axis, 0, 1.75 )
		
		Sleep( 280 )
		
		Move(base, y_axis, 3.6, 6)
		
		Turn( lthigh, x_axis, -1, 2.5 )
		Turn( lleg, x_axis, -0.4, 3 )
		Turn( lfoot, x_axis, -0.8, 2 )
		
		Turn( rthigh, x_axis, 0.6, 2 )
		Turn( r_eg, x_axis, 0.6, 1.75 )
		
		Sleep( 280 )
		
		Move(base, y_axis, 0, 5)
		
		Turn( lthigh, x_axis, -1, 1 )
		Turn( lleg, x_axis, 0.4, 3 )
		Turn( lfoot, x_axis, 0, 1.75 )
		
		Sleep(  280 )
	end
end

local function StopWalk()
	Move(base, y_axis, 0, 6)
	
	Turn( lthigh, x_axis, 0, 1 )
	Turn( lleg, x_axis, 0, 1 )
	Turn( lfoot, x_axis, 0, 1 )
	
	Turn( rthigh, x_axis, 0, 1 )
	Turn( rleg, x_axis, 0, 1 )
	Turn( rfoot, x_axis, 0, 1 )
end

function script.StartMoving()
	--SetSignalMask( walk )
	StartThread( Walk )
end

function script.StopMoving()
	Signal( SIG_Walk )
	--SetSignalMask( SIG_Walk )
	StartThread( StopWalk )
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(2000)
	Turn( body, y_axis, 0, 3 )
	Turn( turret, x_axis, 0, 3 )
end

----[[
function script.QueryWeapon1() return points[missile].missile end

function script.AimFromWeapon1() return body end

function script.AimWeapon1( heading, pitch )
	Signal( SIG_Aim )
	SetSignalMask( SIG_Aim )
	pitch = math.max(pitch, math.rad(20))	-- results in a minimum pod angle of 20° above horizontal
	Turn( body, y_axis, heading, 3 )
	Turn( turret, x_axis, -pitch, 3 )
	WaitForTurn( body, y_axis )
	WaitForTurn( turret, x_axis )
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	missile = missile + 1
	if missile > 2 then missile = 1 end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(body, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(turret, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(body, sfxNone)
		Explode(pelvis, sfxNone)
		Explode(turret, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(body, sfxShatter)
		Explode(pelvis, sfxSmoke + sfxFire)
		Explode(turret, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
