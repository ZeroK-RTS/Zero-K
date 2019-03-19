include "constants.lua"
include "pieceControl.lua"

local aimLOS = piece('aimLOS');
local body = piece('body');
local body_001 = piece('body_001');
local Circle = piece('Circle');
local Cube = piece('Cube');
local fins = piece('fins');
local Plane = piece('Plane');
local skid = piece('skid');
local skid_001 = piece('skid_001');
local torpedo = piece('torpedo');
local turretBase = piece('turretBase');
local turretMain = piece('turretMain');
local turretRail = piece('turretRail');
local turretSlidePanel = piece('turretSlidePanel');
local wakeLeft = piece('wakeLeft');
local wakeRight = piece('wakeRight');
local TorpMuzzle = piece('TorpMuzzle');

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
	Turn (turretMain, z_axis, 0, math.rad(30))
end

local function MoveScript()
	while true do
		if moving and not Spring.GetUnitIsCloaked(unitID) and (sfxNum == 1 or sfxNum == 2) then
			EmitSfx(wakeLeft, 3)
			EmitSfx(wakeRight, 3)
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
	StopTurn (turretMain, y_axis)
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
	StartThread(SmokeUnit, {body_001, turretMain})
end

function script.AimFromWeapon(id)
	return turretRail
end

function script.QueryWeapon(id)
	return turretRail;
end

local function FireAndReload(num)
	Hide(torpedo)
	Move(torpedo,y_axis,7);
	Move(torpedo,z_axis,-2);
	Sleep(1000);
	Show(torpedo);
	Move(torpedo,y_axis,0,10);
	Move(torpedo,z_axis,0,10);
end

function script.FireWeapon(id)
	StartThread(FireAndReload);
	return true
end

function script.AimWeapon(id, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)

	while disarmed do
		Sleep(34)
	end

	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (turretMain, z_axis, heading, math.rad(300 * slowMult))
	WaitForTurn (turretMain, z_axis)

	StartThread (RestoreAfterDelay)

	return true
end

function script.BlockShot(num, targetID)
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 190, 55, 0.25) then -- leaving at 190 for the case of amph regen
		return true
	end
	return false
end

local explodables = {turretBase, turretMain, turretRail}
function script.Killed(severity, health)
	severity = severity / health

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], sfxFall + sfxFire + sfxSmoke)
		end
		Explode(skid, sfxShatter)
	end

	if severity <= 0.5 then
		return 1
	else
		Explode(body, sfxShatter)
		Explode(skid, sfxShatter)
		Explode(fins, sfxShatter)
		Explode(Plane, sfxShatter)
		
		return 2
	end
end
