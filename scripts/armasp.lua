include "constants.lua"

local base = piece 'base' 
local body = piece 'body' 
local land1 = piece 'land1' 
local land2 = piece 'land2' 
local land3 = piece 'land3' 
local land4 = piece 'land4' 
local radar = piece 'radar' 

local function SpinRadar()
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
		Sleep(400)
	end
	Spin( radar , y_axis, math.rad(90))
end

function script.Create()
	StartThread(SmokeUnit)
	StartThread(SpinRadar)
end

function script.QueryLandingPads()
	return {land1, land2, land3, land4}
end

function script.QueryNanoPiece()
	return radar
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(land1, sfxNone)
		Explode(land2, sfxNone)
		Explode(land3, sfxNone)
		Explode(land4, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(body, sfxShatter)
		Explode(land1, sfxNone)
		Explode(land2, sfxNone)
		Explode(land3, sfxNone)
		Explode(land4, sfxNone)
		Explode(radar, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 1
	elseif  severity <= .99  then
		Explode(base, sfxNone)
		Explode(body, sfxShatter)
		Explode(land1, sfxNone)
		Explode(land2, sfxNone)
		Explode(land3, sfxNone)
		Explode(land4, sfxNone)
		Explode(radar, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	else
		Explode(base, sfxNone)
		Explode(body, sfxShatter)
		Explode(land1, sfxNone)
		Explode(land2, sfxNone)
		Explode(land3, sfxNone)
		Explode(land4, sfxNone)
		Explode(radar, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	end
end
