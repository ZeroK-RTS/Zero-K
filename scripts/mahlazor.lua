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

local max = math.max

local smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2
local TARGET_ALT = 143565270/2^16

local spGetUnitIsStunned = Spring.GetUnitIsStunned


function TargetingLaser()
	while on do
		local _, flashY = Spring.GetUnitPiecePosition(unitID, flashpoint)
		local _, mah_lazerY = Spring.GetUnitPiecePosition(unitID, mah_lazer)
		newHeight = max(mah_lazerY-flashY, 1)
		if newHeight ~= oldHeight then
			Spring.SetUnitWeaponState(unitID, 5, "range", newHeight)
			Spring.SetUnitWeaponState(unitID, 3, "range", newHeight)
			oldHeight = newHeight
		end
		
		awake = (not spGetUnitIsStunned(unitID)) and (Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1);
		
		if awake then		
			if shooting ~= 0 then
				EmitSfx(mah_lazer, FIRE_W2)
				EmitSfx(flashpoint, FIRE_W3)
				shooting = shooting - 1
			else
				EmitSfx(mah_lazer, FIRE_W4)
				EmitSfx(flashpoint, FIRE_W5)
			end
		else
			--EmitSfx(flashpoint, FIRE_W6)
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

function script.AimWeapon(num, heading, pitch)
	if on and awake and num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		--local echoHeading = heading*180/math.pi - 90
		--if echoHeading < 0 then
		--	echoHeading = echoHeading + 360
		--end
		--Spring.Echo("heading " .. echoHeading)
		Turn(mah_lazer, y_axis, heading, math.rad(3.5))
		Turn(mah_lazer, x_axis, -pitch, math.rad(1.2))
		WaitForTurn(mah_lazer, y_axis)
		WaitForTurn(mah_lazer, x_axis)
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return mah_lazer
end

function script.FireWeapon(num)
	shooting = 30
end

function script.AimFromWeapon(num)
	return mah_lazer
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
