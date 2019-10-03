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
include "rockPiece.lua"
local dynamicRockData

local ROCK_PIECE = base	-- should be negative to alternate rocking direction
local ROCK_SPEED = 3		--number of quarter-cycles per second around z-axis
local ROCK_DECAY = -1/2	--rocking around z-axis is reduced by this factor each time'
local ROCK_MIN = math.rad(3)	--if around z-axis rock is not greater than this amount rocking will stop after returning to center
local ROCK_MAX = math.rad(15)
local SIG_ROCK_Z = 16		--Signal( to prevent multiple rocking

local ROCK_FORCE = 0.1

local rockData = {
	[z_axis] = {
		piece = ROCK_PIECE,
		speed = ROCK_SPEED,
		decay = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_Z,
		axis = z_axis,
	},
}

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
	Hide( radardish)
	Hide( depthcharge1)
	Hide( depthcharge2)
	Hide( depthcharge3)
	Hide( depthcharge4)
	Hide( depthcharge5)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spin( sonar , y_axis, math.rad(60) )
	Spin( radarpole , y_axis, math.rad(-90) )
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
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

	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(50.000000) )
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
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gun_1_yaw, ROCK_FORCE)

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

function script.EndBurst()
	gun_1 = 1 - gun_1
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	if gun_1 == 1 then
		return fire2
	else
		return fire1
	end
end

function script.BlockShot(num, targetID)
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, 600.1, 95, false, false, true) then
		return true
	end
	return false
end

function script.SweetSpot(num)
	return base
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	Explode( body, SFX.SHATTER)
	if  severity <= 0.25  then
		return 1
	elseif  severity <= 0.50  then
		Explode( sleeve1, SFX.FALL)
		Explode( sleeve2, SFX.FALL)
		Explode( barrel1, SFX.FALL)
		Explode( barrel2, SFX.FALL)
		Explode( depthcharge1, SFX.FALL)
		Explode( depthcharge2, SFX.FALL)
		Explode( depthcharge3, SFX.FALL)
		Explode( depthcharge4, SFX.FALL)
		Explode( depthcharge5, SFX.FALL)
		Explode( radarpole, SFX.FALL)
		Explode( radardish, SFX.FALL)
		Explode( propeller, SFX.FALL)
		return 1
	else
		Explode( turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( sleeve1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( sleeve2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( barrel1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( barrel2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( depthcharge1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( depthcharge2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( depthcharge3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( depthcharge4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( depthcharge5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( radarpole, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( radardish, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		Explode( propeller, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT + SFX.SHATTER)
		return 2
	end
end
