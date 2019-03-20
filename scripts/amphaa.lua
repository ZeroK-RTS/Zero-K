--linear constant 65536

include "constants.lua"

local scriptReload = include("scriptReload.lua")

local base, pelvis, torso, vent = piece('base', 'pelvis', 'torso', 'vent')
local rthigh, rcalf, rfoot, lthigh, lcalf, lfoot = piece('rthigh', 'rcalf', 'rfoot', 'lthigh', 'lcalf', 'lfoot')
local lgun, lbarrel1, lbarrel2, rgun, rbarrel1, rbarrel2 = piece('lgun', 'lbarrel1', 'lbarrel2', 'rgun', 'rbarrel1', 'rbarrel2')


local shot = 0
local gun = {
	[0] = {firepoint = rbarrel1, loaded = true, readyToAim = true},
	[1] = {firepoint = lbarrel1, loaded = true, readyToAim = true},
	[2] = {firepoint = rbarrel2, loaded = true, readyToAim = true},
	[3] = {firepoint = lbarrel2, loaded = true, readyToAim = true},
}

local smokePiece = {torso}
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local PACE = 2

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(30)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local calf_FRONT_ANGLE = math.rad(45)
local calf_FRONT_SPEED = math.rad(90) * PACE
local calf_BACK_ANGLE = math.rad(10)
local calf_BACK_SPEED = math.rad(90) * PACE

local SLEEP_TIME = 0 -- 1000 * math.abs(THIGH_FRONT_ANGLE - THIGH_BACK_ANGLE) / THIGH_FRONT_SPEED

local SIG_WALK = 1
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8
local SIG_FLOAT = 16
local SIG_BOB = 32

local gameSpeed = Game.gameSpeed

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim functions

local floatState = nil
-- rising, sinking, static

local function Bob()
	Signal(SIG_BOB)
	SetSignalMask(SIG_BOB)
	while true do
		Turn(base, x_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Turn(base, z_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Move(base, y_axis, math.rad(math.random(0,2)), math.rad(math.random()))
		Sleep(2000)
		Turn(base, x_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Turn(base, z_axis, math.rad(math.random(-2,2)), math.rad(math.random()))
		Move(base, y_axis, math.rad(math.random(-2,0)), math.rad(math.random()))
		Sleep(2000)
	end
end

local function FloatBubbles()
	--[[
	SetSignalMask(SIG_FLOAT)
	local isSubmerged = true
	while true do
		--EmitSfx(vent, SFX.BUBBLE)

		if isSubmerged then -- water breaking anim - kind of overkill?
			local x,y,z = Spring.GetUnitPosition(unitID)
			y = y + Spring.GetUnitHeight(unitID)*0.5
			if y > 0 then
				--Spring.Echo("splash")
				Spring.SpawnCEG("water_breaksurface", x, 0, z, 0, 1, 0, 20, 0)
				isSubmerged = false
			end
		end
		Sleep(33)

	end
	]]
end

local function riseFloat_thread()
	if floatState ~= 0 then
		floatState = 0
	else
		return
	end
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)
		--StartThread(FloatBubbles)

	Turn(lthigh,x_axis, math.rad(30), math.rad(240))
	Turn(lcalf,x_axis, math.rad(-50), math.rad(240))
	Turn(lfoot,x_axis, math.rad(80), math.rad(240))

	Turn(rthigh,x_axis, math.rad(30), math.rad(240))
	Turn(rcalf,x_axis, math.rad(-50), math.rad(240))
	Turn(rfoot,x_axis, math.rad(80), math.rad(240))

	Sleep(400)

	while true do

		Turn(lthigh,x_axis, math.rad(30+15), math.rad(75))
		Turn(rthigh,x_axis, math.rad(30-15), math.rad(75))


		Sleep(200)

		Turn(lcalf,x_axis, math.rad(-55-20), math.rad(100))
		Turn(lfoot,x_axis, math.rad(80+20), math.rad(100))
		Turn(rcalf,x_axis, math.rad(-55+20), math.rad(100))
		Turn(rfoot,x_axis, math.rad(80-20), math.rad(100))

		Sleep(200)

		Turn(lthigh,x_axis, math.rad(30-15), math.rad(75))
		Turn(rthigh,x_axis, math.rad(30+15), math.rad(75))

		Sleep(200)

		Turn(lcalf,x_axis, math.rad(-55+20), math.rad(100))
		Turn(lfoot,x_axis, math.rad(80-20), math.rad(100))
		Turn(rcalf,x_axis, math.rad(-55-20), math.rad(100))
		Turn(rfoot,x_axis, math.rad(80+20), math.rad(100))

		Sleep(200)
	end
end

local function staticFloat_thread()
	if floatState ~= 2 then
		floatState = 2
	else
		return
	end
	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)

	Turn(lcalf,x_axis, math.rad(-55-20), math.rad(50))
	Turn(lfoot,x_axis, math.rad(80+20), math.rad(50))
	Turn(rcalf,x_axis, math.rad(-55+20), math.rad(50))
	Turn(rfoot,x_axis, math.rad(80-20), math.rad(50))

	while true do

		Turn(lthigh,x_axis, math.rad(30+15), math.rad(37.5))
		Turn(rthigh,x_axis, math.rad(30-15), math.rad(37.5))


		Sleep(400)

		Turn(lcalf,x_axis, math.rad(-55-20), math.rad(50))
		Turn(lfoot,x_axis, math.rad(80+20), math.rad(50))
		Turn(rcalf,x_axis, math.rad(-55+20), math.rad(50))
		Turn(rfoot,x_axis, math.rad(80-20), math.rad(50))

		Sleep(400)

		Turn(lthigh,x_axis, math.rad(30-15), math.rad(37.5))
		Turn(rthigh,x_axis, math.rad(30+15), math.rad(37.5))

		Sleep(400)

		Turn(lcalf,x_axis, math.rad(-55+20), math.rad(50))
		Turn(lfoot,x_axis, math.rad(80-20), math.rad(50))
		Turn(rcalf,x_axis, math.rad(-55-20), math.rad(50))
		Turn(rfoot,x_axis, math.rad(80+20), math.rad(50))

		Sleep(400)
	end
end

local function sinkFloat_thread()
	if floatState ~= 1 then
		floatState = 1
	else
		return
	end

	Signal(SIG_FLOAT)
	SetSignalMask(SIG_FLOAT)

	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rcalf, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lcalf, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(pelvis, z_axis, 0, math.rad(20)*PACE)
	Move(pelvis, y_axis, 0, 12*PACE)

	Turn(base, x_axis,0, math.rad(math.random(1,2)))
	Turn(base, z_axis, 0, math.rad(math.random(1,2)))
	Move(base, y_axis, 0, math.rad(math.random(1,2)))

	while true do --FIXME: not stopped when sinking ends!
		EmitSfx(vent, SFX.BUBBLE)
		Sleep(66)
	end

end

local function dustBottom()
	local x,y,z = Spring.GetUnitPiecePosDir(unitID,rfoot)
	Spring.SpawnCEG("uw_vindiback", x, y+5, z, 0, 0, 0, 0)
	local x,y,z = Spring.GetUnitPiecePosDir(unitID,lfoot)
	Spring.SpawnCEG("uw_vindiback", x, y+5, z, 0, 0, 0, 0)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Swim gadget callins

function Float_startFromFloor()
	dustBottom()
	Signal(SIG_WALK)
	StartThread(riseFloat_thread)
	StartThread(Bob)
end

function Float_stopOnFloor()
	dustBottom()
	Signal(SIG_FLOAT)
	Signal(SIG_BOB)
end

function Float_rising()
	StartThread(riseFloat_thread)
end

function Float_sinking()
	StartThread(sinkFloat_thread)
end

function Float_crossWaterline(speed)
	StartThread(staticFloat_thread)
end

function Float_stationaryOnSurface()
	StartThread(staticFloat_thread)
end

function unit_teleported(position)
	return GG.Floating_UnitTeleported(unitID, position)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		local speedmult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)

		--left leg up, right leg back
		Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(lcalf, x_axis, calf_FRONT_ANGLE, calf_FRONT_SPEED)
		Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(rcalf, x_axis, calf_BACK_ANGLE, calf_BACK_SPEED)
		WaitForTurn(lthigh, x_axis)
		Sleep(SLEEP_TIME)

		--right leg up, left leg back
		Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED)
		Turn(lcalf, x_axis, calf_BACK_ANGLE, calf_BACK_SPEED)
		Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED)
		Turn(rcalf, x_axis, calf_FRONT_ANGLE, calf_FRONT_SPEED)
		WaitForTurn(rthigh, x_axis)
		Sleep(SLEEP_TIME)
	end
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rcalf, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lcalf, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(pelvis, z_axis, 0, math.rad(20)*PACE)
	Move(pelvis, y_axis, 0, 12*PACE)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_START_FLOAT)
	StartThread(Stopping)
	GG.Floating_StopMoving(unitID)
