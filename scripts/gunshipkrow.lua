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

local jets = {jetleft, jetright, jetrear}

local gunpoints = {
	[1] = {aim = RightTurretSeat, rot = RightTurret, pitch = RightGun, fire = RightFlashPoint},
	[2] = {aim = LeftTurretSeat, rot = LeftTurret, pitch = LeftGun, fire = LeftFlashPoint},
	[3] = {aim = subpoint, pitch = subpoint, fire = subpoint},
	[4] = {aim = RearTurretSeat, rot = RearTurret, pitch = RearGun, fire = RearFlashPoint},
	[5] = {aim = Base, pitch = Base, fire = Base},
	[6] = {aim = Base, pitch = Base, fire = Base},
}

gunpoints[2].radial = {0.67289841175079, -0.29416278004646, 0.67873126268387}
gunpoints[2].right = {0.6971772313118, -0.030258473008871, -0.71625995635986}
gunpoints[2].normal = {0.23123440146446, 0.95516616106033, 0.18472272157669}
gunpoints[1].radial = {-0.67857336997986, -0.29443317651749, 0.67293930053711}
gunpoints[1].right = {0.70172995328903, 0.036489851772785, 0.71150785684586}
gunpoints[1].normal = {-0.23404698073864, 0.95503199100494, 0.18185153603554}
gunpoints[4].radial = {0.0040571023710072, -0.25233194231987, -0.96763223409653}
gunpoints[4].right = {-0.99998968839645, 0.0029705890920013, 0.0034227864816785}
gunpoints[4].normal = {0.0020107594318688, 0.96760839223862, -0.25231730937958}

--------------------------------------------------------------------------------
--signals
local signals = {
	[1] = 2,
	[2] = 4,
	[4] = 8,
	tilt = 1,
	particle = { -- unused
		[1] = 16,
		[2] = 32,
		[4] = 64,
	}
}

local restoreDelay = 3000

--local blockAim = {false, false, false, false}

local turretSpeed = 8

--local tiltAngle = math.rad(30)
local isLanded = true
local SPECIAL_FIRE_COUNT = 75

local SLOWDOWN_FACTOR = 0.75
local ACCEL_FACTOR = 1.25
local UNIT_SPEED = UnitDefNames["gunshipkrow"].speed*SLOWDOWN_FACTOR/30

local sound_index = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function script.Activate()
 isLanded = false
end

function script.Deactivate()
 isLanded = true
end

local function IsCrashing()
	return (Spring.GetUnitMoveTypeData(unitID).aircraftState or "") == "crashing"
end

