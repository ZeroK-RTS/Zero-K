include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
local hips = piece 'hips'
local torsoPivot = piece 'torsopivot'
local torsoTrue = piece 'torso'
local camera = piece 'camera'
local shoulderl = piece 'shoulderl'
local shoulderr = piece 'shoulderr'
local arml = piece 'arml'
local armr = piece 'armr'
local forearml = piece 'forearml'
local forearmr = piece 'forearmr'
local handl = piece 'handl'
local handr = piece 'handr'
local receiver = piece 'receiver'
local barrel = piece 'barrel'
local flare = piece 'flare'
local gunemit = piece 'gunemit'
local scope = piece 'scope'
local stock = piece 'stock'
local thighl = piece 'thighl'
local thighr = piece 'thighr'
local shinl = piece 'shinl'
local shinr = piece 'shinr'
local anklel = piece 'anklel'
local ankler = piece 'ankler'
local footl = piece 'footl'
local footr = piece 'footr'
local backpack = piece 'backpack'

local shoulder = {shoulderl, shoulderr}
local thigh = {thighl, thighr}
local shin = {shinl, shinr}
local ankle = {anklel, ankler}
local foot = {footl, footr}

local smokePiece = {torsoTrue, backpack}
--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_IDLE = 1
local SIG_AIM = 2
local SIG_PACK = 4
local SIG_WALK = 8
local SIG_RESTORE = 16

-- future-proof running animation against balance tweaks
local PACE = 8.1 * (UnitDefs[unitDefID].speed / 43)

local GUN_STOWED_ANGLE = math.rad(-45)
local GUN_STOWED_SPEED = math.rad(45)
local GUN_READY_SPEED = math.rad(45)

local VERT_AIM_SPEED = math.rad(210)
local AIM_SPEED = math.rad(480) -- noscope

local RELOAD_PENALTY = tonumber(UnitDefs[unitDefID].customParams.reload_move_penalty)
local RELOAD_PENALTY_HALF = 0.5 + 0.5 * tonumber(UnitDefs[unitDefID].customParams.reload_move_penalty)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local bAiming, canAim, gun_unpacked, aimBlocked = false, true, false, false
local maintainHeading = false
local torsoHeading = 0

local function GetSpeedMod()
	-- disallow zero (instant turn instead -> infinite loop)
	return math.max(0.05, GG.att_MoveChange[unitID] or 1)
end

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	local side = 1
	while true do
		local speedmod = math.sqrt(GetSpeedMod())
		local speedMult = PACE * speedmod
		local strideMult = speedmod

		if not(bAiming) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end

		Turn(shin[side],    x_axis, strideMult * math.rad(85),  speedMult*0.35)
		Turn(ankle[side],   x_axis, strideMult * math.rad(0),   speedMult*0.25)
		Turn(foot[side],    x_axis, strideMult * math.rad(0),   speedMult*0.25)
		Turn(thigh[side],   x_axis, strideMult * math.rad(-36), speedMult*0.16)
		Turn(thigh[3-side], x_axis, strideMult * math.rad(36),  speedMult*0.16)
		Turn(shin[3-side],  x_axis, strideMult * math.rad(0),   speedMult*0.16)

		Move(hips, y_axis, 1.5, speedMult*2.0)
		WaitForMove(hips, y_axis)

		Turn(shin[side],   x_axis, strideMult * math.rad(0),   speedMult*0.26)
		Turn(ankle[side],  x_axis, strideMult * math.rad(10),  speedMult*0.26)
		Turn(foot[side],   x_axis, strideMult * math.rad(-20), speedMult*0.25)
		Turn(foot[3-side], x_axis, strideMult * math.rad(5),   speedMult*0.15)
		Move(hips, y_axis, strideMult * -0.5, speedMult*0.65)

		WaitForMove(hips, y_axis)

		Move(hips, y_axis, strideMult * -3, speedMult*1.0)
		Turn(shin[3-side], x_axis, math.rad(10), speedMult*0.15)

		WaitForTurn(thigh[side], x_axis)
		side = 3 - side
	end
end

