
--by Chris Mackey

--include "lua/test.lua"


local SOUND_PERIOD = 2
local soundIndex = SOUND_PERIOD
local TANK_MAX = 100
--pieces
local body = piece "body"
local firepoint = piece "firepoint"
local digger = piece "digger"
local wheell1 = piece "wheell1"
local wheell2 = piece "wheell2"
local wheelr1 = piece "wheelr1"
local wheelr2 = piece "wheelr2"

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
local aim = 1
local Sig_move= 2

--cob values
local cloaked = COB.CLOAKED
local stealth = COB.STEALTH

local function Burrow()
	Signal(Sig_move)
	SetSignalMask(Sig_move)

	burrowed = true
	EmitSfx( digger, dirtfling )
	
	--burrow
	Turn( body, 1, (-PI/6), 2 ) --butt into dirt
	Move( body, 2, -4, 5 ) -- body down
	Sleep( pause )
	--pieces to resting positions
	Turn( body, 3, 0, 1 )
	Turn( body, 2, 0, 1 )
	----[[ leg anim goes here
	--]]
	if( burrowed == true ) then
		Spring.UnitScript.SetUnitValue( cloaked, 1 )
		Spring.UnitScript.SetUnitValue( stealth, 1 )
		--Spring.UnitScript.SetUnitValue() MAX_SPEED to maxSpeed/4
		--Spring.UnitScript.SetUnitValue() STANDINGFIREORDERS to 2
	end
end

local function UnBurrow()
	burrowed = false
	Spring.UnitScript.SetUnitValue( cloaked, 0 )
	Spring.UnitScript.SetUnitValue( stealth, 0 )
	--Spring.UnitScript.SetUnitValue() STANDINGFIREORDERS to 0
	EmitSfx( digger, dirtfling )
	Move( body, 2, 0, 3 )
	Turn( body, 1, 0, 3 )
end
--]]

local function Walk()
	while (walking == true) do
		Turn( body, 2, .1, .5 )         	-- body roll left
		Turn( body, 3, sa/2, 1.5 )         	-- body turn right
		
		Sleep( pause )
		
		Turn( body, 2, -.1, .5 )        	-- body roll right
		Turn( body, 3, -sa/2, 1.5 )        	-- body turn left
		
		Sleep( pause )
	end
end

local function Talk()
	Spring.Echo("Hello World! ... Directive: Kill all humans")
end

function script.Create()
	
end

local function Moving()
	Signal(Sig_move)
	SetSignalMask(Sig_move)
	Spin(wheell1, x_axis, (12))
	Spin(wheell2, x_axis, (12))
	Spin(wheelr1, x_axis, (12))
	Spin(wheelr2, x_axis, (12))
	StartThread( UnBurrow ) --decloak
	walking = true
	StartThread( Walk )
end

function script.StartMoving()
	StartThread(Moving)
	--StartThread( Talk )
end

function script.StopMoving()
	walking = false
	StopSpin(wheell1, x_axis, (10))
	StopSpin(wheell2, x_axis, (10))
	StopSpin(wheelr1, x_axis, (10))
	StopSpin(wheelr2, x_axis, (10))
	if select(2,Spring.GetUnitPosition(unitID)) > 0 then
		StartThread( Burrow ) --cloaked
	end
end

function script.FireWeapon(num)
	soundIndex = soundIndex - 1
	if soundIndex <= 0 then
		local proportion = 1
		local waterTank = Spring.GetUnitRulesParam(unitID,"watertank")
		if waterTank then
			proportion = waterTank/TANK_MAX
		end
		soundIndex = math.floor(math.random()+1.5)
		local px, py, pz = Spring.GetUnitPosition(unitID)
		Spring.PlaySoundFile("sounds/weapon/watershort.wav", 20+proportion*5, px, py, pz)
	end

	GG.shotWaterWeapon(unitID)
end

function script.Shot(num)
	GG.Floating_AimWeapon(unitID)
    -- if math.random() < 0.2 then
		-- EmitSfx(firepoints[gun_1], 1024)
	-- end
	--[[
	local waterTank = Spring.GetUnitRulesParam(unitID,"watertank")
	if waterTank then
        local proportion = waterTank/TANK_MAX
		if proportion > 0.4 then
			EmitSfx(firepoints[gun_1], 1024)
			if math.random() < (proportion-0.4)/0.6 then
				EmitSfx(firepoints[gun_1], 1024)
			end
		else
			if math.random() < (proportion + 0.2)/0.6 then
				EmitSfx(firepoints[gun_1], 1024)
			end
		end
	end--]]
	--Spring.Echo(Spring.GetGameFrame())
	-- gun_1 = 1 - gun_1
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

function script.Killed()
	--Spring.Echo("I am ded")
	--[[ desync testing
	Explode( body, SFX.EXPLODE )
	--]]
end
