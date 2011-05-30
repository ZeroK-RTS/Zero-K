include 'constants.lua'
-- by MergeNine

-- shortcuts
local GetUnitPosition = Spring.GetUnitPosition
local SpawnCEG = Spring.SpawnCEG
local GetGroundHeight = Spring.GetGroundHeight

--pieces
local Base = piece "Base"
local RearTurretSeat = piece "RearTurretSeat"
local RearTurret = piece "RearTurret"
local RearGun = piece "RearGun"
local RearFlashPoint = piece "RearFlashPoint"

local LeftTurretSeat = piece "LeftTurretSeat"
local LeftTurret = piece "LeftTurret"
local LeftGun = piece "LeftGun"
local LeftFlashPoint = piece "LeftFlashPoint"

local RightTurretSeat = piece "RightTurretSeat"
local RightTurret = piece "RightTurret"
local RightGun = piece "RightGun"
local RightFlashPoint = piece "RightFlashPoint"

local subpoint = piece "subpoint"
local jetleft, jetright, jetrear = piece('jetleft', 'jetright', 'jetrear')

local gunpoints = {
	[1] = {aim = RightTurret, pitch = RightGun, fire = RightFlashPoint},
	[2] = {aim = LeftTurret, pitch = LeftGun, fire = LeftFlashPoint},
	[3] = {aim = subpoint, pitch = subpoint, fire = subpoint},
	[4] = {aim = RearTurret, pitch = RearGun, fire = RearFlashPoint},
	[5] = {aim = Base, pitch = Base, fire = Base},
}

--signals
local signals = {
	[1] = 2,
	[2] = 4,
	[4] = 8,
	tilt = 1,
	particle = {	-- unused
		[1] = 16,
		[2] = 32,
		[4] = 64,
	}
}

local restoreDelay = 3000
local attacking = 0

local blockAim = {false, false, false}

local minPitch = {
	math.rad(35), math.rad(35), 0,  math.rad(20)}
local headingMod = {math.rad(45), math.rad(-45), 0,  math.rad(180) }
local pitchMod = {math.rad(-25), math.rad(-25), 0, math.rad(-15) }

local turretSpeed = 5

local tiltAngle = math.rad(30)
local isLanded = true


function script.Activate()
  isLanded = false
end

function script.Deactivate()
  isLanded = true
end

function EmitDust()
  while true do
    if not isLanded then
      local x, _, z = GetUnitPosition(unitID)
      local y = GetGroundHeight(x, z) + 30
      SpawnCEG("krowdust", x, y, z, 0, 0, 0, 1, 1)
    end
    Sleep(33)
  end
end


function script.Create()
	--set starting positions for turrets
	Turn(RightTurretSeat,y_axis,math.rad(-45),100)
	Turn(RightTurretSeat,x_axis,math.rad(17))	--15
	Turn(RightTurretSeat,z_axis,math.rad(2)) -- -4
	
	Turn(LeftTurretSeat,y_axis,math.rad(45),100)
	Turn(LeftTurretSeat,x_axis,math.rad(17)) --15
	Turn(LeftTurretSeat,z_axis,math.rad(-2))-- 4
	
	Turn(RearTurretSeat,y_axis,math.rad(180),100)
	Turn(RearTurretSeat,x_axis,math.rad(14.5),100)
	
	Turn(jetleft, x_axis, math.rad(90))
	Turn(jetright, x_axis, math.rad(90))
	Turn(jetrear, x_axis, math.rad(90))
	
	--Move(LeftTurretSeat,x_axis,-2)
	--Move(LeftTurretSeat,y_axis,-1.1)
	--Move(LeftTurretSeat,z_axis,17)
	StartThread(EmitDust)
end

function TiltBody(heading)
	Signal( signals.tilt )
	SetSignalMask( signals.tilt )	
		if( attacking ) then
			--calculate tilt amount for z angle and x angle
			local amountz = -math.sin(heading)
			local amountx = math.cos(heading)
					
			Turn(Base,x_axis, amountx * tiltAngle,1)							
			Turn(Base,z_axis, amountz * tiltAngle,1)
			WaitForTurn ( Base , x_axis )
			WaitForTurn ( Base , z_axis )
		end
		
end

local function RestoreAfterDelay()
	Sleep(restoreDelay)
	attacking = false
	Turn(Base,x_axis, math.rad(0),1) --default tilt
	WaitForTurn ( Base , x_axis )
	Turn(Base,z_axis, math.rad(0),1) --default tilt
	WaitForTurn ( Base , z_axis )
	--Signal( tiltSignal )
end

function script.QueryWeapon(num) 	
	return gunpoints[num].fire	
end

function script.AimFromWeapon(num)	
	return gunpoints[num].aim
end

local function ParticleBeam(num)
	Signal(signals.particle[num])
	SetSignalMask(signals.particle[num])
	for i=1, 30 do
		EmitSfx(gunpoints[num].fire, 2048 + 4)
		Sleep(33)
	end
end

function script.AimWeapon( num, heading, pitch )
	if num == 5 then
		return false
	elseif num == 3 then
		--EmitSfx(Base, 2048 + 2)
		return true
	end
	Signal( signals[num] )
	SetSignalMask( signals[num] )
	attacking = true	
	
	if (-pitch -math.rad(25) > minPitch[num]) then
		--Spring.Echo("stop pitch " .. math.deg(-pitch) - 25)
		return false
	end
	StartThread(TiltBody, heading)	
	
	Turn(gunpoints[num].aim, y_axis, heading + headingMod[num], turretSpeed)
	WaitForTurn (gunpoints[num].aim , y_axis )
	
	Turn(gunpoints[num].pitch, x_axis, -pitch + pitchMod[num] ,turretSpeed)	
	WaitForTurn (gunpoints[num].pitch, x_axis ) 
		
	StartThread(RestoreAfterDelay)
	--StartThread(ParticleBeam, num)
	--return false
	return true
end

function script.FireWeapon(num)
	--Sleep( 1000 )
	if num ~= 3 then
		EmitSfx(gunpoints[num].fire, 1024)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 50 then
		Explode( Base, sfxNone )
		Explode( RightTurret, sfxNone )
		Explode( LeftTurret, sfxNone )
		Explode( RearTurret, sfxNone )
		return 1
	else
		Explode( Base, sfxShatter )
		Explode( RightTurret, sfxExplode )
		Explode( LeftTurret, sfxExplode )
		Explode( RearTurret, sfxExplode )
		return 2
	end
end
