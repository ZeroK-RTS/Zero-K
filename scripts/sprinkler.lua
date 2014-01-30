include "constants.lua"

--pieces
local concrete, belt = piece('Concrete','Belt');
local wheel, arm, hand, cannon = piece('Wheel', 'Arm','Hand', 'Cannon');
local barrel1, barrel2, barrel3, muzzle = piece("Barrel1","Barrel2","Barrel3","Muzzle");
local lidLeft, lidRight = piece("lidLeft","lidRight");
local aimProxy = piece("AimProxy");

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam
local spGetUnitIsStunned = Spring.GetUnitIsStunned

local unpackSpeed = 5;

local smokePiece = { lidLeft, lidRight, wheel}

--variables
local is_open = false
local restore_delay = 2000;

--signals
local aim  = 2
local open = 8
local close = 16

-- private functions

function Sweep()
	while(true) do
		Sleep(33);
		EmitSfx(muzzle, SFX.FIRE_WEAPON);
	end
end

-- event handlers


function script.Create()
	is_open = true;
	
	Turn(cannon, x_axis, math.rad(10));
	Spin(belt, y_axis, 2);
	Move(muzzle, z_axis, 5);
	StartThread(Sweep)
	
end


function script.QueryWeapon(n)
	return muzzle
end

function script.AimFromWeapon(n) 
	return aimProxy 
end

function script.AimWeapon(num, heading, pitch )
	return false
end

function script.FireWeapon(n)
	EmitSfx(muzzle, 1024)
	Move(barrel1,z_axis,-1,5);
	Move(barrel2,z_axis,-1,7);
	Move(barrel3,z_axis,-1,9);
	
	Sleep(200);
	Move(barrel3,z_axis,0,2);
	Sleep(100);
	Move(barrel2,z_axis,0,2);
	Sleep(100);
	Move(barrel1,z_axis,0,2);
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