local ANIM_DEBUG_MODE = false
local function DeathAnim()
	local count = 0
	local index = math.random(1,#jets)
	while true do
		if (not IsCrashing()) and (not ANIM_DEBUG_MODE) then
			Sleep(100)
		else
			for i=1,#jets do
				EmitSfx(jets[i], 258)
			end
			if count % 18 == 0 then
				EmitSfx(jets[index], 1025)
				index = index + 1
				if index > #jets then
					index = 1
				end
			end
			count = count + 1
			Sleep(33)
		end
	end
end

local function EmitDust()
	while true do
		if not (isLanded or Spring.GetUnitIsStunned(unitID) or Spring.GetUnitIsCloaked(unitID)) then
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
	Sleep(400)
	local _, _, _, x1, y1, z1 = Spring.UnitScript.GetPiecePosDir(gunpoints[num].pitch)
	gunpoints[num].radial = hat({x1, y1, z1})
	
	Turn(gunpoints[num].rot,y_axis,math.rad(90))
	Turn(gunpoints[num].pitch,x_axis,math.rad(90))
	Sleep(400)
	local _, _, _, x2, y2, z2 = Spring.UnitScript.GetPiecePosDir(gunpoints[num].pitch)
	gunpoints[num].right = hat({x2, y2, z2})
	
	gunpoints[num].normal = cross(gunpoints[num].radial,gunpoints[num].right)
	
	Turn(gunpoints[num].rot,y_axis,0)
	Turn(gunpoints[num].pitch,x_axis,0)
	
	
	Spring.Echo("gunpoints[" .. num .. "].radial = {" .. gunpoints[num].radial[1] .. ", " .. gunpoints[num].radial[2] .. ", " .. gunpoints[num].radial[3] .. "}")
	Spring.Echo("gunpoints[" .. num .. "].right = {" .. gunpoints[num].right[1] .. ", " .. gunpoints[num].right[2] .. ", " .. gunpoints[num].right[3] .. "}")
	Spring.Echo("gunpoints[" .. num .. "].normal = {" .. gunpoints[num].normal[1] .. ", " .. gunpoints[num].normal[2] .. ", " .. gunpoints[num].normal[3] .. "}")
end

local function updateAllVectors()

	updateVectors(1)
	updateVectors(2)
	updateVectors(4)
	
	-- idk why they must be swapped
	gunpoints[1].normal,gunpoints[2].normal = gunpoints[2].normal,gunpoints[1].normal
	gunpoints[1].radial,gunpoints[2].radial = gunpoints[2].radial,gunpoints[1].radial
	gunpoints[1].right,gunpoints[2].right = gunpoints[2].right,gunpoints[1].right
end

function script.Create()
	--Turn(Base,y_axis, math.pi)
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
	
	--StartThread(updateAllVectors)
	
	Turn(jetleft, x_axis, math.rad(90))
	Turn(jetright, x_axis, math.rad(90))
	Turn(jetrear, x_axis, math.rad(90))
	
	--Move(LeftTurretSeat,x_axis,-2)
	--Move(LeftTurretSeat,y_axis,-1.1)
	--Move(LeftTurretSeat,z_axis,17)
	--SetDGunCMD()
	StartThread(GG.Script.SmokeUnit, unitID, {RearTurret, RightTurret, LeftTurret})
	StartThread(EmitDust)
	StartThread(DeathAnim)
end

--[[
function TiltBody(heading)
	Signal(signals.tilt)
	SetSignalMask(signals.tilt)
		if(attacking) then
			--calculate tilt amount for z angle and x angle
			local amountz = -math.sin(heading)
			local amountx = math.cos(heading)
					
			--Turn(Base,x_axis, amountx * tiltAngle,1)
			--Turn(Base,z_axis, amountz * tiltAngle,1)
			WaitForTurn (Base, x_axis)
			WaitForTurn (Base, z_axis)
		end
		
end
--]]

local function RestoreAfterDelay()
	Sleep(restoreDelay)
	--Turn(Base,x_axis, math.rad(0),1) --default tilt
	--WaitForTurn (Base, x_axis)
	--Turn(Base,z_axis, math.rad(0),1) --default tilt
	--WaitForTurn (Base, z_axis)
	--Signal(tiltSignal)
end

function script.QueryWeapon(num)
	return gunpoints[num].fire
end

function script.AimFromWeapon(num)
	return gunpoints[num].aim
end


local function ClusterBombThread()
	local sleepTime = 70
	local index = 1
	while index <= SPECIAL_FIRE_COUNT do
		local stunned_or_inbuild = Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID,"disarmed") == 1)
		if not stunned_or_inbuild then
			GG.PokeDecloakUnit(unitID, unitDefID)
			EmitSfx(subemit[0], GG.Script.FIRE_W3)
			index = index + 1
		end
		local slowState = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		Sleep(sleepTime/slowState)
	end
	Sleep(330)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfMaxAccelerationChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function ClusterBomb()
	StartThread(ClusterBombThread)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", SLOWDOWN_FACTOR)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1/SLOWDOWN_FACTOR)
	Spring.SetUnitRulesParam(unitID, "selfMaxAccelerationChange", ACCEL_FACTOR/SLOWDOWN_FACTOR)
	
	GG.UpdateUnitAttributes(unitID)
	--local vx, vy, vz = Spring.GetUnitVelocity(unitID)
	--local hSpeed = math.sqrt(vx^2 + vz^2)
	--if hSpeed > UNIT_SPEED then
	--	Spring.SetUnitVelocity(unitID, vx*UNIT_SPEED/hSpeed, vy, vz*UNIT_SPEED/hSpeed)
	--end
end

function OnLoadGame()
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	Spring.SetUnitRulesParam(unitID, "selfMaxAccelerationChange", 1)
	GG.UpdateUnitAttributes(unitID)
end

function script.AimWeapon(num, heading, pitch)
	if num >= 5 then
		return false
	elseif num == 3 then
		--EmitSfx(Base, 2048 + 2)
		return false
	end
	Signal(signals[num])
	SetSignalMask(signals[num])

	--StartThread(TiltBody, heading)
	
	local theta, phi = getTheActuallyCorrectHeadingAndPitch(heading, pitch, gunpoints[num].normal, gunpoints[num].radial, gunpoints[num].right)
	
	Turn(gunpoints[num].rot, y_axis, theta, turretSpeed)
	Turn(gunpoints[num].pitch, x_axis, phi,turretSpeed)
	WaitForTurn (gunpoints[num].pitch, x_axis)
	WaitForTurn (gunpoints[num].rot, y_axis)
	
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	if num ~= 3 then
		EmitSfx(gunpoints[num].fire, 1024)
	end
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .5 or IsCrashing() then
		Explode(Base, SFX.NONE)
		Explode(RightTurret, SFX.NONE)
		Explode(LeftTurret, SFX.NONE)
		Explode(RearTurret, SFX.NONE)
		return 1
	else
		Explode(Base, SFX.SHATTER)
		Explode(RightTurret, SFX.EXPLODE)
		Explode(LeftTurret, SFX.EXPLODE)
		Explode(RearTurret, SFX.EXPLODE)
		return 2
	end
end
