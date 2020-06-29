include "constants.lua"
include "pieceControl.lua"

local hull, torp, turret, sonar, wake1, wake2 = piece ('Hull', 'Torp', 'Turret', 'Sonar', 'Wake1', 'Wake2')

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

function script.Activate()
	Spin(sonar, y_axis, math.rad(60))
end

function script.Deactivate()
	StopSpin(sonar, y_axis)
end

local function StunThread ()
	disarmed = true
	Signal (SIG_Aim)
	GG.PieceControl.StopTurn (turret, y_axis)
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
	StartThread(GG.Script.SmokeUnit, unitID, {hull, sonar, turret})
end

function script.AimFromWeapon(id)
	return turret
end

function script.QueryWeapon(id)
	return torp
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

local explodables = {sonar, turret}
function script.Killed(severity, health)
	severity = severity / health

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], SFX.FALL + SFX.FIRE + SFX.SMOKE)
		end
	end

	if severity <= 0.5 then
		return 1
	else
		Explode (hull, SFX.SHATTER)
		return 2
	end
end
