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

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitHeading      = Spring.GetUnitHeading
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spMoveCtrlGetTag      = Spring.MoveCtrl.GetTag
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData  = Spring.MoveCtrl.SetAirMoveTypeData
local spGetGroundHeight     = Spring.GetGroundHeight

local min, max = math.min, math.max

local smokePiece = {fuselage, thrustr, thrustl}

local bombs = 1

include "bombers.lua"
include "fakeUpright.lua"
include "constants.lua"
include "fixedwingTakeOff.lua"

local ud = UnitDefs[unitDefID]

local highBehaviour = {
	wantedHeight = UnitDefNames["bomberprec"].wantedHeight*1.5,
	maxPitch = ud.maxPitch,
	maxBank = ud.maxBank,
	turnRadius = ud.turnRadius,
	maxAileron = ud.maxAileron,
	maxElevator = ud.maxElevator,
	maxRudder = ud.maxRudder,
}

local lowBehaviour = {
	maxPitch = 0.72,
	maxBank = 0.5,
	turnRadius = 100,
	maxAileron = 0.004,
	maxElevator = 0.018,
	maxRudder = 0.015,
}

local currentBehaviour = {
	wantedHeight = highBehaviour.wantedHeight,
	maxPitch = highBehaviour.maxPitch,
	maxBank = highBehaviour.maxBank,
	turnRadius = highBehaviour.turnRadius,
	maxAileron = highBehaviour.maxAileron,
	maxElevator = highBehaviour.maxElevator,
	maxRudder = highBehaviour.maxRudder,
}

local pitchOverride = false

local SIG_TAKEOFF = 1
local SIG_CHANGE_FLY_HEIGHT = 2
local SIG_SPEED_CONTROL = 4

local takeoffHeight = UnitDefNames["bomberprec"].wantedHeight
local fullHeight = UnitDefNames["bomberprec"].wantedHeight/1.5

local minSpeedMult = 0.75

local function SetMoveTypeDataWithOverrides(behaviour)
	if behaviour then
		currentBehaviour.wantedHeight = behaviour.wantedHeight or currentBehaviour.wantedHeight
		currentBehaviour.maxPitch     = behaviour.maxPitch     or currentBehaviour.maxPitch
		currentBehaviour.maxBank      = behaviour.maxBank      or currentBehaviour.maxBank
		currentBehaviour.turnRadius   = behaviour.turnRadius   or currentBehaviour.turnRadius
		currentBehaviour.maxAileron   = behaviour.maxAileron   or currentBehaviour.maxAileron
		currentBehaviour.maxElevator  = behaviour.maxElevator  or currentBehaviour.maxElevator
		currentBehaviour.maxRudder    = behaviour.maxRudder    or currentBehaviour.maxRudder
	end
	
	local origPitch = currentBehaviour.maxPitch
	if pitchOverride and (pitchOverride > currentBehaviour.maxPitch) then
		currentBehaviour.maxPitch = pitchOverride
	end
	
	if not Spring.MoveCtrl.GetTag(unitID) then
		spSetAirMoveTypeData(unitID, currentBehaviour)
	end
	currentBehaviour.maxPitch = origPitch
end

local PREDICT_FRAMES = 10
local function TargetHeightUpdateThread(targetID, behaviour)
	-- Inherits signals from BehaviourChangeThread
	local flatDiveHeight = behaviour.wantedHeight
	
	while Spring.ValidUnitID(targetID) do
		local tx,_,tz = spGetUnitPosition(targetID)
		local tHeight = max(Spring.GetGroundHeight(tx, tz), 0)
		
		local ux,_,uz = spGetUnitPosition(unitID)
		local vx,vy,vz = spGetUnitVelocity(unitID)
		vx, vz = vx*PREDICT_FRAMES, vz*PREDICT_FRAMES
		local predictX, predictZ = ux + vx, uz + vz
		if math.abs(ux - tx) < vx then
			predictX = tx
		end
		if math.abs(uz - tz) < vz then
			predictZ = tz
		end
		local uHeight = max(spGetGroundHeight(predictX, predictZ), 0)
		
		behaviour.wantedHeight = flatDiveHeight + max((tHeight - uHeight)*0.4, 0)
		if not Spring.MoveCtrl.GetTag(unitID) then
			SetMoveTypeDataWithOverrides(behaviour)
		end
		Sleep(200)
	end
