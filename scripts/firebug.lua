
--by Chris Mackey

--include "lua/test.lua"

--pieces
local body = piece "body"
local digger = piece "digger"
local missile = piece "missile"

--constants
local PI = math.pi
local sa = math.rad(20)
local ma = math.rad(60)
local la = math.rad(100)
local pause = 300
local dirtfling = 1024+2

--variables
local walking = false
local burrowed = false
local forward = 8
local backward = 5
local up = 8

--signals
local aim = 1

--cob values
local cloaked = COB.CLOAKED
local stealth = COB.STEALTH

local function Burrow()
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

function script.StartMoving()
	StartThread( UnBurrow )
	walking = true
	StartThread( Walk )
	--StartThread( Talk )
end

function script.StopMoving()
	walking = false
	StartThread( Burrow )
end

function script.QueryWeapon1()
	return missile
end

function script.AimFromWeapon1()
	return missile
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
