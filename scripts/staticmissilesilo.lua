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
local pads = {silo1, silo2, silo3, silo4}

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
function SetPadNum(num)
	if num ~= nil then
		padnum = num
	end
end

function GetPadNum(num)
	return padnum
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.StartBuilding()
	Turn(scaffold, y_axis, math.rad((-padnum*90) + 45), math.rad(90))
end

function script.StopBuilding()
end

function script.Activate()
	SetUnitValue(COB.INBUILDSTANCE, 1)
end

function script.Deactivate()
	SetUnitValue(COB.INBUILDSTANCE, 0)
end

function script.QueryNanoPiece()
	return trolleyb
end

function script.QueryBuildInfo()
	return pads[padnum]
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(body, sfxNone)
		Explode(scaffold, sfxNone)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxNone)
		Explode(trolleyb, sfxNone)
		return 1
	elseif severity <= .50 then
		Explode(body, sfxNone)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 1
	elseif severity <= .99 then
		Explode(body, sfxShatter)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	else
		Explode(body, sfxShatter)
		Explode(scaffold, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampb2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu1, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(clampu2, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyu, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		Explode(trolleyb, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end
