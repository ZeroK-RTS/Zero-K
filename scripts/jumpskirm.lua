local support = piece 'support'
local hips = piece 'cod'
local flare = piece 'flare'
local eye_flare = piece 'eye_flare'
local thigh1 = piece 'thigh1'
local thigh2 = piece 'thigh2'
local torso = piece 'torso'
local head = piece 'head'
local barrel = piece 'barrel'
local foot2 = piece 'foot2'
local foot1 = piece 'foot1'
local leg2 = piece 'leg2'
local leg1 = piece 'leg1'
local shoulder = piece 'shoulder'
local shoulder_left = piece 'shoulder_left'


-- groups
local shoulders = {shoulder_left, shoulder}
local thigh = {thigh2, thigh1}
local shin = {leg2, leg1}
local foot = {foot2, foot1}

--constants
local runspeed = 29 * (UnitDefs[unitDefID].speed / 115)  -- run animation rate, future-proofed
local steptime = 40  -- how long legs stay extended during stride
local hangtime = 20 -- how long it takes for "gravity" to accelerate stride descent
local stride_top = 1.5  -- how high hips go during stride
local stride_bottom = -1.0  -- how low hips go during stride

include "constants.lua"

local aiming = false
local moving = false

local RESTORE_DELAY = 2000


function jumping(jumpPercent)
	if jumpPercent < 65 then
		GG.PokeDecloakUnit(unitID, unitDefID)
		EmitSfx(foot1, 1026)
		EmitSfx(foot2, 1026)
	end
	
	if jumpPercent > 95 and not landing then
		landing = true
		--StartThread(PrepareJumpLand)
	end
end

function beginJump()
end

function endJump()
	landing = false
end


-- Signal definitions
local SIG_Idle = 1
local SIG_Walk = 2
local SIG_Aim = 4
local SIG_RESTORE = 8

local function GetSpeedMod()
	-- disallow zero (instant turn instead -> infinite loop)
	return math.max(0.05, GG.att_MoveChange[unitID] or 1)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)

	for i = 1, 2 do
		Turn (thigh[i], y_axis, 0, runspeed*0.15)
		Turn (thigh[i], z_axis, 0, runspeed*0.15)
	end

	local side = 1
	while true do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod
		local turnMult = 1
		if truespeed > 25 then
			turnMult = 1 + (truespeed - 25) * 0.1
		end

		Turn (shin[side], x_axis, math.rad(85)*turnMult, truespeed*0.28)
		Turn (foot[side], x_axis, 0, truespeed*0.25)
		Turn (thigh[side], x_axis, math.rad(-36)*turnMult, truespeed*0.16)
		Turn (thigh[3-side], x_axis, math.rad(36)*turnMult, truespeed*0.16)

		Move (hips, y_axis, 0, truespeed*0.4 / turnMult)
		Move (torso, y_axis, 0, truespeed*0.4 / turnMult)
		WaitForMove (hips, y_axis)

		Turn (shin[side], x_axis, math.rad(10)*turnMult, truespeed*0.32)
		Turn (foot[side], x_axis, math.rad(-20)*turnMult, truespeed*0.25)
		Move (hips, y_axis, -1, truespeed*0.2)
		Move (torso, y_axis, -1, truespeed*0.2)
		WaitForMove (hips, y_axis)

		Move (hips, y_axis, -2, truespeed*0.4 / turnMult)
		Move (torso, y_axis, -2, truespeed*0.4 / turnMult)

		WaitForTurn (thigh[side], x_axis)

		side = 3 - side
	end
end

function script.Create()
	Hide(flare)
	Hide(support)
	Hide(barrel)
	StartThread(GG.Script.SmokeUnit, unitID, {torso})
end

local function StopWalk()
	Signal(SIG_Walk)

	Move (hips, y_axis, 0, runspeed*0.5)

	for i = 1, 2 do
		Turn (thigh[i], x_axis, 0, runspeed*0.2)
		Turn (shin[i],  x_axis, 0, runspeed*0.2)
		Turn (foot[i], x_axis, 0, runspeed*0.2)

		Turn (thigh[i], y_axis, math.rad(0) - i*math.rad(0), runspeed*0.1)
		Turn (thigh[i], z_axis, math.rad(0)*i - math.rad(0), runspeed*0.1)
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Turn(torso, y_axis, 0, math.rad(160))
	Turn(head, x_axis, 0, math.rad(45))
	aiming = false
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	StartThread(RestoreAfterDelay)
	aiming = true
	
	-- The aim check messes with unit targeting. This is not required for Moderator as
	-- it very rarely shoots at radar dots.
	--GG.DontFireRadar_CheckAim(unitID)
	
	Turn(torso, y_axis, heading, math.rad(300))
	Turn(head, x_axis, -pitch, math.rad(150))
	WaitForTurn(torso, y_axis)
	WaitForTurn(head, x_axis)
	return true
end

function script.FireWeapon()
	EmitSfx(eye_flare, 1024)
	Spin(shoulder, x_axis, math.rad(485), math.rad(5))
	Spin(shoulder_left, x_axis, math.rad(485), math.rad(5))
	Sleep(6600)
	Spin(shoulder, x_axis, 0, math.rad(5))
	Spin(shoulder_left, x_axis, 0, math.rad(5))
	Sleep(3100)
	Turn(shoulder, x_axis, 0, math.rad(50))
	Turn(shoulder_left, x_axis, 0, math.rad(50))
end

function script.QueryWeapon()
	return eye_flare
end

function script.AimFromWeapon()
	return head
end

function script.BlockShot(num, targetID)
	return (targetID and GG.DontFireRadar_CheckBlock(unitID, targetID)) or false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(foot1, SFX.NONE)
		Explode(foot2, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(thigh1, SFX.NONE)
		Explode(thigh2, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(foot1, SFX.NONE)
		Explode(foot2, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(thigh1, SFX.NONE)
		Explode(thigh2, SFX.NONE)
		Explode(torso, SFX.SHATTER)
		return 1
	end

	Explode(foot1, SFX.SMOKE + SFX.FIRE)
	Explode(foot2, SFX.SMOKE + SFX.FIRE)
	Explode(leg1, SFX.SMOKE + SFX.FIRE)
	Explode(leg2, SFX.SMOKE + SFX.FIRE)
	Explode(thigh1, SFX.SMOKE + SFX.FIRE)
	Explode(thigh2, SFX.SMOKE + SFX.FIRE)
	Explode(torso, SFX.SHATTER)
	return 2
end
