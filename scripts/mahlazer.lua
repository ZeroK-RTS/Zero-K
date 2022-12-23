include "constants.lua"
include "pieceControl.lua"

local ActuatorBase = piece('ActuatorBase')
local ActuatorBase_1 = piece('ActuatorBase_1')
local ActuatorBase_2 = piece('ActuatorBase_2')
local ActuatorBase_3 = piece('ActuatorBase_3')
local ActuatorBase_4 = piece('ActuatorBase_4')
local ActuatorBase_5 = piece('ActuatorBase_5')
local ActuatorBase_6 = piece('ActuatorBase_6')
local ActuatorBase_7 = piece('ActuatorBase_7')
local ActuatorMiddle = piece('ActuatorMiddle')
local ActuatorMiddle_1 = piece('ActuatorMiddle_1')
local ActuatorMiddle_2 = piece('ActuatorMiddle_2')
local ActuatorMiddle_3 = piece('ActuatorMiddle_3')
local ActuatorMiddle_4 = piece('ActuatorMiddle_4')
local ActuatorMiddle_5 = piece('ActuatorMiddle_5')
local ActuatorMiddle_6 = piece('ActuatorMiddle_6')
local ActuatorMiddle_7 = piece('ActuatorMiddle_7')
local ActuatorTip = piece('ActuatorTip')
local ActuatorTip_1 = piece('ActuatorTip_1')
local ActuatorTip_2 = piece('ActuatorTip_2')
local ActuatorTip_3 = piece('ActuatorTip_3')
local ActuatorTip_4 = piece('ActuatorTip_4')
local ActuatorTip_5 = piece('ActuatorTip_5')
local ActuatorTip_6 = piece('ActuatorTip_6')
local ActuatorTip_7 = piece('ActuatorTip_7')

local Basis = piece('Basis')
local Dock = piece('Dock')
local Dock_1 = piece('Dock_1')
local Dock_2 = piece('Dock_2')
local Dock_3 = piece('Dock_3')
local Dock_4 = piece('Dock_4')
local Dock_5 = piece('Dock_5')
local Dock_6 = piece('Dock_6')
local Dock_7 = piece('Dock_7')
local Emitter = piece('Emitter')
local EmitterMuzzle = piece('EmitterMuzzle')

-- these are satellite pieces
local LimbA1 = piece('LimbA1')
local LimbA2 = piece('LimbA2')
local LimbB1 = piece('LimbB1')
local LimbB2 = piece('LimbB2')
local LimbC1 = piece('LimbC1')
local LimbC2 = piece('LimbC2')
local LimbD1 = piece('LimbD1')
local LimbD2 = piece('LimbD2')
local Satellite = piece('Satellite')
local SatelliteMuzzle = piece('SatelliteMuzzle')
local SatelliteMount = piece('SatelliteMount')


local LongSpikes = piece('LongSpikes')
local LowerCoil = piece('LowerCoil')

local ShortSpikes = piece('ShortSpikes')
local UpperCoil = piece('UpperCoil')

local DocksClockwise = {Dock,Dock_1,Dock_2,Dock_3}
local DocksCounterClockwise = {Dock_4,Dock_5,Dock_6,Dock_7}
local ActuatorBaseClockwise = {ActuatorBase,ActuatorBase_1,ActuatorBase_2,ActuatorBase_3}
local ActuatorBaseCCW = {ActuatorBase_4,ActuatorBase_5,ActuatorBase_6,ActuatorBase_7}
local ActuatorMidCW =  {ActuatorMiddle,ActuatorMiddle_1,ActuatorMiddle_2,ActuatorMiddle_3}
local ActuatorMidCCW = {ActuatorMiddle_4,ActuatorMiddle_5,ActuatorMiddle_6,ActuatorMiddle_7}
local ActuatorTipCW =  {ActuatorTip,ActuatorTip_1,ActuatorTip_2,ActuatorTip_3}
local ActuatorTipCCW = {ActuatorTip_4,ActuatorTip_5,ActuatorTip_6,ActuatorTip_7}

local smokePiece = {Basis,ActuatorBase,ActuatorBase_1,ActuatorBase_2,ActuatorBase_3,ActuatorBase_4,ActuatorBase_5,ActuatorBase_6,ActuatorBase_7}

local YAW_AIM_RATE = math.rad(2.5)
local PITCH_AIM_RATE = math.rad(0.75)

local oldHeight = 0
local shooting = 0
local wantedDirection = 0