local function IdleAnim()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(1000)
	end
	Sleep(3000)
	while true do
		if not(bAiming or aimBlocked) then
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(-30), math.rad(80))
		Sleep(3500)
		if not(bAiming or aimBlocked) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(30), math.rad(80))
		Turn(forearmr, x_axis, math.rad(-30), math.rad(60))
		Sleep(3500)
		if not(bAiming or aimBlocked) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(-30), math.rad(80))
		Sleep(3500)
		if not(bAiming or aimBlocked) then
			Turn(shoulderl, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
			Turn(shoulderr, x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
		Turn(camera, y_axis, math.rad(30), math.rad(80))
		Turn(forearmr, x_axis, 0, math.rad(60))
		Sleep(3500)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Move(hips, y_axis, 0, 8.0)
	for side = 1, 2 do
		Turn(thigh[side], x_axis, 0, math.rad(90))
		Turn(shin[side], x_axis, 0, math.rad(90))
		Turn(foot[side], x_axis, 0, math.rad(90))
		Turn(ankle[side], x_axis, 0, math.rad(90))
		if not(bAiming) then
			Turn(shoulder[side], x_axis, GUN_STOWED_ANGLE, GUN_STOWED_SPEED)
		end
	end
	StartThread(IdleAnim)
end

function script.StartMoving()
	StartThread(Walk)
	Signal(SIG_IDLE)
end

function script.StopMoving()
	StartThread(Stopping)
end


function script.ChangeHeading(delta)
	if delta == 0 then
		return
	end
	if maintainHeading then
		torsoHeading = torsoHeading + delta * GG.Script.headingToRad
		Turn(torsoTrue, y_axis, -torsoHeading, AIM_SPEED)
	end
end

----------------------------------------------------
--start ups :)
--------------------------------------------------------

local function UnpackGunInstant()
	Turn(shoulderr, x_axis, math.rad(-90))
	Turn(shoulderl, x_axis, math.rad(-90))
	--Turn(forearml, x_axis, math.rad(-90))
	Turn(forearml, z_axis, math.rad(-80))
	Turn(handl, y_axis, math.rad(-90))
	Move(barrel, y_axis, -4.2)
	Move(stock, y_axis, 9)
	gun_unpacked = true
end

-----------------------------------------------------------------------
--gun functions
-----------------------------------------------------------------------

local function PackGun()
	Signal(SIG_IDLE)
	Signal(SIG_PACK)
	SetSignalMask(SIG_PACK)

	canAim = false
	Move(barrel, y_axis, 0, 900)
	Move(stock, y_axis, 0, 1400)

	WaitForMove(barrel, y_axis)
	WaitForMove(stock, y_axis)

	Turn(forearmr, x_axis, 0, math.rad(140))
	--Turn(torsoTrue, y_axis, 0, math.rad(120))
	Turn(forearml, z_axis, 0, math.rad(250))
	Turn(handl, y_axis, 0, math.rad(250))

	WaitForTurn(forearml, z_axis)
	Turn(shoulderl, x_axis, 0, math.rad(250))
	gun_unpacked = false
	canAim = true
end

local function UnpackGun()
	Signal(SIG_IDLE)
	Signal(SIG_PACK)
	SetSignalMask(SIG_PACK)

	Turn(forearmr, x_axis, 0, math.rad(200))
	Turn(forearml, z_axis, math.rad(-80), math.rad(200))
	Turn(handl, y_axis, math.rad(90), math.rad(200))
	WaitForTurn(forearml, z_axis)
	Move(barrel, y_axis, -4.2, 900)
	Move(stock, y_axis, 9, 1400)
	WaitForMove(barrel, y_axis)
	gun_unpacked = true
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(10000)
	--if the gun is unpacked and we\'re not aiming, close it
	--if gun_unpacked and not bAiming then
	--
		Turn(torsoTrue, y_axis, 0, math.rad(120))
		Turn(torsoPivot, y_axis, 0, math.rad(120))
		torsoHeading = 0
		--Turn(shoulderr, x_axis, math.rad(-90), math.rad(140))
	--	StartThread(PackGun)
	--end
	maintainHeading = false
	bAiming = false
	StartThread(IdleAnim)
end

-----------------------------------------------------------------------
-- reload functions
-----------------------------------------------------------------------

local function SetSelfSpeedMod(speedmod)
	if RELOAD_PENALTY == 1 then
		return
	end
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", speedmod)
	GG.UpdateUnitAttributes(unitID)
end

local function SetupReloadStance()
	Turn(arml, y_axis, math.rad(-8), math.rad(45))
	Turn(arml, x_axis, math.rad(28), math.rad(45))
	Turn(arml, z_axis, math.rad(5), math.rad(45))
	
	Turn(forearml, z_axis, math.rad(-45), math.rad(45))
	
	Turn(armr, x_axis, math.rad(38), math.rad(45))
	Turn(armr, y_axis, math.rad(8), math.rad(45))
	
	Turn(forearmr, z_axis, math.rad(45), math.rad(45))
	
	Turn(camera, y_axis, math.rad(-12), math.rad(80))
	Turn(camera, x_axis, math.rad(35), math.rad(80))
end

local function LeaveReloadStance()
	Turn(arml, y_axis, math.rad(0), math.rad(45))
	Turn(arml, x_axis, math.rad(0), math.rad(45))
	Turn(arml, z_axis, math.rad(0), math.rad(45))
	
	Turn(forearml, z_axis, math.rad(-90), math.rad(45))
	
	Turn(armr, x_axis, math.rad(0), math.rad(45))
	Turn(armr, y_axis, math.rad(0), math.rad(45))
	
	Turn(forearmr, z_axis, math.rad(0), math.rad(45))
	
	Turn(camera, y_axis, math.rad(0), math.rad(80))
	Turn(camera, x_axis, math.rad(0), math.rad(80))
	
	Move(stock, y_axis, 9, 9)
	Turn(handl, z_axis, 0, math.rad(6))
	Turn(handr, z_axis, 0, math.rad(6))
	
	-- Happens in fire weapon
	Move(barrel, y_axis, -4.2, 4)
end

local function WiggleReload()
	Move(stock, y_axis, 9 - 10 * math.random(), 20 * math.random())
	Turn(forearml, z_axis, math.rad(-48 + 6 * math.random()), math.rad(8))
	Turn(forearmr, z_axis, math.rad(45 - 3 * math.random()), math.rad(8))
	Turn(camera, y_axis, math.rad(-15 + 20 * math.random()), math.rad(30))
	Turn(handl, z_axis, math.rad(8 - 16 * math.random()), math.rad(10))
	Turn(handr, z_axis, math.rad(10 - 10 * math.random()), math.rad(10))
end

local function ReloadPenaltyAndAnimation()
	aimBlocked = true
	SetSelfSpeedMod(RELOAD_PENALTY_HALF)
	Signal(SIG_AIM)
	Signal(SIG_RESTORE)

	Sleep(1000)
	SetSelfSpeedMod(RELOAD_PENALTY)
	Turn(torsoTrue, y_axis, 0, math.rad(120))
	Turn(torsoPivot, y_axis, 0, math.rad(120))
	SetupReloadStance()
	
	-- 17 second reload so no point checking earlier (with room for animation reset).
	Sleep(1000)
	for i = 1, 25 do
		WiggleReload()
		Sleep(500)
	end
	
	while true do
		local state = Spring.GetUnitWeaponState(unitID, 1, "reloadState")
		local gameFrame = Spring.GetGameFrame()
		if state - 32 < gameFrame then
			aimBlocked = false
			Signal(SIG_AIM)

			Sleep(500)
			SetSelfSpeedMod(1)
			return
		elseif state - 64 < gameFrame then
			SetSelfSpeedMod(RELOAD_PENALTY_HALF)
			LeaveReloadStance()
		else
			WiggleReload()
		end
		Sleep(500)
	end
end

-----------------------------------------------------------------------
-- callins
-----------------------------------------------------------------------

function script.Create()
	--Turn(forearmr, x_axis, math.rad(-45), math.rad(280))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	UnpackGunInstant()
	StartThread(IdleAnim)
	--StartThread(TorsoHeadingThread)
end

function script.AimFromWeapon(num)
	return shoulderr
end

function script.QueryWeapon(num)
	return gunemit
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_IDLE)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	maintainHeading = true

	GG.DontFireRadar_CheckAim(unitID)

	-- Announce that we would like to aim, and wait until we can
	while aimBlocked or not canAim do
		Sleep(500)
	end
	bAiming = true
	Turn(hips, x_axis, 0)
	Turn(torsoTrue, x_axis, 0)
	Turn(camera, y_axis, 0, math.rad(100))
	Turn(shoulderr, x_axis, math.rad(-90) - pitch, math.rad(180))
	Turn(shoulderl, x_axis, math.rad(-90) - pitch, math.rad(180))
	Turn(forearmr, x_axis, 0, math.rad(180))
	if not gun_unpacked then
		UnpackGun()
	end
	Turn(torsoPivot, y_axis, heading, AIM_SPEED)
	Turn(torsoTrue, y_axis, 0, VERT_AIM_SPEED)
	WaitForTurn(shoulderl, x_axis)
	WaitForTurn(torsoPivot, y_axis)
	WaitForTurn(torsoTrue, y_axis)
	WaitForTurn(shoulderr, x_axis)
	WaitForTurn(forearmr, x_axis)
	StartThread(RestoreAfterDelay)
	torsoHeading = 0
	Turn(camera, y_axis, 0, math.rad(100))
	return(true)
