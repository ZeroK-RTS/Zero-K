local base, fan, cradle, flaot = piece('base', 'fan', 'cradle', 'flaot')
include "constants.lua"

local baseDirection

local smokePiece = {base}

local tau = math.pi*2
local pi = math.pi
local hpi = math.pi*0.5
local pi34 = math.pi*1.5

local UPDATE_PERIOD = 1000
local BUILD_PERIOD = 500

local turnSpeed = math.rad(20)

local isWind, baseWind, rangeWind

function BobTidal()
	baseDirection = baseDirection + math.random(0,math.rad(2))
	while true do
		Turn(cradle, y_axis, baseDirection, math.rad(1))
		
		Move(cradle, x_axis, math.random(-2,2), 0.2)
		Move(cradle, y_axis, math.random(-0.5,0.5) - 51, 0.05)
		Move(cradle, z_axis, math.random(-2,2), 0.2)
		Sleep(1000)
	end
end

function SpinWind() 
	while true do 
		if select(5, Spring.GetUnitHealth(unitID)) < 1 then
			Spin( fan , z_axis, 0)
			Sleep(BUILD_PERIOD)
		else
			local st = baseWind + (Spring.GetGameRulesParam("WindStrength") or 0)*rangeWind
			local direction = Spring.GetGameRulesParam("WindHeading")
			
			Spin( fan , z_axis, -st)
			Turn( cradle , y_axis, direction - baseDirection + pi, turnSpeed )
			Sleep(UPDATE_PERIOD)
		end
	end
end

function script.Create()
	StartThread(SmokeUnit)
    baseDirection = math.random(0,tau)
	Turn( base , y_axis, baseDirection )
	baseDirection = baseDirection + hpi * Spring.GetUnitBuildFacing(unitID)
	
	isWind, baseWind, rangeWind = GG.SetupWindmill(unitID)
	if isWind then
		StartThread(SpinWind)
	else
		StartThread(BobTidal)
		Hide( base)
		Hide( flaot)
		Move( cradle, y_axis, -51)
		Turn( fan, x_axis, math.rad(90))
		Move( fan, z_axis, 9)
		Move( fan, y_axis, -5)
		--[[ diagonal down, needs teamcolour
		Move( cradle, y_axis, -41)
		Move( cradle, z_axis, -10)
		Turn( cradle, z_axis, math.pi)
		Turn( cradle, x_axis, math.rad(-15))
		Turn( fan, x_axis, math.rad(50))
		Move( fan, x_axis, 0)
		Move( fan, z_axis, 14)
		Move( fan, y_axis, 18)
		--]]
		Spin( fan , z_axis, math.rad(30))
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if isWind then
		if  severity <= 0.25  then
			Explode(base, sfxFire)
			Explode(fan, sfxSmoke)
			Explode(cradle, sfxFire)
			return 1
		elseif severity <= 0.5  then
			Explode(base, sfxSmoke)
			Explode(fan, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
			Explode(cradle, sfxSmoke)
			return 1
		else
			Explode(base, sfxShatter)
			Explode(fan, sfxShatter)
			Explode(cradle, sfxShatter)
			return 2
		end
	else
		if  severity <= 0.25  then
			Explode(fan, sfxSmoke)
			Explode(cradle, sfxFire)
			return 1
		elseif severity <= 0.5  then
			Explode(fan, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
			Explode(cradle, sfxSmoke)
			return 1
		else
			Explode(fan, sfxShatter)
			Explode(cradle, sfxShatter)
			return 2
		end
	end
end
