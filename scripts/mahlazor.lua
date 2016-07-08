include "constants.lua"

local ActuatorBase = piece('ActuatorBase');
local ActuatorBase_1 = piece('ActuatorBase_1');
local ActuatorBase_2 = piece('ActuatorBase_2');
local ActuatorBase_3 = piece('ActuatorBase_3');
local ActuatorBase_4 = piece('ActuatorBase_4');
local ActuatorBase_5 = piece('ActuatorBase_5');
local ActuatorBase_6 = piece('ActuatorBase_6');
local ActuatorBase_7 = piece('ActuatorBase_7');
local ActuatorMiddle = piece('ActuatorMiddle');
local ActuatorMiddle_1 = piece('ActuatorMiddle_1');
local ActuatorMiddle_2 = piece('ActuatorMiddle_2');
local ActuatorMiddle_3 = piece('ActuatorMiddle_3');
local ActuatorMiddle_4 = piece('ActuatorMiddle_4');
local ActuatorMiddle_5 = piece('ActuatorMiddle_5');
local ActuatorMiddle_6 = piece('ActuatorMiddle_6');
local ActuatorMiddle_7 = piece('ActuatorMiddle_7');
local ActuatorTip = piece('ActuatorTip');
local ActuatorTip_1 = piece('ActuatorTip_1');
local ActuatorTip_2 = piece('ActuatorTip_2');
local ActuatorTip_3 = piece('ActuatorTip_3');
local ActuatorTip_4 = piece('ActuatorTip_4');
local ActuatorTip_5 = piece('ActuatorTip_5');
local ActuatorTip_6 = piece('ActuatorTip_6');
local ActuatorTip_7 = piece('ActuatorTip_7');

local Basis = piece('Basis');
local Dock = piece('Dock');
local Dock_1 = piece('Dock_1');
local Dock_2 = piece('Dock_2');
local Dock_3 = piece('Dock_3');
local Dock_4 = piece('Dock_4');
local Dock_5 = piece('Dock_5');
local Dock_6 = piece('Dock_6');
local Dock_7 = piece('Dock_7');
local Emitter = piece('Emitter');
local EmitterMuzzle = piece('EmitterMuzzle');

-- these are satellite pieces
local LimbA1 = piece('LimbA1');
local LimbA2 = piece('LimbA2');
local LimbB1 = piece('LimbB1');
local LimbB2 = piece('LimbB2');
local LimbC1 = piece('LimbC1');
local LimbC2 = piece('LimbC2');
local LimbD1 = piece('LimbD1');
local LimbD2 = piece('LimbD2');
local Satellite = piece('Satellite');
local SatelliteMuzzle = piece('SatelliteMuzzle');
local SatelliteMount = piece('SatelliteMount');


local LongSpikes = piece('LongSpikes');
local LowerCoil = piece('LowerCoil');

local ShortSpikes = piece('ShortSpikes');
local UpperCoil = piece('UpperCoil');

local DocksClockwise = {Dock,Dock_1,Dock_2,Dock_3};
local DocksCounterClockwise = {Dock_4,Dock_5,Dock_6,Dock_7};
local ActuatorBaseClockwise = {ActuatorBase,ActuatorBase_1,ActuatorBase_2,ActuatorBase_3}
local ActuatorBaseCCW = {ActuatorBase_4,ActuatorBase_5,ActuatorBase_6,ActuatorBase_7}
local ActuatorMidCW =  {ActuatorMiddle,ActuatorMiddle_1,ActuatorMiddle_2,ActuatorMiddle_3}
local ActuatorMidCCW = {ActuatorMiddle_4,ActuatorMiddle_5,ActuatorMiddle_6,ActuatorMiddle_7}
local ActuatorTipCW =  {ActuatorTip,ActuatorTip_1,ActuatorTip_2,ActuatorTip_3}
local ActuatorTipCCW = {ActuatorTip_4,ActuatorTip_5,ActuatorTip_6,ActuatorTip_7}

local smokePiece = {Basis,ActuatorBase,ActuatorBase_1,ActuatorBase_2,ActuatorBase_3,ActuatorBase_4,ActuatorBase_5,ActuatorBase_6,ActuatorBase_7}

local on = false;
local awake = false;
local oldHeight = 0
local shooting = 0
local wantedDirection = 0
local ROTATION_SPEED = math.rad(3.5)/30
local TARGET_ALT = 143565270/2^16
local Vector = Spring.Utilities.Vector 
local max = math.max
local soundTime = 0
local spGetUnitIsStunned = Spring.GetUnitIsStunned

local satUnitID = false;
local satelliteCreated = false;
local engaged = false;

-- Signal definitions
local SIG_AIM = 2
local SIG_DOCK = 4

local function CallSatelliteScript(funcName, args)
	local func = Spring.UnitScript.GetScriptEnv(satUnitID)[funcName]
	if func then
		Spring.UnitScript.CallAsUnit(satUnitID, func, args)
	end
