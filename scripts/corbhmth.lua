include "constants.lua"

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local base = piece 'base' 
local fanbox = piece 'fanbox' 
local vent1 = piece 'vent1' 
local vent2 = piece 'vent2' 
local fan = piece 'fan' 
local turret = piece 'turret' 
local sleeve = piece 'sleeve' 
local barrel1 = piece 'barrel1' 
local flare1 = piece 'flare1' 
local barrel2 = piece 'barrel2' 
local flare2 = piece 'flare2' 
local barrel3 = piece 'barrel3' 
local flare3 = piece 'flare3' 

local gun_1 = 1

-- Signal definitions
local SIG_AIM = 2

local RECOIL_DISTANCE = -3
local RECOIL_RESTORE_SPEED = 1

smokePiece = {base, turret}

function script.Create()
	Hide( flare1)
	Hide( flare2)
	Hide( flare3)
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
	gun_1 = gun_1 + 1
	if gun_1 > 3 then gun_1 = 1 end
	if gun_1 == 1 then 
		Move( barrel1 , z_axis, RECOIL_DISTANCE  )
		Move( barrel1 , z_axis, 0 , RECOIL_RESTORE_SPEED )
	elseif gun_1 == 2 then 
		Move( barrel2 , z_axis, RECOIL_DISTANCE  )
		Move( barrel2 , z_axis, 0 , RECOIL_RESTORE_SPEED )
	else 
		Move( barrel3 , z_axis, RECOIL_DISTANCE  )
		Move( barrel3 , z_axis, 0 , RECOIL_RESTORE_SPEED )
	end
end

function script.QueryWeapon(num)
	if gun_1 == 1 then return flare1
	elseif gun_1 == 2 then return flare2
	else return flare3 end
end

function script.AimFromWeapon(num)
	return sleeve
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, SFX.SHATTER)
		Explode(fanbox, SFX.BITMAPONLY)
		Explode(vent1, SFX.BITMAPONLY)
		Explode(vent2, SFX.BITMAPONLY)
		Explode(fan, SFX.FALL)
		Explode(turret, SFX.BITMAPONLY)
		Explode(barrel1, SFX.BITMAPONLY)
		Explode(barrel2, SFX.BITMAPONLY)
		Explode(barrel3, SFX.BITMAPONLY)
		return 1
	elseif  severity <= .50  then
		Explode(base, SFX.SHATTER)
		Explode(fanbox, SFX.BITMAPONLY)
		Explode(vent1, SFX.BITMAPONLY)
		Explode(vent2, SFX.BITMAPONLY)
		Explode(fan, SFX.FALL)
		Explode(turret, SFX.FALL + SFX.SMOKE )
		Explode(barrel1, SFX.BITMAPONLY)
		Explode(barrel2, SFX.BITMAPONLY)
		Explode(barrel3, SFX.BITMAPONLY)
		return 1
	elseif severity <= .99  then
		Explode(base, SFX.SHATTER)
		Explode(fanbox, SFX.BITMAPONLY)
		Explode(vent1, SFX.BITMAPONLY)
		Explode(vent2, SFX.BITMAPONLY)
		Explode(fan, SFX.FALL)
		Explode(turret, SFX.FALL + SFX.SMOKE  + SFX.FIRE  + SFX.EXPLODE_ON_HIT )
		Explode(barrel1, SFX.BITMAPONLY)
		Explode(barrel2, SFX.BITMAPONLY)
		Explode(barrel3, SFX.BITMAPONLY)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(fanbox, SFX.BITMAPONLY)
		Explode(vent1, SFX.BITMAPONLY)
		Explode(vent2, SFX.BITMAPONLY)
		Explode(fan, SFX.FALL)
		Explode(turret, SFX.FALL + SFX.SMOKE  + SFX.FIRE  + SFX.EXPLODE_ON_HIT )
		Explode(barrel1, SFX.BITMAPONLY)
		Explode(barrel2, SFX.BITMAPONLY)
		Explode(barrel3, SFX.BITMAPONLY)
		return 2
	end
end
