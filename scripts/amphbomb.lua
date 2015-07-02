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
local dirtfling = 1024 +3 --explosiongenerators=[[custom:digdig]]

--variables
local walking = false
local burrowed = false
local forward = 8
local backward = 5
local up = 8

--signals
local SIG_BURROW = 1
local SIG_Walk = 2

--cob values
local cloaked = COB.CLOAKED
local stealth = COB.STEALTH

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

local function Burrow()
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	Sleep(400)
	
	Signal(SIG_Walk)
	burrowed = true
	EmitSfx(digger, dirtfling)
	
	--burrow
	Move(body, y_axis, -1.500000, 1.500000)
	Turn(body, x_axis, math.rad(-20.000000), math.rad(20.000000))
	
	if(burrowed == true) then
		GG.SetWantedCloaked(unitID, 1)
		Spring.UnitScript.SetUnitValue(stealth, 1)
	end
end

local function UnBurrow()
	Signal(SIG_BURROW)
	burrowed = false
	GG.SetWantedCloaked(unitID, 0)
	Spring.UnitScript.SetUnitValue(stealth, 0)
	Move(body, y_axis, 0.000000, 2.000000)
	Turn(body, x_axis, 0, math.rad(60.000000))
	
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 0)
	GG.UpdateUnitAttributes(unitID)
	
	Sleep(600)
	
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	GG.UpdateUnitAttributes(unitID)
	EmitSfx(digger, dirtfling)
	
	StartThread(Walk)
end

local function Moving()
	Signal(Sig_Walk)
	SetSignalMask(Sig_Walk)
	Spin(wheell1, x_axis, (12))
	Spin(wheell2, x_axis, (12))
	Spin(wheelr1, x_axis, (12))
	Spin(wheelr2, x_axis, (12))
	StartThread(UnBurrow)
	walking = true
	StartThread(Walk)
end


function script.StartMoving()
	Signal(SIG_BURROW)
	if burrowed then
		StartThread(UnBurrow)
	else
		StartThread(Moving)
	end
end

function script.StopMoving()
	walking = false
	StopSpin(wheell1, x_axis, (10))
	StopSpin(wheell2, x_axis, (10))
	StopSpin(wheelr1, x_axis, (10))
	StopSpin(wheelr2, x_axis, (10))
	if select(2,Spring.GetUnitPosition(unitID)) > 0 then
		StartThread(Burrow) --cloaked
	end
end

function script.FireWeapon(num)
	GG.shotWaterWeapon(unitID)
end

function script.Killed()
	Explode(body, sfxShatter)
	Explode(wheell1, sfxSmoke + sfxFire)
	Explode(wheell2, sfxSmoke + sfxFire)
	Explode(wheelr1, sfxSmoke + sfxFire)
	Explode(wheelr2, sfxSmoke + sfxFire)
end
