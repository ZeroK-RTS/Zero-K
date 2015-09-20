
include "constants.lua"

-- pieces
local head = piece "head"
local hips = piece "hips"
local chest = piece "chest"

-- left arm
local lshoulder = piece "lshoulder"
local lforearm = piece "lforearm"
local halberd = piece "halberd"
local blade = piece "blade"

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
local runspeed = 6
local steptime = 40

-- variables
local firing = false
local moving = false
local idling = false

--signals
local SIG_Restore = 1
local SIG_Walk = 2
local SIG_Aim = 4
local SIG_Idle = 6

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Turn(lforearm, x_axis, 0, 2)
	Turn(lshoulder, z_axis, - 0.9, 6)
	Turn(lshoulder, x_axis, - 0.8, 6)
	Turn(lforearm, y_axis, - 1, 5)
	Turn(halberd, z_axis, 0, 5)
end


local function RestoreFromIdle ()
	idling = false
	Turn (rthigh, y_axis, 0, math.rad(60))
	Turn (lthigh, y_axis, 0, math.rad(100))
	Turn (rthigh, x_axis, 0, math.rad(100))
	Turn (lthigh, x_axis, 0, math.rad(60))
	Turn (rshin, z_axis, 0, math.rad(60))
	Turn (lshin, z_axis, 0, math.rad(60))
	Turn (rshin, x_axis, 0, math.rad(60))
	Turn (lshin, x_axis, 0, math.rad(160))
	Turn (rfoot, z_axis, 0, math.rad(50))
	Turn (rfoot, x_axis, 0, math.rad(40))
	Turn (lfoot, x_axis, 0, math.rad(110))
	Turn (lfoot, z_axis, 0, math.rad(40))
	Move (hips, y_axis, 0, 10)
	Turn (head, y_axis, 0, math.rad(70))
	Turn (rshoulder, x_axis, 0, math.rad(150))
	Turn (rforearm, x_axis, 0, math.rad(34.38))
	Turn (rforearm, y_axis, 0, math.rad(-126))
	Turn (rforearm, z_axis, 0, math.rad(57.3))
	Turn (lshoulder, z_axis, 0, math.rad(60))
	Turn (lshoulder, x_axis, 0, math.rad(60))
	Turn (lforearm, x_axis, 0, math.rad(60))
	Turn (lforearm, y_axis, 0, math.rad(120))
	Move (halberd, z_axis, 0, 30)
	Turn (chest, y_axis, 0, math.rad(140))
end

local function Idle ()
	if moving or firing then return end
	SetSignalMask (SIG_Idle)
	Sleep (12000)
	idling = true
	Turn (rthigh, y_axis, math.rad(-30), math.rad(60))
	Turn (lthigh, y_axis, math.rad(50), math.rad(100))
	Turn (rthigh, x_axis, math.rad(-50), math.rad(100))
	Turn (lthigh, x_axis, math.rad(-30), math.rad(60))
	Turn (rshin, z_axis, math.rad(-30), math.rad(60))
	Turn (lshin, z_axis, math.rad(30), math.rad(60))
	Turn (rshin, x_axis, math.rad(30), math.rad(60))
	Turn (lshin, x_axis, math.rad(80), math.rad(160))
	Turn (rfoot, z_axis, math.rad(25), math.rad(50))
	Turn (rfoot, x_axis, math.rad(20), math.rad(40))
	Turn (lfoot, x_axis, math.rad(-55), math.rad(110))
	Turn (lfoot, z_axis, math.rad(-20), math.rad(40))
	Move (hips, y_axis, -5, 10)
	Turn (head, y_axis, math.rad(-35), math.rad(70))
	Turn (rshoulder, x_axis, math.rad(-75), math.rad(150))
	Turn (rforearm, x_axis, math.rad(17.2), math.rad(34.38))
	Turn (rforearm, y_axis, math.rad(-63), math.rad(-126))
	Turn (rforearm, z_axis, math.rad(28.65), math.rad(57.3))
	Turn (lshoulder, z_axis, math.rad(30), math.rad(60))
	Turn (lshoulder, x_axis, math.rad(-30), math.rad(60))
	Turn (lforearm, x_axis, math.rad(-30), math.rad(60))
	Turn (lforearm, y_axis, math.rad(-60), math.rad(120))
	Move (halberd, z_axis, 15, 30)

	while true do
		Sleep (math.random(1000, 2500))
		Turn (chest, y_axis, math.rad(math.random(10, 70)), math.rad(25))
		WaitForTurn (chest, y_axis)
	end
end

local function Walk()
	if idling then RestoreFromIdle() end
	moving = true
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
	moving = false
	Turn(hips, z_axis, 0, 0.5)
	Turn(rshoulder, x_axis, 0, 0.5)
		
	Turn(lthigh, x_axis, 0, 2)
	Turn(lshin, x_axis, 0, 2)
	Turn(lfoot, x_axis, 0, 2)
	
	Turn(rthigh, x_axis, 0, 2)
	Turn(rshin, x_axis, 0, 2)
	Turn(rfoot, x_axis, 0, 2)
	
	StartThread (Idle)
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
	firing = false
	Turn(chest, y_axis, 0, 3)
	Move(halberd, z_axis, 0, 2)

	StartThread (Idle)
end

----[[
function script.QueryWeapon1() return head end

function script.AimFromWeapon1() return head end

function script.AimWeapon1(heading, pitch)
	if idling then RestoreFromIdle() end
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
	firing = true
	Turn(chest, y_axis, heading, 12)
	
	WaitForTurn(chest, y_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon1()
	Turn(lforearm, x_axis, 0.4, 5)
	Turn(lshoulder, z_axis, - 0, 12)
	Turn(lshoulder, x_axis, - 0.7, 12)
	Turn(lforearm, y_axis, - 0.2, 10)
	Turn(halberd, z_axis, 1, 8)
	Move(halberd, z_axis, 15, 40)
	Sleep (800)
	Turn(lforearm, x_axis, 0, 2)
	Turn(lshoulder, z_axis, - 0.9, 6)
	Turn(lshoulder, x_axis, - 0.8, 6)
	Turn(lforearm, y_axis, - 1, 5)
	Turn(halberd, z_axis, 0, 5)
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
