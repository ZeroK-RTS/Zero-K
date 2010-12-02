local base = piece 'base' 
local arm = piece 'arm' 
local turret = piece 'turret' 
local gun = piece 'gun' 
local ledgun = piece 'ledgun' 
local radar = piece 'radar' 
local barrel = piece 'barrel' 
local fire = piece 'fire' 
local antenna = piece 'antenna' 
local door1 = piece 'door1' 
local door2 = piece 'door2' 

local smokePiece = {base, turret}

include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

-- Signal definitions
local SIG_AIM = 2
local SIG_OPEN = 1

local open = true


local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Spring.SetUnitArmored(unitID,false)
	Turn( door1 , z_axis, 0, math.rad(80) )
	Turn( door2 , z_axis, 0, math.rad(80) )
	WaitForTurn(door1, z_axis)
	Move( arm , y_axis, 0 , 12)
	Turn( antenna , x_axis, 0, math.rad(50) )
	Sleep(200)
	Move( barrel , z_axis, 0 , 7 )
	Move( ledgun , z_axis, 0 , 7 )
	WaitForMove(barrel, z_axis)
	WaitForMove(ledgun, z_axis)
	open = true
end

local function Close()
	open = false
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Turn( turret , y_axis, 0, math.rad(50) )
	Turn( gun , x_axis, 0, math.rad(40) )
	Move( barrel , z_axis, -20 , 7 )
	Move( ledgun , z_axis, -11 , 7 )
	Turn( antenna , x_axis, math.rad(90), math.rad(50) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	Move( arm , y_axis, -42.5 , 12 )
	WaitForMove(arm, y_axis)
	Turn( door1 , z_axis, math.rad(-(90)), math.rad(80) )
	Turn( door2 , z_axis, math.rad(-(-90)), math.rad(80) )
	WaitForTurn(door1, z_axis)
	WaitForTurn(door2, z_axis)
	Spring.SetUnitArmored(unitID,true)
end

function script.Create()
	StartThread(SmokeUnit)
end
function script.Activate()
	Spin( radar , y_axis, math.rad(100) )
	StartThread(Open)
end

function script.Deactivate()
	StopSpin(radar, y_axis)
	Signal(SIG_AIM)
	Turn(radar , y_axis, 0, math.rad(100) )
	StartThread(Close)
end

function script.AimWeapon(weaponNum, heading, pitch)
	if not open then return false end
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(50) )
	Turn( gun , x_axis, 0 - pitch, math.rad(40) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	return (spGetUnitRulesParam(unitID, "lowpower") == 0)	--checks for sufficient energy in grid
end

function script.AimFromWeapon(weaponNum)
	return barrel
end

function script.QueryWeapon(weaponNum)
	return fire
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(arm, sfxNone)
		Explode(turret, sfxNone)
		Explode(gun, sfxNone)
		Explode(ledgun, sfxNone)
		Explode(radar, sfxNone)
		Explode(barrel, sfxNone)
		Explode(fire, sfxNone)
		Explode(antenna, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(arm, sfxNone)
		Explode(turret, sfxNone)
		Explode(gun, sfxShatter)
		Explode(ledgun, sfxNone)
		Explode(radar, sfxNone)
		Explode(barrel, sfxFall)
		Explode(fire, sfxNone)
		Explode(antenna, sfxFall)
		Explode(door1, sfxFall)
		Explode(door2, sfxFall)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxNone)
		Explode(arm, sfxNone)
		Explode(turret, sfxNone)
		Explode(gun, sfxShatter)
		Explode(ledgun, sfxNone)
		Explode(radar, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fire, sfxNone)
		Explode(antenna, sfxFall)
		Explode(door1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(door2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 3
	else
		Explode(base, sfxNone)
		Explode(arm, sfxNone)
		Explode(turret, sfxNone)
		Explode(gun, sfxShatter)
		Explode(ledgun, sfxNone)
		Explode(radar, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fire, sfxNone)
		Explode(antenna, sfxFall)
		Explode(door1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(door2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 3
	end
end
