include "constants.lua"

local base = piece 'base' 
local turret = piece 'turret' 
local hull = piece 'hull' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2'
local missile = piece 'missile' 
local firepoint = piece 'firepoint' 
local doorl = piece 'doorl'
local doorr = piece 'doorr'

local smokePiece = {base}

-- Signal definitions
local SIG_MOVE = 1

local gun_1 = 0

function script.Create()
	restore_delay = 3000
	StartThread(SmokeUnit, smokePiece)
	Turn(turret, x_axis, math.rad(-90), math.rad(10000))
	Turn(doorl, z_axis, math.rad(-100), math.rad(240))
	Turn(doorr, z_axis, math.rad(100), math.rad(240))
	Move(turret, y_axis, 20, 16)
end

local function Motion()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		if(not Spring.GetUnitIsCloaked(unitID)) then
			EmitSfx(wake1, 2)
			EmitSfx(wake2, 2)
		end
		Sleep(150)
	end
end

local function shootyThingo()
	Sleep(33)
	Move(turret, y_axis, 0,40)
	Hide(missile)
	Sleep(1000)
	Move(turret, y_axis, 20, 40)
	Show(missile)
end


function script.Shot()
	StartThread(shootyThingo)
end

function script.StartMoving()
	StartThread(Motion)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.AimFromWeapon()
	return missile
end

function script.QueryWeapon()
	return firepoint
end

function script.BlockShot(num, targetID)	
	-- This causes poor behaviour if there is nothing nearby which needs disarming, so OKP for Skeeter is default set to 'off' in \LuaRules\Gadgets\unit_overkill_prevention.lua
	if GG.OverkillPrevention_CheckBlockDisarm(unitID, targetID, 180, 20, 120) then --less than 1 second - timeout, 3 seconds - disarmTimer
		return true
	end
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 45, 20) then
		return true
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		return 1
	elseif severity <= .50 then
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxExplode)
		Explode(wake2, sfxFall + sfxExplode)
		return 1
	elseif severity <= .99 then
		corpsetype = 3
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