local ROTATION_PER_FRAME = YAW_AIM_RATE/30
local TARGET_ALT = 143565270/2^16
local Vector = Spring.Utilities.Vector
local max = math.max
local soundTime = 0
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local satUnitID = false

local DOCKED = 1
local READY = 2
local FALLING = 3
local UNDOCKING = 4

local aimingDone = false
local isStunned = true
local state = DOCKED

-- Signal definitions
local SIG_AIM = 2
local SIG_DOCK = 4

local function IsDisabled()
	local state = Spring.GetUnitStates(unitID)
	if not (state and state.active) then
		return true
	end
	return spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1) or (spGetUnitRulesParam(unitID, "lowpower") == 1)
end

local function CallSatelliteScript(funcName, args, args2)
	if not satUnitID then
		return
	end
	local env = Spring.UnitScript.GetScriptEnv(satUnitID)
	if not env then
		return
	end
	local func = env[funcName]
	if func then
		Spring.UnitScript.CallAsUnit(satUnitID, func, args, args2)
	end
end

local HEADING_TO_RAD = 1/32768*math.pi
local function GetDir(checkUnitID)
	if not satUnitID then
		return
	end
	local heading = Spring.GetUnitHeading(satUnitID)
	if heading then
		return math.pi/2 - heading*HEADING_TO_RAD
	end
end

function StopAim()
	CallSatelliteScript('mahlazer_StopAim')
	GG.PieceControl.StopTurn(SatelliteMuzzle, x_axis)
	Signal(SIG_AIM)
	if satUnitID then
		wantedDirection = GetDir(satUnitID)
	end
end

local isFiring = false
local function SetFiringState(shouldFire)
	if isFiring == shouldFire then
		return
	end
	isFiring = shouldFire

	if shouldFire then
		CallSatelliteScript('mahlazer_EngageTheLaserBeam')
	else
		CallSatelliteScript('mahlazer_DisengageTheLaserBeam')
		StopAim()
	end
end

function Undock()
	SetSignalMask(SIG_DOCK)
	
	while IsDisabled() do
		Sleep(500)
	end
	
	if state == DOCKED then
		state = UNDOCKING
		for i = 1, 4 do
			Turn(DocksClockwise[i]      ,z_axis,math.rad(-42.5),1)
			Turn(DocksCounterClockwise[i],z_axis,math.rad( 42.5),1)
			
			Turn(ActuatorBaseClockwise[i],z_axis,math.rad(-86),2)
			Turn(ActuatorBaseCCW[i]      ,z_axis,math.rad( 86),2)
			
			Turn(ActuatorMidCW [i],z_axis,math.rad( 53),1.5)
			Turn(ActuatorMidCCW[i],z_axis,math.rad( 53),1.5)
			
			Turn(ActuatorTipCW [i],z_axis,math.rad( 90),2.2)
			Turn(ActuatorTipCCW[i],z_axis,math.rad( 90),2.2)

			-- 53 for mid
			-- 90 for tip
		end

		Sleep(1000)
		CallSatelliteScript('mahlazer_Undock')
		
		Sleep(1200)
	end
	state = READY
	
	Move(SatelliteMount, z_axis, TARGET_ALT, 30*4)
end

function Dock()
	SetSignalMask(SIG_DOCK)
	state = FALLING
	SetFiringState(false)
	
	Move(SatelliteMount, z_axis, 0, 30*4)
	WaitForMove(SatelliteMount,z_axis)
	
	state = DOCKED
	Move(ShortSpikes,z_axis, -5,1)
	Move(LongSpikes,z_axis, -10,1.5)
	Sleep(100)
	
	while not Spring.ValidUnitID(satUnitID) do
		Sleep(30)
	end
	
	local dx, _, dz = Spring.GetUnitDirection(unitID)
	if dx then
		local heading = Vector.Angle(dx, dz)
		
		while spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1) do
			-- This is basically just visuals to stop animation while visually stunned.
			Sleep(500)
		end
		CallSatelliteScript('mahlazer_Dock')
		
		Sleep(100)
		
		for i = 1, 4 do
			Turn(DocksClockwise[i]	   ,z_axis,math.rad(0),1)
			Turn(DocksCounterClockwise[i],z_axis,math.rad(0),1)
			
			Turn(ActuatorBaseClockwise[i],z_axis,math.rad(0),2)
			Turn(ActuatorBaseCCW[i]	  ,z_axis,math.rad(0),2)
			
			Turn(ActuatorMidCW [i],z_axis,math.rad( 0),1.5)
			Turn(ActuatorMidCCW[i],z_axis,math.rad( 0),1.5)
			
			Turn(ActuatorTipCW [i],z_axis,math.rad( 0),2.2)
			Turn(ActuatorTipCCW[i],z_axis,math.rad( 0),2.2)
		end
	end