end

function script.Create()
	scriptReload.SetupScriptReload(4, 12 * gameSpeed)
	StartThread(GG.Script.SmokeUnit, smokePiece)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(torso, y_axis, 0, math.rad(65))
	Turn(lgun, x_axis, 0, math.rad(47.5))
	Turn(rgun, x_axis, 0, math.rad(47.5))
end


function script.AimFromWeapon()
	return torso
end

function script.AimWeapon(num, heading, pitch)
	local reloadState = Spring.GetUnitWeaponState(unitID, 1, 'reloadState')
	if (reloadState < 0 or reloadState - Spring.GetGameFrame() < 70) and gun[num].readyToAim then
		GG.Floating_AimWeapon(unitID)
	end

	Signal(SIG_AIM1)
	SetSignalMask(SIG_AIM1)
	Turn(torso, y_axis, heading, math.rad(360))
	Turn(lgun, x_axis, -pitch, math.rad(180))
	Turn(rgun, x_axis, -pitch, math.rad(180))
	WaitForTurn(torso, y_axis)
	WaitForTurn(lgun, x_axis)
	WaitForTurn(rgun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.QueryWeapon(num)
	return gun[shot].firepoint
end

local SleepAndUpdateReload = scriptReload.SleepAndUpdateReload

local function reload(num)
	scriptReload.GunStartReload(num)
	gun[num].loaded = false
	gun[num].readyToAim = false

	SleepAndUpdateReload(num, 9 * gameSpeed)

	gun[num].readyToAim = true

	SleepAndUpdateReload(num, 3 * gameSpeed)

	if scriptReload.GunLoaded(num) then
		shot = 0
	end
	gun[num].loaded = true
end

function script.Shot(num)
	EmitSfx(gun[shot].firepoint, 1024)
	GG.Floating_AimWeapon(unitID)
	StartThread(reload,shot)
	shot = (shot + 1)%4
end

function script.BlockShot(num, targetID)
	if gun[shot].loaded then
		local distMult = (Spring.ValidUnitID(targetID) and Spring.GetUnitSeparation(unitID, targetID) or 0)/820
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 150.1, 35 * distMult)
	end
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lfoot, SFX.NONE)
		Explode(lcalf, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(pelvis, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rcalf, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lcalf, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(pelvis, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rcalf, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(pelvis, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rcalf, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end