end

function script.BlockShot(num, targetID)
	return (targetID and (GG.DontFireRadar_CheckBlock(unitID, targetID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 1500.1, 28))) or false
end

function script.FireWeapon(num)
	Turn(forearmr, x_axis, math.rad(-20), math.rad(300))
	Sleep(33)
	Turn(torsoTrue, y_axis, math.rad(-20), math.rad(400))
	Turn(camera, y_axis, math.rad(20), math.rad(400))
	Turn(forearmr, y_axis, math.rad(10), math.rad(400))
	Move(barrel, y_axis, 0)
	StartThread(ReloadPenaltyAndAnimation)
	WaitForTurn(forearmr, x_axis)
	Turn(forearmr, x_axis, 0, math.rad(-90), math.rad(15))
	Turn(torsoTrue, y_axis, 0, math.rad(100))
	Turn(camera, y_axis, 0, math.rad(150))
	Turn(forearmr, y_axis, 0, math.rad(200))
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		--[[
		Turn(shinr, x_axis, 0)
		Turn(thighr, x_axis, 0)
		Turn(thighl, x_axis, 0)
		Turn(shinl, x_axis, 0)

		WaitForTurn(thighl, x_axis)
		WaitForTurn(thighl, x_axis)
		Sleep(250)

		Turn(base, x_axis, math.rad(90), math.rad(50))
		Turn(hips, x_axis, math.rad(-90), math.rad(50))
		Turn(thighr, x_axis, math.rad(-45), math.rad(50))
		Turn(thighl, x_axis, math.rad(-45), math.rad(50))
		Turn(shinr, x_axis, math.rad(135), math.rad(50))
		Turn(shinl, x_axis, math.rad(135), math.rad(50))
		Move(hips, y_axis, -3, 2000)

		WaitForMove(hips, y_axis)
		Sleep(2000)]]

		Explode(shoulderl, SFX.NONE)
		Explode(shoulderr, SFX.NONE)
		Explode(hips, SFX.NONE)
		Explode(torsoTrue, SFX.NONE)
		Explode(camera, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(shoulderl, SFX.SHATTER)
		Explode(shoulderr, SFX.SHATTER)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE)
