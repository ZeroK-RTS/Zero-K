--------------------------------------------------------------------------------
-- refer to LuaRules\Gadgets\unit_missilesilo.lua for documentation
--------------------------------------------------------------------------------

include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base' 
local body = piece 'body' 
local scaffold = piece 'scaffold' 
local trolleyb = piece 'trolleyb' 
local trolleyu = piece 'trolleyu' 
local clampb1 = piece 'clampb1' 
local clampb2 = piece 'clampb2' 
local clampu1 = piece 'clampu1' 
local clampu2 = piece 'clampu2' 
local silo1 = piece 'silo1' 
local silo2 = piece 'silo2' 
local silo3 = piece 'silo3' 
local silo4 = piece 'silo4' 

local smokePiece = {body, silo1, silo3, scaffold}

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
local padnum = 1

local missiles = {}

--------------------------------------------------------------------------------
-- signals
--------------------------------------------------------------------------------
local SIG_AIM = 2


--------------------------------------------------------------------------------
-- main code
--------------------------------------------------------------------------------
function BuildNewMissile()
	for i=1,4 do
		if missiles[i] == nil then
			padnum = i
			--Spring.Echo("Missile build order confirmed: using pad "..i)
			return true
		end
	end
	return false
end

function AddMissile(missileID)
	missiles[padnum] = missileID
end

function RemoveMissile(deadID)
	for i=1,4 do
		if deadID == missiles[i] then
			missiles[i] = nil
			--Spring.Echo("Clearing pad "..i)
			break
		end		--if this was a missile, clear it from our silo data
	end
end

function script.Create()
	StartThread(SmokeUnit,smokePiece)
	--set INBUILDSTANCE to 1
end

function script.StartBuilding()
	Turn(scaffold , y_axis, math.rad((-padnum*90) + 45), math.rad(90) )
end

function script.StopBuilding()
end

function script.QueryNanoPiece() return trolleyb end

function script.QueryBuildInfo()
	if padnum == 1 then return silo1
	elseif padnum == 2 then return silo2
	elseif  padnum == 3 then return silo3
	else return silo4 end
end

function KillAllMissiles()
	for i=1,4 do
		if missiles[i] then Spring.DestroyUnit(missiles[i], true) end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(body, sfxNone)
		Explode(scaffold, sfxNone)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxNone)
		Explode(trolleyb, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(body, sfxNone)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 1
	elseif severity <= .99  then
		Explode(body, sfxShatter)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 3
	else
		Explode(body, sfxShatter)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 3
	end
end
