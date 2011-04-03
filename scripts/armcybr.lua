include "constants.lua"
include "bombers.lua"

local flare1 = piece 'flare1' 
local flare2 = piece 'flare2' 
local base = piece 'base' 
local wing1 = piece 'wing1' 
local wing2 = piece 'wing2' 
local rearthrust = piece 'rearthrust' 
local wingthrust1 = piece 'wingthrust1' 
local wingthrust2 = piece 'wingthrust2' 
local thrust1 = piece 'thrust1' 
local thrust2 = piece 'thrust2' 
local drop = piece 'drop' 
local emit1 = piece 'emit1' 
local emit2 = piece 'emit2' 
local emit3 = piece 'emit3' 
local emit4 = piece 'emit4' 

smokePiece = {base}

local gun_1 = false

function script.StartMoving()
	Move( wing1 , x_axis, 2.4, 1.65 )
	Move( wing1 , z_axis, -0.5, 0.35)
	Move( wing2 , x_axis, -2.4, 1.65 )
	Move( wing2 , z_axis, -0.5, 0.35)
	Turn( wing1 , z_axis, math.rad(-2.7), math.rad(1.85) )
	Turn( wing2 , z_axis, math.rad(-2.7), math.rad(1.85))
end

function script.StopMoving()
	Move( wing1 , x_axis, -0, 1.65)
	Move( wing1 , z_axis, 0, 0.35 )
	Move( wing2 , x_axis, 0, 1.65 )
	Move( wing2 , z_axis, 0, 0.35)
	Turn( wing1 , z_axis, 0, math.rad(0.62) )
	Turn( wing2 , z_axis, 0, math.rad(1.85) )
end

function script.MoveRate(rate)
	if rate == 1 then
		--Signal(SIG_BARREL)
		--SetSignalMask(SIG_BARREL)
		Turn( base , z_axis, math.rad(-240), math.rad(120) )
		WaitForTurn(base, z_axis)
		Turn( base , z_axis, math.rad(-(120)), math.rad(180) )
		WaitForTurn(base, z_axis)
		Turn( base , z_axis, 0, math.rad(120) )
	end
end

function script.Create()
	StartThread(SmokeUnit)
	Hide( rearthrust)
	Hide( wingthrust1)
	Hide( wingthrust2)
	Hide( flare1)
	Hide( flare2)
	Hide( drop)
end

function script.FireWeapon(num)
	gun_1 = not gun_1
	Reload()
end

function script.QueryWeapon(num)
	return (gun_1 and flare1) or flare2
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1) or false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		Explode(wing1, sfxNone)
		Explode(wing2, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(base, sfxNone)
		Explode(wing1, sfxShatter)
		Explode(wing2, sfxShatter)
		return 1
	elseif  severity <= .99  then
		Explode(base, sfxShatter)
		Explode(wing1, sfxShatter)
		Explode(wing2, sfxShatter)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(wing1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(wing2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
