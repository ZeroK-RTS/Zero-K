
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

local smokePiece = {head, hips, chest}


--constants
local runspeed = 8
local steptime = 40

-- variables
local firing = 0

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim  = 4

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Turn(flare, x_axis, 1.6, 5)
	Turn(lshoulder, x_axis, -0.9, 5)
	Turn(lforearm, z_axis, -0.2, 5)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	while (true) do
		Turn(lshoulder, x_axis, -1.2, runspeed*0.2)
		Turn(hips, z_axis, 0.1, runspeed*0.05)
		Turn(rshoulder, x_axis, 0.5, runspeed*0.3)
		
		Turn(rthigh, x_axis, -1.5, runspeed*1)
		Turn(rshin, x_axis, 1.3, runspeed*1)
--		Turn(rfoot, x_axis, 0.5, runspeed*1)
		
		Turn(lshin, x_axis, 0.2, runspeed*1)
		Turn(lthigh, x_axis, 1.2, runspeed*1)

		WaitForTurn(rthigh, x_axis)

		Sleep(steptime)
		
		Turn(lshoulder, x_axis, -0.6, runspeed*0.2)
		Turn(hips, z_axis, -0.1, runspeed*0.05)
		Turn(rshoulder, x_axis, -0.5, runspeed*0.3)
		
		Turn(lthigh, x_axis, -1.5, runspeed*1)
		Turn(lshin, x_axis, 1.3, runspeed*1)
--		Turn(lfoot, x_axis, 0.5, runspeed*1)
		
		Turn(rshin, x_axis, 0.2, runspeed*1)
		Turn(rthigh, x_axis, 1.2, runspeed*1)
		
		WaitForTurn(lthigh, x_axis)
		
		Sleep(steptime)

	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	Turn(hips, z_axis, 0, 0.5)
	
	Turn(lthigh, x_axis, 0, 2)
	Turn(lshin, x_axis, 0, 2)
	Turn(lfoot, x_axis, 0, 2)
	
	Turn(rthigh, x_axis, 0, 2)
	Turn(rshin, x_axis, 0, 2)
	Turn(rfoot, x_axis, 0, 2)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Signal(SIG_Restore)
	SetSignalMask(SIG_Restore)
	Sleep(2000)
	firing = 0
	Turn(chest, y_axis, 0, 3)
	Turn(lshoulder, x_axis, -0.9, 5)
	Turn(rshoulder, x_axis, 0, 3)

	Turn(lforearm, z_axis, -0.2, 5)
	Turn(lshoulder, z_axis, 0, 3)
	Turn(rshoulder, z_axis, 0, 3)
	Turn(head, y_axis, 0, 2)
	Turn(head, x_axis, 0, 2)
	Spin(magazine, y_axis, 0)
end

function script.QueryWeapon(num) 
	return flare 
end

function script.AimFromWeapon(num) 
	return chest 
end

function script.AimWeapon(num, heading, pitch)
	
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	--[[ Gun Hugger
	Turn(chest, y_axis, 1.1 + heading, 12)
	Turn(lshoulder, x_axis, -1 -pitch, 12)
	Turn(rshoulder, x_axis, -0.9 -pitch, 12)
	
	Turn(rshoulder, z_axis, 0.3, 9)
	Turn(lshoulder, z_axis, -0.3, 9)
	
	Turn(head, y_axis, -0.8, 9)
	Turn(head, x_axis, -pitch, 9)--]]
	
	-- Outstreched Arm
	firing = 1
	Turn(chest, y_axis, heading, 12)
	Turn(lforearm, z_axis, 0, 5)
	Turn(lshoulder, x_axis, -pitch - 1.5, 12)
	
	
	WaitForTurn(chest, y_axis)
	WaitForTurn(lshoulder, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	Spin(magazine, y_axis, 2)
	EmitSfx(ejector, 1024)
	EmitSfx(flare, 1025)
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
