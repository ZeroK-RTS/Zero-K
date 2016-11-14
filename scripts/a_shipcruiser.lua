--Stupid dumb Bos converted to amazing awesome Lua (see http://packages.springrts.com/bos2lua/index.php)

--linear constant 65536

include 'constants.lua'


--------------------------------------------------------------------
--pieces
--------------------------------------------------------------------
local base, body, sonar, propeller, turret, sleeve1, sleeve2, barrel1, barrel2, fire1, fire2 = piece('base', 'body', 'sonar', 'propeller', 'turret', 'sleeve1', 'sleeve2', 'barrel1', 'barrel2', 'fire1', 'fire2')

local radarpole, radardish, depthcharge1, depthcharge2, depthcharge3, depthcharge4, depthcharge5, depthchargefire, wake1, wake2, wake3, wake4 = piece('radarpole', 'radardish', 'depthcharge1', 'depthcharge2', 'depthcharge3', 'depthcharge4', 'depthcharge5', 'depthchargefire', 'wake1', 'wake2', 'wake3', 'wake4')



--------------------------------------------------------------------
--constants
--------------------------------------------------------------------
local smokePiece = {body, sonar, propeller, turret}

-- Signal definitions
local SIG_AIM = 4
local SIG_MOVE = 1

-- local DEPTHCHARGE_Y = 0.9
-- local DEPTHCHARGE_Z = 3.95
-- local DEPTHCHARGE_ROLL = <-115>
-- local DEPTHCHARGE_LIFT = 16
-- local DEPTHCHARGE_LOAD_Y = 3.6
-- local DEPTHCHARGE_LOAD_Z = 15.8
-- local DEPTHCHARGE_LOAD_ROLL = -460

--rockz
include 'RockPiece.lua'

local ROCK_PIECE = base	-- should be negative to alternate rocking direction
local ROCK_Z_SPEED = 3		--number of quarter-cycles per second around z-axis
local ROCK_Z_DECAY = -1/2	--rocking around z-axis is reduced by this factor each time' 
local ROCK_Z_MIN = math.rad(3)	--if around z-axis rock is not greater than this amount rocking will stop after returning to center
local ROCK_Z_MAX = math.rad(15)
local SIG_ROCK_Z = 16		--Signal( to prevent multiple rocking

local ROCK_Z_FIRE_1 = -5
local ROCK_FORCE = 0.1

local unitDefID = Spring.GetUnitDefID(unitID)
local wd1 = UnitDefs[unitDefID].weapons[1] and UnitDefs[unitDefID].weapons[1].weaponDef
local reloadTime1 = wd1 and WeaponDefs[wd1].reload*30 or 30

local wd2 = UnitDefs[unitDefID].weapons[2] and UnitDefs[unitDefID].weapons[2].weaponDef
local reloadTime2 = wd2 and WeaponDefs[wd2].reload*30 or 30
--------------------------------------------------------------------
--variables
--------------------------------------------------------------------
local gun_1 = 0
local restore_delay = 3000
--local bMoving,
local gun_1_yaw = 0
local dead = false


-- SmokeUnit(healthpercent, Sleep(time, smoketype)

	-- while  get BUILD_PERCENT_LEFT  do
	
		-- sleep 400)
	-- end
	-- while  true  do
	
		-- healthpercent = get HEALTH)
		-- if  healthpercent < 66  then
		
			-- smoketype = 256 + sfx2
			-- if  1, 66 ) < healthpercent  then
			
				-- smoketype = 256 + sfx1
			-- end
			-- EmitSfx( base,  smoketype )
		-- end
		-- Sleep(time = healthpercent * 50)
		-- if  Sleep(time < 200  then
		
			-- sleeptime = 200)
		-- end
		-- Sleep( sleeptime)
	-- end
-- end

-- EmitWakes()

	-- while  true  do
	
		-- if  bMoving  then
		
			-- EmitSfx( wake1,  2 )
			-- EmitSfx( wake2,  2 )
			-- EmitSfx( wake3,  2 )
			-- EmitSfx( wake4,  2 )
			-- EmitSfx( propeller,  259 )
		-- end
		-- Sleep( 150)
	-- end
-- end

local function Wake()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			EmitSfx(wake1, 2)
			EmitSfx(wake2, 2)
			EmitSfx(wake3, 2)
			EmitSfx(wake4, 2)
			EmitSfx( propeller,  259 )
		end
		Sleep(150)
	end
end

function script.Create()
	--gun_1 = 0
	--bMoving = false
	--restore_delay = 3000
	Hide( radardish)
	StartThread(SmokeUnit, smokePiece)
	Spin( sonar , y_axis, math.rad(60) )
	Spin( radarpole , y_axis, math.rad(-90) )
	InitializeRock(ROCK_PIECE, ROCK_Z_SPEED, ROCK_Z_DECAY, ROCK_Z_MIN, ROCK_Z_MAX, SIG_ROCK_Z, z_axis)
end

