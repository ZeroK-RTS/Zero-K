include 'constants.lua'

local base = piece 'base'
local pelvis = piece 'pelvis'
local torso = piece 'torso'
local emit = piece 'emit'
local fire = piece 'fire'
local lleg = piece 'lleg'
local rleg = piece 'rleg'
local lowerlleg = piece 'lowerlleg'
local lowerrleg = piece 'lowerrleg'
local lfoot = piece 'lfoot'
local rfoot = piece 'rfoot'

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
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetGameFrame       = Spring.GetGameFrame

local waveWeaponDef = WeaponDefNames["shieldriot_blast"]
local WAVE_RELOAD = math.floor(waveWeaponDef.reload * Game.gameSpeed)
local WAVE_TIMEOUT = math.ceil(waveWeaponDef.damageAreaOfEffect / waveWeaponDef.explosionSpeed)* (1000 / Game.gameSpeed) + 200 -- empirically maximum delay of damage was (damageAreaOfEffect / explosionSpeed) - 4 frames

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local PACE = 2.8

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(pelvis, y_axis, 2, PACE*2)
	Turn(lleg, x_axis, math.rad(20),  PACE*math.rad(50))
	Turn(rleg, x_axis, math.rad(-20), PACE*math.rad(50))
	Turn(lfoot,  x_axis, math.rad(-15), PACE*math.rad(70))
	Turn(rfoot,  x_axis, math.rad(5),   PACE*math.rad(50))
	Turn(lowerrleg,  x_axis, math.rad(-15), PACE*math.rad(70))
	Sleep(360/PACE)
	
	Turn(lfoot,  x_axis, math.rad(20),  PACE*math.rad(100))
	Turn(rfoot,  x_axis, math.rad(10),  PACE*math.rad(50))
	Turn(lowerrleg,  x_axis, math.rad(20),  PACE*math.rad(100))
	Sleep(360/PACE)
	
	Move(pelvis, y_axis, 2.5, PACE*2)
	Turn(pelvis, z_axis, math.rad(-3.5), PACE*math.rad(3))
	Turn(lleg, x_axis, math.rad(-20),  PACE*math.rad(50))
	Turn(rleg, x_axis, math.rad(20),   PACE*math.rad(50))
	Turn(rfoot,  x_axis, math.rad(-20),  PACE*math.rad(130))
	Turn(lowerlleg,  x_axis, math.rad(-25),  PACE*math.rad(100))
	Sleep(650/PACE)
	
	Turn(rfoot,  x_axis, math.rad(20),   PACE*math.rad(100))
	Turn(lowerlleg,  x_axis, math.rad(20),   PACE*math.rad(100))
	Move(pelvis, y_axis, 0, 2)
	Sleep(360/PACE)
	
	while true do
		Move(pelvis, y_axis, 3.2, PACE*2)
		Turn(pelvis, z_axis, math.rad(3.5), PACE*math.rad(8))
		
		Turn(rleg, x_axis, math.rad(-24), PACE*math.rad(70))
		Turn(lowerrleg,  x_axis, math.rad(-20), PACE*math.rad(100))
		Turn(lleg, x_axis, math.rad(20),  PACE*math.rad(70))
		Turn(lfoot,  x_axis, math.rad(-40), PACE*math.rad(50))
		
		Sleep(650/PACE)
		
		Turn(lfoot,  x_axis, math.rad(20),  PACE*math.rad(80))
		Turn(lowerrleg,  x_axis, math.rad(30),  PACE*math.rad(100))
		Turn(rfoot,  x_axis, math.rad(-5),  PACE*math.rad(80))
		Move(pelvis, y_axis, 0, PACE*2)
		Sleep(360/PACE)
		
		Move(pelvis, y_axis, 3.2, PACE*2)
		Turn(pelvis, z_axis, math.rad(-3.50), PACE*math.rad(8))
		
		Turn(lleg, x_axis, math.rad(-24),   PACE*math.rad(70))
		Turn(lowerlleg,  x_axis, math.rad(-20),   PACE*math.rad(100))
		Turn(rleg, x_axis, math.rad(20),    PACE*math.rad(70))
		Turn(rfoot,  x_axis, math.rad(-40),   PACE*math.rad(50))
		
		Sleep(650/PACE)
		
		Turn(rfoot, x_axis, math.rad(20), PACE*math.rad(80))
		Turn(lowerlleg, x_axis, math.rad(30), PACE*math.rad(100))
		Turn(lfoot,  x_axis, math.rad(-5),  PACE*math.rad(80))
		Move(pelvis, y_axis, 0, PACE*2)
		Sleep(360/PACE)
	end
end

function script.Create()
	--Move(emit, y_axis, 20)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function AutoAttack_Thread()
	Signal(SIG_ACTIVATE)
	SetSignalMask(SIG_ACTIVATE)
	while true do
		Sleep(100)
		local reloaded = select(2, spGetUnitWeaponState(unitID,3))
		if reloaded then
			local height = select(5, Spring.GetUnitPosition(unitID, true))
			if height > -8 then -- Matches offset of AimFromWeapon position for FAKEGUN2
				local gameFrame = spGetGameFrame()
				local reloadMult = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1.0
				local reloadFrame = gameFrame + WAVE_RELOAD / reloadMult
				spSetUnitWeaponState(unitID, 3, {reloadFrame = reloadFrame})
				GG.PokeDecloakUnit(unitID, unitDefID)
				
				EmitSfx(emit, GG.Script.UNIT_SFX1)
				EmitSfx(emit, GG.Script.DETO_W2)
				FireAnim()
			end
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
	Turn(lleg, x_axis, 0,  PACE*math.rad(50))
	Turn(rleg, x_axis, 0, PACE*math.rad(50))
	Turn(lfoot,  x_axis, 0, PACE*math.rad(70))
	Turn(rfoot,      x_axis, 0,   PACE*math.rad(50))
	Turn(lowerrleg,  x_axis, 0,  PACE*math.rad(100))
	Turn(lowerlleg,  x_axis, 0, PACE*math.rad(70))
	
	Move(pelvis, y_axis, 0, PACE*10)
	Turn(pelvis, z_axis, 0, PACE*math.rad(8))
	
	Signal(SIG_WALK)
end

function script.FireWeapon(num)
	if num == 3 then
		EmitSfx(emit, GG.Script.UNIT_SFX1)
		EmitSfx(emit, GG.Script.DETO_W2)
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
		Explode(base, SFX.NONE)
		Explode(torso, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(torso, SFX.NONE)
		Explode(rleg, SFX.NONE)
		Explode(lleg, SFX.NONE)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(lfoot, SFX.NONE)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, SFX.NONE)

		Explode(rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.NONE)
		return 2
	else
		Explode(base, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(torso, SFX.NONE)
	
		Explode(rleg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lleg, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lowerrleg, SFX.NONE)
		Explode(lowerlleg, SFX.NONE)
		Explode(rfoot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(lfoot, SFX.NONE)
		return 2
	end
end

function script.Killed(recentDamage, maxHealth)
	Signal(SIG_ACTIVATE) -- prevent pulsing while undead

	-- keep the unit technically alive (but hidden) for some time so that any inbound
	-- pulses know who their owner is (so that they can do no damage to allies)
	return GG.Script.DelayTrueDeath(unitID, unitDefID, recentDamage, maxHealth, Killed, WAVE_TIMEOUT)
end
