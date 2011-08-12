local fuselage = piece 'fuselage' 
local wingl = piece 'wingl' 
local wingr = piece 'wingr' 
local enginel = piece 'enginel' 
local enginer = piece 'enginer' 
local finl = piece 'finl' 
local finr = piece 'finr' 
local predrop = piece 'predrop' 
local drop = piece 'drop' 
local thrustl = piece 'thrustl' 
local thrustr = piece 'thrustr' 
local wingtipl = piece 'wingtipl' 
local wingtipr = piece 'wingtipr' 

smokePiece = {fuselage, enginel, enginer}

include "bombers.lua"
include "constants.lua"

function script.StartMoving()
	Turn( finl , z_axis, math.rad(-(-30)), math.rad(50) )
	Turn( finr , z_axis, math.rad(-(30)), math.rad(50) )
end

function script.StopMoving()
	Turn( finl , z_axis, math.rad(-(0)), math.rad(80) )
	Turn( finr , z_axis, math.rad(-(0)), math.rad(80) )
end

local function Lights()
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
		Sleep(400)
	end
	while true do
		EmitSfx( wingtipr, 1024 )
		EmitSfx( wingtipl, 1025 )
		Sleep(2000)
	end
end

function script.Create()
	StartThread(SmokeUnit)
	StartThread(Lights)
end

function script.QueryWeapon(num)
	return drop
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitFuel(unitID) >= 1 and Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

function script.FireWeapon(num)
	if num == 2 then
		GG.Bomber_Dive_fired(unitID)
		Reload()
	elseif num == 3 then
		GG.Bomber_Dive_fake_fired(unitID)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(fuselage, sfxNone)
		Explode(enginel, sfxNone)
		Explode(enginer, sfxNone)
		Explode(wingl, sfxNone)
		Explode(wingr, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(fuselage, sfxNone)
		Explode(enginel, sfxNone)
		Explode(enginer, sfxNone)
		Explode(wingl, sfxNone)
		Explode(wingr, sfxNone)
		return 1
	elseif severity <= 99  then
		Explode(fuselage, sfxNone)
		Explode(enginel, sfxFall + sfxSmoke  + sfxFire )
		Explode(enginer, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingr, sfxFall + sfxSmoke  + sfxFire )
		return 2
	else
		Explode(fuselage, sfxNone)
		Explode(enginel, sfxFall + sfxSmoke  + sfxFire )
		Explode(enginer, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingr, sfxFall + sfxSmoke  + sfxFire )
		return 2
	end
end
