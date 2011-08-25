include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base = piece 'base' 
local turret = piece 'turret' 
local sleeve = piece 'sleeve' 
local barrel1 = piece 'barrel1' 
local flare1 = piece 'flare1' 
local barrel2 = piece 'barrel2' 
local flare2 = piece 'flare2' 
local barrel3 = piece 'barrel3' 
local flare3 = piece 'flare3' 

local gun_1 = 1

local gunPieces = {
	{ barrel = barrel1, flare = flare1 },
	{ barrel = barrel2, flare = flare2 },
	{ barrel = barrel3, flare = flare3 }
}

-- Signal definitions
local SIG_AIM = 2

local RECOIL_DISTANCE = -3
local RECOIL_RESTORE_SPEED = 1

smokePiece = {base, turret}

function script.Create()
	StartThread(SmokeUnit)
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(75))
	Turn( sleeve , x_axis, -pitch, math.rad(30))
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	return (spGetUnitRulesParam(unitID, "lowpower") == 0)	--checks for sufficient energy in grid
end

function script.Shot(num) 
	EmitSfx( gunPieces[gun_1].flare, 1024)
	Move( gunPieces[gun_1].barrel , z_axis, RECOIL_DISTANCE  )
	Move( gunPieces[gun_1].barrel , z_axis, 0 , RECOIL_RESTORE_SPEED )
	gun_1 = gun_1 + 1
	if gun_1 > 3 then gun_1 = 1 end
end

function script.QueryWeapon(num)
	return gunPieces[gun_1].flare
end

function script.AimFromWeapon(num)
	return sleeve
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(barrel1, sfxNone)
		Explode(barrel2, sfxNone)
		Explode(barrel3, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke )
		Explode(barrel1, sfxNone)
		Explode(barrel2, sfxNone)
		Explode(barrel3, sfxNone)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(barrel1, sfxFall + sfxSmoke)
		Explode(barrel2, sfxFall + sfxSmoke)
		Explode(barrel3, sfxFall + sfxSmoke)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(turret, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(barrel1, sfxFall + sfxSmoke  + sfxFire)
		Explode(barrel2, sfxFall + sfxSmoke  + sfxFire)
		Explode(barrel3, sfxFall + sfxSmoke  + sfxFire)
		return 2
	end
end
