include 'constants.lua'

--------------------------------------------------------------------
--pieces
--------------------------------------------------------------------
local hull, turret1, turret2, turret3, radar = piece('hull', 'turret1', 'turret2', 'turret3', 'radar')
local ground = piece('ground')

local wake = {}
for i = 1, 6 do
	wake[i] = piece('wake' .. i)
end

local turrets = { turret1, turret2, turret3 }

local barrels = {
	[1] = {piece 'barrel11', piece 'barrel12', piece 'barrel13'},
	[2] = {piece 'barrel21', piece 'barrel22', piece 'barrel23'},
	[3] = {piece 'barrel31', piece 'barrel32', piece 'barrel33'},
}
local flares = {
	[1] = {piece 'flare11', piece 'flare12', piece 'flare13'},
	[2] = {piece 'flare21', piece 'flare22', piece 'flare23'},
	[3] = {piece 'flare31', piece 'flare32', piece 'flare33'},
}

--------------------------------------------------------------------
--constants
--------------------------------------------------------------------
local smokePiece = {hull, turret1, turret2, turret3}

local SIG_Move = 1

local RESTORE_DELAY = 5000

local TURRET_PITCH_SPEED_1 = math.rad(30)
local TURRET_YAW_SPEED_1 = math.rad(60)
local RECOIL_DISTANCE =	-3
local RECOIL_RESTORE_SPEED = 2.5

--rockz
include "rockPiece.lua"
local dynamicRockData

local ROCK_PIECE = ground		--piece to rock
local ROCK_SPEED = 1		--number of rock angles per second around z-axis
local ROCK_DECAY = -0.5	--rocking around z-axis is reduced by this factor each time; should be negative to alternate rocking direction
local ROCK_MIN = math.rad(3)	--if around z-axis rock is not greater than this amount rocking will stop after returning to center
local ROCK_MAX = math.rad(15)
local SIG_ROCK_Z = 1024		--signal to prevent multiple rocking

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

--------------------------------------------------------------------
--variables
--------------------------------------------------------------------
local gun = {1, 1, 1}
local gunHeading = {0, 0, 0}

local dead = false

function script.Create()
	Turn(turret2, y_axis, math.rad(180))
	Turn(turret3, y_axis, math.rad(180))
	Spin(radar, y_axis, math.rad(100))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	if dead then return false end
	Turn(turret1, y_axis, 0, math.rad(35))
	Turn(turret2, y_axis, math.rad(180), math.rad(35))
	Turn(turret3, y_axis, math.rad(180), math.rad(35))
end

local function Wake()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			for i = 1, 6 do
				Move(wake[i], z_axis, math.random()*50 - 25)
				EmitSfx(wake[i], 2)
			end
		end
		Sleep(200)
	end
end

function script.StartMoving()
	StartThread(Wake)
end

function script.StopMoving()
	Signal(SIG_Move)
end

function script.AimWeapon(num, heading, pitch)
	if dead then return false end
	local SIG_Aim = 2^num
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
	Turn(turrets[num], y_axis, heading, math.rad(40))
	for i=1,3 do
		Turn(barrels[num][i], x_axis, -pitch, math.rad(40))
	end
	WaitForTurn(barrels[num][1], x_axis)
	WaitForTurn(turrets[num], y_axis)
	StartThread(RestoreAfterDelay)
	gunHeading[num] = heading
	return true
end

function script.FireWeapon(num)
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gunHeading[num], ROCK_FORCE)
end

function script.Shot(num)
	local barrel = barrels[num][(gun[num])]
	local flare = flares[num][(gun[num])]
	EmitSfx(flare, 1026)
	Move(barrel, z_axis, RECOIL_DISTANCE)
	Move(barrel, z_axis, 0, RECOIL_RESTORE_SPEED)
	gun[num] = gun[num] + 1
	if gun[num] > 3 then gun[num] = 1 end
end

function script.AimFromWeapon(num)
	return turrets[num]
end

function script.QueryWeapon(num)
	return flares[num][(gun[num])]
end

local function ExplodeTurret(num)
	for i=1,3 do
		if math.random() > 0.5 then
			Explode(barrels[num][i], SFX.FALL + SFX.SMOKE + SFX.EXPLODE)
			Hide(barrels[num][i], SFX.FALL + SFX.SMOKE + SFX.EXPLODE)
		else
			Explode(barrels[num][i], SFX.SHATTER)
		end
	end
	Sleep(250)
	Explode(turrets[num], SFX.SHATTER)
	--Hide(turrets[num])
end

--not actually called; copypasta into Killed()
local function DeathAnim()
	dead = true
	--Turn(ground, z_axis, math.random(math.rad(-15), math.rad(15)), math.rad(1))
	local speed = math.rad(math.random(3, 10)/10)
	--Turn(ground, x_axis, math.rad(-10), speed)
	EmitSfx(turret2, 1024)
	
	GG.Script.InitializeDeathAnimation(unitID)
	Sleep(120)
	EmitSfx(turret1, 1024)
	Explode(radar, SFX.SMOKE)
	EmitSfx(radar, 1024)
	Hide(radar)
	Sleep(120)
	EmitSfx(hull, 1025)
	EmitSfx(turret2, 1025)
	ExplodeTurret(2)
	Sleep(180)
	EmitSfx(turret1, 1025)
	ExplodeTurret(1)
	Sleep(100)
	EmitSfx(hull, 1024)
	EmitSfx(turret3, 1025)
	ExplodeTurret(3)
	Sleep(150)
	EmitSfx(hull, 1025)
	EmitSfx(turret1, 1024)
	EmitSfx(turret2, 1024)
	EmitSfx(turret3, 1024)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.25 then
		DeathAnim()
		Explode(hull, SFX.NONE)
		return 1
	elseif severity < 0.5 then
		DeathAnim()
		Explode(hull, SFX.NONE)
		return 1
	else
		for i=1,3 do
			for v=1,3 do
				Explode(barrels[i][v], SFX.FALL + SFX.SMOKE + SFX.EXPLODE)
			end
		end
		Explode(hull, SFX.SHATTER)
		Explode(ground, SFX.SHATTER)
		Explode(turret1, SFX.SHATTER)
		Explode(turret2, SFX.SHATTER)
		Explode(turret3, SFX.SHATTER)
		return 2
	end
end