end

function SpiralDown()
	SetSignalMask(SIG_DOCK)
	
	while state == FALLING do
		-- this ignores base unit rotation. because it wants to snap to multiples of 90, and base unit is guaranteed to be
		-- always snapped to multiples of 90 because of how buildings are
		-- this is an invitation for someone to implement arbitrary 360-deg rotation and break this. I dare you. Fight me.
		if not satUnitID then
			break
		end
		
		local dx, _, dz = Spring.GetUnitDirection(satUnitID)
		if not dx then
			break
		end
		local currentHeading  = Vector.Angle(dx, dz)
		local closestMultiple = math.round(currentHeading/(math.pi/2))*math.pi/2
		local aimOff = closestMultiple - currentHeading

		if aimOff < 0 then
			aimOff = math.max(-ROTATION_PER_FRAME, aimOff)
		else
			aimOff = math.min(ROTATION_PER_FRAME, aimOff)
		end
		
		CallSatelliteScript('mahlazer_AimAt', 0, PITCH_AIM_RATE)
		Turn(SatelliteMuzzle, x_axis, 0, YAW_AIM_RATE)
		
		Spring.SetUnitRotation(satUnitID, 0, currentHeading + aimOff - math.pi/2 , 0)
		
		if (currentHeading == closestMultiple) then
			break
		end
		
		Sleep(33)
	end
end

function TargetingLaserUpdate()
	while true do
		isStunned = IsDisabled()
		SetFiringState(state == READY and not isStunned)
		if satUnitID then
			if state == READY then
				if isStunned then
					Signal(SIG_DOCK)
					StartThread(Dock)
					StartThread(SpiralDown)
					Signal(SIG_AIM)
				else
					--// Aiming
					local dx, _, dz = Spring.GetUnitDirection(satUnitID)
					local otherCurrentHeading = GetDir(satUnitID)
					if dx and otherCurrentHeading then
						local currentHeading = Vector.Angle(dx, dz)
						local aimOff = (otherCurrentHeading - wantedDirection + math.pi)%(2*math.pi) - math.pi
						
						if aimOff < 0 then
							if aimOff < -ROTATION_PER_FRAME then
								aimOff = -ROTATION_PER_FRAME
								aimingDone = false
							else
								aimingDone = true
							end
						else
							if aimOff > ROTATION_PER_FRAME then
								aimOff = ROTATION_PER_FRAME
								aimingDone = false
							else
								aimingDone = true
							end
						end
						
						Spring.SetUnitRotation(satUnitID, 0, currentHeading - aimOff - math.pi/2, 0)
						
						--// Relay range
						local _, flashY = Spring.GetUnitPiecePosition(unitID, EmitterMuzzle)
						local _, SatelliteMuzzleY = Spring.GetUnitPiecePosition(unitID, SatelliteMuzzle)
						newHeight = max(SatelliteMuzzleY-flashY, 1)
						if newHeight ~= oldHeight then
							Spring.SetUnitWeaponState(unitID, 2, "range", newHeight)
							Spring.SetUnitWeaponState(unitID, 3, "range", newHeight)
							oldHeight = newHeight
						end
						
						--// Sound effects
						if soundTime < 0 then
							local px, py, pz = Spring.GetUnitPosition(unitID)
							Spring.PlaySoundFile("sounds/weapon/laser/laser_burn6.wav", 10, px, (py + flashY)/2, pz)
							soundTime = 46
						else
							soundTime = soundTime - 1
						end
						
						--// Shooting
						if shooting ~= 0 then
							EmitSfx(EmitterMuzzle, GG.Script.FIRE_W2)
							shooting = shooting - 1
						else
							EmitSfx(EmitterMuzzle, GG.Script.FIRE_W3)
						end
					end
				end
			elseif not isStunned and state ~= UNDOCKING then
				Signal(SIG_DOCK)
				StartThread(Undock)
			end
		end
		
		Sleep(30)
	end
end

local function SnapSatellite()
	while true do
		local x,y,z = Spring.GetUnitPiecePosDir(unitID,SatelliteMount)
		Spring.MoveCtrl.SetPosition(satUnitID,x,y,z)
		Sleep(30)
	end
