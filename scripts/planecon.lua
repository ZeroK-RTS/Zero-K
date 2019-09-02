include "constants.lua"
include "gunshipConstructionTurnHax.lua"

local base = piece 'base'
local body = piece 'body'
local engine1 = piece 'engine1'
local engine2 = piece 'engine2'
local nozzle = piece 'nozzle'
local nano = piece 'nano'

--New bits
local centreClaw 		= piece 'CentreClaw'
local centreClawBit 	= piece 'CentreClawBit'
local CentreNano 		= piece 'CentreNano'
local leftClaw 			= piece 'LeftClaw'
local leftClawBit 		= piece 'LeftClawBit'
local leftNano 			= piece 'LeftNano'
local rightClaw 		= piece 'RightClaw'
local rightClawBit 		= piece 'RightClawBit'
local engShield1 		= piece 'EngShield1'
local engShield2 		= piece 'EngShield2'

local smokePiece = {base, engine1, engine2}
local nanoPieces = {nano, CentreNano, LeftNano}

local SIG_TILT = 1
local SIG_LAND = 2

local function TiltBody()
	Signal(SIG_TILT)
	SetSignalMask(SIG_TILT)
	while true do
		local vx,_,vz,speed = Spring.GetUnitVelocity(unitID)
		if vx*vx + vz*vz > 0.5 then
			if speed > 6 then
				speed = 6
			end
			Turn(base, x_axis, math.rad(2) * speed, math.rad(45))
			Move(engShield1, y_axis, 0.25*speed, 2)
			Move(engShield2, y_axis, -0.25*speed, 2)
			Sleep(100)
		else
			Turn(base, x_axis, math.rad(0), math.rad(45))
			Move(engShield1, y_axis, 0, 2)
			Move(engShield2, y_axis, 0, 2)
			Sleep(100)
		end
	end
end

function script.Create()
	Move(engine1, y_axis, -1)
	Move(engine2, y_axis, -1)
	Move(engine1, z_axis, 15)
	Move(engine2, z_axis, 15)
	Move(engine1, x_axis, 19.5)
	Move(engine2, x_axis, -19.5)
	
	Move(body, z_axis, -8)

	Move(engShield1, y_axis, 0, 0.5)
	Move(engShield2, y_axis, 0, 0.5)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
	StartThread(TiltBody)
end

local function StartLanded()
	Signal(SIG_LAND)
	SetSignalMask(SIG_LAND)
	Sleep(500) -- Repair and reclaim have jittery Deactivate
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 0)
end

local function StopLanded()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1)
	Signal(SIG_LAND)
end

function script.Activate()
	StopLanded()
end

function script.Deactivate()
	StartThread(StartLanded)
end

function script.StartBuilding()
	ConstructionTurnHax()
	
	Signal(SIG_TILT)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	
	Turn(base,x_axis, math.rad(30),0.5)
	
	Turn(centreClaw,x_axis, math.rad(-35),1)
	Turn(centreClawBit,x_axis, math.rad(-135),2.5)
	Turn(leftClaw,y_axis, math.rad(40),1)
	Turn(leftClawBit,y_axis, math.rad(135),2.5)
	Turn(rightClaw,y_axis, math.rad(-40),1)
	Turn(rightClawBit,y_axis, math.rad(-135),2.5)
	
	--[[
	WaitForTurn(centreClaw, x_axis)
	WaitForTurn(centreClawBit, x_axis)
	WaitForTurn(leftClaw, y_axis)
	WaitForTurn(leftClawBit, y_axis)
	WaitForTurn(rightClaw, y_axis)
	WaitForTurn(rightClawBit, y_axis)
	]]
end

function script.StopBuilding()
	StartThread(TiltBody)
	SetUnitValue(COB.INBUILDSTANCE, 0)
	
	Turn(base,x_axis, math.rad(0),0.5)
	Turn(centreClaw,x_axis, math.rad(0),0.5)
	Turn(centreClawBit,x_axis, math.rad(0),2)
	Turn(leftClaw,y_axis, math.rad(0),0.5)
	Turn(leftClawBit,y_axis, math.rad(0),2)
	Turn(rightClaw,y_axis, math.rad(0),0.5)
	Turn(rightClawBit,y_axis, math.rad(0),2)
	
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
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),CentreNano)
	return nano
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(engine2, SFX.FALL)
		Explode(engine1, SFX.FALL)
		return 1
	elseif severity <= 0.50 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(base, SFX.SHATTER)
		Explode(engine2, SFX.FALL)
		Explode(engine1, SFX.FALL)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(engine2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(engine1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
