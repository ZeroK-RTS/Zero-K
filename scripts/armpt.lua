include "constants.lua"

local base = piece 'base' 
local turret = piece 'turret' 
local firepoint1, firepoint2 = piece('firepoint1', 'firepoint2')
local hull = piece 'hull' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2'

local flares = {[0] = firepoint1, [1] = firepoint2}

smokePiece = {base}

-- Signal definitions
local SIG_MOVE = 1
local SIG_AIM = 2
local SIG_AIM_2 = 4
local SIG_AIM_3 = 8

local gun_1 = 0

function script.Create()
	restore_delay = 3000
	StartThread(SmokeUnit)
end

local function RestoreAfterDelay()
	Sleep(restore_delay)
	Turn( turret , x_axis, 0, math.rad(60) )
end

local function Motion()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	while  true  do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep(150)
	end
end

function script.StartMoving()
	StartThread(Motion)
end

function script.StopMoving()
	Signal( SIG_MOVE)
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then return end
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , x_axis, math.rad(-20), math.rad(150) )
	WaitForTurn(turret, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return flares[gun_1]
end

function script.Shot(num)
	--[[
	--Spring.Echo(num)
	local num2 = 3
	if num == 3 then num2 = 2 end
	--num2 = num2 - 1
	--local frame = select(3, Spring.GetUnitWeaponState(unitID, num))
	local frame = Spring.GetUnitWeaponState(unitID, num, "reloadTime")
	if frame then
		frame = math.floor(30*frame) + Spring.GetGameFrame()
		--Spring.Echo("Setting reload frame to "..frame)
		Spring.SetUnitWeaponState(unitID, num2, "reloadFrame", frame)
	end
	]]--
	EmitSfx(flares[gun_1], 1024)
	gun_1 = 1 - gun_1
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxExplode )
		Explode(wake2, sfxFall + sfxExplode )
		return 1
	elseif  severity <= .99  then
		corpsetype = 3
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(wake2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return (0)
	else
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(wake2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
	end
end
