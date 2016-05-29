include "constants.lua"

local ExhaustForwardLeft = piece('ExhaustForwardLeft');
local ExhaustForwardRight = piece('ExhaustForwardRight');
local ExhaustRearLeft = piece('ExhaustRearLeft');
local ExhaustRearRight = piece('ExhaustRearRight');
local EyeLower = piece('EyeLower');
local EyeUpper = piece('EyeUpper');
local ForearmLeft = piece('ForearmLeft');
local ForearmRight = piece('ForearmRight');
local ForejetLeft = piece('ForejetLeft');
local ForejetRight = piece('ForejetRight');
local Head = piece('Head');
local HindArmLeft = piece('HindArmLeft');
local HindArmRight = piece('HindArmRight');
local HindJetLeft = piece('HindJetLeft');
local HindJetRight = piece('HindJetRight');
local Nano = piece('Nano');
local Spine1 = piece('Spine1');
local Spine2 = piece('Spine2');
local Spine3 = piece('Spine3');
local Spine4 = piece('Spine4');
local Spine5 = piece('Spine5');
local Spine6 = piece('Spine6');
local Sting = piece('Sting');

local smokePiece = {Spine1, ForejetLeft, ForejetRight, HindJetLeft.HindJetRight}
local nanoPieces = {Nano}

local SIG_TILT = 1

local function TiltBody()
	Signal(SIG_TILT)
	SetSignalMask(SIG_TILT)
	while true do
		local vx,_,vz,speed = Spring.GetUnitVelocity(unitID)
		if vx*vx + vz*vz > 0.5 then
			if speed > 3.1 then
				speed = 3.1
			end
			Turn(base, x_axis, math.rad(7) * speed, math.rad(45))
			Move(Spine1, y_axis, 0.3*speed, 1) 
			Move(Spine2, y_axis, -0.3*speed, 1) 
			Sleep(100)
		else
			Turn(base, x_axis, math.rad(0), math.rad(45))
			Move(Spine1, y_axis, 0, 1) 
			Move(Spine2, y_axis, 0, 1) 
			Sleep(100)
		end
	end
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(TiltBody)
end

function script.StartBuilding()
	Signal(SIG_TILT)
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.StopBuilding()
	StartThread(TiltBody)
	SetUnitValue(COB.INBUILDSTANCE, 0)
	
	--[[
	WaitForTurn(centreClaw, x_axis)
	WaitForTurn(centreClawBit, x_axis)
	WaitForTurn(leftClaw, y_axis)
	WaitForTurn(leftClawBit, y_axis)
	WaitForTurn(rightClaw, y_axis)
	WaitForTurn(rightClawBit, y_axis)
	]]
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
