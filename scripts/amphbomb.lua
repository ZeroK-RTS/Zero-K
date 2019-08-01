-- pieces
local base = piece "base"
local body = piece "body"
local firepoint = piece "firepoint"
local wheell1 = piece "wheell1"
local wheell2 = piece "wheell2"
local wheelr1 = piece "wheelr1"
local wheelr2 = piece "wheelr2"

include "constants.lua"

-- constants
local pause = 150

local rollAmount = 0.1
local rollSpeed = rollAmount*2000/(3*pause)

local turnAmount = math.rad(10)
local turnSpeed = turnAmount*2000/(2*pause)

-- variables
local walking = false
local forward = 8
local backward = 5
local up = 8

local waveWeaponDef = WeaponDefNames["amphbomb_amphbomb_death"]
local WAVE_TIMEOUT = math.ceil(waveWeaponDef.damageAreaOfEffect / waveWeaponDef.explosionSpeed)* (1000 / Game.gameSpeed) + 200 -- empirically maximum delay of damage was (damageAreaOfEffect / explosionSpeed) - 4 frames

-- signals
local SIG_Walk = 2

local function Walk()
	Signal(Sig_Walk)
	SetSignalMask(Sig_Walk)
	while true do
		Turn(base, y_axis, rollAmount, rollSpeed)		 	-- body roll left
		
		Sleep(pause)
		Turn(body, z_axis, turnAmount, turnSpeed)		 	-- body turn right
		
		Sleep(pause)
		
		
		Sleep(pause)
		Turn(body, z_axis, -turnAmount, turnSpeed)			-- body turn left
		Turn(base, y_axis, -rollAmount, rollSpeed)			-- body roll right
		Sleep(pause)
		
		
		Sleep(pause)
		Turn(body, z_axis, turnAmount, turnSpeed)		 	-- body turn right
		
		Sleep(pause)
		Turn(base, y_axis, rollAmount, rollSpeed)		 	-- body roll left
		
		Sleep(pause)
		Turn(body, z_axis, -turnAmount, turnSpeed)			-- body turn left
		
		Sleep(pause)
		
		
		Sleep(pause)
		Turn(base, y_axis, -rollAmount, rollSpeed)			-- body roll right
		Turn(body, z_axis, turnAmount, turnSpeed)		 	-- body turn right
		Sleep(pause)
		
		
		Sleep(pause)
		Turn(body, z_axis, -turnAmount, turnSpeed)			-- body turn left
		
		Sleep(pause)
	end
end

function script.QueryWeapon()
	return firepoint
end

function script.AimFromWeapon()
	return firepoint
end

function script.AimWeapon()
	return true
end

function script.StartMoving()
	Spin(wheell1, x_axis, 12)
	Spin(wheell2, x_axis, 12)
	Spin(wheelr1, x_axis, 12)
	Spin(wheelr2, x_axis, 12)
	StartThread(Walk)
end

function script.StopMoving()
	Signal(Sig_Walk)
	
	StopSpin(wheell1, x_axis, 8)
	StopSpin(wheell2, x_axis, 8)
	StopSpin(wheelr1, x_axis, 8)
	StopSpin(wheelr2, x_axis, 8)
	
	Turn(base, y_axis, 0, rollSpeed)
	Turn(body, z_axis, 0, turnSpeed)
end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

local function Killed(recentDamage, maxHealth)
	Explode(body, SFX.SMOKE + SFX.SHATTER)
	Explode(wheell1, SFX.SMOKE + SFX.FIRE)
	Explode(wheell2, SFX.SMOKE + SFX.FIRE)
	Explode(wheelr1, SFX.SMOKE + SFX.FIRE)
	Explode(wheelr2, SFX.SMOKE + SFX.FIRE)
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end

function script.Killed(recentDamage, maxHealth)
	return GG.Script.DelayTrueDeath(unitID, unitDefID, recentDamage, maxHealth, Killed, WAVE_TIMEOUT)
end

