
include "constants.lua"

-- pieces
local head = piece "head"
local hips = piece "hips"
local chest = piece "chest"

-- left arm
local lshoulder = piece "lshoulder"
local lforearm = piece "lforearm"
local gun = piece "gun"
local magazine = piece "magazine"
local flare = piece "flare"
local ejector = piece "ejector"

-- right arm
local rshoulder = piece "rshoulder"
local rforearm = piece "rforearm"

-- left leg
local lthigh = piece "lthigh"
local lshin = piece "lshin"
local lfoot = piece "lfoot"

-- right leg
local rthigh = piece "rthigh"
local rshin = piece "rshin"
local rfoot = piece "rfoot"

smokePiece = {head, hips, chest}


--constants
local runspeed = 8
local steptime = 40

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim  = 4

function script.Create()
	StartThread(SmokeUnit)
	Turn( flare, x_axis, 1.6, 5 )
	Turn( lshoulder, x_axis, -0.9, 5 )
	Turn( lforearm, z_axis, -0.9, 5 )
end

local function Walk()
	SetSignalMask( SIG_Walk )
	while ( true ) do
		Move(hips, y_axis, 1.6, runspeed*2)
		Turn( lshoulder, x_axis, -1.2, runspeed*0.2 )
		Turn( rshoulder, x_axis, 0.3, runspeed*0.5 )
		
		Turn( rthigh, x_axis, -1.5, runspeed*1 )
		Turn( rshin, x_axis, 1.3, runspeed*1 )
--		Turn( rfoot, x_axis, 0.5, runspeed*1 )
		
		Turn( lshin, x_axis, 0.2, runspeed*1 )
		Turn( lthigh, x_axis, 1.2, runspeed*1 )
		
		Sleep( steptime )
		Move(hips, y_axis, -1.6, runspeed*3)
		WaitForTurn( rthigh, x_axis )
		
		Sleep( steptime )
		
		Move(hips, y_axis, 1.6, runspeed*2)
		Turn( lshoulder, x_axis, -0.6, runspeed*0.2 )
		Turn( rshoulder, x_axis, -0.3, runspeed*0.5 )
		
		Turn( lthigh, x_axis, -1.5, runspeed*1 )
		Turn( lshin, x_axis, 1.3, runspeed*1 )
--		Turn( lfoot, x_axis, 0.5, runspeed*1 )
		
		Turn( rshin, x_axis, 0.2, runspeed*1 )
		Turn( rthigh, x_axis, 1.2, runspeed*1 )
		
		Sleep( steptime )
		
		Move(hips, y_axis, -1.6, runspeed*3)
		WaitForTurn( lthigh, x_axis )
		
		Sleep( steptime )

	end
end

local function StopWalk()
	Move(hips, y_axis, 0, 12)
	
	Turn( lthigh, x_axis, 0, 2 )
	Turn( lshin, x_axis, 0, 2 )
	Turn( lfoot, x_axis, 0, 2 )
	
	Turn( rthigh, x_axis, 0, 2 )
	Turn( rshin, x_axis, 0, 2 )
	Turn( rfoot, x_axis, 0, 2 )
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
	Turn( chest, y_axis, 0, 3 )
	Turn( lshoulder, x_axis, -0.9, 5 )
	Turn( rshoulder, x_axis, 0, 3 )

	Turn( lforearm, z_axis, -0.9, 5 )
	Turn( lshoulder, z_axis, 0, 3 )
	Turn( rshoulder, z_axis, 0, 3 )
	Turn( head, y_axis, 0, 2  )
	Turn( head, x_axis, 0, 2 )
	Spin( magazine, y_axis, 0  )
end

----[[
function script.QueryWeapon1() return flare end

function script.AimFromWeapon1() return chest end

function script.AimWeapon1( heading, pitch )
	Signal( SIG_Aim )
	SetSignalMask( SIG_Aim )
	Turn( chest, y_axis, 1.1 + heading, 12 )
	Turn( lshoulder, x_axis, -1 -pitch, 12 )
	Turn( rshoulder, x_axis, -0.9 -pitch, 12 )
	
	Turn( rshoulder, z_axis, 0.3, 9 )
	Turn( lshoulder, z_axis, -0.3, 9 )
	
	Turn( head, y_axis, -0.8, 9  )
	Turn( head, x_axis, -pitch, 9 )
	
--	WaitForTurn( chest, y_axis )
--	WaitForTurn( lshoulder, x_axis )
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	Spin( magazine, y_axis, 2  )
	EmitSfx( ejector, 1024 )
	EmitSfx( flare, 1025 )
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(hips, sfxNone)
		Explode(head, sfxNone)
		Explode(chest, sfxNone)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(hips, sfxNone)
		Explode(head, sfxNone)
		Explode(chest, sfxShatter)
		return 1 -- corpsetype
	else
		Explode(hips, sfxShatter)
		Explode(head, sfxSmoke + sfxFire)
		Explode(chest, sfxSmoke + sfxFire + sfxExplode)
		return 2 -- corpsetype
	end
end
