include "constants.lua"

local Scene = piece('Scene')
local ExhaustForwardLeft = piece('ExhaustForwardLeft')
local ExhaustForwardRight = piece('ExhaustForwardRight')
local ExhaustRearLeft = piece('ExhaustRearLeft')
local ExhaustRearRight = piece('ExhaustRearRight')
local EyeLower = piece('EyeLower')
local EyeUpper = piece('EyeUpper')
local ForearmLeft = piece('ForearmLeft')
local ForearmRight = piece('ForearmRight')
local ForejetLeft = piece('ForejetLeft')
local ForejetRight = piece('ForejetRight')
local Head = piece('Head')
local HindArmLeft = piece('HindArmLeft')
local HindArmRight = piece('HindArmRight')
local HindJetLeft = piece('HindJetLeft')
local HindJetRight = piece('HindJetRight')
local Nano = piece('Nano')
local Spine1 = piece('Spine1')
local Spine2 = piece('Spine2')
local Spine3 = piece('Spine3')
local Spine4 = piece('Spine4')
local Spine5 = piece('Spine5')
local Spine6 = piece('Spine6')
local Sting = piece('Sting')

local subspine = {Head, Spine2, Spine3, Spine4, Spine5, Spine6}

local smokePiece = {Spine1, ForejetLeft, ForejetRight, HindJetLeft, HindJetRight}
local nanoPieces = {Nano}

local SIG_TILT = 1
local SIG_BUILD = 2

local function RestoreTilt()
	Turn(Scene, x_axis, math.rad(0), math.rad(45))
	Move(Spine1, y_axis, 0, 1) 
	Move(Spine2, y_axis, 0, 1) 
	
	Turn(ForejetLeft, z_axis, 0, math.rad(60))
	Turn(ForejetRight, z_axis, 0, math.rad(60))
	Turn(HindJetLeft, z_axis, 0, math.rad(60))
	Turn(HindJetRight, z_axis, 0, math.rad(60))
	Sleep(100)
end

local function TiltBody()
	Signal(SIG_TILT)
	SetSignalMask(SIG_TILT)
	while true do
		local vx,_,vz,speed = Spring.GetUnitVelocity(unitID)
		if vx*vx + vz*vz > 0.5 then
			if speed > 3.1 then
				speed = 3.1
			end
			Turn(Scene, x_axis, math.rad(7) * speed, math.rad(45))
			Move(Spine1, y_axis, 0.3*speed, 1) 
			Move(Spine2, y_axis, -0.3*speed, 1) 
			
			Turn(ForejetLeft, z_axis, -math.rad(2) * speed, math.rad(60))
			Turn(ForejetRight, z_axis, -math.rad(2) * speed, math.rad(60))
			Turn(HindJetLeft, z_axis, -math.rad(6) * speed, math.rad(60))
			Turn(HindJetRight, z_axis, -math.rad(6) * speed, math.rad(60))
			Sleep(100)
		else
			RestoreTilt()
			Sleep(100)
		end
	end
end

local function Build()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	while true do
		local mag = math.rad(math.random()*8 - 4)
		for i = 1, 5 do
			Turn(subspine[i], z_axis, mag, math.rad(5))
		end
		Sleep(500)
	end
end

local function StopBuild()
	Signal(SIG_BUILD)
	for i = 1, 5 do
		Turn(subspine[i], z_axis, 0, math.rad(5))
	end
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(TiltBody)
	Move(Scene, y_axis, 20)
	Move(Spine1, z_axis, -5)
	Hide(Sting)
end

function script.StartBuilding()
	Signal(SIG_TILT)
	RestoreTilt()
	SetUnitValue(COB.INBUILDSTANCE, 1)
	StartThread(Build)
end

function script.StopBuilding()
	Signal(SIG_TILT)
	StopBuild()
	StartThread(TiltBody)
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),Nano)
	return Nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(ForejetLeft, sfxFall)
		Explode(ForejetRight, sfxFall)
		Explode(HindJetLeft, sfxFall)
		Explode(HindJetRight, sfxFall)
		return 1
	elseif severity <= 0.50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(Spine1, sfxShatter)
		Explode(ForejetLeft, sfxFall)
		Explode(ForejetRight, sfxFall)
		Explode(HindJetLeft, sfxFall)
		Explode(HindJetRight, sfxFall)
		return 1
	else
		Explode(Spine1, sfxShatter)
		Explode(ForejetLeft, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(ForejetRight, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(HindJetLeft, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(HindJetRight, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
end
