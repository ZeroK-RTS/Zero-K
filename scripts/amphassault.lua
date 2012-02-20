include "constants.lua"

local base, body, turret, rbarrel1, rbarrel2, lbarrel1, lbarrel2 = piece('base', 'body', 'turret', 'rbarrel1', 'rbarrel2', 'lbarrel1', 'lbarrel2')
local rfleg, rffoot, lfleg, lffoot, rbleg, rbfoot, lbleg, lbfoot =  piece('rfleg', 'rffoot', 'lfleg', 'lffoot', 'rbleg', 'rbfoot', 'lbleg', 'lbfoot')

local SIG_WALK = 1

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	while true do
		
		-- right
		Turn( rfleg, x_axis, math.rad(40),math.rad(40))
		Turn( rffoot, x_axis, math.rad(-40),math.rad(40))
		
		Turn( rbleg, x_axis, math.rad(5),math.rad(10))
		Turn( rbfoot, x_axis, math.rad(-40),math.rad(80))
		
		Move( rfleg, y_axis, 0.3,0.6)
		Move( rbleg, y_axis, 0.3,0.6)
		
		-- left
		Turn( lfleg, x_axis, math.rad(-20),math.rad(120))
		Turn( lffoot, x_axis, math.rad(35),math.rad(150))
		
		Turn( lbleg, x_axis, math.rad(0),math.rad(45))
		Turn( lbfoot, x_axis, math.rad(0),math.rad(46))

		Move( lfleg, y_axis, 0.5,2.2)
		Move( lbleg, y_axis, 0.5,1)
		
		Move( body, y_axis, 1,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rbleg, x_axis, math.rad(-50),math.rad(110))
		Turn( rbfoot, x_axis, math.rad(50),math.rad(180))
		
		Move( rfleg, y_axis, 1.6,2.6)
		Move( rbleg, y_axis, 1,1.4)
		
		-- left
		Turn( lfleg, x_axis, math.rad(0),math.rad(40))
		Turn( lffoot, x_axis, math.rad(0),math.rad(80))
		
		Move( lfleg, y_axis, 0,1)
		Move( lbleg, y_axis, 0,1)
		
		Move( body, y_axis, 0.5,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(-20),math.rad(120))
		Turn( rffoot, x_axis, math.rad(35),math.rad(150))
		
		Turn( rbleg, x_axis, math.rad(0),math.rad(45))
		Turn( rbfoot, x_axis, math.rad(0),math.rad(46))
		
		Move( rfleg, y_axis, 0.5,2.2)
		Move( rbleg, y_axis, 0.5,1)
		
		
		-- left
		Turn( lfleg, x_axis, math.rad(40),math.rad(40))
		Turn( lffoot, x_axis, math.rad(-40),math.rad(40))
		
		Turn( lbleg, x_axis, math.rad(5),math.rad(10))
		Turn( lbfoot, x_axis, math.rad(-40),math.rad(80))
		
		Move( lfleg, y_axis, 0.3,0.6)
		Move( lbleg, y_axis, 0.3,0.6)
		
		Move( body, y_axis, 1,1)
		Sleep(500) -- ****************
		
		-- right
		Turn( rfleg, x_axis, math.rad(0),math.rad(40))
		Turn( rffoot, x_axis, math.rad(0),math.rad(80))
		
		Move( rfleg, y_axis, 0,1)
		Move( rbleg, y_axis, 0,1)
		
		-- left
		Turn( lbleg, x_axis, math.rad(-50),math.rad(110))
		Turn( lbfoot, x_axis, math.rad(50),math.rad(180))
		
		Move( lfleg, y_axis, 1.6,2.6)
		Move( lbleg, y_axis, 1,1.4)
		
		Move( body, y_axis, 0.5,1)
		Sleep(500) -- ****************
	end
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	
	Turn( rfleg, x_axis, math.rad(0),math.rad(60))
	Turn( rffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( rbleg, x_axis, math.rad(0),math.rad(60))
	Turn( rbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( rfleg, y_axis, 0,1)
	Move( rbleg, y_axis, 0,1)
	
	Turn( lfleg, x_axis, math.rad(0),math.rad(60))
	Turn( lffoot, x_axis, math.rad(0),math.rad(60))
	
	Turn( lbleg, x_axis, math.rad(0),math.rad(60))
	Turn( lbfoot, x_axis, math.rad(0),math.rad(60))
	
	Move( lfleg, y_axis, 0,1)
	Move( lbleg, y_axis, 0,1)
	
end


function script.Killed(recentDamage, maxHealth)
	return 0
end

function script.Create()
Spring.MoveCtrl.SetGroundMoveTypeData(unitID, {maxSpeed = 10})

	Turn( rfleg, x_axis, math.rad(0))
	Turn( rffoot, x_axis, math.rad(0))
	
	Turn( rbleg, x_axis, math.rad(0))
	Turn( rbfoot, x_axis, math.rad(0))
	
end