end

function script.Create()

end

function Undock()
    SetSignalMask(SIG_DOCK);

    docking = false

    for i=1,4 do
        Turn(DocksClockwise[i]       ,z_axis,math.rad(-42.5),1);
        Turn(DocksCounterClockwise[i],z_axis,math.rad( 42.5),1);
        
        Turn(ActuatorBaseClockwise[i],z_axis,math.rad(-86),2);
        Turn(ActuatorBaseCCW[i]      ,z_axis,math.rad( 86),2);
        
        Turn(ActuatorMidCW [i],z_axis,math.rad( 53),1.5);
        Turn(ActuatorMidCCW[i],z_axis,math.rad( 53),1.5);
        
        Turn(ActuatorTipCW [i],z_axis,math.rad( 90),2.2);
        Turn(ActuatorTipCCW[i],z_axis,math.rad( 90),2.2);

        -- 53 for mid
        -- 90 for tip
    end

    Sleep(1000);


    
    on = true
	StartThread(TargetingLaser)
    CallSatelliteScript('mahlazer_Undock')

    Sleep(1500);
    engaged = true;
    CallSatelliteScript('mahlazer_EngageTheLaserBeam');
    
	Move(SatelliteMount, z_axis, TARGET_ALT, 30*4)
end

function Dock()
    SetSignalMask(SIG_DOCK);
    docking = true;
    CallSatelliteScript('mahlazer_DisengageTheLaserBeam');
    engaged = false;
    
	Move(SatelliteMount, z_axis, 0, 30*4)
    WaitForMove(SatelliteMount,z_axis);
    Sleep(1000)
    
    local dx, _, dz = Spring.GetUnitDirection(unitID)
    local heading = Vector.Angle(dx, dz)
    Spring.SetUnitRotation(satUnitID, 0, heading, 0);
    
    docking = false
    
    CallSatelliteScript('mahlazer_Dock');
    
    Sleep(500);
        
    for i=1,4 do
        Turn(DocksClockwise[i]       ,z_axis,math.rad(0),1);
        Turn(DocksCounterClockwise[i],z_axis,math.rad(0),1);
        
        Turn(ActuatorBaseClockwise[i],z_axis,math.rad(0),2);
        Turn(ActuatorBaseCCW[i]      ,z_axis,math.rad(0),2);
        
        Turn(ActuatorMidCW [i],z_axis,math.rad( 0),1.5);
        Turn(ActuatorMidCCW[i],z_axis,math.rad( 0),1.5);
        
        Turn(ActuatorTipCW [i],z_axis,math.rad( 0),2.2);
        Turn(ActuatorTipCCW[i],z_axis,math.rad( 0),2.2);
    end

end

function SpiralDown()
    SetSignalMask(SIG_DOCK);
    while(docking) do
        local dx, _, dz = Spring.GetUnitDirection(satUnitID);
        local bx, _, bz = Spring.GetUnitDirection(unitID);
        local currentHeading = Vector.Angle(dx, dz);
        local baseHeading = Vector.Angle(bx,bz); 
      
        local aimOff = (currentHeading - baseHeading)
        
        if aimOff < 0 then
            aimOff = math.max(-ROTATION_SPEED, aimOff)
        else
            aimOff = math.min(ROTATION_SPEED, aimOff)
        end
        
        Spring.SetUnitRotation(satUnitID, 0, currentHeading - aimOff - math.pi/2, 0)
        
        if(currentHeading == baseHeading) then
            break;
        end
        
        Sleep(33)
    end
end

function TargetingLaser()
	while on do
		awake = (not spGetUnitIsStunned(unitID)) and (Spring.GetUnitRulesParam(unitID,"disarmed") ~= 1);
		
		if awake then
        
            if not engaged then
                engaged = true;
                CallSatelliteScript('mahlazer_EngageTheLaserBeam');
            end
        
			--// Aiming

            
			local dx, _, dz = Spring.GetUnitDirection(satUnitID)
			local currentHeading = Vector.Angle(dx, dz)
			
			local aimOff = (currentHeading - wantedDirection + math.pi)%(2*math.pi) - math.pi*1.5
			
			if aimOff < 0 then
				aimOff = math.max(-ROTATION_SPEED, aimOff)
			else
				aimOff = math.min(ROTATION_SPEED, aimOff)
			end
			
			Spring.SetUnitRotation(satUnitID, 0, currentHeading - aimOff - math.pi/2, 0)
			
			--// Relay range
			local _, flashY = Spring.GetUnitPiecePosition(unitID, EmitterMuzzle)
			local _, SatelliteMuzzleY = Spring.GetUnitPiecePosition(unitID, SatelliteMuzzle)
			newHeight = max(SatelliteMuzzleY-flashY, 1)
			if newHeight ~= oldHeight then
				Spring.SetUnitWeaponState(unitID, 3, "range", newHeight)
				Spring.SetUnitWeaponState(unitID, 5, "range", newHeight)
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
				EmitSfx(EmitterMuzzle, FIRE_W3)
				shooting = shooting - 1
			else
				EmitSfx(EmitterMuzzle, FIRE_W5)
			end
        elseif engaged then
            engaged = false;
            CallSatelliteScript('mahlazer_DisengageTheLaserBeam');
		end
		
		Sleep(30)
	end
