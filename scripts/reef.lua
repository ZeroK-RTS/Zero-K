local BayAft = piece('BayAft');
local BayAftHatch = piece('BayAftHatch');
local BayAftSlider = piece('BayAftSlider');
local BayFore = piece('BayFore');
local BayForeHatch = piece('BayForeHatch');
local BayForeSlider = piece('BayForeSlider');
local BayInner = piece('BayInner');
local BayInnerHatch = piece('BayInnerHatch');
local BayInnerSlider = piece('BayInnerSlider');
local BayLower = piece('BayLower');
local BayLowerHatch = piece('BayLowerHatch');
local BayLowerSlider = piece('BayLowerSlider');
local BayUpper = piece('BayUpper');
local BayUpperHatch = piece('BayUpperHatch');
local BayUpperSlider = piece('BayUpperSlider');
local Hull = piece('Hull');
local PadAft = piece('PadAft');
local PadAftNanoL = piece('PadAftNanoL');
local PadAftNanoR = piece('PadAftNanoR');
local PadFront = piece('PadFront');
local PadFrontNanoL = piece('PadFrontNanoL');
local PadFrontNanoR = piece('PadFrontNanoR');
local Radar = piece('Radar'); 
local Launcher = piece('Launcher');
local Wake1 = piece('Wake1');
local Wake2 = piece('Wake2');


local droneBays = {};

droneBays[BayAft] = {
		slider=BayAftSlider,
		hatch=BayAftHatch
}
droneBays[BayFore] = {
	slider=BayForeSlider,
	hatch=BayForeHatch
}
droneBays[BayUpper] = {
	slider=BayUpperSlider,
	hatch=BayUpperHatch
}
droneBays[BayLower] = {
	slider=BayLowerSlider,
	hatch=BayLowerHatch
}



include "constants.lua"

local smokePiece = {Hull,BayAft,BayFore,BayInner,BayLower,BayUpper,PadAft,PadFront,Radar, Launcher}

local missileGun = 1

local SIG_MOVE = 1
local SIG_RESTORE = 2

function script.Create()
	Hide(Launcher)
	Hide(Wake1)
	Hide(Wake2)
	StartThread(SmokeUnit, smokePiece)
	
	while select(5, Spring.GetUnitHealth(unitID)) < 1  do
		Sleep(1000)
	end
	Spin( Radar , y_axis, rad(60) )
end

local function StartMoving()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	while  true  do
		EmitSfx( Wake1,  2 )
		EmitSfx( Wake2,  2 )
		Sleep(150)
	end
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	Signal( SIG_MOVE)
end

local function RestoreAfterDelay()
	Signal( SIG_RESTORE)
	SetSignalMask( SIG_RESTORE)
	Sleep(3000)
	Turn( hatch1 , x_axis, 0, rad(35) )
	Turn( hatch2 , x_axis, 0, rad(35) )
	Turn( hatch3 , x_axis, 0, rad(35) )
	Turn( hatch4 , x_axis, 0, rad(35) )
	Turn( hatch5 , x_axis, 0, rad(35) )
end

function script.AimWeapon(num, heading, pitch)
		return true
end

function script.FireWeapon(num)

end

function script.AimFromWeapon(num)
	return Launcher;
end

function script.QueryWeapon(num)
	return Launcher;
end


function script.QueryLandingPads()
	return {PadFront, PadAft}
end

function Carrier_droneStarted(piece)
	if(piece) then
		local bay = droneBays[piece];
		if(bay) then
			Signal("bay"..piece)
			Move(bay.slider,x_axis,-7,4);
			Turn(bay.hatch, z_axis, math.rad(-100),math.rad(60));
		end
	end
end

local function closeBay(piece)
	if(piece) then	
		local bay = droneBays[piece];
		if(bay) then
			Signal("bay"..piece)
			SetSignalMask( "bay"..piece)
			Sleep(1000);
			Move(bay.slider,x_axis,0,4);
			Turn(bay.hatch, z_axis, math.rad(0),math.rad(40));
		end
	end
end

function Carrier_droneCompleted(piece)
	if(piece) then	
		local bay = droneBays[piece];
		if(bay) then
			StartThread(closeBay,piece);
		end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		return 1
	elseif severity <= 0.50 then
		return 1
	else
		return 2
	end
end
