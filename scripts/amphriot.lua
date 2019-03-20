include 'constants.lua'

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, pelvis, torso = piece('base', 'torso', 'torso')
local lfleg, rfleg, lbleg, rbleg = piece('lfleg', 'rfleg', 'lbleg', 'rbleg')
local lffoot, rffoot, lbfoot, rbfoot = piece('lffoot', 'rffoot', 'lbfoot', 'rbfoot')
local mainturret, lturret1, lturret2, rturret1, rturret2 = piece('mainturret', 'lturret1', 'lturret2', 'rturret1', 'rturret2')
local flaremain, flarel1, flarel2, flarer1, flarer2 = piece('flaremain', 'flarel1', 'flarel2', 'flarer1', 'flarer2')

local flares = {flarel1, flarer1, flarel2, flarer2}

local smokePiece = {pelvis, torso}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------

local restore_delay = 3000
local base_speed = 100

local SIG_WALK = 1	
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8

local SPEED = 1.9

local SPEED = 2

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local gun_1 = 1

-- four-stroke tetrapedal walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
	
		local speedmult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)*SPEED
		
		-- extend left
		Turn(lfleg, x_axis, math.rad(-50), math.rad(25)*speedmult)
		Turn(lffoot, x_axis, math.rad(0), math.rad(150)*speedmult)
		
		Turn(rfleg, x_axis, math.rad(-40), math.rad(80)*speedmult)
		Turn(rffoot, x_axis, math.rad(60), math.rad(120)*speedmult)	
		
		Turn(rbleg, x_axis, math.rad(20), math.rad(100)*speedmult)
		Turn(rbfoot, x_axis, math.rad(30), math.rad(50)*speedmult)
		
		Turn(lbleg, x_axis, math.rad(-40), math.rad(80)*speedmult)
		Turn(lbfoot, x_axis, math.rad(60), math.rad(120)*speedmult)	

		Sleep(400/speedmult)
		
		Turn(lfleg, x_axis, math.rad(40), math.rad(150)*speedmult)
		Turn(lffoot, x_axis, math.rad(-60), math.rad(100)*speedmult)
		
		Sleep(200/speedmult)
		
		Turn(rbleg, x_axis, math.rad(40), math.rad(50)*speedmult)
		Turn(rbfoot, x_axis, math.rad(-60), math.rad(225)*speedmult)
		
		Sleep(400/speedmult)

		-- extend right
		Turn(lfleg, x_axis, math.rad(-40), math.rad(80)*speedmult)
		Turn(lffoot, x_axis, math.rad(60), math.rad(120)*speedmult)
		
		Turn(rfleg, x_axis, math.rad(-50), math.rad(25)*speedmult)
		Turn(rffoot, x_axis, math.rad(0), math.rad(150)*speedmult)
		
		Turn(rbleg, x_axis, math.rad(-40), math.rad(80)*speedmult)
		Turn(rbfoot, x_axis, math.rad(60), math.rad(120)*speedmult)
		
		Turn(lbleg, x_axis, math.rad(20), math.rad(100)*speedmult)
		Turn(lbfoot, x_axis, math.rad(30), math.rad(50)*speedmult)		
	
		Sleep(400/speedmult)
		
		Turn(rfleg, x_axis, math.rad(40), math.rad(150)*speedmult)
		Turn(rffoot, x_axis, math.rad(-60), math.rad(100)*speedmult)
		
		Sleep(200/speedmult)
		
		Turn(lbleg, x_axis, math.rad(40), math.rad(50)*speedmult)
		Turn(lbfoot, x_axis, math.rad(-60), math.rad(225)*speedmult)
		
		Sleep(400/speedmult)
	end
end

local function ResetLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	Turn(lfleg, x_axis, 0, math.rad(80))
	Turn(lffoot, x_axis, 0, math.rad(80))
	Turn(rfleg, x_axis, 0, math.rad(80))
	Turn(rffoot, x_axis, 0, math.rad(80))
	Turn(lbleg, x_axis, 0, math.rad(80))
	Turn(lbfoot, x_axis, 0, math.rad(80))
	Turn(rbleg, x_axis, 0, math.rad(80))
	Turn(rbfoot, x_axis, 0, math.rad(80))	