end

local function DeferredInitialize()
	while select(3, Spring.GetUnitIsStunned(unitID)) do
		Sleep(30)
	end
	
	Spin(UpperCoil, z_axis, 10,0.5)
	Spin(LowerCoil, z_axis, 10,0.5)
	
	Move(ShortSpikes,z_axis, 0,1)
	Move(LongSpikes,z_axis, 0,1.5)
	
	local x,y,z = Spring.GetUnitPiecePosDir(unitID,SatelliteMount)
	local dx, _, dz = Spring.GetUnitDirection(unitID)
	if not dx then
		return
	end
	local heading = Vector.Angle(dx, dz)
	
	while not Spring.ValidUnitID(satUnitID) do
		Sleep(30)
		satUnitID = Spring.CreateUnit('starlight_satellite',x,y,z,0,Spring.GetUnitTeam(unitID))
		if satUnitID then
			satelliteCreated = true
			Spring.SetUnitNoSelect(satUnitID,true)
			Spring.SetUnitNoMinimap(satUnitID,true)
			Spring.SetUnitNeutral(satUnitID,true)
			Spring.MoveCtrl.Enable(satUnitID)
			Spring.MoveCtrl.SetPosition(satUnitID,x,y,z)
			Spring.SetUnitRotation(satUnitID, 0, heading+math.pi/2, 0)
			Spring.SetUnitLoadingTransport(satUnitID,unitID)
			Spring.SetUnitRulesParam(satUnitID,'cannot_damage_unit',unitID)
			Spring.SetUnitRulesParam(satUnitID,'parent_unit_id',unitID)
			Spring.SetUnitRulesParam(satUnitID,'untargetable',1)
			Spring.SetUnitRulesParam(unitID,'has_satellite',satUnitID)
			Spring.SetUnitCollisionVolumeData(satUnitID, 0,0,0, 0,0,0, -1,0,0)
			Hide(LimbA1)
			Hide(LimbA2)
			Hide(LimbB1)
			Hide(LimbB2)
			Hide(LimbC1)
			Hide(LimbC2)
			Hide(LimbD1)
			Hide(LimbD2)
			Hide(Satellite)
			Hide(SatelliteMuzzle)
		end
	end
	
	StartThread(SnapSatellite)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	-- Give the targeter +500 extra range to allow the build UI to show what a Starlight can hit
	Spring.SetUnitWeaponState(unitID, 1, "range", 10500)

	--Move(ShortSpikes,z_axis, -5)
	--Move(LongSpikes,z_axis, -10)
	local facing = Spring.GetUnitBuildFacing(unitID)
	StartThread(TargetingLaserUpdate)
	
	wantedDirection = math.pi*(3 - facing)/2
	StartThread(DeferredInitialize)
end

function script.Activate()
	Signal(SIG_DOCK)
	StartThread(Undock)
end

function script.Deactivate()
	Signal(SIG_DOCK)
	StartThread(Dock)
	StartThread(SpiralDown)
	Signal(SIG_AIM)
end

function script.AimWeapon(num, heading, pitch)
	if (not isStunned) and state == READY and num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		
		local dx, _, dz = Spring.GetUnitDirection(unitID)
		if not dx then
			return false
		end
		local currentHeading = Vector.Angle(dx, dz)
		
		wantedDirection = currentHeading - heading + math.pi
		
		pitchFudge = (math.pi/2 + pitch)*0.998 - math.pi/2
		
		local speedMult = (GG.att_ReloadChange[unitID] or 1)
		CallSatelliteScript('mahlazer_AimAt', pitchFudge + math.pi/2, PITCH_AIM_RATE*speedMult)
		Turn(SatelliteMuzzle, x_axis, math.pi/2 + pitch, PITCH_AIM_RATE*speedMult)
		WaitForTurn(SatelliteMuzzle, x_axis)
		return aimingDone and (spGetUnitRulesParam(unitID, "lowpower") == 0)
	end
	return false
end

function script.QueryWeapon(num)
	return SatelliteMuzzle
end

function script.FireWeapon(num)
	shooting = 30
	CallSatelliteScript('mahlazer_SetShoot',shooting)
end

function script.AimFromWeapon(num)
	return SatelliteMuzzle
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= 0.25) then
		Explode(Basis, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= 0.5) then
		Explode(Basis, SFX.NONE)
		return 1 -- corpsetype
	else
		Explode(Basis, SFX.SHATTER)
		return 2 -- corpsetype
	end
end

