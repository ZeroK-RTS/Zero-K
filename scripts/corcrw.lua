include 'constants.lua'
include 'letsNotFailAtTrig.lua'

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

local subpoint, emit = piece("subpoint", "emit")
local jetleft, jetright, jetrear = piece('jetleft', 'jetright', 'jetrear')

local subemit = {}
for i=0,4 do
	subemit[i] = piece("subemit"..i)
end

local gunpoints = {
	[1] = {aim = RightTurretSeat, rot = RightTurret, pitch = RightGun, fire = RightFlashPoint},
	[2] = {aim = LeftTurretSeat, rot = LeftTurret, pitch = LeftGun, fire = LeftFlashPoint},
	[3] = {aim = subpoint, pitch = subpoint, fire = subpoint},
	[4] = {aim = RearTurretSeat, rot = RearTurret, pitch = RearGun, fire = RearFlashPoint},
	[5] = {aim = Base, pitch = Base, fire = Base},
	[6] = {aim = Base, pitch = Base, fire = Base},
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

--local blockAim = {false, false, false, false}

local turretSpeed = 8

--local tiltAngle = math.rad(30)
local isLanded = true
local SPECIAL_FIRE_COUNT = 75

local SLOWDOWN_FACTOR = 0.75
local UNIT_SPEED = UnitDefNames["corcrw"].speed*SLOWDOWN_FACTOR/30

local sound_index = 0

function script.Activate()
  isLanded = false
end

function script.Deactivate()
  isLanded = true
end

local function EmitDust()
  while true do
    if not isLanded then
      local x, _, z = GetUnitPosition(unitID)
      local y = GetGroundHeight(x, z) + 30
      SpawnCEG("krowdust", x, y, z, 0, 0, 0, 1, 1)
    end
    Sleep(33)
  end
end

--[[
local function SetDGunCMD()
	local cmd = Spring.FindUnitCmdDesc(unitID, CMD.DGUN)
	local desc = {
		name = "Cluster Bomb",
		tooltip = "Drop a huge number of bombs in a circle under the Krow",
		type = CMDTYPE.ICON_MAP,
	}
	if cmd then Spring.EditUnitCmdDesc(unitID, cmd, desc) end
end
]]--

local function updateVectors(num)
	Turn(gunpoints[num].rot,y_axis,0)
	Turn(gunpoints[num].pitch,x_axis,0)
	
	Turn(gunpoints[num].pitch,x_axis,math.rad(-90))
	local _, _, _, x, y, z = Spring.UnitScript.GetPiecePosDir(gunpoints[num].pitch)
	gunpoints[num].radial = hat({x, y, z})
	
	Turn(gunpoints[num].rot,y_axis,math.rad(90))
	Turn(gunpoints[num].pitch,x_axis,math.rad(90))
	local _, _, _, x, y, z = Spring.UnitScript.GetPiecePosDir(gunpoints[num].pitch)
	gunpoints[num].right = hat({x, y, z})
	
	gunpoints[num].normal = cross(gunpoints[num].radial,gunpoints[num].right)
	
	Turn(gunpoints[num].rot,y_axis,0)
	Turn(gunpoints[num].pitch,x_axis,0)
end

function script.Create()	
	--Turn(Base,y_axis, math.pi)	

	Spring.MoveCtrl.SetGunshipMoveTypeData(unitID,"bankingAllowed",false)
	--Spring.MoveCtrl.SetGunshipMoveTypeData(unitID,"turnRate",0)
	
	--set starting positions for turrets
	Turn(RightTurretSeat,x_axis,math.rad(17)) -- 17
	Turn(RightTurretSeat,z_axis,math.rad(2)) -- 2
	Turn(RightTurretSeat,y_axis,math.rad(-45)) -- -45
	
	Turn(LeftTurretSeat,x_axis,math.rad(17)) -- 17
	Turn(LeftTurretSeat,z_axis,math.rad(-2)) -- -2
	Turn(LeftTurretSeat,y_axis,math.rad(45)) -- 45
	
	Turn(RearTurretSeat,y_axis,math.rad(180))
	Turn(RearTurretSeat,x_axis,math.rad(14.5))
	
	for i=0,4 do
		Turn(subemit[i], x_axis, math.rad(90))
	end
	
	updateVectors(1)
	updateVectors(2)
	updateVectors(4)
	
	-- idk why they must be swapped
	gunpoints[1].normal,gunpoints[2].normal = gunpoints[2].normal,gunpoints[1].normal
	gunpoints[1].radial,gunpoints[2].radial = gunpoints[2].radial,gunpoints[1].radial
	gunpoints[1].right,gunpoints[2].right = gunpoints[2].right,gunpoints[1].right
	
	Turn(jetleft, x_axis, math.rad(90))
	Turn(jetright, x_axis, math.rad(90))
	Turn(jetrear, x_axis, math.rad(90))
	
	Spin(emit, y_axis, math.rad(180))
	
	--Move(LeftTurretSeat,x_axis,-2)
	--Move(LeftTurretSeat,y_axis,-1.1)
	--Move(LeftTurretSeat,z_axis,17)
	--SetDGunCMD()
	StartThread(EmitDust)
end

--[[
function TiltBody(heading)
	Signal( signals.tilt )
	SetSignalMask( signals.tilt )	
		if( attacking ) then
			--calculate tilt amount for z angle and x angle
			local amountz = -math.sin(heading)
			local amountx = math.cos(heading)
					
			--Turn(Base,x_axis, amountx * tiltAngle,1)							
			--Turn(Base,z_axis, amountz * tiltAngle,1)
			WaitForTurn ( Base , x_axis )
			WaitForTurn ( Base , z_axis )
		end
		
end
--]]

local function RestoreAfterDelay()
	Sleep(restoreDelay)
	attacking = false
	--Turn(Base,x_axis, math.rad(0),1) --default tilt
	--WaitForTurn ( Base , x_axis )
	--Turn(Base,z_axis, math.rad(0),1) --default tilt
	--WaitForTurn ( Base , z_axis )
	--Signal( tiltSignal )
end

function script.QueryWeapon(num) 	
	return gunpoints[num].fire	
end

function script.AimFromWeapon(num)	
	return gunpoints[num].aim
end


local function ClusterBombThread()
	local slowState = 1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
	local sleepTime = 70/slowState
	for i = 1, SPECIAL_FIRE_COUNT do
		EmitSfx( subemit[0],  FIRE_W5 )
		Sleep(sleepTime)
	end
	Sleep(330)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function ClusterBomb()
	StartThread(ClusterBombThread)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", SLOWDOWN_FACTOR)
	GG.attUnits[unitID] = true
	GG.UpdateUnitAttributes(unitID)
	--local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	--local hSpeed = math.sqrt(vx^2 + vz^2)
	--if hSpeed > UNIT_SPEED then
	--	Spring.SetUnitVelocity(unitID, vx*UNIT_SPEED/hSpeed, vy, vz*UNIT_SPEED/hSpeed)
	--end
end

function script.AimWeapon( num, heading, pitch )
	if num >= 5 then
		return false
	elseif num == 3 then
		--EmitSfx(Base, 2048 + 2)
		return false
	end
	Signal( signals[num] )
	SetSignalMask( signals[num] )
	attacking = true	

	--StartThread(TiltBody, heading)	
	
	local theta, phi = getTheActuallyCorrectHeadingAndPitch(heading, pitch, gunpoints[num].normal, gunpoints[num].radial, gunpoints[num].right)
	
	Turn(gunpoints[num].rot, y_axis, theta, turretSpeed)
	Turn(gunpoints[num].pitch, x_axis, phi ,turretSpeed)	
	WaitForTurn (gunpoints[num].pitch, x_axis ) 
	WaitForTurn (gunpoints[num].rot , y_axis )
	
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	--Sleep( 1000 )
	if num ~= 3 then
		EmitSfx(gunpoints[num].fire, 1024)
	else
		--ClusterBomb()
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .5 then
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
