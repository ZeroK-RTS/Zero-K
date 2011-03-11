

include "constants.lua"

--pieces
local base = piece "base"
local pelvis = piece "pelvis"
local torso = piece "torso"

-- guns
local lturret1 = piece "lturret1"
local lturret2 = piece "lturret2"
local rturret1 = piece "rturret1"
local rturret2 = piece "rturret2"

-- legs
local lfleg = piece "lfleg"
local lffoot = piece "lffoot"

local rfleg = piece "rfleg"
local rffoot = piece "rffoot"

local lbleg = piece "lbleg"
local lbfoot = piece "lbfoot"

local rbleg = piece "rbleg"
local rbfoot = piece "rbfoot"


local smokePieces = { pelvis, torso, lturret1, rbleg}

local points = {
	{missile = lturret1},
	{missile = lturret2},
	{missile = rturret1},
	{missile = rturret2},
}

local missile = 1

--constants
local missilespeed = 850
local mfront = 10
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
	while ( true ) do
		Move(base, y_axis, 2.8, 12)
		
		Turn( lfleg, x_axis, -0.3, 2 )
		Turn( lffoot, x_axis, 0.6, 4 )
		
		Turn( rfleg, x_axis, 0.3, 1 )
		Turn( rffoot, x_axis, -0.6, 4 )
		
		Sleep( 280 )
		Move(base, y_axis, 0, 10)
		
		Turn( rbleg, x_axis, 0.3, 3 )
		Turn( rbfoot, x_axis, -0.6, 2 )
		
		Turn( lbleg, x_axis, -0.3, 2 )
		Turn( lbfoot, x_axis, 0.6, 3 )
		
		Sleep( 280 )
		Move(base, y_axis, 2.8, 12)
		
		Turn( rfleg, x_axis, -0.3, 2 )
		Turn( rffoot, x_axis, 0.6, 4 )
		
		Turn( lfleg, x_axis, 0.3, 1 )
		Turn( lffoot, x_axis, -0.6, 4 )
		
		Sleep( 280 )
		Move(base, y_axis, 0, 10)
		
		Turn( lbleg, x_axis, 0.3, 3 )
		Turn( lbfoot, x_axis, -0.6, 2 )
		
		Turn( rbleg, x_axis, -0.3, 2 )
		Turn( rbfoot, x_axis, 0.6, 3 )
		
		Sleep( 280 )
		
	end
end

local function StopWalk()
	Move(base, y_axis, 0, 12)
	
	Turn( rfleg, x_axis, 0, 1 )
	Turn( rffoot, x_axis, 0, 2 )
		
	Turn( lfleg, x_axis, 0, 1 )
	Turn( lffoot, x_axis, 0, 2 )
		
	Turn( lbleg, x_axis, 0, 1 )
	Turn( lbfoot, x_axis, 0, 2 )
		
	Turn( rbleg, x_axis, 0, 1 )
	Turn( rbfoot, x_axis, 0, 2 )
		
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
	Turn( torso, y_axis, 0, 3 )
end

----[[
function script.QueryWeapon1() return points[missile].missile end

function script.AimFromWeapon1() return torso end

function script.AimWeapon1( heading, pitch )
	Signal( SIG_Aim )
	SetSignalMask( SIG_Aim )
	Turn( torso, y_axis, heading, 3 )
	WaitForTurn( torso, y_axis )
	StartThread(RestoreAfterDelay)
	return true
end

function script.Shot1()
	missile = missile + 1
	if missile > 4 then missile = 1 end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		Explode(lturret1, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(pelvis, sfxNone)
		Explode(torso, sfxNone)
		Explode(lturret1, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(pelvis, sfxShatter)
		Explode(torso, sfxSmoke + sfxFire)
		Explode(lturret1, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
