include "constants.lua"
include "pieceControl.lua"

local base, base2, sleeve, body, turret, firepoint, wake1, wake2, platform = piece ('base', 'bas2', 'sleeve', 'body', 'turret', 'firepoint', 'wake1', 'wake2', 'platform')

local SIG_Move = 1
local SIG_Aim = 2

local stuns = {false, false, false}
local disarmed = false
local moving = false
local sfxNum = 2

function script.setSFXoccupy(num)
	sfxNum = num
end

local function RestoreAfterDelay()
	SetSignalMask(SIG_Aim)
	Sleep (5000)
	Turn (turret, y_axis, 0, math.rad(30))
end

local function MoveScript()
	while true do
		if moving and not Spring.GetUnitIsCloaked(unitID) and (sfxNum == 1 or sfxNum == 2) then
			EmitSfx(wake1, 3)
			EmitSfx(wake2, 3)
		end
		Sleep(150)
	end
end

function script.StopMoving()
	moving = false
end

function script.StartMoving()
	moving = true
end

local function StunThread ()
	disarmed = true
	Signal (SIG_Aim)
	StopTurn (turret, y_axis)
end

local function UnstunThread ()
	disarmed = false
	RestoreAfterDelay()
end

function Stunned (stun_type)
	stuns[stun_type] = true
	StartThread (StunThread)
end

function Unstunned (stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread (UnstunThread)
	end
end

function script.Create()
	StartThread(MoveScript)
	StartThread(SmokeUnit, {sleeve, turret})
end

function script.AimFromWeapon(id)
	return turret
end

function script.QueryWeapon(id)
	return firepoint
end

function script.AimWeapon(id, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)

	while disarmed do
		Sleep(34)
	end

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (turret, y_axis, heading, math.rad(300 * slowMult))
	WaitForTurn (turret, y_axis)

	StartThread (RestoreAfterDelay)

	return true
end

function script.BlockShot(num, targetID)
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 190, 55, 0.25) then -- leaving at 190 for the case of amph regen
		return true
	end
	return false
end

local explodables = {base2, sleeve, turret}
function script.Killed(severity, health)
	severity = severity / health

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], sfxFall + sfxFire + sfxSmoke)
		end
	end

	if severity <= 0.5 then
		return 1
	else
		-- no shatter because 3do models are gebork
		return 2
	end
end
