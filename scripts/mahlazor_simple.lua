include "constants.lua"

local base = piece 'base' 
local imma_chargin = piece 'imma_chargin' 
local mah_lazer = piece 'mah_lazer' 
local downbeam = piece 'downbeam' 
local shoop_da_woop = piece 'shoop_da_woop' 
local flashpoint = piece 'flashpoint' 
local beam1 = piece 'beam1' 

local oldHeight = 0

local max = math.max

-- Signal definitions
local TARGET_ALT = 143565270/2^16

local moveTimer = 0

function TargetingLaser()
	while true do
		EmitSfx( mah_lazer,  FIRE_W4 )
		EmitSfx( flashpoint,  FIRE_W4 )
		Sleep(30)
		
		if moveTimer == 1000 then
			Move( flashpoint , y_axis, 0)
		elseif moveTimer == 2000 then
			Move( flashpoint , y_axis, TARGET_ALT*0.3)
			moveTimer = 0
		end
		moveTimer = moveTimer + 1
	end
end

function script.Create()
	StartThread(TargetingLaser)
	Spin( mah_lazer , x_axis, math.rad(20) )
	Spin( flashpoint , x_axis, math.rad(20) )
	Move( flashpoint , y_axis, TARGET_ALT*0.3)
	Move( shoop_da_woop , y_axis, TARGET_ALT)
	Hide( mah_lazer)
	Hide( downbeam)
end

function script.AimWeapon(num, heading, pitch)
	return false
end

function script.QueryWeapon(num)
	return mah_lazer
end

function script.FireWeapon(num)
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
