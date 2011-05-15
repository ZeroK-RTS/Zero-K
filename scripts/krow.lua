include 'constants.lua'
-- by MergeNine

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



--signals
local aim = 1
local aim2 = 2
local aim3 = 4
local tiltSignal = 5
local restoreDelay = 3000
local attacking = 0
local blockAim1 = false
local blockAim2 = false
local blockAim3 = false
local frontTurretsMinPitch = math.rad(35)
local rearTurretMinPitch = math.rad(20)
local turretSpeed = 5

local tiltAngle = math.rad(30)

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
	
	--Move(LeftTurretSeat,x_axis,-2)
	--Move(LeftTurretSeat,y_axis,-1.1)
	--Move(LeftTurretSeat,z_axis,17)
	
end

function TiltBody(heading)
	Signal( tiltSignal )
	SetSignalMask( tiltSignal )
			
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
	attacking = 0
	Turn(Base,x_axis, math.rad(0),1) --default tilt
	WaitForTurn ( Base , x_axis )
	Turn(Base,z_axis, math.rad(0),1) --default tilt
	WaitForTurn ( Base , z_axis )
	--Signal( tiltSignal )
end

function script.QueryWeapon1() 	
		return RightFlashPoint	
end
function script.QueryWeapon2() 	
		return LeftFlashPoint	
end
function script.QueryWeapon3() 	
		return RearFlashPoint	
end

function script.AimFromWeapon1()	
	return RightFlashPoint	
end
function script.AimFromWeapon2() 		
	return LeftGun		
end
function script.AimFromWeapon3() 	
	return RearGun		
end

--these make sure the turrets dont try to turn through themselves
function script.BlockShot1(UnitId, block)

	if (blockAim1 == true) then		
		return true
	end
	return false

end
function script.BlockShot2(UnitId, block)

	if (blockAim2 == true) then		
		return true
	end
	return false

end
function script.BlockShot3(UnitId, block)

	if (blockAim3 == true) then		
		return true
	end
	return false

end

function script.AimWeapon1( heading, pitch )
	
	Signal( aim )
	SetSignalMask( aim )
	attacking = 1	
	
	if (-pitch -math.rad(25) > frontTurretsMinPitch) then
		blockAim1 = true
		--Spring.Echo("stop pitch " .. math.deg(-pitch) - 25)
		return 0
	else
		--Spring.Echo("pitch " .. math.deg(-pitch) - 25)
		blockAim1 = false
	end
		
	Spring.UnitScript.StartThread(TiltBody,heading)	
	
	Turn(RightTurret,y_axis,heading + math.rad(45),turretSpeed)
	Spring.UnitScript.WaitForTurn ( RightTurret , y_axis )
	
	Turn(RightGun,x_axis,-pitch -math.rad(25) ,turretSpeed)	
	Spring.UnitScript.WaitForTurn ( RightGun, x_axis ) 
		
	Spring.UnitScript.StartThread(RestoreAfterDelay)
	return 1
end

function script.AimWeapon2( heading, pitch )
	Signal( aim2 )
	SetSignalMask( aim2 )
	attacking = 1
	
	if (-pitch -math.rad(25) > frontTurretsMinPitch) then
		blockAim2 = true		
		return 0
	else		
		blockAim2 = false
	end
	
	
	Turn(LeftTurret,y_axis,heading + math.rad(-45),turretSpeed)
	Spring.UnitScript.WaitForTurn ( LeftTurret, y_axis )
	
	Turn(LeftGun,x_axis,-pitch - math.rad(25) ,turretSpeed)
	Spring.UnitScript.WaitForTurn ( LeftGun, x_axis ) 
	
	Spring.UnitScript.StartThread(RestoreAfterDelay)
	
	return 1
end

function script.AimWeapon3( heading, pitch )
	Signal( aim3 )
	SetSignalMask( aim3 )		
	attacking = 1
	
	if (-pitch -math.rad(25) > rearTurretMinPitch) then
		blockAim3 = true		
		return 0
	else	
		blockAim3 = false
	end
	
	Turn(RearTurret,y_axis,heading + math.rad(180),turretSpeed)
	Spring.UnitScript.WaitForTurn ( RearTurret , y_axis )
	
	Turn(RearGun,x_axis,-pitch - math.rad(15),turretSpeed)
	Spring.UnitScript.WaitForTurn ( RearGun, x_axis ) 
		
	Spring.UnitScript.StartThread(RestoreAfterDelay)
	
	
	return 1
end

function script.FireWeapon1()
	--Sleep( 1000 )
	EmitSfx (RightFlashPoint, 1024)
end

function script.FireWeapon2()
	--Sleep( 1000 )
	EmitSfx (LeftFlashPoint, 1024)
end

function script.FireWeapon3()
	--Sleep( 1000 )
	EmitSfx (RearFlashPoint, 1024)
end

function script.Killed()
	Explode( Base, sfxFall )
	Explode( RightTurret, SFX.EXPLODE )
	Explode( LeftTurret, SFX.EXPLODE )
	Explode( RearTurret, SFX.EXPLODE )
end
