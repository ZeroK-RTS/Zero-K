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

local l_gun = piece 'l_gun' 
local r_gun = piece 'r_gun' 

local smokePiece = {torso}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_ACTIVATE = 8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetGameFrame	 = Spring.GetGameFrame

local waveWeaponDef = WeaponDefNames["cormak_blast"]
local WAVE_RELOAD = math.ceil(waveWeaponDef.reload * Game.gameSpeed) -- 27
local WAVE_TIMEOUT = math.ceil(waveWeaponDef.damageAreaOfEffect / waveWeaponDef.explosionSpeed)* (1000 / Game.gameSpeed) + 200 -- empirically maximum delay of damage was (damageAreaOfEffect / explosionSpeed) - 4 frames

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		Move(torso, y_axis, 0.000000)
		Turn(Rleg, x_axis, 0)
		Turn(lowerRleg, x_axis, 0)
		Turn(Rfoot, x_axis, 0)
		Turn(Lleg, x_axis, 0)
		Turn(lowerLleg, x_axis, 0)
		Turn(Lfoot, x_axis, 0)
		Sleep(67)
	
		Move(torso, y_axis, 0.300000)
		Turn(Rleg, x_axis, math.rad(-10.000000))
		Turn(lowerRleg, x_axis, math.rad(-20.000000))
		Turn(Rfoot, x_axis, math.rad(20.000000))
		Turn(Lleg, x_axis, math.rad(10.000000))
		Turn(lowerLleg, x_axis, math.rad(20.000000))
		Turn(Lfoot, x_axis, math.rad(-20.000000))
		Sleep(67)
	
		Move(torso, y_axis, 0.700000)
		Turn(Rleg, x_axis, math.rad(-20.000000))
		Turn(lowerRleg, x_axis, math.rad(-30.005495))
		Turn(Rfoot, x_axis, math.rad(30.005495))
		Turn(lowerLleg, x_axis, math.rad(20.000000))
		Turn(Lfoot, x_axis, math.rad(-20.000000))
		Sleep(67)
	
		Move(torso, y_axis, 0.300000)
		Turn(Rleg, x_axis, math.rad(-30.005495))
		Turn(lowerRleg, x_axis, math.rad(-20.000000))
		Turn(Rfoot, x_axis, math.rad(40.005495))
		Turn(lowerLleg, x_axis, math.rad(30.005495))
		Turn(Lfoot, x_axis, math.rad(-30.005495))
		Sleep(67)
	
		Move(torso, y_axis, 0.000000)
		Turn(Rleg, x_axis, math.rad(-20.000000))
		Turn(lowerRleg, x_axis, math.rad(-10.000000))
		Turn(Rfoot, x_axis, math.rad(30.005495))
		Turn(lowerLleg, x_axis, math.rad(40.005495))
		Turn(Lfoot, x_axis, math.rad(-40.005495))
		Sleep(67)
	
		Move(torso, y_axis, -0.100000)
		Turn(Rleg, x_axis, 0)
		Turn(lowerRleg, x_axis, 0)
		Turn(Rfoot, x_axis, 0)
		Turn(Lleg, x_axis, 0)
		Turn(lowerLleg, x_axis, 0)
		Turn(Lfoot, x_axis, 0)
		Sleep(67)
	
		Move(torso, y_axis, -0.200000)
		Turn(Rleg, x_axis, math.rad(10.000000))
		Turn(lowerRleg, x_axis, math.rad(20.000000))
		Turn(Rfoot, x_axis, math.rad(-20.000000))
		Turn(Lleg, x_axis, math.rad(-10.000000))
		Turn(lowerLleg, x_axis, math.rad(-20.000000))
		Turn(Lfoot, x_axis, math.rad(20.000000))
		Sleep(67)

		Move(torso, y_axis, -0.300000)
		Turn(lowerRleg, x_axis, math.rad(20.000000))
		Turn(Rfoot, x_axis, math.rad(-20.000000))
		Turn(Lleg, x_axis, math.rad(-20.000000))
		Turn(lowerLleg, x_axis, math.rad(-30.005495))
		Turn(Lfoot, x_axis, math.rad(30.005495))
		Sleep(67)

		Move(torso, y_axis, -0.400000)
		Turn(lowerRleg, x_axis, math.rad(30.005495))
		Turn(Rfoot, x_axis, math.rad(-30.005495))
		Turn(Lleg, x_axis, math.rad(-30.005495))
		Turn(lowerLleg, x_axis, math.rad(-20.000000))
		Turn(Lfoot, x_axis, math.rad(40.005495))
		Sleep(67)

		Move(torso, y_axis, -0.500000)
		Turn(lowerRleg, x_axis, math.rad(40.005495))
		Turn(Rfoot, x_axis, math.rad(-40.005495))
		Turn(Lleg, x_axis, math.rad(-20.000000))
		Turn(lowerLleg, x_axis, math.rad(-10.000000))
		Turn(Lfoot, x_axis, math.rad(30.005495))
		Sleep(67)

		Move(torso, y_axis, 0.000000)
		Turn(lowerRleg, x_axis, 0, math.rad(200.000000))
		Turn(Rleg, x_axis, 0, math.rad(200.000000))
		Turn(Rfoot, x_axis, 0, math.rad(200.000000))
		Turn(Lleg, x_axis, 0)
		Turn(lowerLleg, x_axis, 0)
		Turn(Lfoot, x_axis, 0)
		Sleep(67)
	end
