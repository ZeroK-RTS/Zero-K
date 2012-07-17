include "constants.lua"

local base = piece 'base' 
local imma_chargin = piece 'imma_chargin' 
local mah_lazer = piece 'mah_lazer' 
local downbeam = piece 'downbeam' 
local shoop_da_woop = piece 'shoop_da_woop' 
local flashpoint = piece 'flashpoint' 

local on

smokePiece = {base}

-- Signal definitions
local SIG_AIM = 2
local TARGET_ALT = 143565270/2^16

function TargetingLaser()
	while on do
		EmitSfx( mah_lazer,  FIRE_W2 )
		EmitSfx( downbeam,  FIRE_W3 )
		EmitSfx( flashpoint,  FIRE_W3 )	--fakes the laser flare
		Sleep(30)
	end
end

function script.Activate()
	Move( shoop_da_woop , y_axis, TARGET_ALT , 30*4)
	on = true
	StartThread(TargetingLaser)
end

function script.Deactivate()
	Move( shoop_da_woop , y_axis, 0 , 250*4)
	on = false
	Signal( SIG_AIM)
end

function script.Create()
	Turn( mah_lazer , x_axis, math.rad(90) )
	Turn( downbeam , x_axis, math.rad(90) )
	Turn( shoop_da_woop , z_axis, math.rad(0.04) )
	Turn( flashpoint , x_axis, math.rad(90) )
	Hide( mah_lazer)
	Hide( downbeam)
	StartThread(SmokeUnit)
end

function script.AimWeapon(num, heading, pitch)
	if on then
		Signal( SIG_AIM)
		SetSignalMask( SIG_AIM)
		Turn( mah_lazer , y_axis, heading , math.rad(3.5) )
		Turn( mah_lazer , x_axis, -pitch, math.rad(1.2) )
		WaitForTurn(mah_lazer, y_axis)
		WaitForTurn(mah_lazer, x_axis)
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return mah_lazer
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
