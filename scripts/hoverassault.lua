local base = piece 'base' 
local shield = piece 'shield' 
local turret = piece 'turret' 
local gun = piece 'gun' 
local flare1 = piece 'flare1' 
local flare2 = piece 'flare2'

local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ('wake' .. i)
end

local ground1 = piece 'ground1' 
local door1 = piece 'door1' 
local door2 = piece 'door2' 
local turretbase = piece 'turretbase' 
local rim1 = piece 'rim1' 
local rim2 = piece 'rim2' 

include "constants.lua"
include "rockPiece.lua"

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

local rockData = {
	[x_axis] = {
		piece  = ROCK_PIECE,
		speed  = ROCK_SPEED,
		decay  = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_X,
		axis = x_axis,
	},
	[z_axis] = {
		piece  = ROCK_PIECE,
		speed  = ROCK_SPEED,
		decay  = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_Z,
		axis = z_axis,
	},
}

----------------------------------------------------------
VFS.Include("LuaRules/Configs/customcmds.h.lua")
local firestate = 0
local firstTime = true

-- use GG.DelegateOrder as a safety, see https://github.com/ZeroK-RTS/Zero-K/issues/3056
function RetreatFunction()
	if firstTime then
		firestate = Spring.GetUnitStates(unitID).firestate
		firstTime = false
	end
	GG.DelegateOrder(unitID, CMD.FIRE_STATE, {0}, 0)
	GG.DelegateOrder(unitID, CMD_UNIT_CANCEL_TARGET, {}, 0)
end

function StopRetreatFunction()
	GG.DelegateOrder(unitID, CMD.FIRE_STATE, {firestate}, 0)
	firstTime = true
end

----------------------------------------------------------

local function WobbleUnit()

	while true do
		Move(base, y_axis, 1, 1.20000)
		Sleep(750)
		Move(base, y_axis, -1, 1.20000)
		Sleep(750)
	end
end

--[[
function script.HitByWeapon(x, z, weaponID, damage)
	StartThread(Rock, z_axis, false, x*ROCK_DAMGE_MULT*damage)
	StartThread(Rock, x_axis, false, -z*ROCK_DAMGE_MULT*damage)
end
]]

local sfxNum = 0
function script.setSFXoccupy(num)
	sfxNum = num
end

local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	while true do 
		if not Spring.GetUnitIsCloaked(unitID) then
			if (sfxNum == 1 or sfxNum == 2) and select(2, Spring.GetUnitPosition(unitID)) == 0 then
				for i = 1, 8 do
					EmitSfx(wakes[i], 3)
				end
			else
				EmitSfx(ground1, 1024)
			end
		end
		Sleep(150)
	end
end

function script.Create()
	Hide(ground1)
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
	InitializeRock(rockData)
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (100)
	end
	Spring.SetUnitArmored(unitID,true)
end

local function RestoreAfterDelay()

	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(RESTORE_DELAY)
	Move(turretbase, y_axis, 0, 20)
	Turn(turretbase, x_axis, 0, math.rad(150.000000))
	Turn(turret, x_axis, 0, math.rad(150.000000))
	Turn(door1, z_axis, math.rad(-(0)), math.rad(150.000000))
	Turn(door2, z_axis, math.rad(-(0)), math.rad(150.000000))
	Turn(rim1, z_axis, math.rad(-(0)), math.rad(150.000000))
	Turn(rim2, z_axis, math.rad(-(0)), math.rad(150.000000))
	Turn(gun, y_axis, 0, math.rad(300.000000))
	Turn(gun, x_axis, 0, math.rad(60.000000))
	WaitForMove(turretbase, y_axis)
	Spring.SetUnitArmored(unitID,true)
end

function script.AimFromWeapon(num) 
	return turret
end

function script.AimWeapon(num, heading, pitch)

	StartThread(RestoreAfterDelay)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	Spring.SetUnitArmored(unitID,false)
	
	Move(turretbase, y_axis, 3, 30)
	Turn(turretbase, x_axis, math.rad(30), math.rad(150.000000))
	Turn(turret, x_axis, math.rad(-30), math.rad(150.000000))
	Turn(door1, z_axis, math.rad(80), math.rad(150.000000))
	Turn(door2, z_axis, math.rad(-80), math.rad(150.000000))
	Turn(rim1, z_axis, math.rad(-30), math.rad(150.000000))
	Turn(rim2, z_axis, math.rad(30), math.rad(150.000000))
	Turn(gun, y_axis, heading, math.rad(300.000000))
	Turn(gun, x_axis, -pitch, math.rad(60.000000))
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	gunHeading = heading
	return true
end

function script.QueryWeapon(num)
	return flareMap[shootCycle]
end


function script.FireWeapon(num)
	StartThread(Rock, z_axis, gunHeading, ROCK_FIRE_FORCE)
	StartThread(Rock, x_axis, gunHeading - hpi, ROCK_FIRE_FORCE)
	EmitSfx(flareMap[shootCycle], 1025)
	shootCycle = (shootCycle + 1) % 2
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxNone)
		Explode(door1, sfxNone)
		Explode(door2, sfxNone)
		Explode(rim1, sfxShatter)
		Explode(rim2, sfxShatter)
		return 1
	end
	Explode(door1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(door2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(rim1, sfxShatter)
	Explode(rim2, sfxShatter)
	return 2
end