end

function script.Create()
	Spring.SetUnitWeaponState(unitID, 2, "range", 9300)
	Spring.SetUnitWeaponState(unitID, 4, "range", 9300)
	StartThread(SmokeUnit, smokePiece)
end

function script.Activate()
    Spin(UpperCoil, z_axis, 10,0.5);
    Spin(LowerCoil, z_axis, 10,0.5);
    
    if(not satelliteCreated)then
        satelliteCreated = true;
        Hide(LimbA1);
        Hide(LimbA2);
        Hide(LimbB1);
        Hide(LimbB2);
        Hide(LimbC1);
        Hide(LimbC2);
        Hide(LimbD1);
        Hide(LimbD2);
        Hide(Satellite)
        Hide(SatelliteMuzzle);
        
        local x,y,z = Spring.GetUnitPiecePosDir(unitID,SatelliteMount);
        local dx, _, dz = Spring.GetUnitDirection(unitID)
        local heading = Vector.Angle(dx, dz)
        
        satUnitID = Spring.CreateUnit('satellite',x,y,z,0,Spring.GetUnitTeam(unitID));
        Spring.SetUnitNoSelect(satUnitID,true);
        Spring.SetUnitNoMinimap(satUnitID,true);
        Spring.SetUnitNeutral(satUnitID,true);
        Spring.MoveCtrl.Enable(satUnitID);
        Spring.MoveCtrl.SetPosition(satUnitID,x,y,z);
        Spring.SetUnitRotation(satUnitID, 0, heading, 0);
        Spring.SetUnitLoadingTransport(satUnitID,unitID);
        Spring.SetUnitRulesParam(satUnitID,'cannot_damage_unit',unitID);
        Spring.SetUnitRulesParam(satUnitID,'untargetable',1);
        Spring.SetUnitRulesParam(unitID,'has_satellite',satUnitID);
        Spring.SetUnitCollisionVolumeData(satUnitID, 0,0,0, 0,0,0, -1,0,0);

        StartThread(SnapSatellite);
    end
    Signal(SIG_DOCK);
    StartThread(Undock);
end

function script.Deactivate()
    Signal(SIG_DOCK);
    StartThread(Dock);
    StartThread(SpiralDown);
	on = false
	Signal(SIG_AIM)
end


function script.AimWeapon(num, heading, pitch)
	if on and awake and num == 1 then
		Signal(SIG_AIM)
		SetSignalMask(SIG_AIM)
		
		local dx, _, dz = Spring.GetUnitDirection(satUnitID)
		local currentHeading = Vector.Angle(dx, dz)
		
        wantedDirection = -heading;
        
        CallSatelliteScript('mahlazer_AimAt',math.pi*1.5-pitch);
		
		Turn(SatelliteMuzzle, y_axis, 0)
		Turn(SatelliteMuzzle, x_axis, pitch, math.rad(1.2))
		WaitForTurn(SatelliteMuzzle, x_axis)
		return true
	end
	return false
end

function SnapSatellite()
    while true do
        local x,y,z = Spring.GetUnitPiecePosDir(unitID,SatelliteMount);
        Spring.MoveCtrl.SetPosition(satUnitID,x,y,z);
        Sleep(30);
    end
end

function script.QueryWeapon(num)
	return SatelliteMuzzle
end

function script.FireWeapon(num)
	shooting = 30
    CallSatelliteScript('mahlazer_SetShoot',shooting);
end

function script.AimFromWeapon(num)
	return SatelliteMuzzle
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
    if(satUnitID) then
        CallSatelliteScript("mahlazer_DisengageTheLaserBeam");
        Spring.SetUnitHealth(satUnitID,500);
        EmitSfx(Satellite, 1025);
        Spring.MoveCtrl.SetRotationVelocity(satUnitID,math.random(1,20)-10,math.random(1,20)-10,math.random(1,20)-10);
        Spring.MoveCtrl.Disable(satUnitID);
        Spring.AddUnitImpulse(satUnitID,math.random(1,10)-5,math.random(1,10)-5,math.random(1,10)-5)
    end
	if (severity <= .25) then
		Explode(Basis, SFX.NONE)
		return 1 -- corpsetype
	elseif (severity <= .5) then
		Explode(Basis, SFX.NONE)
		return 1 -- corpsetype
	else
		Explode(Basis, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
     
