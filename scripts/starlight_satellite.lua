include "constants.lua"
include "pieceControl.lua"

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

local InnerLimbs = {LimbA1,LimbB1,LimbC1,LimbD1}
local OuterLimbs = {LimbA2,LimbB2,LimbC2,LimbD2}

local SIG_DOCK  = 2
local SIG_SHOOT = 4
local SIG_WATCH = 8

local on = false
local shooting = 0

local parentUnitID

local function MonitorHost()
	SetSignalMask(SIG_WATCH)
	while true do
		if(parentUnitID) then
			if not Spring.ValidUnitID(parentUnitID) then
				on = false
				Signal(SIG_DOCK+SIG_SHOOT)
				Spring.SetUnitHealth(unitID, 500)
				EmitSfx(Satellite, 1025)
				Spring.MoveCtrl.SetRotationVelocity(unitID, math.random(1, 20) - 10,math.random(1, 20) - 10,math.random(1, 20) - 10)
				Spring.MoveCtrl.Disable(unitID)
				Spring.AddUnitImpulse(unitID, math.random(1, 10) - 5, math.random(1, 10) - 5, math.random(1, 10) - 5)
				Spring.SetUnitNoSelect(unitID, false)
				Spring.SetUnitNoMinimap(unitID, false)
				Spring.SetUnitNeutral(unitID, false)
				Spring.SetUnitRulesParam(unitID, 'untargetable', nil)
				Spring.SetUnitCollisionVolumeData(unitID, 30, 30, 30, 10, 0, 0, 0, 0, 0)
				GG.starlightSatelliteInvulnerable[unitID] = false
				return
			end
		else
			parentUnitID = Spring.GetUnitRulesParam(unitID,'cannot_damage_unit')
			--if not parentUnitID then return end
		end
		Sleep(33)
	end
end

function script.Create()
	--Move(Satellite, y_axis, -10)
	--Spin(Satellite, x_axis, math.rad(80))
	StartThread(MonitorHost)
	GG.starlightSatelliteInvulnerable = GG.starlightSatelliteInvulnerable or {}
	GG.starlightSatelliteInvulnerable[unitID] = true
end

local function Dock()
	SetSignalMask(SIG_DOCK)
	for i=1,4 do
		Turn(InnerLimbs[i],y_axis,math.rad(0),1)
		Turn(OuterLimbs[i],y_axis,math.rad(0),1)
	end
end

local function Undock()
	SetSignalMask(SIG_DOCK)
	for i=1,4 do
		Turn(InnerLimbs[i],y_axis,math.rad(-85),1)
		Turn(OuterLimbs[i],y_axis,math.rad(-85),1)
	end
end

local function EmitShot()
	if not parentUnitID then
		return
	end
	
	if GG.Starlight_DamageFrame[parentUnitID] then
		local frame = Spring.GetGameFrame()
		if frame <= GG.Starlight_DamageFrame[parentUnitID] + 1 then
			return
		end
		GG.Starlight_DamageFrame[parentUnitID] = nil
	end
	
	if shooting ~= 0 then
		EmitSfx(SatelliteMuzzle, GG.Script.FIRE_W1)
		shooting = shooting - 1
	else
		EmitSfx(SatelliteMuzzle, GG.Script.FIRE_W2)
	end
end

function Shoot()
	SetSignalMask(SIG_SHOOT)
	while(on) do
		EmitShot()
		Sleep(30)
	end
end

function mahlazer_SetShoot(n)
	shooting = n
end

function mahlazer_Hide()
	for i=1,4 do
		Hide(InnerLimbs[i])
		Hide(OuterLimbs[i])
	end
	Hide(Satellite)
end

function mahlazer_Show()
	for i = 1, 4 do
		Show(InnerLimbs[i])
		Show(OuterLimbs[i])
	end
	Show(Satellite)
end

-- prepare the laser beam, i'm gonna use it tonite
function mahlazer_EngageTheLaserBeam() -- it's gonna END YOUR LIFE
	on = true
	Signal(SIG_SHOOT)
	StartThread(Shoot)
end

function mahlazer_DisengageTheLaserBeam()
	Signal(SIG_SHOOT)
	on = false
end

function mahlazer_StopAim()
	GG.PieceControl.StopTurn(SatelliteMuzzle, x_axis)
	GG.PieceControl.StopTurn(Satellite, x_axis)
end

function mahlazer_AimAt(pitch, speed)
	Turn(SatelliteMuzzle, x_axis, pitch, speed)
	Turn(Satellite, x_axis, pitch/2, speed*0.5)
end

function mahlazer_Undock()
	Signal(SIG_DOCK)
	StartThread(Undock)
end

function mahlazer_Dock()
	Signal(SIG_DOCK)
	StartThread(Dock)
end

function script.AimWeapon(num, heading, pitch)
	return false
end

function script.FireWeapon(num)
	return false
end

function script.AimFromWeapon(num)
	return SatelliteMuzzle
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.25) then
		Explode(Satellite, SFX.SHATTER)
		return 0 -- corpsetype
	elseif (severity <= 0.5) then
		Explode(Satellite, SFX.SHATTER)
		return 1 -- corpsetype
	else
		Explode(Satellite, SFX.SHATTER)
		return 2 -- corpsetype
	end
end
