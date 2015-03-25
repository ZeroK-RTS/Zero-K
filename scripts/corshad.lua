local base = piece 'base'
local fuselage = piece 'fuselage' 
local wingl1 = piece 'wingl1' 
local wingr1 = piece 'wingr1' 
local wingl2 = piece 'wingl2' 
local wingr2 = piece 'wingr2' 
local engines = piece 'engines' 
local fins = piece 'fins' 
local rflap = piece 'rflap' 
local lflap = piece 'lflap' 
local predrop = piece 'predrop' 
local drop = piece 'drop' 
local thrustl = piece 'thrustl' 
local thrustr = piece 'thrustr' 
local wingtipl = piece 'wingtipl' 
local wingtipr = piece 'wingtipr' 
local xp,zp = piece("x","z")

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitHeading = Spring.GetUnitHeading
local spGetUnitVelocity = Spring.GetUnitVelocity
local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData = Spring.MoveCtrl.SetAirMoveTypeData
local spGetGroundHeight = Spring.GetGroundHeight

local min, max = math.min, math.max

local smokePiece = {fuselage, thrustr, thrustl}

local bombs = 1

include "bombers.lua"
include "fakeUpright.lua"
include "constants.lua"
include "fixedwingTakeOff.lua"

local ud = UnitDefs[unitDefID]
local highBehaviour = {
	wantedHeight = UnitDefNames["corshad"].wantedHeight*1.5,
	maxPitch = ud.maxPitch,
	maxBank = ud.maxBank,
	turnRadius = ud.turnRadius,
	maxAileron = ud.maxAileron,
	maxElevator = ud.maxElevator,
	maxRudder = ud.maxRudder,
}
local lowBehaviour = {
	maxPitch = 0.5,
	maxBank = 0.5,
	turnRadius = 100,
	maxAileron = 0.004,
	maxElevator = 0.026,
	maxRudder = 0.015,
}

local SIG_TAKEOFF = 1
local SIG_CHANGE_FLY_HEIGHT = 2
local SIG_SPEED_CONTROL = 4
local takeoffHeight = UnitDefNames["corshad"].wantedHeight
local fullHeight = UnitDefNames["corshad"].wantedHeight/1.5

local minSpeedMult = 0.44
local speedUpdateRate = 400

