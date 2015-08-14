include "constants.lua"

local base = piece 'base' 
local imma_chargin = piece 'imma_chargin' 
local mah_lazer = piece 'mah_lazer' 
local downbeam = piece 'downbeam' 
local shoop_da_woop = piece 'shoop_da_woop' 
local flashpoint = piece 'flashpoint' 
local beam1 = piece 'beam1' 

local on = false
local awake = false;
local oldHeight = 0
local shooting = 0

local lazerDefID = WeaponDefNames["mahlazer_lazer"].id

local Vector = Spring.Utilities.Vector 

local max = math.max

local smokePiece = {base}

local wantedDirection = 0
local ROTATION_SPEED = math.rad(3.5)/30

-- Signal definitions
local SIG_AIM = 2
local TARGET_ALT = 143565270/2^16

local soundTime = 0

local spGetUnitIsStunned = Spring.GetUnitIsStunned

function TargetingLaser()
	while on do
		awake = (not spGetUnitIsStunned(unitID)) and (Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1);
		
		if awake then
			--// Aiming
			local dx, _, dz = Spring.GetUnitDirection(unitID)
			local currentHeading = Vector.Angle(dx, dz)
			
			local aimOff = (currentHeading - wantedDirection + math.pi)%(2*math.pi) - math.pi
			
			if aimOff < 0 then
				aimOff = math.max(-ROTATION_SPEED, aimOff)
			else
				aimOff = math.min(ROTATION_SPEED, aimOff)
			end
			
			Spring.SetUnitRotation(unitID, 0, currentHeading - aimOff - math.pi/2, 0)
			
			--// Relay range
			local _, flashY = Spring.GetUnitPiecePosition(unitID, flashpoint)
			local _, mah_lazerY = Spring.GetUnitPiecePosition(unitID, mah_lazer)
			newHeight = max(mah_lazerY-flashY, 1)
			if newHeight ~= oldHeight then
				Spring.SetUnitWeaponState(unitID, 3, "range", newHeight)
				Spring.SetUnitWeaponState(unitID, 5, "range", newHeight)
				oldHeight = newHeight
			end
			
			--// Sound effects
			if soundTime < 0 then
				local px, py, pz = Spring.GetUnitPosition(unitID)
				Spring.PlaySoundFile("sounds/weapon/laser/laser_burn6.wav", 10, px, (py + flashY)/2, pz)
				soundTime = 46
			else
				soundTime = soundTime - 1
			end
			
			--// Shooting
			if shooting ~= 0 then
				EmitSfx(mah_lazer, FIRE_W2)
				EmitSfx(flashpoint, FIRE_W3)
				shooting = shooting - 1
			else
				EmitSfx(mah_lazer, FIRE_W4)
				EmitSfx(flashpoint, FIRE_W5)
			end
		end
		
		Sleep(30)
	end
end

function script.Activate()
	Move(shoop_da_woop, y_axis, TARGET_ALT, 30*4)
	on = true
	StartThread(TargetingLaser)
end

function script.Deactivate()
	Move(shoop_da_woop, y_axis, 0, 250*4)
	on = false
	Signal(SIG_AIM)
end

function script.Create()
	--Move(beam1, z_axis, 28)
	--Move(beam1, y_axis, -2)

	Turn(mah_lazer, x_axis, math.rad(90))
	Turn(downbeam, x_axis, math.rad(90))
	--Turn(shoop_da_woop, z_axis, math.rad(0.04))
	Turn(flashpoint, x_axis, math.rad(-90))
	--Turn(flashpoint, x_axis, math.rad(0))
	Hide(mah_lazer)
	Hide(downbeam)
	StartThread(SmokeUnit, smokePiece)
end

-- Unused but good for testing. Perhaps needed if the unit breaks.
local function DoAimFromBetterHeading()
	local cQueue = Spring.GetCommandQueue(unitID, 1)
	if not (cQueue and cQueue[1] and cQueue[1].id == CMD.ATTACK) then
		return false
	end
	
	local px, py, pz, dx, dy, dz = Spring.GetUnitPiecePosDir(unitID, shoop_da_woop)

	local ax, ay, az 
	if cQueue[1].params[3] then
		ax, ay, az = cQueue[1].params[1], Spring.GetGroundHeight(cQueue[1].params[1], cQueue[1].params[3]), cQueue[1].params[3]
	elseif #cQueue[1].params == 1 then
		_,_,_, ax, ay, az = Spring.GetUnitPosition(cQueue[1].params[1], true)
	end
	
	if not ay then
		return false
	end
	
	local horVec = {ax - px, az - pz}
	local vertVec = {Vector.AbsVal(horVec), ay - py}
	
	local myHeading = Vector.Angle(horVec) - math.pi/2
	local myPitch   = Vector.Angle(vertVec)
	
	local fudge = -0.0091
	local pitchFudge = 0
	
	myHeading = myHeading + fudge
	myPitch   = myPitch   + pitchFudge
	
	Spring.Echo("My        heading pitch",  myHeading*180/math.pi, myPitch*180/math.pi)
	return myHeading, myPitch
end

function script.AimWeapon(num, heading, pitch)
	if on and awake and num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		
		local dx, _, dz = Spring.GetUnitDirection(unitID)
		local currentHeading = Vector.Angle(dx, dz)
		
		wantedDirection = currentHeading - heading
		
		--Spring.Echo("Spring heading pitch",  heading*180/math.pi, pitch*180/math.pi)
		
		--local newHeading, newPitch = DoAimFromBetterHeading()
		--if newHeading then
		--	heading = newHeading
		--	pitch = newPitch
		--end
		
		Turn(mah_lazer, y_axis, 0)
		Turn(mah_lazer, x_axis, -pitch, math.rad(1.2))
		WaitForTurn(mah_lazer, x_axis)
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return shoop_da_woop
end

function script.FireWeapon(num)
	shooting = 30
end

function script.AimFromWeapon(num)
	return shoop_da_woop
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= .25) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(base, SFX.NONE)
		return 1 -- corpsetype
	else
		Explode(base, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
