include 'constants.lua'

local head = piece 'head'
local hips = piece 'hips'
local lshoulder = piece 'lshoulder'
local lbcover = piece 'lbcover'
local ltcover = piece 'ltcover'
local rshoulder = piece 'rshoulder'
local rbcover = piece 'rbcover'
local rtcover = piece 'rtcover'
local chest = piece 'chest'
local rthigh = piece 'rthigh'
local lthigh = piece 'lthigh'
local lshin = piece 'lshin'
local rshin = piece 'rshin'
local rfoot = piece 'rfoot'
local lfoot = piece 'lfoot'
local lmissile = piece 'lmissile'
local rmissile = piece 'rmissile'
local rmuzzle = piece 'rmuzzle'
local rexhaust = piece 'rexhaust'
local lmuzzle = piece 'lmuzzle'
local lexhaust = piece 'lexhaust'

local thigh = {lthigh, rthigh}
local shin = {lshin, rshin}
local foot = {lfoot, rfoot}

local RESTORE_SPEED = math.rad(100)
local COVER_UNFOLD_ANGLE = math.rad(100)
local COVER_UNFOLD_SPEED = math.rad(400)

local gun = false
local moving = false
local aiming = false

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_IDLE = 4

-- future-proof running animation against balance tweaks
local runspeed = 0.56 * (UnitDefs[unitDefID].speed / 87)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetSpeedMod()
	return (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
end

local function Idle()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)

	if moving or aiming then return end

	Sleep(3000)

	local rand = math.random()
	local dir = 1
	if rand > 0.5 then dir = -1 end
	while true do
		Sleep(3000 * rand)

		Turn(head, y_axis, math.rad(30)*dir, 0.5)
		dir = dir * -1

		Sleep(3000)
	end
end

local function Walk()
	Signal(SIG_IDLE)
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	moving = true

	local side = 1
	local sway = 1
	-- randomly lead with either foot
	if math.random() > 0.5 then
		side = 2
		sway = -1
	end

	for i = 1, 2 do
		Turn(thigh[i], y_axis, 0, math.rad(135))
		Turn(thigh[i], z_axis, 0, math.rad(135))
		Turn(foot[i], z_axis, 0, math.rad(135))
	end

	while true do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod

		if not aiming then
			Turn(head, y_axis, 0, 2.0)
			Turn(chest, x_axis, math.rad(10), truespeed*math.rad(40))
			Turn(chest, y_axis, math.rad(-10)*sway, truespeed*math.rad(40))
		end

		Turn(hips, z_axis, math.rad(-5)*sway, truespeed*math.rad(45))

		Turn(thigh[side], x_axis, math.rad(-50), truespeed*math.rad(450))
		Turn(shin[side], x_axis, math.rad(65), truespeed*math.rad(640))
		Turn(foot[side], x_axis, math.rad(0), truespeed*math.rad(30))

		Turn(thigh[3-side], x_axis, math.rad(50), truespeed*math.rad(450))
		Turn(shin[3-side], x_axis, math.rad(0), truespeed*math.rad(800))

		Move(hips, y_axis, 0.5, truespeed*18)
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, -2.5, truespeed*18)
		Turn(shin[side], x_axis, math.rad(15), truespeed*math.rad(640))
		Turn(foot[side], x_axis, math.rad(-15), truespeed*math.rad(30))
		Turn(foot[3-side], x_axis, math.rad(15), truespeed*math.rad(30))

		WaitForTurn(thigh[side], x_axis)

		side = 3 - side
		sway = sway * -1
	end
end

local function StopWalk()
	Signal(SIG_WALK)
	moving = false

	Turn(chest, x_axis, 0, math.rad(120))
	Turn(chest, y_axis, 0, math.rad(120))
	Turn(hips, z_axis, 0, math.rad(80))
	Move(hips, y_axis, 0.0, 10.0)

	Turn(rthigh, y_axis, math.rad(-20), math.rad(135))
	Turn(lthigh, y_axis, math.rad(20), math.rad(130))
	Turn(rthigh, z_axis, math.rad(-3), math.rad(135))
	Turn(lthigh, z_axis, math.rad(3), math.rad(130))
	Turn(lfoot, z_axis, math.rad(-3), math.rad(130))
	Turn(rfoot, z_axis, math.rad(3), math.rad(130))

	for side = 1, 2 do
		Turn(foot[side], x_axis, 0, math.rad(395))
		Turn(thigh[side], x_axis, 0, math.rad(235))
		Turn(shin[side], x_axis, 0, math.rad(235))
	end

	StartThread(Idle)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, {chest})
	Turn(rthigh, y_axis, math.rad(-20))
	Turn(lthigh, y_axis, math.rad(20))
	Turn(rthigh, z_axis, math.rad(-3))
	Turn(lthigh, z_axis, math.rad(3))
	Turn(lfoot, z_axis, math.rad(-3))
	Turn(rfoot, z_axis, math.rad(3))
end

-----------------------------------------------------------------------
--gun functions
-----------------------------------------------------------------------
function script.QueryWeapon(num)
	return gun and rmissile or lmissile
end

local function RestoreAfterDelay()
	Sleep(2000)
	Turn(chest, y_axis, 0, RESTORE_SPEED)
	Turn(rtcover, x_axis, 0, RESTORE_SPEED)
	Turn(rbcover, x_axis, 0, RESTORE_SPEED)
	Turn(ltcover, x_axis, 0, RESTORE_SPEED)
	Turn(lbcover, x_axis, 0, RESTORE_SPEED)
	aiming = false

	StartThread(Idle)
end

function script.AimFromWeapon(num)
	return head
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	Signal(SIG_IDLE)
	SetSignalMask(SIG_AIM)
	aiming = true
	Turn(head, y_axis, 0, 4.0)
	Turn(chest, x_axis, 0, math.rad(120))
	Turn(chest, y_axis, heading, math.rad(450))
	Turn(lshoulder, x_axis, -pitch, math.rad(500))
	Turn(rshoulder, x_axis, -pitch, math.rad(500))
	Turn(rtcover, x_axis, -COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(rbcover, x_axis, COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(ltcover, x_axis, -COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	Turn(lbcover, x_axis, COVER_UNFOLD_ANGLE, COVER_UNFOLD_SPEED)
	WaitForTurn(chest, y_axis)
	WaitForTurn(lshoulder, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.Shot(num)
	if gun then
		EmitSfx(lmuzzle,  1024)
		EmitSfx(lexhaust,  1025)
		Move(lmissile, z_axis, -1 )
		Move(lmissile, z_axis, 0, 500)
	else
		EmitSfx(rmuzzle,  1024)
		EmitSfx(rexhaust,  1025)
		Move(rmissile, z_axis, -1 )
		Move(rmissile, z_axis, 0, 500)
	end
	gun = not gun
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local corpseType = 1
	if severity <= .25 then
		Explode(hips, SFX.NONE)
		Explode(chest, SFX.NONE)
		Explode(lshoulder, SFX.NONE)
		Explode(rshoulder, SFX.NONE)
		Explode(head, SFX.FALL + SFX.FIRE)
	elseif severity <= .50 then
		Explode(hips, SFX.NONE)
		Explode(chest, SFX.NONE)
		Explode(lshoulder, SFX.FALL + SFX.FIRE)
		Explode(rshoulder, SFX.FALL + SFX.FIRE)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	else
		corpseType = 2
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SHATTER)
		Explode(lshoulder, SFX.SHATTER)
		Explode(rshoulder, SFX.SHATTER)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	end

	return corpseType
end