local function BehaviourChangeThread(behaviour)
	Signal(SIG_CHANGE_FLY_HEIGHT)
	SetSignalMask(SIG_CHANGE_FLY_HEIGHT)
	
	takeoffHeight = behaviour.wantedHeight/1.5
	
	local state = spGetUnitMoveTypeData(unitID).aircraftState
	local flying = spMoveCtrlGetTag(unitID) == nil and (state == "flying" or state == "takeoff")
	if not flying then
		StartThread(TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	end
	
	while not flying do
		Sleep(600)
		state = spGetUnitMoveTypeData(unitID).aircraftState
		notFlying = spMoveCtrlGetTag(unitID) == nil and (state == "flying" or state == "takeoff")
	end
	
	Spring.MoveCtrl.SetAirMoveTypeData(unitID, behaviour)
	--Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	--GG.UpdateUnitAttributes(unitID)
	--GG.UpdateUnitAttributes(unitID)
end

function BomberDive_FlyHigh()
	StartThread(BehaviourChangeThread, highBehaviour)
	speedUpdateRate = 400
end

function BomberDive_FlyLow(height)
	lowBehaviour.wantedHeight = height
	StartThread(BehaviourChangeThread, lowBehaviour)
	speedUpdateRate = 200
end

local function SpeedControl()
	Signal(SIG_SPEED_CONTROL)
	SetSignalMask(SIG_SPEED_CONTROL)
	while true do
		local x,y,z = spGetUnitPosition(unitID)
		local terrain = spGetGroundHeight(x,z)
		local speedMult = minSpeedMult + (1-minSpeedMult)*max(0, min(1, (y - terrain-50)/(fullHeight-60)))
		Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", speedMult)
		GG.UpdateUnitAttributes(unitID)
		GG.UpdateUnitAttributes(unitID)
		Sleep(speedUpdateRate)
	end
end

function script.StartMoving()
	--Turn( fins , z_axis, math.rad(-(-30)), math.rad(50) )
	Move( wingr1 , x_axis, 0, 50)
	Move( wingr2 , x_axis, 0, 50)
	Move( wingl1 , x_axis, 0, 50)
	Move( wingl2 , x_axis, 0, 50)
	StartThread(SpeedControl)
end

function script.StopMoving()
	--Turn( fins , z_axis, math.rad(-(0)), math.rad(80) )
	Move( wingr1 , x_axis, 5, 30)
	Move( wingr2 , x_axis, 5, 30)
	Move( wingl1 , x_axis, -5, 30)
	Move( wingl2 , x_axis, -5, 30)
	StartThread(TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

local function Lights()
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
		Sleep(400)
	end
	while true do
		EmitSfx( wingtipr, 1024 )
		EmitSfx( wingtipl, 1025 )
		Sleep(2000)
	end
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	StartThread(TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	FakeUprightInit(xp, zp, drop) 
	--StartThread(Lights)
end

function script.QueryWeapon(num)
	return drop
end

function script.AimFromWeapon(num)
	return drop
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitFuel(unitID) >= 1 and Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

local predictMult = 3

function script.BlockShot(num, targetID)
	if num ~= 2 then
		return false
	end
	local ableToFire = not ((GetUnitValue(COB.CRASHING) == 1) or (Spring.GetUnitFuel(unitID) < 1) or (Spring.GetUnitRulesParam(unitID, "noammo") == 1))
	if not (targetID and ableToFire) then
		return not ableToFire
	end
	local x,y,z = spGetUnitPosition(unitID)
	local _,_,_,_,_,_,tx,ty,tz = spGetUnitPosition(targetID, true, true)
	local vx,vy,vz = spGetUnitVelocity(targetID)
	local heading = spGetUnitHeading(unitID)*headingToRad
	vx, vy, vz = vx*predictMult, vy*predictMult, vz*predictMult
	local dx, dy, dz = tx + vx - x, ty + vy - y, tz + vz - z
	local cosHeading = cos(heading)
	local sinHeading = sin(heading)
	dx, dz = cosHeading*dx - sinHeading*dz, cosHeading*dz + sinHeading*dx
	
	--Spring.Echo(vx .. ", " .. vy .. ", " .. vz)
	--Spring.Echo(dx .. ", " .. dy .. ", " .. dz)
	--Spring.Echo(heading)
	
	if dz < 30 and dz > -30 and dx < 100 and dx > -100 and dy < 0 then
		FakeUprightTurn(unitID, xp, zp, base, predrop) 
		Move(drop, x_axis, dx)
		Move(drop, z_axis, dz)
		dy = math.max(dy, -30)
		Move(drop, y_axis, dy)
		return false
	end
	return true
end

function script.FireWeapon(num)
	if num == 2 then
		GG.Bomber_Dive_fired(unitID)
		Sleep(33)	-- delay before clearing attack order; else bomb loses target and fails to home
		Move(drop, x_axis, 0)
		Move(drop, z_axis, 0)
		Move(drop, y_axis, 0)
		Reload()
	elseif num == 3 then
		GG.Bomber_Dive_fake_fired(unitID)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= 0.25  then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxNone)
		Explode(wingl1, sfxNone)
		Explode(wingr2, sfxNone)
		return 1
	elseif severity <= 0.50 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxNone)
		Explode(wingl2, sfxNone)
		Explode(wingr1, sfxNone)
		return 1
	elseif severity <= 1 then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl1, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingr2, sfxFall + sfxSmoke  + sfxFire )
		return 2
	else
		Explode(fuselage, sfxNone)
		Explode(engines, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl1, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl2, sfxFall + sfxSmoke  + sfxFire )
		return 2
	end
end