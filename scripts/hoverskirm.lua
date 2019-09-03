include "constants.lua"
include "rockPiece.lua"
local dynamicRockData

local base = piece 'base'
local front = piece 'front'
local turret = piece 'turret'
local lbarrel = piece 'lbarrel'
local rbarrel = piece 'rbarrel'
local lflare = piece 'lflare'
local rflare = piece 'rflare'
local exhaust = piece 'exhaust'
local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ('wake' .. i)
end
local ground1 = piece 'ground1'

local random = math.random
local hpi = math.pi*0.5

local shotNum = 1
local flares = {
	lflare,
	rflare,
}

local gunHeading = 0

local ROCKET_SPREAD = 0.4

local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16

local ROCK_FIRE_FORCE = 0.35
local ROCK_SPEED = 10	--Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.85	--Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base	-- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

local SIG_MOVE = 1
local SIG_AIM = 2
local RESTORE_DELAY = 3000

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

local function WobbleUnit()
	local wobble = true
	while true do
		if wobble == true then
			Move(base, y_axis, 0.9, 1.2)
		end
		if wobble == false then
		
			Move(base, y_axis, -0.9, 1.2)
		end
		wobble = not wobble
		Sleep(750)
	end
end

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
	Turn(exhaust, y_axis, math.rad(-180))
	Turn(lbarrel, y_axis, ROCKET_SPREAD)
	Turn(rbarrel, y_axis, -ROCKET_SPREAD)
	StartThread(GG.Script.SmokeUnit, unitID, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, math.rad(90))
	Turn(turret, x_axis, 0, math.rad(45))
end

function script.AimFromWeapon()
	return turret
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	local spreadPitch = math.min(0.8, pitch)
	Turn(turret, y_axis, heading, math.rad(180))
	Turn(turret, x_axis, -spreadPitch, math.rad(100))
	Turn(lbarrel, y_axis, ROCKET_SPREAD + 2*spreadPitch, math.rad(300))
	Turn(rbarrel, y_axis, -ROCKET_SPREAD - 2*spreadPitch, math.rad(300))
	Turn(lbarrel, x_axis, -spreadPitch, math.rad(300))
	Turn(rbarrel, x_axis, -spreadPitch, math.rad(300))
	gunHeading = heading
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
	StartThread(RestoreAfterDelay)
	return (1)
end

function script.QueryWeapon(piecenum)
	return flares[shotNum]
end

function script.FireWeapon()
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gunHeading, ROCK_FIRE_FORCE)
	StartThread(GG.ScriptRock.Rock, dynamicRockData[x_axis], gunHeading - hpi, ROCK_FIRE_FORCE*0.4)
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 660.1, 70, 0.3)
end

function script.Shot()
	EmitSfx(flares[shotNum], GG.Script.UNIT_SFX2)
	EmitSfx(exhaust, GG.Script.UNIT_SFX3)
	shotNum = 3 - shotNum
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		return 1
	elseif severity <= 0.50 then
		Explode(front, SFX.NONE)
		Explode(turret, SFX.SHATTER)
		return 1
	elseif severity <= 0.99 then
		Explode(front, SFX.SHATTER)
		Explode(turret, SFX.SHATTER)
		return 2
	end
	Explode(front, SFX.SHATTER)
	Explode(turret, SFX.SHATTER)
	return 2
end
