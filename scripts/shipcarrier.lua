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
local WakeForeRight = piece('WakeForeRight');
local WakeForeLeft = piece('WakeForeLeft');
local WakeAftRight = piece('WakeAftRight');
local WakeAftLeft = piece('WakeAftLeft');

local DroneAft = piece('DroneAft');
local DroneFore = piece('DroneFore');
local DroneUpper = piece('DroneUpper');
local DroneLower = piece('DroneLower');

local LandingAft = piece('LandingAft');
local LandingFore = piece('LandingFore');

local droneBays = {};

droneBays[DroneAft] = {
	slider=BayAftSlider,
	hatch=BayAftHatch
}
droneBays[DroneFore] = {
	slider=BayForeSlider,
	hatch=BayForeHatch
}
droneBays[DroneUpper] = {
	slider=BayUpperSlider,
	hatch=BayUpperHatch
}
droneBays[DroneLower] = {
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
	Hide(WakeForeLeft)
	Hide(WakeForeRight)
	Hide(WakeAftLeft)
	Hide(WakeAftRight)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	
	for bay,_ in pairs(droneBays) do
		Move(bay, x_axis, 16)
	end
	
	while select(5, Spring.GetUnitHealth(unitID)) < 1 do
		Sleep(1000)
	end
	Spin(Radar, y_axis, math.rad(60))
end

local function StartMoving()
	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	while true do
		if(not Spring.GetUnitIsCloaked(unitID)) then
			EmitSfx(WakeForeLeft, 2)
			EmitSfx(WakeForeRight, 2)
			EmitSfx(WakeAftLeft, 2)
			EmitSfx(WakeAftRight, 2)
		end
		Sleep(150)
	end
end

function script.StartMoving()
	StartThread(StartMoving)
end

function script.StopMoving()
	Signal(SIG_MOVE)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(3000)
end

function script.AimWeapon(num, heading, pitch)
	return true
end

function script.FireWeapon(num)
	return true;
end

function script.AimFromWeapon(num)
	return Radar;
end

function script.QueryWeapon(num)
	return Launcher;
end

function script.QueryLandingPads()
	return {LandingFore, LandingAft}
end

function Carrier_droneStarted(piece)
	if(piece) then
		local bay = droneBays[piece];
		if(bay) then
			Signal("bay"..piece)
			Move(bay.slider,x_axis,-7,3);
			Turn(bay.hatch, z_axis, math.rad(-100),math.rad(60));
		end
	end
end

local function closeBay(piece)
	if(piece) then
		local bay = droneBays[piece];
		if(bay) then
			Signal("bay"..piece)
			SetSignalMask("bay"..piece)
			Sleep(1000);
			Move(bay.slider,x_axis,0,3);
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

local function ExplodeBay(piece)
	Explode(droneBays[piece].slider, SFX.FIRE)
	Explode(droneBays[piece].hatch, SFX.FIRE)
	EmitSfx(piece, 1024)
end

local function DoSomeHax()
	Sleep(33)
	local commands = Spring.GetCommandQueue(unitID, 0)
	if commands == 0 then
		Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, 0)
	end
end

function script.BlockShot(num, targetID)
	StartThread(DoSomeHax)
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.50 then
		EmitSfx(DroneFore, 1024)
		Turn(BayForeHatch, z_axis, math.rad(-100),math.rad(200));

		GG.Script.InitializeDeathAnimation(unitID)
		Sleep(120)
		
		EmitSfx(DroneAft, 1024)
		Explode(BayAftSlider, SFX.FIRE)
		Explode(BayAftHatch, SFX.FIRE)
		
		Sleep(120)
		
		Explode(PadFrontNanoL, SFX.FIRE)
		Explode(PadFrontNanoR, SFX.FIRE)
		Hide(PadFrontNanoL);
		Hide(PadFrontNanoR);
		
		Sleep(120)

		EmitSfx(PadFront, 1024)
		Explode(PadFront, SFX.FIRE)
		Hide(PadFront)
		
		Sleep(120)
		
		Explode(PadAftNanoR, SFX.FIRE)
		Hide(PadAftNanoR);
		
		Sleep(120)
		ExplodeBay(DroneAft)
		Sleep(180)
		Explode(BayInnerSlider, SFX.FIRE)
		Explode(BayInnerHatch, SFX.FIRE)
		EmitSfx(BayInner, 1024)
		Sleep(100)
		ExplodeBay(DroneLower)
		Sleep(150)
		EmitSfx(DroneUpper, 1024)
		Turn(BayUpperHatch, z_axis, math.rad(-100),math.rad(200));
		return 1
	else
		return 2
	end
end
