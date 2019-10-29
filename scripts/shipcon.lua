include 'constants.lua'

local body = piece 'body'
local turret = piece 'turret'
local arm1 = piece 'arm1'
local arm2 = piece 'arm2'
local armpiece = piece 'armpiece'
local claw1 = piece 'claw1'
local claw2 = piece 'claw2'
local wakes =
	{ piece 'wake1'
	, piece 'wake2'
}
local beam = piece 'beam'

local smokePiece = {body, claw1, turret}
local nanoPieces = {beam}

local SIG_Build = 1
local SIG_Move = 2

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

local sfxNum = 2
function script.setSFXoccupy(num)
	sfxNum = num
end

local function MoveThread()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		if not Spring.GetUnitIsCloaked(unitID) and (sfxNum == 1 or sfxNum == 2) then
			EmitSfx(wakes[1], 2)
			EmitSfx(wakes[2], 2)
		end
		Sleep(200)
	end
end

function script.StartMoving()
	StartThread(MoveThread)
end

function script.StopMoving()
	Signal(SIG_Move)
end

function script.StartBuilding(heading, pitch)
	Signal(SIG_Build)
	Turn (arm1, x_axis, math.rad(135), math.rad(405))
	Turn (arm2, x_axis, math.rad(-135), math.rad(405))
	Turn (claw1, x_axis, math.rad( 30), math.rad(90))
	Turn (claw2, x_axis, math.rad(-30), math.rad(90))
	Turn (turret, y_axis, heading, math.rad(180))
	WaitForTurn (turret, y_axis)
	WaitForTurn (arm1, y_axis)
	Spring.SetUnitCOBValue(unitID, COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	SetSignalMask (SIG_Build)
	Sleep (5000)
	Turn (arm1, x_axis, 0, math.rad(65))
	Turn (arm2, x_axis, 0, math.rad(65))
	Turn (claw1, x_axis, 0, math.rad(15))
	Turn (claw2, x_axis, 0, math.rad(15))
	Turn (turret, y_axis, 0, math.rad(45))
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID, unitDefID, Spring.GetUnitTeam(unitID), beam)
	return beam
end

local explodables = {turret, arm1, arm2, armpiece, claw1, claw2}
function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], SFX.FALL + SFX.FIRE + SFX.SMOKE)
		end
	end

	if severity < 0.5 then
		return 1
	else
		Explode(body, SFX.SHATTER)
		return 2
	end
end
