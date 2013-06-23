include "constants.lua"

--pieces
local concrete, belt = piece('Concrete','Belt');
local wheel, arm, hand, cannon = piece('Wheel', 'Arm','Hand', 'Cannon');
local barrel1, barrel2, barrel3, muzzle = piece("Barrel1","Barrel2","Barrel3","Muzzle");
local lidLeft, lidRight = piece("lidLeft","lidRight");
local aimProxy = piece("AimProxy");

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam

local unpackSpeed = 5;

smokePiece = { lidLeft, lidRight, wheel}

--variables
local is_open = false
local restore_delay = 2000;

--signals
local aim  = 2
local open = 8
local close = 16

-- private functions

local function Open()
	
	Spring.SetUnitArmored(unitID,false);
	Signal(close) --kill the closing animation if it is in process
	SetSignalMask(open) --set the signal to kill the opening animation

	
	Turn(lidLeft, x_axis, math.rad(0), unpackSpeed);
	Turn(lidRight, x_axis, math.rad(0), unpackSpeed);
	
	WaitForTurn(lidLeft, x_axis);
	
	Turn(wheel, y_axis, math.rad(-15),unpackSpeed);
	
	WaitForTurn(wheel, y_axis);
	
	Turn(hand, y_axis, math.rad(20), unpackSpeed);
	Turn(arm,y_axis,math.rad(20), unpackSpeed);
	Turn(wheel, y_axis, math.rad(-30), unpackSpeed);
	Turn(cannon, y_axis, math.rad(-10), unpackSpeed);
	
	WaitForTurn(cannon, y_axis);
	
	Move(barrel1,x_axis,0,6);
	Move(barrel2,x_axis,0,6);
	Move(barrel3,x_axis,0,6);
	
	is_open = true
end

--closing animation of the factory
local function Close()
	Signal( aim )
	Signal(open) --kill the opening animation if it is in process
	SetSignalMask(close) --set the signal to kill the closing animation
	is_open = false;
	
	Move(barrel1,x_axis,-1,2);
	Move(barrel2,x_axis,-1,2);
	Move(barrel3,x_axis,-1,2);
		
	Turn(wheel, y_axis, math.rad(-15),math.rad(90));
	Turn(cannon, y_axis, math.rad(65),math.rad(90));
	
	Turn(hand, y_axis, math.rad(60),math.rad(90));
	Turn(arm,y_axis,math.rad(107),math.rad(90));
	
	WaitForTurn(arm,y_axis);
	
	Turn(wheel, y_axis, math.rad(55),math.rad(160));
	
	WaitForTurn(wheel, y_axis);
	
	Turn(wheel, y_axis, math.rad(65),math.rad(20));
	
	Turn(lidLeft, x_axis, math.rad(90), math.rad(180));
	Turn(lidRight, x_axis, math.rad(-90), math.rad(180));

	Spring.SetUnitArmored(unitID,true);

end

function RestoreAfterDelay()
	Sleep(restore_delay);
	StartThread(Close);
end

-- event handlers


function script.Activate ( )
	StartThread( Open )
end

function script.Deactivate ( )
	is_open = false
	StartThread( Close )
end

function script.Create()
	is_open = true;
	StartThread(SmokeUnit)
	StartThread(RestoreAfterDelay);
end


function script.QueryWeapon(n)
	return muzzle
end

function script.AimFromWeapon(n) 
	return aimProxy 
end

function script.AimWeapon(num, heading, pitch )
	Signal( aim )
	SetSignalMask( aim )
	
	Turn( belt,  z_axis, heading, math.rad(200));
	
	if (not is_open) then
		StartThread(Open);

		while(not is_open) do
			Sleep(250);
		end
	end

	--Turn( cannon, y_axis, heading, 1.2 )
	Turn( belt,  z_axis, heading, math.rad(200));
	Turn( wheel, y_axis, -math.rad(30), math.rad(200));
	Turn( arm, y_axis, math.rad(30),10);
	Turn( hand, y_axis, math.rad(30),10);
	Turn( cannon, y_axis, -pitch-math.rad(30),10);
	 
	WaitForTurn (belt, z_axis)
	WaitForTurn (wheel, y_axis)
	
	StartThread(RestoreAfterDelay);

	return is_open;	
end

function script.FireWeapon(n)
	EmitSfx(muzzle, 1024)
	Move(barrel1,x_axis,-1,5);
	Move(barrel2,x_axis,-1,7);
	Move(barrel3,x_axis,-1,9);
	
	Sleep(200);
	Move(barrel3,x_axis,0,2);
	Sleep(100);
	Move(barrel2,x_axis,0,2);
	Sleep(100);
	Move(barrel1,x_axis,0,2);
	
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else		
		return 2 -- corpsetype
	end
end
