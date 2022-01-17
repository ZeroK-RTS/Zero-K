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
local spMoveCtrlGetTag      = Spring.MoveCtrl.GetTag
local spGetUnitMoveTypeData = Spring.GetUnitMoveTypeData
local spSetAirMoveTypeData  = Spring.MoveCtrl.SetAirMoveTypeData
local spGetGroundHeight     = Spring.GetGroundHeight

local predictMult = 3

local takeoffHeight = UnitDefNames["bomberprec"].wantedHeight
local smokePiece = {fuselage, thrustr, thrustl}

function script.StartMoving()
	--Turn(fins, z_axis, math.rad(-(-30)), math.rad(50))
	Move(wingr1, x_axis, 0, 50)
	Move(wingr2, x_axis, 0, 50)
	Move(wingl1, x_axis, 0, 50)
	Move(wingl2, x_axis, 0, 50)
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
	
	local isMobile = not GG.IsUnitIdentifiedStructure(true, targetID)
	local damage = (isMobile and 500.05) or GG.OverkillPrevention_GetHealthThreshold(targetID, 800.1, 770.1)
	
	--Spring.Echo(vx .. ", " .. vy .. ", " .. vz)
	--Spring.Echo(dx .. ", " .. dy .. ", " .. dz)
	--Spring.Echo(heading)
	if GG.OverkillPrevention_CheckBlockNoFire(unitID, targetID, damage, 60, false, false, false) then
		-- Remove attack command on blocked target, it's already dead so move on.
		local cQueue = Spring.GetCommandQueue(unitID, 1)
		if cQueue and cQueue[1] and cQueue[1].id == CMD.ATTACK and (not cQueue[1].params[2]) and cQueue[1].params[1] == targetID then
			Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cQueue[1].tag, 0)
		end
		return true
	end
	
	if dy > 0 then
		return true
	end
	
	if (dz > 30 or dz < -30 or dx > 80 or dx < -80) then
		return true
	end
	
	if isMobile then
		dx = math.min(math.max(-50, dx), 50)
		dz = math.min(math.max(-20, dz), 20)
		dy = math.max(dy, -20)
	else
		dx = math.min(math.max(-30, dx), 30)
		dz = math.min(math.max(-10, dz), 10)
		dy = math.max(dy, -5)
	end
	
	GG.FakeUpright.FakeUprightTurn(unitID, xp, zp, base, predrop)
	Move(drop, x_axis, dx)
	Move(drop, z_axis, dz)
	Move(drop, y_axis, dy)
	
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, 60, false, false, false) then
		return true
	end
	return false
end


function script.FireWeapon(num)
	if num == 2 then
		SetUnarmedAI()
		Sleep(33) -- delay before clearing attack order; else bomb loses target and fails to home
		Move(drop, x_axis, 0)
		Move(drop, z_axis, 0)
		Move(drop, y_axis, 0)
		Reload()
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
