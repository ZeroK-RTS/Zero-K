
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

-- groups
local shoulder = {lshoulder, rshoulder}
local forearm = {lforearm, rforearm}
local thigh = {lthigh, rthigh}
local shin = {lshin, rshin}
local foot = {lfoot, rfoot}

local smokePiece = {head, hips, chest}

--constants
local runspeed = 8.5 * (UnitDefs[unitDefID].speed / 115)  -- run animation rate, future-proofed
local steptime = 40  -- how long legs stay extended during stride
local hangtime = 20 -- how long it takes for "gravity" to accelerate stride descent
local stride_top = 1.5  -- how high hips go during stride
local stride_bottom = -1.0  -- how low hips go during stride

-- variables
local moving = false
local aiming = false

--signals
local SIG_Idle = 1
local SIG_Walk = 2
local SIG_Aim = 4

local function GetSpeedMod()
	return (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Turn(flare, x_axis, 1.6, 5)
	Turn(lshoulder, x_axis, math.rad(-10))
	Turn(lforearm, x_axis, math.rad(-30))
	Turn(lforearm, z_axis, math.rad(-12))
	Turn(rshoulder, x_axis, math.rad(0))
	Turn(rforearm, x_axis, math.rad(-15))
end

local function Walk()
	Signal(SIG_Walk)
	Signal(SIG_Idle)
	SetSignalMask(SIG_Walk)

	moving = true

	for i = 1, 2 do
		Turn(thigh[i], y_axis, 0, runspeed*0.15)
		Turn(thigh[i], z_axis, 0, runspeed*0.15)
	end

	local side = 1
	local sway = 1
	-- randomly lead with either foot
	if math.random() > 0.5 then
		side = 2
		sway = -1
	end

	while true do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod

		if not aiming then
			Turn(head, y_axis, 0, 2.0)
			Turn(lshoulder, x_axis, math.rad(-15)-math.rad(45)*sway, truespeed*0.5)
			Turn(lforearm, x_axis, math.rad(-45)+math.rad(45)*sway, truespeed*0.5)
			Turn(rshoulder, x_axis, math.rad(0)+math.rad(45)*sway, truespeed*0.5)
			Turn(rforearm, x_axis, math.rad(-80)-math.rad(40)*sway, truespeed*0.5)
		end

		Turn(thigh[side], x_axis, math.rad(-85), truespeed*1)
		Turn(shin[side], x_axis, math.rad(75), truespeed*1)
		Turn(foot[side], x_axis, math.rad(0), truespeed*0.33)

		Turn(thigh[3-side], x_axis, math.rad(68), truespeed*1)
		Turn(shin[3-side], x_axis, math.rad(12), truespeed*1)
		Turn(foot[3-side], x_axis, math.rad(-20), truespeed*0.33)

		Turn(hips, z_axis, math.rad(-6)*sway, truespeed*0.05)
		Move(hips, y_axis, stride_bottom, truespeed*1)
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

local function Idle()
	Signal(SIG_Idle)
	SetSignalMask(SIG_Idle)

	if moving or aiming then return end

	Sleep(3000)

	local rand = math.random()
	local dir = 1
	if rand > 0.5 then dir = -1 end
	while true do
		Sleep(3000 * rand)

		Turn(lshoulder, x_axis, math.rad(-10), 0.5)
		Turn(lforearm, x_axis, math.rad(-30), 0.5)

		Turn(head, y_axis, math.rad(30)*dir, 0.5)
		dir = dir * -1

		Sleep(3000)
	end
end

local function StopWalk()
	Signal(SIG_Walk)

	moving = false

	Move(hips, y_axis, 0, 15.0)
	Turn(hips, z_axis, 0, 0.5)

	if not aiming then
		Turn(lshoulder, x_axis, math.rad(-45), runspeed*0.3)
		Turn(lforearm, x_axis, math.rad(-12), runspeed*0.3)
	end

	Turn(rshoulder, x_axis, math.rad(0), runspeed*0.3)
	Turn(rforearm, x_axis, math.rad(-15), runspeed*0.3)

	for i = 1, 2 do
		Turn(thigh[i], x_axis, 0, 5)
		Turn(shin[i], x_axis, 0, 5)
		Turn(foot[i], x_axis, 0, 5)

		Turn(thigh[i], y_axis, math.rad(12 - i*8), runspeed*0.1)
		Turn(thigh[i], z_axis, math.rad(4*i - 6), runspeed*0.1)
	end

	StartThread(Idle)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Sleep(2000)
	aiming = false

	Turn(chest, y_axis, 0, 3)
	Turn(lshoulder, x_axis, math.rad(-45), 5)
	Turn(lshoulder, z_axis, 0, 3)
	Turn(lforearm, z_axis, math.rad(-12), 5)
	Turn(rshoulder, x_axis, math.rad(0), runspeed*0.3)
	Turn(rforearm, x_axis, math.rad(-15), runspeed*0.3)
	Spin(magazine, y_axis, 0)

	StartThread(Idle)
end

function script.QueryWeapon(num)
	return flare
end

function script.AimFromWeapon(num)
	return chest
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	Signal(SIG_Idle)
	SetSignalMask(SIG_Aim)
	aiming = true

	Turn(head, y_axis, 0, 4.0)
	Turn(chest, y_axis, heading, 12)
	Turn(lforearm, z_axis, 0, 6)
	Turn(lforearm, x_axis, 0, 6)
	Turn(lshoulder, x_axis, -pitch - math.rad(80), 12)
	Turn(rshoulder, x_axis, math.rad(0), math.rad(90))
	Turn(rforearm, x_axis, math.rad(-45), math.rad(90))

	WaitForTurn(chest, y_axis)
	WaitForTurn(lshoulder, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	Spin(magazine, y_axis, 2)
	EmitSfx(ejector, 1024)
	EmitSfx(flare, 1025)
	-- Generic attributes testing.
	--GG.Attributes.RemoveEffect(unitID, math.floor(math.random()*10))
	--GG.Attributes.AddEffect(unitID, math.floor(math.random()*10), {
	--	move = 0.5 + math.random(),
	--	reload = 0.5 + math.random(),
	--	sense = 0.5 + math.random(),
	--	range = 0.5 + math.random()
	--})
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
