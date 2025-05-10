include "bombers.lua"
include "fakeUpright.lua"
include "constants.lua"
include "fixedwingTakeOff.lua"

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
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData  = Spring.MoveCtrl.SetAirMoveTypeData
local spGetGroundHeight     = Spring.GetGroundHeight

local EstimateCurrentMaxSpeed = Spring.Utilities.EstimateCurrentMaxSpeed

local doingRun = false

local SIG_TAKEOFF = 1
local SIG_NOT_BLOCKED = 2
local predictMult = 3

local takeoffHeight = UnitDefNames["bomberprec"].cruiseAltitude
local takeoffHeightInElmos = takeoffHeight*1.5
local smokePiece = {fuselage, thrustr, thrustl}

function script.StartMoving()
	--Turn(fins, z_axis, math.rad(30), math.rad(50))
	Move(wingr1, x_axis, 0, 50)
	Move(wingr2, x_axis, 0, 50)
	Move(wingl1, x_axis, 0, 50)
	Move(wingl2, x_axis, 0, 50)
end

function script.StopMoving()
	--Turn(fins, z_axis, 0, math.rad(80))
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
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.TakeOffFuncs.TakeOffThread, takeoffHeight, SIG_TAKEOFF)
	GG.FakeUpright.FakeUprightInit(xp, zp, drop)
	Move (drop, y_axis, -9)
	Move (drop, z_axis, 1.8)
	--StartThread(Lights)
end

function script.QueryWeapon(num)
	return drop
end

function script.AimFromWeapon(num)
	return drop
end

function script.AimWeapon(num, heading, pitch)
	return not RearmBlockShot()
end

local function ResetTurnRadius()
	Signal(SIG_NOT_BLOCKED)
	SetSignalMask(SIG_NOT_BLOCKED)
	Sleep(500)
	SetUnarmedAI(300)
end

function script.FireWeapon()
	if doingRun then
		return
	end
	if RearmBlockShot() then
		return
	end
	SetUnarmedAI()
	
	doingRun = true
	Sleep(500)
	local i = 1
	while i <= 9 do
		local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
		if not stunned_or_inbuild then
			local xx, xy, xz = Spring.GetUnitPiecePosDir(unitID,xp)
			local zx, zy, zz = Spring.GetUnitPiecePosDir(unitID,zp)
			local bx, by, bz = Spring.GetUnitPiecePosDir(unitID,base)
			local xdx = xx - bx
			local xdy = xy - by
			local xdz = xz - bz
			local zdx = zx - bx
			local zdy = zy - by
			local zdz = zz - bz
			local angle_x = math.atan2(xdy, math.sqrt(xdx^2 + xdz^2))
			local angle_z = math.atan2(zdy, math.sqrt(zdx^2 + zdz^2))
	
			Turn(predrop, x_axis, angle_x)
			Turn(predrop, z_axis, -angle_z)
			if i == 1 then
				Spring.PlaySoundFile("sounds/weapon/laser/heavy_laser3.wav", 4, px, py, pz)
			end
			EmitSfx(drop, GG.Script.FIRE_W2)
			GG.PokeDecloakUnit(unitID, unitDefID)
			i = i + 1
		end
		local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		Sleep(35/slowMult) -- fire density
	end
	
	doingRun = false
	Reload()
end

function StartRun()
	script.FireWeapon()
end

function script.BlockShot()
	return (GetUnitValue(GG.Script.CRASHING) == 1)
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