end

local longRange = false
local torpRange = WeaponDefNames["amphriot_torpedo"].range
local shotRange = WeaponDefNames["amphriot_flechette"].range

local function WeaponRangeUpdate()
	while true do
		local height = select(2, Spring.GetUnitPosition(unitID))
		if height < -35 then
			if not longRange then
				Spring.SetUnitWeaponState(unitID, 1, {range = torpRange})
				longRange = true
			end
		elseif longRange then
			Spring.SetUnitWeaponState(unitID, 1, {range = shotRange})
			longRange = false
		end
		Sleep(200)
	end
end

function script.Create()
	--StartThread(Walk)
	StartThread(GG.Script.SmokeUnit, smokePiece)
	StartThread(WeaponRangeUpdate)
	local height = select(2, Spring.GetUnitPosition(unitID))
	if height < -20 then
		if not longRange then
			Spring.SetUnitWeaponState(unitID, 1, {range = torpRange})
			longRange = true
		end
	elseif longRange then
		Spring.SetUnitWeaponState(unitID, 1, {range = shotRange})
		longRange = false
	end
end

function script.StartMoving()
	--Spring.Echo("Moving")
	StartThread(Walk)
end

function script.StopMoving()
	--Spring.Echo("Stopped moving")
	StartThread(ResetLegs)
end

local function RestoreAfterDelay()
	Sleep(3000)
	Turn(torso, y_axis, 0, math.rad(70))
	Turn(lturret1, x_axis, 0, math.rad(50))
	Turn(rturret1, x_axis, 0, math.rad(50))
	Turn(lturret2, x_axis, 0, math.rad(50))
	Turn(rturret2, x_axis, 0, math.rad(50))	
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		
		Turn(torso, y_axis, heading, math.rad(360))	
		Turn(mainturret, x_axis, -pitch, math.rad(180))
		WaitForTurn(torso, y_axis)
		WaitForTurn(mainturret, x_axis)
		
		return true
	elseif num == 2 then
	
		Signal(SIG_AIM2)	
		SetSignalMask(SIG_AIM2)
		
		if pitch < -math.rad(10) then 
			pitch = -math.rad(10)
		elseif pitch > math.rad(10) then 
			pitch = math.rad(10) 
		end
		
		Turn(torso, y_axis, heading, math.rad(360))
		Turn(lturret1, x_axis, -pitch, math.rad(180))
		Turn(rturret1, x_axis, -pitch, math.rad(180))
		Turn(lturret2, x_axis, -pitch, math.rad(180))
		Turn(rturret2, x_axis, -pitch, math.rad(180))
		WaitForTurn(lturret1, x_axis)
		WaitForTurn(torso, y_axis)
		StartThread(RestoreAfterDelay)	
		
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.FireWeapon(num)
	if num == 1 then
		EmitSfx(flaremain, 1024)
		EmitSfx(mainturret, 1025)
	elseif num == 2 then
		local px, py, pz = Spring.GetUnitPosition(unitID)
		if py < -8 then
			Spring.PlaySoundFile("sounds/weapon/torpedofast.wav", 8, px, py, pz)
		else
			Spring.PlaySoundFile("sounds/weapon/torp_land.wav", 8, px, py, pz)
		end
	end
end

function script.Shot(num)
	if num == 2 then
		gun_1 = gun_1 + 1
		if gun_1 > 4 then 
			gun_1 = 1 
		end
	end
end

function script.BlockShot(num, targetID)
	if num == 2 then -- torpedoes
		-- Lower than real damage (180) to help against Duck regen case.
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 172, 40)
	end
	return false
end

function script.AimFromWeapon(num)
	return flaremain
end

function script.QueryWeapon(num)
	if num == 2 then 
		return flares[gun_1] 
	else 
		return flaremain
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		return 1
	elseif (severity <= .50) then
		Explode(pelvis, SFX.NONE)
		return 1
	elseif (severity <= .99) then
		Explode(pelvis, SFX.SHATTER)
		Explode(torso, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(pelvis, SFX.SHATTER)
		Explode(torso, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