end

function script.Create()
	--Move(emit, y_axis, 20)
	StartThread(SmokeUnit, smokePiece)
end

function AutoAttack_Thread()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	while true do
		Sleep(100)
		local reloaded = select(2, spGetUnitWeaponState(unitID,3))
		if reloaded then
			local gameFrame = spGetGameFrame()
			local reloadMult = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1.0
			local reloadFrame = gameFrame + WAVE_RELOAD / reloadMult
			spSetUnitWeaponState(unitID, 3, {reloadFrame = reloadFrame})
			GG.PokeDecloakUnit(unitID,100)
			
			EmitSfx(emit, UNIT_SFX1)
			EmitSfx(emit, DETO_W2)
			FireAnim()
		end
	end
end

function FireAnim()
	
	local mspeed = 4
	Move (l_gun, x_axis, 2, mspeed*3)	
	Move (r_gun, x_axis, -2, mspeed*3)
	WaitForMove(l_gun, x_axis)
	WaitForMove(r_gun, x_axis)
	Sleep(1)
	Move (l_gun, x_axis, 0, mspeed)	
	Move (r_gun, x_axis, 0, mspeed)
	Sleep(1)
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
		EmitSfx(emit, UNIT_SFX1)
		EmitSfx(emit, DETO_W2)
		FireAnim()
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

local function Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, sfxNone)
		Explode(torso, sfxNone)
		Explode(Rleg, sfxNone)
		Explode(Lleg, sfxNone)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, sfxNone)
		Explode(Lfoot, sfxNone)
		return 1
	elseif severity <= .50 then
		Explode(base, sfxNone)
		Explode(torso, sfxNone)
		Explode(Rleg, sfxNone)
		Explode(Lleg, sfxNone)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, sfxNone)
		Explode(Lfoot, sfxNone)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, sfxNone)

		Explode(Rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(Lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(Lfoot, sfxNone)
		return 2
	else
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, sfxNone)
	
		Explode(Rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(Lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerRleg, sfxNone)
		Explode(lowerLleg, sfxNone)
		Explode(Rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(Lfoot, sfxNone)
		return 2
	end
end

function script.Killed(recentDamage, maxHealth)
	-- spawn debris etc.
	local wreckLevel = Killed(recentDamage, maxHealth)

	local ud = UnitDefs[unitDefID]
	local x, y, z = Spring.GetUnitPosition(unitID)

	-- hide unit
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitNoDraw(unitID, true)
	Spring.SetUnitNoMinimap(unitID, true)
	Spring.SetUnitSensorRadius(unitID, "los", 0)
	Spring.SetUnitSensorRadius(unitID, "airLos", 0)
	Spring.MoveCtrl.Enable(unitID, true)
	Spring.MoveCtrl.SetNoBlocking(unitID, true)
	Spring.MoveCtrl.SetPosition(unitID, x, Spring.GetGroundHeight(x, z) - 1000, z)

	-- spawn wreck
	local makeRezzable = (wreckLevel == 1)
	local wreckDef = FeatureDefNames[ud.wreckName]
	while (wreckLevel > 1 and wreckDef) do
		wreckDef = FeatureDefs[ wreckDef.deathFeatureID ]
		wreckLevel = wreckLevel - 1
	end
	if (wreckDef) then
		local heading = Spring.GetUnitHeading(unitID)
		local teamID	= Spring.GetUnitTeam(unitID)
		local featureID = Spring.CreateFeature(wreckDef.id, x, y, z, heading, teamID)
		if makeRezzable then
			Spring.SetFeatureResurrect(featureID, ud.name)
		end
		-- engine also sets speed and smokeTime for wrecks, but there are no lua functions for these
	end
	
	Sleep(WAVE_TIMEOUT) -- wait until all waves hit

	return 10 -- don't spawn second wreck
end