--		Sleep(200)
		Explode(torsoTrue, SFX.SHATTER)

--		Turn(base, x_axis, math.rad(-90), math.rad(50))
--		Turn(hips, x_axis, math.rad(90), math.rad(50))
--		WaitForTurn(base, x_axis)
--		Sleep(1000)

		Explode(hips, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 1
	elseif severity <= .99 then
		Explode(hips, SFX.SHATTER)
		Explode(torsoTrue, SFX.SHATTER)
		Explode(shoulderl, SFX.SHATTER)
		Explode(forearml, SFX.SHATTER)
		Explode(shoulderr, SFX.SHATTER)
		Explode(forearmr, SFX.SHATTER)
		Explode(thighr, SFX.SHATTER)
		Explode(thighl, SFX.SHATTER)
		Explode(shinl, SFX.SHATTER)
		Explode(shinr, SFX.SHATTER)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(backpack, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(receiver, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(hips, SFX.SHATTER)
		Explode(torsoTrue, SFX.SHATTER)
		Explode(shoulderl, SFX.SHATTER)
		Explode(forearml, SFX.SHATTER)
		Explode(shoulderr, SFX.SHATTER)
		Explode(forearmr, SFX.SHATTER)
		Explode(thighr, SFX.SHATTER)
		Explode(thighl, SFX.SHATTER)
		Explode(shinl, SFX.SHATTER)
		Explode(shinr, SFX.SHATTER)
		Explode(camera, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(backpack, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(receiver, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