-- SetMaxReloadTime(Func_Var_1)

	-- restore_delay = Func_Var_1 * 2
-- end

local function RestoreAfterDelay()
	Sleep(restore_delay)
	if dead then return false end
	Turn( turret , y_axis, 0, math.rad(35.000000) )
	Turn( sleeve1 , x_axis, 0, math.rad(15.000000) )
	Turn( sleeve2 , x_axis, 0, math.rad(15.000000) )
end

-- function script.StartMoving()
	-- StartThread(Wake)
-- end

-- function script.StopMoving()
	-- Signal(SIG_Move)
-- end

function script.StartMoving()
	StartThread(Wake)
	--Signal( SIG_MOVE)
	--SetSignalMask( SIG_MOVE)

	-- bMoving = true
	Spin( propeller , z_axis, math.rad(720) )
end

function script.StopMoving()
	Signal( SIG_MOVE)
	--SetSignalMask( SIG_MOVE)

	-- bMoving = false
	Spin( propeller , z_axis, math.rad(0.01) ) -- should stop
end

-- function script.AimWeapon2(heading, pitch)
	-- return (1)
-- end

-- FireWeapon2() 
	-- return (0)
-- end

-- function script.Shot2()
	-- Move( depthcharge1 , y_axis, DEPTHCHARGE_Y  )
	-- Move( depthcharge2 , y_axis, DEPTHCHARGE_Y  )
	-- Move( depthcharge3 , y_axis, DEPTHCHARGE_Y  )
	-- Move( depthcharge4 , y_axis, DEPTHCHARGE_Y  )
	
	-- Move( depthcharge1 , z_axis, DEPTHCHARGE_Z  )
	-- Move( depthcharge2 , z_axis, DEPTHCHARGE_Z  )
	-- Move( depthcharge3 , z_axis, DEPTHCHARGE_Z  )
	-- Move( depthcharge4 , z_axis, DEPTHCHARGE_Z  )
	
	-- Move( depthcharge5 , y_axis, -12  )
	-- Move( depthcharge5 , z_axis, 4.5  )
	
	-- Spin( depthcharge1 , x_axis, DEPTHCHARGE_ROLL
 -- )
	-- Spin( depthcharge2 , x_axis, DEPTHCHARGE_ROLL
 -- )
	-- Spin( depthcharge3 , x_axis, DEPTHCHARGE_ROLL
 -- )
	-- Spin( depthcharge4 , x_axis, DEPTHCHARGE_ROLL
 -- )
	
	-- Move( depthcharge1 , y_axis, 0 , DEPTHCHARGE_Y )
	-- Move( depthcharge2 , y_axis, 0 , DEPTHCHARGE_Y )
	-- Move( depthcharge3 , y_axis, 0 , DEPTHCHARGE_Y )
	-- Move( depthcharge4 , y_axis, 0 , DEPTHCHARGE_Y )
	
	-- Move( depthcharge1 , z_axis, 0 , DEPTHCHARGE_Z )
	-- Move( depthcharge2 , z_axis, 0 , DEPTHCHARGE_Z )
	-- Move( depthcharge3 , z_axis, 0 , DEPTHCHARGE_Z )
	-- Move( depthcharge4 , z_axis, 0 , DEPTHCHARGE_Z )
	
	-- Move( depthcharge5 , y_axis, DEPTHCHARGE_Y , DEPTHCHARGE_LIFT )
	-- WaitForMove(depthcharge5, y_axis)
	-- Move( depthcharge5 , z_axis, DEPTHCHARGE_Z , DEPTHCHARGE_LIFT )
	-- WaitForMove(depthcharge5, z_axis)
	-- Move( depthcharge5 , y_axis, 0 , DEPTHCHARGE_LOAD_Y )
	-- Move( depthcharge5 , z_axis, 0 , DEPTHCHARGE_LOAD_Z )
	-- Spin( depthcharge5 , x_axis, DEPTHCHARGE_LOAD_ROLL
 -- )
	
	-- WaitForMove(depthcharge1, z_axis)
	-- WaitForMove(depthcharge2, z_axis)
	-- WaitForMove(depthcharge3, z_axis)
	-- WaitForMove(depthcharge4, z_axis)
	-- WaitForMove(depthcharge5, z_axis)
	
	-- stop-spin depthcharge1 around x-axis
	-- stop-spin depthcharge2 around x-axis
	-- stop-spin depthcharge3 around x-axis
	-- stop-spin depthcharge4 around x-axis
	-- stop-spin depthcharge5 around x-axis
-- end

-- function script.AimFromWeapon2(piecenum)

	-- piecenum = depthchargefire
-- end

-- function script.QueryWeapon2(piecenum)

	-- piecenum = depthchargefire
-- end

