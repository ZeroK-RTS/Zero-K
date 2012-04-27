include 'constants.lua'

local base = piece 'base' 
local pelvis = piece 'pelvis' 
local torso = piece 'torso' 
local emit = piece 'emit' 
local fire = piece 'fire' 
local Lleg = piece 'lleg' 
local Rleg = piece 'rleg' 
local lowerLleg = piece 'lowerlleg' 
local lowerRleg = piece 'lowerrleg' 
local Lfoot = piece 'lfoot' 
local Rfoot = piece 'rfoot' 

smokePiece = {torso}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_ACTIVATE = 8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		Move( torso , y_axis, 0.000000  )
		Turn( Rleg , x_axis, 0 )
		Turn( lowerRleg , x_axis, 0 )
		Turn( Rfoot , x_axis, 0 )
		Turn( Lleg , x_axis, 0 )
		Turn( lowerLleg , x_axis, 0 )
		Turn( Lfoot , x_axis, 0 )
		Sleep(67)
	
		Move( torso , y_axis, 0.300000  )
		Turn( Rleg , x_axis, math.rad(-10.000000) )
		Turn( lowerRleg , x_axis, math.rad(-20.000000) )
		Turn( Rfoot , x_axis, math.rad(20.000000) )
		Turn( Lleg , x_axis, math.rad(10.000000) )
		Turn( lowerLleg , x_axis, math.rad(20.000000) )
		Turn( Lfoot , x_axis, math.rad(-20.000000) )
		Sleep(67)
	
		Move( torso , y_axis, 0.700000  )
		Turn( Rleg , x_axis, math.rad(-20.000000) )
		Turn( lowerRleg , x_axis, math.rad(-30.005495) )
		Turn( Rfoot , x_axis, math.rad(30.005495) )
		Turn( lowerLleg , x_axis, math.rad(20.000000) )
		Turn( Lfoot , x_axis, math.rad(-20.000000) )
		Sleep(67)
	
		Move( torso , y_axis, 0.300000  )
		Turn( Rleg , x_axis, math.rad(-30.005495) )
		Turn( lowerRleg , x_axis, math.rad(-20.000000) )
		Turn( Rfoot , x_axis, math.rad(40.005495) )
		Turn( lowerLleg , x_axis, math.rad(30.005495) )
		Turn( Lfoot , x_axis, math.rad(-30.005495) )
		Sleep(67)
	
		Move( torso , y_axis, 0.000000  )
		Turn( Rleg , x_axis, math.rad(-20.000000) )
		Turn( lowerRleg , x_axis, math.rad(-10.000000) )
		Turn( Rfoot , x_axis, math.rad(30.005495) )
		Turn( lowerLleg , x_axis, math.rad(40.005495) )
		Turn( Lfoot , x_axis, math.rad(-40.005495) )
		Sleep(67)
	
		Move( torso , y_axis, -0.100000  )
		Turn( Rleg , x_axis, 0 )
		Turn( lowerRleg , x_axis, 0 )
		Turn( Rfoot , x_axis, 0 )
		Turn( Lleg , x_axis, 0 )
		Turn( lowerLleg , x_axis, 0 )
		Turn( Lfoot , x_axis, 0 )
		Sleep(67)
	
		Move( torso , y_axis, -0.200000  )
		Turn( Rleg , x_axis, math.rad(10.000000) )
		Turn( lowerRleg , x_axis, math.rad(20.000000) )
		Turn( Rfoot , x_axis, math.rad(-20.000000) )
		Turn( Lleg , x_axis, math.rad(-10.000000) )
		Turn( lowerLleg , x_axis, math.rad(-20.000000) )
		Turn( Lfoot , x_axis, math.rad(20.000000) )
		Sleep(67)

		Move( torso , y_axis, -0.300000  )
		Turn( lowerRleg , x_axis, math.rad(20.000000) )
		Turn( Rfoot , x_axis, math.rad(-20.000000) )
		Turn( Lleg , x_axis, math.rad(-20.000000) )
		Turn( lowerLleg , x_axis, math.rad(-30.005495) )
		Turn( Lfoot , x_axis, math.rad(30.005495) )
		Sleep(67)

		Move( torso , y_axis, -0.400000  )
		Turn( lowerRleg , x_axis, math.rad(30.005495) )
		Turn( Rfoot , x_axis, math.rad(-30.005495) )
		Turn( Lleg , x_axis, math.rad(-30.005495) )
		Turn( lowerLleg , x_axis, math.rad(-20.000000) )
		Turn( Lfoot , x_axis, math.rad(40.005495) )
		Sleep(67)

		Move( torso , y_axis, -0.500000  )
		Turn( lowerRleg , x_axis, math.rad(40.005495) )
		Turn( Rfoot , x_axis, math.rad(-40.005495) )
		Turn( Lleg , x_axis, math.rad(-20.000000) )
		Turn( lowerLleg , x_axis, math.rad(-10.000000) )
		Turn( Lfoot , x_axis, math.rad(30.005495) )
		Sleep(67)

		Move( torso , y_axis, 0.000000  )
		Turn( lowerRleg , x_axis, 0, math.rad(200.000000) )
		Turn( Rleg , x_axis, 0, math.rad(200.000000) )
		Turn( Rfoot , x_axis, 0, math.rad(200.000000) )
		Turn( Lleg , x_axis, 0 )
		Turn( lowerLleg , x_axis, 0 )
		Turn( Lfoot , x_axis, 0 )
		Sleep(67)
	end
end

function script.Create()
	StartThread(SmokeUnit)
end

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetGameFrame = Spring.GetGameFrame
local RELOAD_FRAMES = 27

function AutoAttack_Thread()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	while true do
		Sleep(100)
		local reloaded = select(2,spGetUnitWeaponState(unitID,2))
		if reloaded then
			local frame
			local reloadMult = GG.att_reload[unitID]
			if reloadMult then
				frame = spGetGameFrame()+RELOAD_FRAMES/reloadMult
			else
				frame = spGetGameFrame()+RELOAD_FRAMES
			end
			spSetUnitWeaponState(unitID,2,{reloadFrame = frame})
			EmitSfx( emit,  4097 )
		end
	end
end

function script.Activate()
  StartThread(AutoAttack_Thread)
end

function script.Deactivate()
  Signal(SIG_ACTIVATE)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
end

function script.FireWeapon(num)
	if num == 3 then
		EmitSfx( emit,  4097 )
	end
end

function script.AimFromWeapon(num)
	return torso
end

function script.AimWeapon(num, heading, pitch)
	return num == 3
end

function script.QueryWeapon(num)
	return emit
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(torso, sfxNone)
		Explode(Rleg, sfxNone)
		Explode(Lleg, sfxNone)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, sfxNone)
		Explode(Lfoot, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(torso, sfxNone)
		Explode(Rleg, sfxNone)
		Explode(Lleg, sfxNone)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, sfxNone)
		Explode(Lfoot, sfxNone)
		return 1
	elseif  severity <= .99  then
		Explode(base, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(torso, sfxNone)

		Explode(Rleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(Lleg, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(Lfoot, sfxNone)
		return 2
	else
		Explode(base, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(torso, sfxNone)
	
		Explode(Rleg, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(Lleg, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, SFX.SHATTER + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		Explode(Lfoot, sfxNone)
		return 2
	end
end
