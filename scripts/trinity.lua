include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base, radarbase, radarneck, radarhead, dish, missile, aimpoint, light = piece('base', 'radarbase', 'radarneck', 'radarhead', 'dish', 'missile', 'aimpoint', 'light') 
local door = {}
for i=1,4 do door[i] = piece('door'..i) end

local smokePiece = {base, base, radarhead}

--------------------------------------------------------------------------------
-- signals
--------------------------------------------------------------------------------
local SIG_AIM = 2
local SIG_OPEN = 1

-------------------------------------------------------------------------------
-- main code
--------------------------------------------------------------------------------
local open = false

local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Move(door[1], x_axis, -6, 4)
	Move(door[1], z_axis, -6, 4)
	Move(door[2], x_axis, 6, 4)
	Move(door[2], z_axis, -6, 4)
	Move(door[3], x_axis, -6, 4)
	Move(door[3], z_axis, 6, 4)
	Move(door[4], x_axis, 6, 4)
	Move(door[4], z_axis, 6, 4)	
	WaitForMove(door[1], x_axis)
	
	Move(missile, y_axis, 14, 8)
	WaitForMove(missile, y_axis)
	open = true
end

local function Close()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Move(missile, y_axis, 0)
	
	for i=1,4 do
		Move(door[i], x_axis, 0, 4)
		Move(door[i], z_axis, 0, 4)
	end
	WaitForMove(door[1], x_axis)
	open = false
end

local function BlinkingLight()
	while true do
		EmitSfx(light, 1024)
		Sleep(1500)
	end
end

local function IdleAnim()
	while GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0 do Sleep(200) end
	StartThread(BlinkingLight)
	while true do
		Turn(dish, x_axis, math.rad(math.random(-65, -30)), math.rad(30) )
		Turn(radarhead, y_axis, math.rad(math.random(0, 359)), math.rad(45) )
		Sleep(math.random(8000, 16000))
	end
end

function script.Create()
	Turn(dish, x_axis, math.rad(-45))
	StartThread(SmokeUnit)
	StartThread(IdleAnim)
end

local function RestoreAfterDelay()
	Sleep(6000)
	if open then Close() end
end

function script.AimFromWeapon(weaponNum)	return aimpoint end
function script.QueryWeapon(weaponNum) return missile end

function script.AimWeapon(weaponNum, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	if not open then Open() end
	Sleep(100)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(weaponNum)
	Hide(missile)
	Sleep(2500)
	if open then Close() end
	Show(missile)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		Explode(door[1], sfxNone)
		Explode(door[3], sfxNone)
		Explode(radarbase, sfxNone)
		Explode(radarneck, sfxNone)
		Explode(radarhead, sfxSmoke)
		Explode(dish, sfxSmoke)
		return 1
	elseif severity <= .50  then
		Explode(base, sfxNone)
		Explode(door[1], sfxNShatter)
		Explode(door[3], sfxShatter)
		Explode(radarbase, sfxNone)
		Explode(radarneck, sfxNone)
		Explode(radarhead, sfxSmoke)
		Explode(dish, sfxSmoke)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxShatter)
		for i=1,4 do
			Explode(door[i], sfxShatter)
		end
		Explode(radarbase, sfxSmoke + sfxFire)
		Explode(radarneck, sfxSmoke + sfxFire)
		Explode(radarhead, sfxSmoke + sfxFire + sfxExplode)
		Explode(dish, sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(base, sfxShatter)
		for i=1,4 do
			Explode(door[i], sfxShatter)
		end
		Explode(radarbase, sfxShatter)
		Explode(radarneck, sfxSmoke + sfxFire)
		Explode(radarhead, sfxSmoke + sfxFire + sfxExplode)
		Explode(dish, sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
