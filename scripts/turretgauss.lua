include "constants.lua"

--pieces
local concrete, belt = piece('Concrete','Belt');
local wheel, arm, hand, cannon = piece('Wheel', 'Arm','Hand', 'Cannon');
local barrel1, barrel2, barrel3, muzzle = piece("Barrel1","Barrel2","Barrel3","Muzzle");
local muzzleProxy = piece("MuzzleProxy")
local lidLeft, lidRight = piece("lidLeft","lidRight");
local aimProxy = piece("AimProxy");

local legs = piece("Legs");

local pillars = {}

for i = 1,6 do
	pillars[i] = piece("Pillar"..i);
end

local pillarHeight = 0;
local numPillars = 0;

local spGetUnitRulesParam 	= Spring.GetUnitRulesParam
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth

local smokePiece = { lidLeft, lidRight, wheel}

--variables
local unpackSpeed = math.rad(286);
local weaponRange = WeaponDefNames["turretgauss_gauss"].range
local isClosed = false--used for aim
local rangeChanged = false
local restore_delay = 2000;
local BUNKERED_AUTOHEAL = tonumber (UnitDef.customParams.armored_regen or 20) / 2 -- applied every 0.5s

--signals
local SIGanimation = 1
local SIGrestore = 2

-- private functions

-- Closing animation, contains the armored state.
local function Close()
	Signal(SIGanimation)
	SetSignalMask(SIGanimation)
	
	--animation
	if not isClosed then
		Move(barrel1, y_axis, 3, 3);
		Move(barrel2, y_axis, 2, 2);
		Move(barrel3, y_axis, 3, 3);
		
		Turn(wheel, x_axis, math.rad(-15), unpackSpeed/2.5);
		Turn(arm,x_axis,math.rad(30), unpackSpeed)
		Turn(hand, x_axis, math.rad(60), unpackSpeed/10);
		Turn(cannon, x_axis, math.rad(65), unpackSpeed/1.5);
		WaitForTurn(cannon, x_axis);
		
		Turn(arm,x_axis,math.rad(107), unpackSpeed/2.5);
		WaitForTurn(arm,x_axis);
		
		Turn(wheel, x_axis, math.rad(55), unpackSpeed/2);
		WaitForTurn(wheel, x_axis);
	end
	isClosed = true
	Turn(wheel, x_axis, math.rad(66), unpackSpeed/10);
	Turn(lidLeft, y_axis, math.rad(-90), unpackSpeed/1.5);
	Turn(lidRight, y_axis, math.rad(90), unpackSpeed/1.5);
	WaitForTurn(lidLeft, y_axis)
	--end of animation
	
	Spring.SetUnitArmored(unitID, true);
	while true do
		local stunned_or_inbuild = spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1)
		if not stunned_or_inbuild then
			local hp = spGetUnitHealth(unitID)
			local slowMult = (spGetUnitRulesParam(unitID,"baseSpeedMult") or 1)
			local newHp = hp + slowMult*BUNKERED_AUTOHEAL
			spSetUnitHealth(unitID, newHp)
		end
		Sleep(500)
	end
end

-- Controls delay for when it closes
local function RestoreAfterDelay()
	Signal(SIGrestore)
	SetSignalMask(SIGrestore+SIGanimation)
	Sleep(restore_delay);
	
	repeat
		local inactive = spGetUnitIsStunned(unitID)
		if inactive then
			Sleep(restore_delay)
		end
	until not inactive
	
	StartThread(Close);
end
	
-- event handlers
function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(RestoreAfterDelay);
	
	--hacks to move invisible pieces
	Move(aimProxy, y_axis, -13)
--	Move(muzzleProxy, y_axis, 6)
	Turn(muzzle, y_axis, math.rad(-90))
	
	Hide(legs);
	for i = 1,6 do
		Hide(pillars[i]);
	end
	
	local x,y,z = Spring.GetUnitPosition(unitID);
	local gy = Spring.GetGroundHeight(x,z);
	pillarHeight = y-gy;
	
	if(pillarHeight > 0) then
		Show(legs);
		-- each pillar segment is 45 elmo tall
		-- legs are 35 elmos tall
		if(pillarHeight > 35) then
			numPillars = math.min(math.ceil((pillarHeight-35)/45), 6)
			for i = 1, numPillars do
				Show(pillars[i]);
			end
		end
	end
end

function script.BlockShot(num, targetID)
	if targetID then
		local dist = Spring.GetUnitSeparation(unitID, targetID)
		if dist then
			dist = dist + 30
			if dist > weaponRange then
				-- noExplode weapons are hardcoded in the engine to expire after they have travelled their range in distance.
				rangeChanged = true
				Spring.SetUnitWeaponState(unitID, 1, "range", dist)
			end
		end
	end
	return false
end

function script.EndBurst()
	if rangeChanged then
		Spring.SetUnitWeaponState(unitID, 1, "range", weaponRange)
	end
end

function script.QueryWeapon(n)
	if isClosed then
		return aimProxy
	else
		return muzzle
	end
end

function script.AimFromWeapon(n)
	return aimProxy
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIGanimation)
	SetSignalMask(SIGanimation)
	StartThread(RestoreAfterDelay)
	
--	Turn(aimProxy, z_axis, heading)
	
	-- animation handled after here
	Turn(belt, z_axis, heading, math.rad(200))
	if isClosed then
		Spring.SetUnitArmored(unitID, false);
		
		--Opening animation
		Turn(lidLeft, y_axis, math.rad(0), unpackSpeed);
		Turn(lidRight, y_axis, math.rad(0), unpackSpeed);
		WaitForTurn(lidLeft, y_axis);
		
		Turn(wheel, x_axis, math.rad(-15), unpackSpeed)
		WaitForTurn(wheel, x_axis);
		
		Move(barrel1, y_axis, 0, 6);
		Move(barrel2, y_axis, 0, 6);
		Move(barrel3, y_axis, 0, 6);
		
		isClosed = false
	end
	
	local function LeanControl(angle)
		if angle < 0 then 
			return -angle 
		else
			return 0
		end
	end
	
	local lean = LeanControl(pitch + math.rad(30))--min pitch plus pi/6 is -60 degrees or approximately 1 in radians
	local wh = math.rad(-30) + (lean * math.rad(90));
	local ar = math.rad(30) + (lean * math.rad(5));
	local ha = math.rad(30) - (lean * math.rad(25));
	Turn(wheel, x_axis, wh, unpackSpeed/2.5);--constant a
	Turn(arm, x_axis, ar, unpackSpeed);--constant b
	Turn(hand, x_axis, ha, unpackSpeed);--constant c
	Turn(cannon, x_axis, -wh-ar-ha-pitch, unpackSpeed);--constant (-a-b-c)
	
	WaitForTurn(belt, z_axis)
	WaitForTurn(cannon, x_axis)
	WaitForTurn(wheel, x_axis)
	
	return true;
end

function script.FireWeapon(n)
	EmitSfx(muzzle, 1024)
	Move(barrel1, y_axis, 1, 5);
	Move(barrel2, y_axis, 1, 7);
	Move(barrel3, y_axis, 1, 9);
	
	Sleep(200);
	Move(barrel3, y_axis, 0, 2);
	Sleep(100);
	Move(barrel2, y_axis, 0, 2);
	Sleep(100);
	Move(barrel1, y_axis, 0, 2);
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	
	if(pillarHeight > 0) then
		Explode(legs, SFX.SHATTER)
	end
	
	if(numPillars > 0) then
		for i = 1, numPillars do
			Explode(pillars[i],SFX.SHATTER);
		end
	end
	
	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
