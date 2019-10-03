
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

local thigh = {lthigh, rthigh}
local shin = {lshin, rshin}
local foot = {lfoot, rfoot}

local smokePiece = {head, hips, chest}


--constants
local runspeed = 8.5 * (UnitDefs[unitDefID].speed / 90) -- run animation rate, future-proofed
local steptime = 40  -- how long legs stay extended during stride
local hangtime = 50  -- how long it takes for "gravity" to accelerate stride descent
local stride_top = 1.0  -- how high hips go during stride
local stride_bottom = -1.5  -- how low hips go during stride

-- variables
local moving = false
local aiming = false

--signals
local SIG_Walk = 1
local SIG_Aim = 2

local function GetSpeedMod()
	return (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Turn(lshoulder, z_axis, math.rad(0))
	Turn(lshoulder, x_axis, -math.rad(10))
	Turn(lforearm, x_axis, -math.rad(80))
	Turn(lforearm, y_axis, -math.rad(30))
	Turn(halberd, z_axis, math.rad(0))
	Turn(rthigh, y_axis, math.rad(-10))
	Turn(lthigh, y_axis, math.rad(10))
	Turn(rthigh, z_axis, math.rad(-3))
	Turn(lthigh, z_axis, math.rad(3))
	Turn(lfoot, z_axis, math.rad(-3))
	Turn(rfoot, z_axis, math.rad(3))
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	moving = true

	Turn(chest, x_axis, 0.25, 0.12)
	for i = 1, 2 do
		Turn(thigh[i], y_axis, 0, math.rad(135))
		Turn(thigh[i], z_axis, 0, math.rad(135))
		Turn(foot[i], z_axis, 0, math.rad(135))
	end

	local side = 1
	local sway = 1
	-- randomly lead with either foot
	if math.random() > 0.5 then
		side = 2
		sway = -1
	end

	while (true) do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod

		if not aiming then
			Turn(head, y_axis, math.rad(6)*sway, truespeed*math.rad(8))
			Turn(chest, y_axis, math.rad(-6)*sway, truespeed*math.rad(8))
			Turn(rshoulder, x_axis, math.rad(0)-math.rad(35)*sway, truespeed*0.35)
			Turn(rforearm, x_axis, math.rad(-80)+math.rad(20)*sway, truespeed*0.2)

			Turn(lshoulder, x_axis, -math.rad(10)+math.rad(10)*sway, truespeed*0.2)
			Turn(lforearm, x_axis, -math.rad(80)-math.rad(10)*sway, truespeed*0.2)
			Turn(lforearm, y_axis, -math.rad(30)-math.rad(6)*sway, truespeed*0.05)
		end

		Turn(thigh[side], x_axis, math.rad(-64), truespeed*0.75)
		Turn(shin[side], x_axis, math.rad(75), truespeed*1)
		Turn(foot[side], x_axis, math.rad(0), truespeed*0.33)

		Turn(thigh[3-side], x_axis, math.rad(50), truespeed*0.75)
		Turn(shin[3-side], x_axis, math.rad(0), truespeed*1.25)
		Turn(foot[3-side], x_axis, math.rad(-20), truespeed*0.33)

		Turn(hips, z_axis, math.rad(-6)*sway, truespeed*0.05)
		Move(hips, y_axis, stride_bottom, truespeed*1.5)
		Sleep(hangtime)

		Move(hips, y_axis, stride_bottom, truespeed*4)
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, stride_top, truespeed*4)
		Turn(foot[side], x_axis, math.rad(20), truespeed*0.33)

		WaitForTurn(thigh[side], x_axis)

		Sleep(steptime)

		side = 3 - side
		sway = sway * -1
	end
end

local function StopWalk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	moving = false

	Turn(head, y_axis, 0, math.rad(64))

	if not aiming then
		Turn(chest, y_axis, 0, math.rad(64))

		Turn(lshoulder, z_axis, math.rad(0), math.rad(180))
		Turn(lshoulder, x_axis, -math.rad(10), math.rad(180))
		Turn(lforearm, x_axis, -math.rad(80), math.rad(180))
		Turn(lforearm, y_axis, -math.rad(30), math.rad(180))
		Turn(halberd, z_axis, math.rad(0), math.rad(120))
	end

	Move(hips, y_axis, 0, 3.0)
	Turn(chest, x_axis, 0, 1.5)

	Turn(hips, z_axis, 0, 1.5)
	Turn(hips, y_axis, 0, 1.5)
	Turn(rshoulder, x_axis, 0, 1.5)
	Turn(rforearm, x_axis, 0, 1.5)

	Turn(lthigh, x_axis, 0, 4)
	Turn(lshin, x_axis, 0, 4)
	Turn(lfoot, x_axis, 0, 4)

	Turn(rthigh, x_axis, 0, 4)
	Turn(rshin, x_axis, 0, 4)
	Turn(rfoot, x_axis, 0, 4)

	Turn(rthigh, y_axis, math.rad(-10), math.rad(135))
	Turn(lthigh, y_axis, math.rad(10), math.rad(130))
	Turn(rthigh, z_axis, math.rad(-3), math.rad(135))
	Turn(lthigh, z_axis, math.rad(3), math.rad(130))
	Turn(lfoot, z_axis, math.rad(-3), math.rad(130))
	Turn(rfoot, z_axis, math.rad(3), math.rad(130))
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Sleep(2000)
	Turn(lshoulder, z_axis, math.rad(0), math.rad(180))
	Turn(lshoulder, x_axis, -math.rad(10), math.rad(180))
	Turn(lforearm, x_axis, -math.rad(80), math.rad(180))
	Turn(lforearm, y_axis, -math.rad(30), math.rad(180))
	Turn(halberd, z_axis, math.rad(0), math.rad(120))
	Move(halberd, z_axis, 0, 40)

	if not moving then
		Turn(rshoulder, x_axis, 0, 1.5)
		Turn(rforearm, x_axis, 0, 1.5)
	end

	Turn(chest, y_axis, 0, 3)
	WaitForTurn(chest, y_axis)
	aiming = false
end

function script.QueryWeapon1() return head end

function script.AimFromWeapon1() return head end

function script.AimWeapon1(heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	aiming = true

	Turn(chest, y_axis, heading, 12)
	Turn(head, y_axis, 0, math.rad(64))
	Turn(rshoulder, x_axis, math.rad(0), runspeed*0.35)
	Turn(rforearm, x_axis, math.rad(-80), runspeed*0.2)

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
		Explode(hips, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(chest, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(hips, SFX.NONE)
		Explode(head, SFX.NONE)
		Explode(chest, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(hips, SFX.SHATTER)
		Explode(head, SFX.SMOKE + SFX.FIRE)
		Explode(chest, SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2 -- corpsetype
	end
end