function script.AimWeapon(num, heading, pitch)
	if dead then return false end
	
	local states = Spring.GetUnitStates(unitID)
	
	if (states.active and num == 2) or (not states.active and num == 1 ) then
		return false
	end
	
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(150.000000) )
	Turn( sleeve1 , x_axis, -pitch, math.rad(40.000000) )
	Turn( sleeve2 , x_axis, -pitch, math.rad(40.000000) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve1, x_axis)
	WaitForTurn(sleeve2, x_axis)
	StartThread(RestoreAfterDelay)
	gun_1_yaw = heading
	return true
end

function script.FireWeapon(num) 
	--put the other weapon on cd equal to second weapon's cd
	local toChange = 3 - num
	local reloadSpeedMult = Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1
	if reloadSpeedMult <= 0 then
		-- Safety for div0. In theory a unit with reloadSpeedMult = 0 cannot fire because it never reloads.
		reloadSpeedMult = 1
	end
	local reloadTimeMult = 1/reloadSpeedMult
	
	if num == 1 then
		Spring.SetUnitWeaponState(unitID, toChange, "reloadFrame", Spring.GetGameFrame() + reloadTime1*reloadTimeMult)
	else
		Spring.SetUnitWeaponState(unitID, toChange, "reloadFrame", Spring.GetGameFrame() + reloadTime2*reloadTimeMult)
	end
	
	StartThread(Rock, gun_1_yaw, ROCK_FORCE, z_axis)
	
	gun_1 = 1 - gun_1
	
	if  gun_1 == 0 then 
		Show( fire1)
		Hide( fire1)
		Move( barrel1 , z_axis, -8  )
		Move( barrel1 , z_axis, 0 , 8.000000 )
	else 
		Show( fire2)
		Hide( fire2)
		Move( barrel2 , z_axis, -8  )
		Move( barrel2 , z_axis, 0 , 8.000000 )
	end
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num) 
	if gun_1 then 
		return fire1
	else 
		return fire2
	end
end

function script.SweetSpot(num)
	return base
end

--function script.Killed(severity, corpsetype)

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	Explode( body, sfxShatter)
	if  severity <= 0.25  then 
		--Explode( turret, sfxShatter)
		--Explode( barrel1, sfxShatter)
		--Explode( barrel2, sfxShatter)
		--Explode( depthcharge1, sfxShatter)
		return 1
	elseif  severity <= 0.50  then 
		--Explode( turret, sfxShatter)
		Explode( sleeve1, sfxFall)
		Explode( sleeve2, sfxFall)
		Explode( barrel1, sfxFall)
		Explode( barrel2, sfxFall)
		Explode( depthcharge1, sfxFall)
		Explode( depthcharge2, sfxFall)
		Explode( depthcharge3, sfxFall)
		Explode( depthcharge4, sfxFall)
		Explode( depthcharge5, sfxFall)
		Explode( radarpole, sfxFall)
		Explode( radardish, sfxFall)
		Explode( propeller, sfxFall)
		return 1
	else 
		Explode( turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( sleeve1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( sleeve2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( barrel1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( barrel2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( depthcharge1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( depthcharge2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( depthcharge3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( depthcharge4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( depthcharge5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( radarpole, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( radardish, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		Explode( propeller, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxShatter)
		return 2
	end
end

-- function script.Killed(recentDamage, maxHealth)
	-- local severity = recentDamage/maxHealth
	-- Explode( body, sfxBITMAPONLY + sfxBITMAP1)
	-- if  severity <= 25  then 
		-- Explode( turret, sfxBITMAPONLY + sfxBITMAP1)
		-- Explode( barrel1, sfxBITMAPONLY + sfxBITMAP1)
		-- Explode( barrel2, sfxBITMAPONLY + sfxBITMAP1)
		-- Explode( depthcharge1, sfxBITMAPONLY + sfxBITMAP1)
		-- return 1
	-- elseif  severity <= 50  then 
		-- Explode( turret, sfxBITMAPONLY + sfxBITMAP1)
		-- Explode( sleeve1, sfxFall + sfxBITMAP1)
		-- Explode( sleeve2, sfxFall + sfxBITMAP1)
		-- Explode( barrel1, sfxFall + sfxBITMAP1)
		-- Explode( barrel2, sfxFall + sfxBITMAP1)
		-- Explode( depthcharge1, sfxFall + sfxBITMAP1)
		-- Explode( depthcharge2, sfxFall + sfxBITMAP1)
		-- Explode( depthcharge3, sfxFall + sfxBITMAP1)
		-- Explode( depthcharge4, sfxFall + sfxBITMAP1)
		-- Explode( depthcharge5, sfxFall + sfxBITMAP1)
		-- Explode( radarpole, sfxFall + sfxBITMAP1)
		-- Explode( radardish, sfxFall + sfxBITMAP1)
		-- Explode( propeller, sfxFall + sfxBITMAP1)
		-- return 1
	-- else 
		-- Explode( turret, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( sleeve1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( sleeve2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( barrel1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( barrel2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( depthcharge1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( depthcharge2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( depthcharge3, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( depthcharge4, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( depthcharge5, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( radarpole, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( radardish, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- Explode( propeller, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit + sfxBITMAP1)
		-- return 2
	-- end
-- end
