local ground = piece 'ground' 
local base = piece 'base' 
local flare = piece 'flare' 
local muzzle = piece 'muzzle' 
local turret = piece 'turret' 
local barrel = piece 'barrel' 
local barrel_back = piece 'barrel_back' 
local sleeve = piece 'sleeve' 

include "constants.lua"
include "pieceControl.lua"

local spGetUnitIsStunned = Spring.GetUnitIsStunned

-- Signal definitions
local SIG_AIM = 2

smokePiece = {base, turret, ground}

local function DisableCheck()
	while true do
		if select(1, spGetUnitIsStunned(unitID)) then
			if StopTurn( sleeve , x_axis) then
				Signal( SIG_AIM)
			end
			if StopTurn( turret , y_axis) then
				Signal( SIG_AIM)
			end
		end
		Sleep(500)
	end
end

function script.Create()
	Hide( flare)
	Hide( muzzle)
	Hide( barrel_back)
	StartThread(SmokeUnit)
	StartThread(DisableCheck)
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, rad(5) )
	Turn( sleeve , x_axis, -pitch, rad(2.5))
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	return true
end

function script.FireWeapon(num)
	EmitSfx( ground,  UNIT_SFX1 )
	Move( barrel , z_axis, -20 , 500 )
	EmitSfx( barrel_back,  UNIT_SFX2 )
	EmitSfx( muzzle,  UNIT_SFX3 )
	WaitForMove(barrel, z_axis)
	Move( barrel , z_axis, 12 , 6 )
end

function script.QueryWeapon(num)
	return flare
end

function script.AimFromWeapon(num)
	return sleeve
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25  then
		return 1
	elseif severity <= 0.50  then
		Explode(sleeve,  sfxShatter)
		Explode(turret,  sfxShatter)
		return 1
	else
		Explode(base, sfxShatter + sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve, sfxShatter + sfxExplodeOnHit)
		Explode(turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		return 2
	end
end
