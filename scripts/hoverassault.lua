local base = piece 'base' 
local shield = piece 'shield' 
local turret = piece 'turret' 
local gun = piece 'gun' 
local flare1 = piece 'flare1' 
local flare2 = piece 'flare2' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 
local wake3 = piece 'wake3' 
local wake4 = piece 'wake4' 
local wake5 = piece 'wake5' 
local wake6 = piece 'wake6' 
local wake7 = piece 'wake7' 
local wake8 = piece 'wake8' 
local ground1 = piece 'ground1' 
local door1 = piece 'door1' 
local door2 = piece 'door2' 
local turretbase = piece 'turretbase' 
local rim1 = piece 'rim1' 
local rim2 = piece 'rim2' 

include "constants.lua"
include "RockPiece.lua"

local shootCycle = 0
local gunHeading = 0

local flareMap = {
	[0] = flare1,
	[1] = flare2,
}

-- Signal definitions
local SIG_AIM = 2
local SIG_RESTORE = 4
local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16

local RESTORE_DELAY = 1100
local ROCK_DAMGE_MULT = 0.003
local ROCK_FIRE_FORCE = 0.03

local ROCK_SPEED = 12		--Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.3	--Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base	-- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.2

----------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")
local firestate = 0
local firstTime = true

function RetreatFunction()
	if firstTime then
		firestate = Spring.GetUnitStates(unitID).firestate
		firstTime = false
	end
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	Spring.GiveOrderToUnit(unitID, CMD_UNIT_CANCEL_TARGET, {}, {})
end

function StopRetreatFunction()
	Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {firestate}, {})
	firstTime = true
end

----------------------------------------------------------

local function WobbleUnit()

	while true do
		Move( base , y_axis, 1, 1.20000 )
		Sleep( 750)
		Move( base , y_axis, -1 , 1.20000 )
		Sleep( 750)
	end
end

--[[
function script.HitByWeapon(x, z, weaponID, damage)
	StartThread(Rock, false, x*ROCK_DAMGE_MULT*damage, z_axis)
	StartThread(Rock, false, -z*ROCK_DAMGE_MULT*damage, x_axis)
end
]]

local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	while true do 
		if math.random() < 0.5  then
			EmitSfx( wake1,  5 )
			EmitSfx( wake3,  5 )
			EmitSfx( wake5,  5 )
			EmitSfx( wake7,  5 )
			EmitSfx( wake1,  3 )
			EmitSfx( wake3,  3 )
			EmitSfx( wake5,  3 )
			EmitSfx( wake7,  3 )
		else
			EmitSfx( wake2,  5 )
			EmitSfx( wake4,  5 )
			EmitSfx( wake6,  5 )
			EmitSfx( wake8,  5 )
			EmitSfx( wake2,  3 )
			EmitSfx( wake4,  3 )
			EmitSfx( wake6,  3 )
			EmitSfx( wake8,  3 )
		end
		EmitSfx( ground1,  1024)
		Sleep( 150)
	end
end

function script.Create()
	Hide( ground1)
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_X, x_axis)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_Z, z_axis)
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (100)
	end
	Spring.SetUnitArmored(unitID,true)
end

local function RestoreAfterDelay()

	Signal( SIG_RESTORE)
	SetSignalMask( SIG_RESTORE)
	Sleep( RESTORE_DELAY)
	Move( turretbase , y_axis, 0 , 20 )
	Turn( turretbase , x_axis, 0, math.rad(150.000000) )
	Turn( turret , x_axis, 0, math.rad(150.000000) )
	Turn( door1 , z_axis, math.rad(-(0)), math.rad(150.000000) )
	Turn( door2 , z_axis, math.rad(-(0)), math.rad(150.000000) )
	Turn( rim1 , z_axis, math.rad(-(0)), math.rad(150.000000) )
	Turn( rim2 , z_axis, math.rad(-(0)), math.rad(150.000000) )
	Turn( gun , y_axis, 0, math.rad(300.000000) )
	Turn( gun , x_axis, 0, math.rad(60.000000) )
	WaitForMove(turretbase, y_axis)
	Spring.SetUnitArmored(unitID,true)
end

function script.AimFromWeapon(num) 
	return turret
end

function script.AimWeapon(num, heading, pitch)

	StartThread(RestoreAfterDelay)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	
	Spring.SetUnitArmored(unitID,false)
	
	Move( turretbase , y_axis, 3 , 30 )
	Turn( turretbase , x_axis, math.rad(30), math.rad(150.000000) )
	Turn( turret , x_axis, math.rad(-30), math.rad(150.000000) )
	Turn( door1 , z_axis, math.rad(80), math.rad(150.000000) )
	Turn( door2 , z_axis, math.rad(-80), math.rad(150.000000) )
	Turn( rim1 , z_axis, math.rad(-30), math.rad(150.000000) )
	Turn( rim2 , z_axis, math.rad(30), math.rad(150.000000) )
	Turn( gun , y_axis, heading, math.rad(300.000000) )
	Turn( gun , x_axis, -pitch, math.rad(60.000000) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	gunHeading = heading
	return true
end

function script.QueryWeapon(num)
	return flareMap[shootCycle]
end


function script.FireWeapon(num)
	StartThread(Rock, gunHeading, ROCK_FIRE_FORCE, z_axis)
	StartThread(Rock, gunHeading - hpi, ROCK_FIRE_FORCE, x_axis)
	EmitSfx( flareMap[shootCycle],  1025 )
	shootCycle = (shootCycle + 1) % 2
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		return 1
	elseif severity <= 0.50  then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		Explode(rim1, sfxShatter)
		Explode(rim2, sfxShatter)
		Explode(wake1, sfxFall)
		Explode(wake2, sfxFall)
		Explode(wake3, sfxFall)
		Explode(wake4, sfxFall)
		Explode(wake5, sfxFall)
		Explode(wake6, sfxFall)
		return 1
	end
	Explode(door1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(door2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(rim1, sfxShatter)
	Explode(rim2, sfxShatter)
	Explode(wake1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake3, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake4, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake5, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake6, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	return 2
end
