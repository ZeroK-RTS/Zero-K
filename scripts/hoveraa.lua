local base = piece 'base' 
local body = piece 'body' 
local turret = piece 'turret' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 
local wake3 = piece 'wake3' 
local wake4 = piece 'wake4' 
local wake5 = piece 'wake5' 
local wake6 = piece 'wake6' 
local wake7 = piece 'wake7' 
local wake8 = piece 'wake8' 
local ground1 = piece 'ground1' 
local missile = piece 'missile' 
local firepoint = piece 'firepoint' 

include "constants.lua"

local SIG_MOVE = 1
local SIG_AIM = 2

local function WobbleUnit()
	local wobble = true
	while true do
		if wobble == true then
			Move(base, y_axis, 1.2, 1.6)
		end
		if wobble == false then
		
			Move(base, y_axis, -1.2, 1.6)
		end
		wobble = not wobble
		Sleep(750)
	end
end


local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	local random = math.random
	while true do
		if random() < 0.5 then
			EmitSfx(wake1, 5)
			EmitSfx(wake3, 5)
			EmitSfx(wake5, 5)
			EmitSfx(wake7, 5)
			EmitSfx(wake1, 3)
			EmitSfx(wake3, 3)
			EmitSfx(wake5, 3)
			EmitSfx(wake7, 3)
		else
			EmitSfx(wake2, 5)
			EmitSfx(wake4, 5)
			EmitSfx(wake6, 5)
			EmitSfx(wake8, 5)
			EmitSfx(wake2, 3)
			EmitSfx(wake4, 3)
			EmitSfx(wake6, 3)
			EmitSfx(wake8, 3)
		end
		EmitSfx(ground1, UNIT_SFX1)
		Sleep(150)
	end
end

function script.Create()
	Turn(firepoint, x_axis, math.rad(-90))
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

function script.AimFromWeapon() 
	return turret
end

function script.AimWeapon()
	return true
end

function script.QueryWeapon()
	return firepoint
end

local function ReloadMissileThread()
	Hide(missile)
	Sleep(1000)
	Show(missile)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 374, 50)
end

function script.FireWeapon()
	StartThread(ReloadMissileThread)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if severity <= 0.25 then
	
		corpsetype = 1
		Explode(body, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		Explode(wake3, sfxNone)
		Explode(wake4, sfxNone)
		Explode(wake5, sfxNone)
		Explode(wake6, sfxNone)
		return 1
	end
	if severity <= 0.50 then
	
		corpsetype = 2
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall)
		Explode(wake2, sfxFall)
		Explode(wake3, sfxFall)
		Explode(wake4, sfxFall)
		Explode(wake5, sfxFall)
		Explode(wake6, sfxFall)
		return 1
	end
	if severity <= 0.99 then
	
		corpsetype = 3
		Explode(body, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(wake6, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
	Explode(body, sfxNone)
	Explode(turret, sfxShatter)
	Explode(wake1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(wake6, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
end