end

local pitchUpdateReset = false
local function PitchOverrideResetThread()
	pitchUpdateReset = 1
	while pitchUpdateReset > 0 do
		pitchUpdateReset = pitchUpdateReset - 1
		Sleep(300)
	end
	
	if pitchOverride then
		pitchOverride = false
		SetMoveTypeDataWithOverrides()
	end
	pitchUpdateReset = false
end

local function PitchUpdate(targetID, targetHeight)
	if not pitchUpdateReset then
		StartThread(PitchOverrideResetThread)
	end
	
	if targetID and Spring.ValidUnitID(targetID) then
		local tx,ty,tz = spGetUnitPosition(targetID)
		targetHeight = ty
	end
	
	if not targetHeight then
		return
	end
	
	local ux,uy,uz = spGetUnitPosition(unitID)
	if uy < targetHeight then
		local newPitch = 0.9
		if targetHeight - uy < 100 then
			newPitch = 0.5 + 0.4*(targetHeight - uy)/100
		end
		if pitchOverride ~= newPitch then
			pitchOverride = newPitch
			SetMoveTypeDataWithOverrides()
		end
	elseif pitchOverride then
		pitchOverride = false
		SetMoveTypeDataWithOverrides()
	end
	
	pitchUpdateReset = 1
end

local function BehaviourChangeThread(behaviour, targetID)
	Signal(SIG_CHANGE_FLY_HEIGHT)
	SetSignalMask(SIG_CHANGE_FLY_HEIGHT)
	
	takeoffHeight = behaviour.wantedHeight/1.5
	
	local state = spGetUnitMoveTypeData(unitID).aircraftState
	local flying = spMoveCtrlGetTag(unitID) == nil and (state == "flying" or state == "takeoff")
	if not flying then
		StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	end
	
	while not flying do
		Sleep(600)
		state = spGetUnitMoveTypeData(unitID).aircraftState
		flying = spMoveCtrlGetTag(unitID) == nil and (state == "flying" or state == "takeoff")
	end
	
	SetMoveTypeDataWithOverrides(behaviour)
	if targetID then
		TargetHeightUpdateThread(targetID, behaviour)
	end
	--Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	--GG.UpdateUnitAttributes(unitID)
	--GG.UpdateUnitAttributes(unitID)
end

local function SpeedControl()
	Signal(SIG_SPEED_CONTROL)
	SetSignalMask(SIG_SPEED_CONTROL)
	while true do
		local x,y,z = spGetUnitPosition(unitID)
		local terrain = max(spGetGroundHeight(x,z), 0) -- not amphibious, treat water as ground
		local speedMult = minSpeedMult + (1-minSpeedMult)*max(0, min(1, (y - terrain - 50)/(fullHeight - 60)))
		Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", speedMult)
		GG.UpdateUnitAttributes(unitID)
		GG.UpdateUnitAttributes(unitID)
		Sleep(50 + 2*max(0, y - terrain - 80))
	end
end

function BomberDive_HighPitchUpdate(targetID, attackGroundHeight)
	PitchUpdate(targetID, attackGroundHeight)
end

function BomberDive_FlyHigh()
	StartThread(BehaviourChangeThread, highBehaviour)
end

function BomberDive_FlyLow(height, targetID)
	height = math.min(height, highBehaviour.wantedHeight)
	StartThread(SpeedControl)
	lowBehaviour.wantedHeight = height
	StartThread(BehaviourChangeThread, lowBehaviour, targetID)
end

function script.StartMoving()
	--Turn(fins, z_axis, math.rad(-(-30)), math.rad(50))
	Move(wingr1, x_axis, 0, 50)
	Move(wingr2, x_axis, 0, 50)
	Move(wingl1, x_axis, 0, 50)
	Move(wingl2, x_axis, 0, 50)
	StartThread(SpeedControl)
end

function script.StopMoving()
	--Turn(fins, z_axis, math.rad(-(0)), math.rad(80))
	Move(wingr1, x_axis, 5, 30)
	Move(wingr2, x_axis, 5, 30)
	Move(wingl1, x_axis, -5, 30)
	Move(wingl2, x_axis, -5, 30)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
