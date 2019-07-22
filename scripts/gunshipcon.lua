include "constants.lua"
include "gunshipConstructionTurnHax.lua"

local Scene = piece('Scene')
local Base = piece('Base')
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

local MAGIC_OFFSET = 8

local SIG_TILT = 1
local SIG_BUILD = 2
local SIG_LAND = 4
local SIG_STOP_BUILDING = 8

local constructing = false

local function RestoreTilt(signal)
	if signal then
		Signal(SIG_TILT)
	end
	Turn(Base, x_axis, math.rad(0), math.rad(45))
	Move(Spine1, y_axis, 0, 1) 
	Move(Spine2, y_axis, 0, 1) 
	
	Turn(ForejetLeft, z_axis, 0, math.rad(60))
	Turn(ForejetRight, z_axis, 0, math.rad(60))
	Turn(HindJetLeft, z_axis, 0, math.rad(60))
	Turn(HindJetRight, z_axis, 0, math.rad(60))
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
			Turn(Base, x_axis, math.rad(7) * speed, math.rad(45))
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
	if constructing then
		return false
	end
	
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	constructing = true
	while true do
		local mag = math.rad(math.random()*8 - 4)
		for i = 1, 5 do
			Turn(subspine[i], z_axis, mag, math.rad(5))
		end
		Sleep(500)
	end
end

local function StopBuild()
	SetSignalMask(SIG_STOP_BUILDING)
	Sleep(450)
	constructing = false
	Signal(SIG_BUILD)
	for i = 1, 5 do
		Turn(subspine[i], z_axis, 0, math.rad(5))
	end
end

local function StartLanded()
	Signal(SIG_LAND)
	SetSignalMask(SIG_LAND)
	Sleep(500) -- Repair and reclaim have jittery Deactivate
	
	RestoreTilt(true)
	
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 0)
	
	Signal(SIG_TILT)
	
	Move(Scene, y_axis, MAGIC_OFFSET, 5)
	Turn(Head, z_axis, -math.rad(15), math.rad(7.5))
	Turn(Spine1, z_axis, -math.rad(15), math.rad(7.5))
	Turn(subspine[2], z_axis, math.rad(5), math.rad(2.5))
	Turn(subspine[3], z_axis, math.rad(5), math.rad(2.5))
	Turn(subspine[4], z_axis, math.rad(5), math.rad(2.5))
	Turn(subspine[5], z_axis, math.rad(-50), math.rad(25))
	Turn(subspine[6], z_axis, math.rad(105), math.rad(52.5))
end

local function StopLanded()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1)

	Signal(SIG_LAND)
	Move(Scene, y_axis, 9 + MAGIC_OFFSET, 5)
	
	Turn(Head, z_axis, 0, math.rad(7.5))
	Turn(Spine1, z_axis, 0, math.rad(7.5))
	Turn(subspine[2], z_axis, 0,  math.rad(2.5))
	Turn(subspine[3], z_axis, 0, math.rad(2.5))
	Turn(subspine[4], z_axis, 0, math.rad(2.5))
	Turn(subspine[5], z_axis, 0, math.rad(25))
	Turn(subspine[6], z_axis, 0, math.rad(52.5))
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 0)
	-- Permanent changes
	--Move(Spine1, z_axis, -5)
	Hide(Sting)
	
	-- Set to landed pose
	Move(Scene, y_axis, MAGIC_OFFSET)
	Turn(Head, z_axis, -math.rad(15))
	Turn(Spine1, z_axis, -math.rad(15))
	Turn(subspine[2], z_axis, math.rad(5))
	Turn(subspine[3], z_axis, math.rad(5))
	Turn(subspine[4], z_axis, math.rad(5))
	Turn(subspine[5], z_axis, math.rad(-50))
	Turn(subspine[6], z_axis, math.rad(105))
end

function script.Activate()
	StartThread(TiltBody)
	StopLanded()
end

function script.Deactivate()
	StartThread(StopBuild)
	StartThread(StartLanded)
end

function script.StartBuilding()
	ConstructionTurnHax()
	
	SetUnitValue(COB.INBUILDSTANCE, 1)
	StartThread(Build)
	Signal(SIG_STOP_BUILDING)
end

function script.StopBuilding()
	StartThread(StopBuild)
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
		Explode(ForejetLeft, SFX.FALL)
		Explode(ForejetRight, SFX.FALL)
		Explode(HindJetLeft, SFX.FALL)
		Explode(HindJetRight, SFX.FALL)
		return 1
	elseif severity <= 0.50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(Spine1, SFX.SHATTER)
		Explode(ForejetLeft, SFX.FALL)
		Explode(ForejetRight, SFX.FALL)
		Explode(HindJetLeft, SFX.FALL)
		Explode(HindJetRight, SFX.FALL)
		return 1
	else
		Explode(Spine1, SFX.SHATTER)
		Explode(ForejetLeft, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(ForejetRight, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(HindJetLeft, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(HindJetRight, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
