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

local SIG_TAKEOFF = 1
local SIG_NOT_BLOCKED = 2
local predictMult = 3

local takeoffHeight = UnitDefNames["bomberprec"].wantedHeight
local takeoffHeightInElmos = takeoffHeight*1.5
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

local function ResetTurnRadius()
	Signal(SIG_NOT_BLOCKED)
	SetSignalMask(SIG_NOT_BLOCKED)
	Sleep(500)
	SetUnarmedAI(300)
end

local function GetAimLocation(targetID)
	if not targetID then
		local targetType, isUser, pos = Spring.GetUnitWeaponTarget(unitID, 2)
		if targetType == 2 and pos then
			return pos[1], pos[2], pos[3]
		end
		return false
	end
	local _,_,_,_,_,_,tx,ty,tz = spGetUnitPosition(targetID, true, true)
	local vx,vy,vz = spGetUnitVelocity(targetID)
	vx, vy, vz = vx*predictMult, vy*predictMult, vz*predictMult
	return tx + vx, ty + vy, tz + vz
end

function script.BlockShot(num, targetID)
	if num == 1 then
		return true
	end
	local ableToFire = not ((GetUnitValue(COB.CRASHING) == 1) or RearmBlockShot())
	if not ableToFire then
		return not ableToFire
	end
	SetUnarmedAI() -- Unarmed before firing because low turn radius fixes the turn aside bug. Try to hit a Flea retreating up a slope without this.
	StartThread(ResetTurnRadius)
	
	local tx, ty, tz = GetAimLocation(targetID)
	--Spring.MarkerAddPoint(tx, ty, tz,"")
	if not tx then
		return false
	end
	local x,y,z = spGetUnitPosition(unitID)
	local dx, dy, dz = tx - x, ty - y, tz - z
	local heading = spGetUnitHeading(unitID)*GG.Script.headingToRad
	local cosHeading = math.cos(heading)
	local sinHeading = math.sin(heading)
	dx, dz = cosHeading*dx - sinHeading*dz, cosHeading*dz + sinHeading*dx
	
	local isMobile = targetID and not GG.IsUnitIdentifiedStructure(true, targetID)
	local damage = targetID and GG.OverkillPrevention_GetHealthThreshold(targetID, 800.1, 770.1)
	
	--Spring.Echo(vx .. ", " .. vy .. ", " .. vz)
	--Spring.Echo(dx .. ", " .. dy .. ", " .. dz)
	--Spring.Echo(heading)
	if targetID and GG.OverkillPrevention_CheckBlockNoFire(unitID, targetID, damage, 40, false, false, false) then
		-- Remove attack command on blocked target, if it is followed by another attack command. This is commands queued in an area.
		local cmdID, _, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID)
		if cmdID == CMD.ATTACK and (not cp_2) and cp_1 == targetID then
			local cmdID_2, _, _, cp_1_2, cp_2_2 = Spring.GetUnitCurrentCommand(unitID, 2)
			if cmdID_2 == CMD.ATTACK and (not cp_2_2) then
				local cQueue = Spring.GetCommandQueue(unitID, 1)
				Spring.GiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
			end
		end
		return true
	end
	
	local mx, mz = dx, dz
	if isMobile then
		mx = math.min(math.max(-45, mx), 45)
		mz = math.min(math.max(-30, mz), 30)
	else
		mx = math.min(math.max(-30, mx), 30)
		mz = math.min(math.max(-15, mz), 15)
	end
	dx, dz = dx - mx, dz - mz
	local hDist = math.sqrt(dx*dx + dz*dz)
	
	if dy > 0 or hDist*1.15 > -dy then
		return true
	end
	
	local isTooFast = false -- Do not OKP for too fast targets as we don't expect to hit.
	if isMobile then
		local speed = EstimateCurrentMaxSpeed(targetID)
		if speed >= 3 then
			isTooFast = true
		end
		--Spring.Echo(hDist, speed, math.max(3, -dy - speed*90 - 35))
		-- Cap out at speed 2.7 on normal terrain
		local diffFactor = -dy
		if diffFactor > takeoffHeightInElmos then
			-- Reduce apparently height difference for cone in cases where Raven is higher than usual.
			-- This can happen when the Raven crests a cliff, or against underwater targets.
			diffFactor = takeoffHeightInElmos*(diffFactor + takeoffHeightInElmos) / (2*diffFactor)
		end
		--Spring.Echo("diffFactor", diffFactor, -dy, takeoffHeightInElmos)
		if hDist > math.max(3, diffFactor - speed*90 - 35) then
			return true
		end
	end
	
	--if (dz > 30 or dz < -30 or dx > 80 or dx < -80) then
		--return true
	--end
	
	if targetID and (not isTooFast) and GG.Script.OverkillPreventionCheck(unitID, targetID, damage, 270, 35, 0.025) then
		return true
	end
	GG.FakeUpright.FakeUprightTurn(unitID, xp, zp, base, predrop)
	Move(drop, x_axis, mx)
	Move(drop, z_axis, mz)
	return false
end

function script.FireWeapon(num)
	if num == 2 then
		Sleep(33) -- delay before clearing attack order; else bomb loses target and fails to home
		Move(drop, x_axis, 0)
		Move(drop, z_axis, 0)
		Signal(SIG_NOT_BLOCKED)
		SetUnarmedAI()
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