end

local function Lights()
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(400)
	end
	while true do
		EmitSfx(wingtipr, 1024)
		EmitSfx(wingtipl, 1025)
		Sleep(2000)
	end
end

function script.Create()
	SetInitialBomberSettings()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	GG.FakeUpright.FakeUprightInit(xp, zp, drop)
	--StartThread(Lights)
end

function script.QueryWeapon(num)
	return drop
end

function script.AimFromWeapon(num)
	return drop
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

local predictMult = 3

function script.BlockShot(num, targetID)
	if num ~= 2 then
		return false
	end
	local ableToFire = not ((GetUnitValue(COB.CRASHING) == 1) or RearmBlockShot())
	if not (targetID and ableToFire) then
		return not ableToFire
	end
	local x,y,z = spGetUnitPosition(unitID)
	local _,_,_,_,_,_,tx,ty,tz = spGetUnitPosition(targetID, true, true)
	local vx,vy,vz = spGetUnitVelocity(targetID)
	local heading = spGetUnitHeading(unitID)*GG.Script.headingToRad
	vx, vy, vz = vx*predictMult, vy*predictMult, vz*predictMult
	local dx, dy, dz = tx + vx - x, ty + vy - y, tz + vz - z
	local cosHeading = math.cos(heading)
	local sinHeading = math.sin(heading)
	dx, dz = cosHeading*dx - sinHeading*dz, cosHeading*dz + sinHeading*dx
	
	--Spring.Echo(vx .. ", " .. vy .. ", " .. vz)
	--Spring.Echo(dx .. ", " .. dy .. ", " .. dz)
	--Spring.Echo(heading)
	
	if dz < 30 and dz > -30 and dx < 100 and dx > -100 and dy < 0 then
		GG.FakeUpright.FakeUprightTurn(unitID, xp, zp, base, predrop)
		Move(drop, x_axis, dx)
		Move(drop, z_axis, dz)
		dy = math.max(dy, -30)
		Move(drop, y_axis, dy)
		local distance = (Spring.GetUnitSeparation(unitID, targetID) or 0)
		local unitHeight = (GG.GetUnitHeight and GG.GetUnitHeight(targetID)) or 0
		distance = math.max(0, distance - unitHeight/2)
		local projectileTime = 35*math.min(1, distance/340)
		
		if GG.OverkillPrevention_CheckBlock(unitID, targetID, 800.1, projectileTime, false, false, true) then
			-- Remove attack command on blocked target, it's already dead so move on.
			local cQueue = Spring.GetCommandQueue(unitID, 1)
			if cQueue and cQueue[1] and cQueue[1].id == CMD.ATTACK and (not cQueue[1].params[2]) and cQueue[1].params[1] == targetID then
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cQueue[1].tag}, 0)
			end
			return true
		end
		return false
	end
	return true
end

local function SpamFireCheck()
	for i = 1, 10 do
		GG.Bomber_Dive_fake_fired(unitID)
		Sleep(100)
	end
end

function script.FireWeapon(num)
	if num == 2 then
		SetUnarmedAI()
		GG.Bomber_Dive_fired(unitID)
		Sleep(33) -- delay before clearing attack order; else bomb loses target and fails to home
		Move(drop, x_axis, 0)
		Move(drop, z_axis, 0)
		Move(drop, y_axis, 0)
		Reload()
	elseif num == 3 then
		StartThread(SpamFireCheck)
	end
end

function script.Killed(recentDamage, maxHealth)
	Signal(SIG_TAKEOFF)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(fuselage, SFX.NONE)
		Explode(engines, SFX.NONE)
		Explode(wingl1, SFX.NONE)
		Explode(wingr2, SFX.NONE)
		return 1
	elseif severity <= 0.50 or (Spring.GetUnitMoveTypeData(unitID).aircraftState == "crashing") then
		Explode(fuselage, SFX.NONE)
		Explode(engines, SFX.NONE)
		Explode(wingl2, SFX.NONE)
		Explode(wingr1, SFX.NONE)
		return 1
	elseif severity <= 1 then
		Explode(fuselage, SFX.NONE)
		Explode(engines, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingl1, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingr2, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(fuselage, SFX.NONE)
		Explode(engines, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingl1, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(wingl2, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
