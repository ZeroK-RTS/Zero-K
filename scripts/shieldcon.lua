-- original bos animation by Chris Mackey
-- converted to lua by psimyn

include 'constants.lua'

local base, pelvis, torso = piece('base', 'pelvis', 'torso')
local shield = piece 'shield' 
local lathe = piece 'lathe' 
local emit = piece 'emit' 
local centerpoint = piece 'centerpoint'
local rthigh, ruppercalf, rlowercalf, rfoot = piece('rthigh', 'ruppercalf', 'rlowercalf', 'rfoot')
local lthigh, luppercalf, llowercalf, lfoot = piece('lthigh', 'luppercalf', 'llowercalf', 'lfoot')
local rightLeg = { thigh=piece('rthigh'), uppercalf=piece('ruppercalf'), lowercalf=piece('rlowercalf'), foot=piece('rfoot') }
local leftLeg = { thigh=piece('lthigh'), uppercalf=piece('luppercalf'), lowercalf=piece('llowercalf'), foot=piece('lfoot') }

local smokePiece = {torso}
local nanoPieces = {emit}

-- signals
local SIG_BUILD = 1
local SIG_MOVE = 2

-- constants
local PACE = 2

local function Step(front, back)
	Turn(front.thigh, x_axis, math.rad(-10), math.rad(36) * PACE)
	Turn(front.uppercalf, x_axis, math.rad(-68), math.rad(83) * PACE)
	Turn(front.foot, x_axis, math.rad(60), math.rad(90) * PACE)
	Move(front.lowercalf, z_axis, 0, 3 * PACE)
	Move(front.lowercalf, y_axis, 0, 3 * PACE)

	Turn(back.thigh, x_axis, math.rad(26), math.rad(36) * PACE)
	Turn(back.uppercalf, x_axis, math.rad(15), math.rad(83) * PACE)
	Turn(back.foot, x_axis, math.rad(-30), math.rad(90) * PACE)
	Move(back.lowercalf, z_axis, -1.1, 2.2 * PACE)
	Move(back.lowercalf, y_axis, -1.1, 2.2 * PACE)
		
	if front == leftLeg then
		Turn(pelvis, z_axis, math.rad(10), math.rad(15) * PACE)
	else
		Turn(pelvis, z_axis, math.rad(-10), math.rad(15) * PACE)
	end

	WaitForTurn(front.thigh, x_axis)
	WaitForTurn(front.uppercalf, x_axis)
	WaitForTurn(back.thigh, x_axis)
	WaitForTurn(back.uppercalf, x_axis)
	-- wait one gameframe 
	Sleep(0)
end

local function Walk()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	
	Move(pelvis, y_axis, 2, 5)
	while true do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

local function Stopping()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)

	Move(pelvis, y_axis, 0, 12)
	Turn(pelvis, z_axis, math.rad(0), math.rad(15) * PACE)
	
	Turn(rightLeg.thigh, x_axis, 0, math.rad(60) * PACE)
	Turn(leftLeg.thigh, x_axis, 0, math.rad(60) * PACE)
	Turn(rightLeg.uppercalf, x_axis, 0, math.rad(70) * PACE)
	Turn(leftLeg.uppercalf, x_axis, 0, math.rad(70) * PACE) 
	Turn(rightLeg.foot, x_axis, 0, math.rad(60) * PACE)
	Turn(leftLeg.foot, x_axis, 0, math.rad(60) * PACE)
	
	Move(leftLeg.lowercalf, z_axis, 0, 3)
	Move(rightLeg.lowercalf, z_axis, 0, 2)
	Move(leftLeg.lowercalf, y_axis, 0, 3)
	Move(rightLeg.lowercalf, y_axis, 0, 2)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

local isBuilding = false
function script.StartBuilding(heading, pitch)
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	isBuilding = false
	
	-- aim at target location
	Turn(torso, y_axis, heading, math.rad(200) * PACE)
	Turn(torso, x_axis, -pitch, math.rad(200) * PACE)
	Turn(shield, x_axis, math.rad(-70), math.rad(100) * PACE)
	
	-- lower to ground. sit comfortably while you build
	Move(pelvis, y_axis, -6, 6 * PACE)
	Turn(leftLeg.uppercalf, x_axis, math.rad(40), math.rad(40) * PACE)
	Turn(leftLeg.foot, x_axis, math.rad(-40), math.rad(40) * PACE)
	Turn(rightLeg.uppercalf, x_axis, math.rad(40), math.rad(40) * PACE)
	Turn(rightLeg.foot, x_axis, math.rad(-40), math.rad(40) * PACE)
	WaitForTurn(torso, y_axis)
end

function script.QueryWeapon(num)
	return centerpoint
end

function script.StopBuilding()
	if not isBuilding then
		return
	end
	isBuilding = false
	SetUnitValue(COB.INBUILDSTANCE, 0)
	
	Turn(torso, y_axis, 0, math.rad(40) * PACE)
	Turn(torso, x_axis, 0, math.rad(40) * PACE)
	Turn(shield, x_axis, 0, math.rad(40) * PACE)
	Turn(leftLeg.uppercalf, x_axis, 0, math.rad(40) * PACE)
	Turn(leftLeg.foot, x_axis, 0, math.rad(40) * PACE)
	Turn(rightLeg.uppercalf, x_axis, 0, math.rad(40) * PACE)
	Turn(rightLeg.foot, x_axis, 0, math.rad(40) * PACE)
	Move(pelvis, y_axis, 0, 6 * PACE)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),emit)
	return emit
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(torso, SFX.FALL)
		Explode(leftLeg.thigh, SFX.NONE)
		Explode(leftLeg.uppercalf, SFX.NONE)
		Explode(leftLeg.lowercalf, SFX.NONE)
		Explode(leftLeg.foot, SFX.NONE)
		Explode(rightLeg.thigh, SFX.NONE)
		Explode(rightLeg.uppercalf, SFX.NONE)
		Explode(rightLeg.lowercalf, SFX.NONE)
		Explode(rightLeg.foot, SFX.NONE)
		Explode(base, SFX.FALL)
		return 1
	else
		Explode(torso, SFX.SHATTER)
		Explode(leftLeg.thigh, SFX.FALL)
		Explode(leftLeg.uppercalf, SFX.FALL)
		Explode(leftLeg.lowercalf, SFX.FALL)
		Explode(leftLeg.foot, SFX.FALL)
		Explode(rightLeg.thigh, SFX.FALL)
		Explode(rightLeg.uppercalf, SFX.FALL)
		Explode(rightLeg.lowercalf, SFX.FALL)
		Explode(rightLeg.foot, SFX.FALL)
		Explode(base, SFX.SHATTER)
		return 2
	end
end
