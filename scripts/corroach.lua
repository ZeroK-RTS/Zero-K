
--by Chris Mackey

--include "lua/test.lua"

--pieces
local body = piece "body"
local digger = piece "digger"
local jet = piece "jet"

local lf_leg = piece "legflup"
local lf_knee = piece "legflmid"
local lf_foot = piece "legflshin"

local rf_leg = piece "legfrup"
local rf_knee = piece "legfrmid"
local rf_foot = piece "legfrshin"

local lb_leg = piece "legrlup"
local lb_knee = piece "legrlmid"
local lb_foot = piece "legrlshin"

local rb_leg = piece "legrrup"
local rb_knee = piece "legrrmid"
local rb_foot = piece "legrrshin"

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
	----[[ could use some polishing
		Turn( lf_leg, 2, ma, forward )   	-- right front forward
		Turn( lf_foot, 3, ma/2, up )
		
		Turn( rf_leg, 2, -ma, forward ) 	-- left front forward
		Turn( rf_foot, 3, -ma/2, up )
		
		Turn( lb_leg, 2, -ma, backward ) 	-- right back backward
		Turn( lb_leg, 3, 0, up )         	-- right back down
		Turn( lb_foot, 3, 0, up )
		
		Turn( rb_leg, 2, ma, backward ) 	-- left back backward
		Turn( rb_leg, 3, 0, up )         	-- left back down
		Turn( rb_foot, 3, 0, up )
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
		
		Turn( lf_leg, 2, ma, forward )   	-- right front forward
		Turn( lf_leg, 3, -ma, up )       	-- right front up
		Turn( lf_foot, 3, ma/2, up )
				
		Turn( lb_leg, 2, -ma, backward ) 	-- right back backward
		Turn( lb_leg, 3, 0, up )         	-- right back down
		Turn( lb_foot, 3, 0, up )
		
		Turn( rf_leg, 2, sa, backward ) 	-- left front backward
		Turn( rf_leg, 3, 0, up )         	-- left front down
		Turn( rf_foot, 3, 0, up )
		
		Turn( rb_leg, 2, -sa, forward ) 	-- left back forward
		Turn( rb_leg, 3, ma/2, up )       	-- left back up
		Turn( rb_foot, 3, -ma/3, up )
		
		Sleep( pause )
		
		Turn( body, 2, -.1, .5 )        	-- body roll right
		Turn( body, 3, -sa/2, 1.5 )        	-- body turn left
		
		Turn( lf_leg, 2, -sa, backward ) 	-- right front backward
		Turn( lf_leg, 3, 0, up )         	-- right front down
		Turn( lf_foot, 3, 0, up )
		
		Turn( lb_leg, 2, sa, forward )   	-- right back forward
		Turn( lb_leg, 3, -ma/2, up )       	-- right back up
		Turn( lb_foot, 3, ma/3, up )
		
		Turn( rf_leg, 2, -ma, forward ) 	-- left front forward
		Turn( rf_leg, 3, ma, up )       	-- left front up
		Turn( rf_foot, 3, -ma/2, up )
		
		Turn( rb_leg, 2, ma, backward ) 	-- left back backward
		Turn( rb_leg, 3, 0, up )         	-- left back down
		Turn( rb_foot, 3, 0, up )
		
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

function script.Killed()
	--Spring.Echo("I am ded")
	--[[ desync testing
	Explode( lf_leg, SFX.EXPLODE )
	Explode( lb_leg, SFX.EXPLODE )
	Explode( rf_leg, SFX.EXPLODE )
	Explode( rb_leg, SFX.EXPLODE )
	Explode( lf_foot, SFX.EXPLODE )
	Explode( lb_foot, SFX.EXPLODE )
	Explode( rf_foot, SFX.EXPLODE )
	Explode( rb_foot, SFX.EXPLODE )
	--]]
end
