local base = piece 'base'
local fuselage = piece 'fuselage' 
local wingl1 = piece 'wingl1' 
local wingr1 = piece 'wingr1' 
local wingl2 = piece 'wingl2' 
local wingr2 = piece 'wingr2' 
local engines = piece 'engines' 
local fins = piece 'fins' 
local rflap = piece 'rflap' 
local lflap = piece 'lflap' 
local predrop = piece 'predrop' 
local drop = piece 'drop' 
local thrustl = piece 'thrustl' 
local thrustr = piece 'thrustr' 
local wingtipl = piece 'wingtipl' 
local wingtipr = piece 'wingtipr' 
local xp,zp = piece("x","z")

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitHeading = Spring.GetUnitHeading
local spGetUnitVelocity = Spring.GetUnitVelocity

smokePiece = {fuselage, thrustr, thrustl}

local bombs = 1

include "bombers.lua"
include "fakeUpright.lua"
include "constants.lua"

function script.StartMoving()
	--Turn( fins , z_axis, math.rad(-(-30)), math.rad(50) )
	Move( wingr1 , x_axis, 0, 50)
	Move( wingr2 , x_axis, 0, 50)
	Move( wingl1 , x_axis, 0, 50)
	Move( wingl2 , x_axis, 0, 50)
end

function script.StopMoving()
	--Turn( fins , z_axis, math.rad(-(0)), math.rad(80) )
	Move( wingr1 , x_axis, 5, 30)
	Move( wingr2 , x_axis, 5, 30)
	Move( wingl1 , x_axis, -5, 30)
	Move( wingl2 , x_axis, -5, 30)
	
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
	FakeUprightInit(xp, zp, drop) 
	--StartThread(Lights)
end

function script.QueryWeapon(num)
	return drop
end

function script.AimFromWeapon(num)
	return drop
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitFuel(unitID) >= 1 and Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

local predictMult = 3

function script.BlockShot(num, targetID)
	if num ~= 2 then
		return false
	end
	local ableToFire = not ((GetUnitValue(COB.CRASHING) == 1) or (Spring.GetUnitFuel(unitID) < 1) or (Spring.GetUnitRulesParam(unitID, "noammo") == 1))
	if not (targetID and ableToFire) then
		return not ableToFire
	end
	local x,y,z = spGetUnitPosition(unitID)
	local _,_,_,_,_,_,tx,ty,tz = spGetUnitPosition(targetID, true, true)
	local vx,vy,vz = spGetUnitVelocity(targetID)
	local heading = spGetUnitHeading(unitID)*headingToRad
	vx, vy, vz = vx*predictMult, vy*predictMult, vz*predictMult
	local dx, dy, dz = tx + vx - x, ty + vy - y, tz + vz - z
	local cosHeading = cos(heading)
	local sinHeading = sin(heading)
	dx, dz = cosHeading*dx - sinHeading*dz, cosHeading*dz + sinHeading*dx
	
	--Spring.Echo(vx .. ", " .. vy .. ", " .. vz)
	--Spring.Echo(dx .. ", " .. dy .. ", " .. dz)
	--Spring.Echo(heading)
	
	if dz < 30 and dz > -30 and dx < 100 and dx > -100 and dy < 0 then
		FakeUprightTurn(unitID, xp, zp, base, predrop) 
		Move(drop, x_axis, dx)
		Move(drop, z_axis, dz)
		dy = math.max(dy, -30)
		Move(drop, y_axis, dy)
		return false
	end
	return true
end

function script.FireWeapon(num)
	if num == 2 then
		GG.Bomber_Dive_fired(unitID)
		Sleep(33)	-- delay before clearing attack order; else bomb loses target and fails to home
		Move(drop, x_axis, 0)
		Move(drop, z_axis, 0)
		Move(drop, y_axis, 0)
		Reload()
	elseif num == 3 then
		GG.Bomber_Dive_fake_fired(unitID)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxNone)
		Explode(wingl1, sfxNone)
		Explode(wingr2, sfxNone)
		return 1
	elseif severity <= .50  then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxNone)
		Explode(wingl2, sfxNone)
		Explode(wingr1, sfxNone)
		return 1
	elseif severity <= 99  then
		Explode(fuselage, sfxNone)
		Explode(engines, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl1, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingr2, sfxFall + sfxSmoke  + sfxFire )
		return 2
	else
		Explode(fuselage, sfxNone)
		Explode(engines, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl1, sfxFall + sfxSmoke  + sfxFire )
		Explode(wingl2, sfxFall + sfxSmoke  + sfxFire )
		return 2
	end
end