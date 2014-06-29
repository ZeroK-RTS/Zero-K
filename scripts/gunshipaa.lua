include "constants.lua"

--pieces
local base, middle, heading,
	mbase, mfbeam, mrbeam, mhull, mwing, mwingtip, mjet, mrack, mmissile, mmissleflare,
	rbase, rfbeam, rrbeam, rhull, rwing, rwingtip, rjet, rrack, rmissile, rmissleflare,
	lbase, lfbeam, lrbeam, lhull, lwing, lwingtip, ljet, lrack, lmissile, lmissleflare = piece(
	"base", "middle", "heading",
	"mbase", "mfbeam", "mrbeam", "mhull", "mwing", "mwingtip", "mjet", "mrack", "mmissile", "mmissleflare", 
	"rbase", "rfbeam", "rrbeam", "rhull", "rwing", "rwingtip", "rjet", "rrack", "rmissile", "rmissleflare", 
	"lbase", "lfbeam", "lrbeam", "lhull", "lwing", "lwingtip", "ljet", "lrack", "lmissile", "lmissleflare")

local spGetUnitVelocity = Spring.GetUnitVelocity
	
local smokePiece = { base}

local root3on2 = math.sqrt(3)/2

local isActive = false

local shot = 0
local gun = {
	[0] = {query = mmissleflare, missile = rmissile, rack = rrack, loaded = true},
	[1] = {query = rmissleflare, missile = lmissile, rack = lrack, loaded = true},
	[2] = {query = lmissleflare, missile = mmissile, rack = mrack, loaded = true},
}

local function restoreWings()
	Turn(mhull, y_axis, math.rad(0),math.rad(15))
	Turn(lhull, y_axis, math.rad(0),math.rad(15))
	Turn(rhull, y_axis, math.rad(0),math.rad(15))
	
	Turn(mhull, x_axis, math.rad(0),math.rad(12))
	Turn(lhull, x_axis, math.rad(0),math.rad(12))
	Turn(rhull, x_axis, math.rad(0),math.rad(12))
	
	Turn(middle, x_axis, math.rad(0), math.rad(30))
	Turn(middle, y_axis, math.rad(0), math.rad(30))
end

local function TiltBody()
	
	while true do
		if isActive then
			local vx,_,vz = spGetUnitVelocity(unitID)
			local speed = vx*vx + vz*vz
			
			if speed > 5 then
				local myHeading = Spring.GetUnitHeading(unitID)*headingToRad
				local velHeading = Spring.GetHeadingFromVector(vx, vz)*headingToRad - myHeading
				-- south is 0, increases anticlockwise
				
				local px,_,pz = Spring.GetUnitPiecePosition(unitID, heading)
				
				local curHeading = -Spring.GetHeadingFromVector(-px, -pz)*headingToRad 
				
				local diffHeading = (velHeading - curHeading + pi)%tau - pi -- keep in range [-pi,pi)
				
				local newHeading 
				
				if diffHeading < -pi/3 then
					Turn(lhull, x_axis, math.rad(speed*0.8),math.rad(24))
					Turn(rhull, y_axis, -math.rad(speed),math.rad(30))
					Turn(mhull, y_axis, math.rad(speed),math.rad(30))
					newHeading = velHeading + 2*pi/3
					
					Turn(middle, x_axis, -math.rad(2*speed*0.5), math.rad(30*0.5))
					Turn(middle, y_axis, -math.rad(2*speed*root3on2), math.rad(30*root3on2))
					
					Turn(lhull, y_axis, math.rad(0),math.rad(30))
					Turn(mhull, x_axis, math.rad(0),math.rad(24))
					Turn(rhull, x_axis, math.rad(0),math.rad(24))
				elseif diffHeading < pi/3 then
					Turn(mhull, x_axis, math.rad(speed*0.8),math.rad(24))
					Turn(lhull, y_axis, -math.rad(speed),math.rad(30))
					Turn(rhull, y_axis, math.rad(speed),math.rad(30))
					newHeading = velHeading
					
					Turn(middle, x_axis, math.rad(2*speed), math.rad(30))
					Turn(middle, y_axis, math.rad(0), math.rad(30))
					
					Turn(mhull, y_axis, math.rad(0),math.rad(30))
					Turn(lhull, x_axis, math.rad(0),math.rad(24))
					Turn(rhull, x_axis, math.rad(0),math.rad(24))
				else
					Turn(rhull, x_axis, math.rad(speed*0.8),math.rad(24))
					Turn(mhull, y_axis, -math.rad(speed),math.rad(30))
					Turn(lhull, y_axis, math.rad(speed),math.rad(30))
					newHeading = velHeading - 2*pi/3
					
					Turn(middle, x_axis, -math.rad(2*speed*0.5), math.rad(30*0.5))
					Turn(middle, y_axis, math.rad(2*speed*root3on2), math.rad(30*root3on2))
					
					Turn(rhull, y_axis, math.rad(0),math.rad(30))
					Turn(mhull, x_axis, math.rad(0),math.rad(24))
					Turn(lhull, x_axis, math.rad(0),math.rad(24))
				end
				
				Turn(base, z_axis, newHeading, math.rad(100))
				Sleep(200)
			else
				restoreWings()
				Sleep(10)
			end
			Sleep(10)
		else
			Sleep(10)
		end
	end
