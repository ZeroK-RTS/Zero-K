local fuselage = piece 'fuselage' 
local head = piece 'head' 
local wingl = piece 'wingl' 
local wingr = piece 'wingr' 
local enginel = piece 'enginel' 
local enginer = piece 'enginer' 
local arm = piece 'arm' 
local lathe = piece 'lathe' 
local jaw1 = piece 'jaw1' 
local jaw2 = piece 'jaw2' 
local nanopoint = piece 'nanopoint' 

include "constants.lua"
include "gunshipConstructionTurnHax.lua"

local smokePiece = {fuselage}
local nanoPieces = {nanopoint}

-- Signal definitions
local SIG_MOVE = 1
local SIG_BUILD = 2

local function BuildDecloakThread()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	while true do
		GG.PokeDecloakUnit(unitID, 50)
		Sleep(1000)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Spring.SetUnitNanoPieces(unitID, nanoPieces)
end

function script.Activate()
end

function script.Deactivate()
end

local function StartMoving()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	Turn(enginel, x_axis, math.rad(10), math.rad(200))
	Turn(enginer, x_axis, math.rad(10), math.rad(200))
end

local function Stopping()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	
	Turn(enginel, x_axis, 0, math.rad(100))
	Turn(enginer, x_axis, 0, math.rad(100))
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	StartThread(Stopping)
end

function script.StartBuilding()
	ConstructionTurnHax()
	StartThread(BuildDecloakThread) -- For rez.
	Turn(arm, x_axis, math.rad(-80), math.rad(200))
	Turn(lathe, x_axis, math.rad(-80), math.rad(200))
	SetUnitValue(COB.INBUILDSTANCE, 1)
	Turn(jaw1, x_axis, math.rad(-30), math.rad(150))
	Turn(jaw2, x_axis, math.rad(30), math.rad(150))
	
end

function script.StopBuilding()
	Signal(SIG_BUILD)
	Turn(arm, x_axis, 0, math.rad(200))
	Turn(lathe, x_axis, 0, math.rad(200))
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn(jaw1, x_axis, 0, math.rad(100))
	Turn(jaw2, x_axis, 0, math.rad(100))
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID),nanopoint)
	return nanopoint
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		return 1
	elseif severity <= 0.5 or ((Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing") then
		Explode(enginel, SFX.FALL + SFX.FIRE)
		Explode(enginer, SFX.FALL + SFX.FIRE)
		return 1
	else
		Explode(fuselage, SFX.FALL)
		Explode(head, SFX.FALL)
		Explode(wingl, SFX.FALL)
		Explode(wingr, SFX.FALL)
		Explode(enginel, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(enginer, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(lathe, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
