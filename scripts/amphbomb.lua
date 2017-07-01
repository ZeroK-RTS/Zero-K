local TANK_MAX = 100
--pieces
local body = piece "body"
local firepoint = piece "firepoint"
local digger = piece "digger"
local wheell1 = piece "wheell1"
local wheell2 = piece "wheell2"
local wheelr1 = piece "wheelr1"
local wheelr2 = piece "wheelr2"


include "constants.lua"

--constants
local PI = math.pi
local sa = math.rad(20)
local ma = math.rad(60)
local la = math.rad(100)
local pause = 300

--variables
local walking = false
local forward = 8
local backward = 5
local up = 8

--signals
local SIG_Walk = 2

local function Walk()
	while (walking == true) do
		Turn(body, 2, .1, .5)		 	-- body roll left
		Turn(body, 3, sa/2, 1.5)		 	-- body turn right
		
		Sleep(pause)
		
		Turn(body, 2, -.1, .5)			-- body roll right
		Turn(body, 3, -sa/2, 1.5)			-- body turn left
		
		Sleep(pause)
	end
end

local function Talk()
	Spring.Echo("Hello World! ... Directive: Kill all humans")
end

function script.Create()
	
end

function script.QueryWeapon1()
	return firepoint
end

function script.AimFromWeapon1()
	return firepoint
end

function script.AimWeapon1()
	return true
end

local function Moving()
	Signal(Sig_Walk)
	SetSignalMask(Sig_Walk)
	Spin(wheell1, x_axis, (12))
	Spin(wheell2, x_axis, (12))
	Spin(wheelr1, x_axis, (12))
	Spin(wheelr2, x_axis, (12))
	walking = true
	StartThread(Walk)
end


function script.StartMoving()
	StartThread(Moving)
end

function script.StopMoving()
	walking = false
	StopSpin(wheell1, x_axis, (10))
	StopSpin(wheell2, x_axis, (10))
	StopSpin(wheelr1, x_axis, (10))
	StopSpin(wheelr2, x_axis, (10))
end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.FireWeapon(num)
	GG.shotWaterWeapon(unitID)
end

function script.Killed(recentDamage, maxHealth)
	Explode(body, sfxShatter)
	Explode(wheell1, sfxSmoke + sfxFire)
	Explode(wheell2, sfxSmoke + sfxFire)
	Explode(wheelr1, sfxSmoke + sfxFire)
	Explode(wheelr2, sfxSmoke + sfxFire)
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