end


local function activate()
	isActive = true
	Move(mhull, y_axis, -1, 2)
	Move(rhull, y_axis, -1, 2)
	Move(lhull, y_axis, -1, 2)
	
	Move(mhull, z_axis, -2, 1)
	Move(rhull, z_axis, -2, 1)
	Move(lhull, z_axis, -2, 1)
	
	--Move(mrack, y_axis, -2.5, 5)
	--Move(rrack, y_axis, -2.5, 5)
	--Move(lrack, y_axis, -2.5, 5)
end

local function deactivate()
	isActive = false
	Move(mhull, y_axis, -5, 2)
	Move(rhull, y_axis, -5, 2)
	Move(lhull, y_axis, -5, 2)
	
	Move(mhull, z_axis, 0, 1)
	Move(rhull, z_axis, 0, 1)
	Move(lhull, z_axis, 0, 1)
	
	--Move(mrack, y_axis, 5, 5)
	--Move(rrack, y_axis, 5, 5)
	--Move(lrack, y_axis, 5, 5)
end

function script.Activate()
	activate()
end

function script.StopMoving()
	deactivate()
end
 
 function script.Create()
	
	Move(mhull, y_axis, -5)
	Move(rhull, y_axis, -5)
	Move(lhull, y_axis, -5)
	
	Turn(rbase, z_axis, math.rad(120))
	Turn(lbase, z_axis, math.rad(-120))
	
	Turn(base, x_axis, math.rad(-90))
	Move(base, y_axis, 22)
	
	Move(mbase, z_axis, 2.9)
	Move(rbase, z_axis, 2.9)
	Move(lbase, z_axis, 2.9)
	
	Move(mhull, y_axis, -5)
	Move(rhull, y_axis, -5)
	Move(lhull, y_axis, -5)
	
	Move(mrack, y_axis, -4)
	Move(rrack, y_axis, -4)
	Move(lrack, y_axis, -4)
	
	Move(mrack, z_axis, -4)
	Move(rrack, z_axis, -4)
	Move(lrack, z_axis, -4)
	
	StartThread(SmokeUnit, smokePiece)
	StartThread(TiltBody)
end

function script.QueryWeapon(num) 
	return gun[shot].query
end

function script.AimFromWeapon(num) 
	return base 
end

function script.AimWeapon( num, heading, pitch )
	return true
end

local function reload(num)
	gun[num].loaded = false
	local adjustedDuration = 0
	while adjustedDuration < 5 do
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		local reloadMult = (stunnedOrInbuild and 0) or (Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1)
		adjustedDuration = adjustedDuration + reloadMult
		Sleep(1000)
	end
	Show(gun[num].missile)
	Move(gun[num].rack, y_axis, -4, 2)
	while adjustedDuration < 10 do
		local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		local reloadMult = (stunnedOrInbuild and 0) or (Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1)
		adjustedDuration = adjustedDuration + reloadMult
		Sleep(1000)
	end
	gun[num].loaded = true
end

function script.BlockShot(num)
	return not gun[shot].loaded
end

function script.Shot(num)
	Hide(gun[shot].missile)
	Move(gun[shot].rack, y_axis, 5, 2)
	StartThread(reload,shot)
	shot = (shot + 1)%3
end

function script.Killed(recentDamage, maxHealth)
	local severity = (recentDamage/maxHealth) * 100
	if severity <= 25 then
		Explode(middle, sfxExplode)
		Explode(mhull, sfxNone)
		Explode(rhull, sfxNone)
		Explode(lhull, sfxNone)
		return 1
	elseif severity <= 50 then
		Explode(middle, sfxExplode)
		Explode(mhull, sfxExplode)
		Explode(rhull, sfxExplode)
		Explode(lhull, sfxExplode)
		Explode(mwing, sfxExplode + sfxFall)
		Explode(rwing, sfxExplode + sfxFall)
		Explode(lwing, sfxExplode + sfxFall)
		return 1
	elseif severity <= 100 then
		Explode(middle, sfxExplode)
		Explode(mhull, sfxExplode + sfxFall)
		Explode(rhull, sfxExplode + sfxFall)
		Explode(lhull, sfxExplode + sfxFall)
		Explode(mwing, sfxExplode + sfxFall + sfxSmoke)
		Explode(rwing, sfxExplode + sfxFall + sfxSmoke)
		Explode(lwing, sfxExplode + sfxFall + sfxSmoke)
		return 1
	else
		Explode(middle, sfxExplode + sfxFall)
		Explode(mhull, sfxExplode + sfxFall + sfxShatter)
		Explode(rhull, sfxExplode + sfxFall + sfxShatter)
		Explode(lhull, sfxExplode + sfxFall + sfxShatter)
		Explode(mwing, sfxExplode + sfxFall + sfxSmoke + sfxFire)
		Explode(rwing, sfxExplode + sfxFall + sfxSmoke + sfxFire)
		Explode(lwing, sfxExplode + sfxFall + sfxSmoke + sfxFire)
		return 2
	end
end