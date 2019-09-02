local base = piece 'base'
local head = piece 'head'
local rupleg1 = piece 'rupleg1'
local rupleg2 = piece 'rupleg2'
local rupleg3 = piece 'rupleg3'
local lupleg1 = piece 'lupleg1'
local lupleg2 = piece 'lupleg2'
local lupleg3 = piece 'lupleg3'
local lleg3 = piece 'lleg3'
local lleg2 = piece 'lleg2'
local lleg1 = piece 'lleg1'
local rleg3 = piece 'rleg3'
local rleg2 = piece 'rleg2'
local rleg1 = piece 'rleg1'
local nano1 = piece 'nano1'
local nano2 = piece 'nano2'
local digger = piece 'digger'
--linear constant 65536

include "constants.lua"
include 'reliableStartMoving.lua'

--cob values
local cloaked = COB.CLOAKED
local stealth = COB.STEALTH

local smokePiece = {base}

local burrowed = false
local SIG_BURROW = 1
local SIG_Walk = 2

local function Burrow()
	Signal(SIG_BURROW)
	SetSignalMask(SIG_BURROW)
	Sleep(400)
	
	Signal(SIG_Walk)
	burrowed = true
	EmitSfx(digger, GG.Script.UNIT_SFX1)
	
	--burrow
	Move(base, y_axis, -1.500000, 1.500000)
	Turn(base, x_axis, math.rad(-20.000000), math.rad(20.000000))
	
	if(burrowed == true) then
		GG.SetWantedCloaked(unitID, 1)
		Spring.UnitScript.SetUnitValue(stealth, 1)
	end
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while true do
	
		Turn(base, x_axis, math.rad(2.098901))
		Turn(base, x_axis, 0, math.rad(21.000000))
		Turn(base, y_axis, math.rad(1.049451))
		Turn(base, y_axis, 0, math.rad(3.000000))
		Turn(rupleg1, y_axis, math.rad(27.423077))
		Turn(rupleg1, y_axis, math.rad(7.000000), math.rad(198.000000))
		Turn(rupleg2, y_axis, math.rad(-13.351648))
		Turn(rupleg2, z_axis, 0)
		Turn(rupleg2, z_axis, math.rad(-(27.005495)), math.rad(276.000000))
		Turn(rupleg3, y_axis, math.rad(27.774725))
		Turn(rupleg3, y_axis, math.rad(7.000000), math.rad(205.000000))
		Turn(lupleg1, y_axis, math.rad(21.434066))
		Turn(lupleg1, z_axis, 0)
		Turn(lupleg1, z_axis, math.rad(-(-24.005495)), math.rad(247.000000))
		Turn(lupleg2, y_axis, math.rad(-14.412088))
		Turn(lupleg2, y_axis, 0, math.rad(138.000000))
		Turn(lupleg2, z_axis, math.rad(-7.379121))
		Turn(lupleg2, z_axis, math.rad(-(0.000000)), math.rad(74.000000))
		Turn(lupleg3, y_axis, math.rad(13.351648))
		Turn(lupleg3, z_axis, 0)
		Turn(lupleg3, z_axis, math.rad(-(-45.010989)), math.rad(456.000000))
		Turn(lleg3, z_axis, 0)
		Turn(lleg3, z_axis, math.rad(-(35.005495)), math.rad(357.000000))
		Turn(lleg2, z_axis, 0)
		Turn(lleg2, z_axis, math.rad(-(-11.000000)), math.rad(120.000000))
		Turn(lleg1, z_axis, 0)
		Turn(lleg1, z_axis, math.rad(-(11.000000)), math.rad(116.000000))
		Turn(rleg3, z_axis, 0)
		Turn(rleg3, z_axis, math.rad(-(8.000000)), math.rad(84.000000))
		Turn(rleg2, z_axis, 0)
		Turn(rleg2, z_axis, math.rad(-(-34.005495)), math.rad(350.000000))
		Turn(rleg1, z_axis, 0)
		Turn(rleg1, z_axis, math.rad(-(9.000000)), math.rad(95.000000))
		
		Sleep(149)
	
		Turn(base, x_axis, math.rad(-1.000000), math.rad(10.000000))
		Turn(base, y_axis, 0, math.rad(10.000000))
		Turn(rupleg1, y_axis, math.rad(-13.000000), math.rad(207.000000))
		Turn(rupleg2, y_axis, math.rad(8.000000), math.rad(221.000000))
		Turn(rupleg2, z_axis, math.rad(-(54.010989)), math.rad(267.000000))
		Turn(rupleg3, y_axis, math.rad(-14.000000), math.rad(218.000000))
		Turn(lupleg1, y_axis, math.rad(1.000000), math.rad(200.000000))
		Turn(lupleg1, z_axis, math.rad(-(-64.010989)), math.rad(400.000000))
		Turn(lupleg2, y_axis, math.rad(20.000000), math.rad(214.000000))
		Turn(lupleg3, y_axis, math.rad(-10.000000), math.rad(235.000000))
		Turn(lupleg3, z_axis, math.rad(-(-75.016484)), math.rad(305.000000))
		Turn(lleg3, z_axis, math.rad(-(63.010989)), math.rad(281.000000))
		Turn(lleg2, z_axis, math.rad(-(0.000000)), math.rad(119.000000))
		Turn(lleg1, z_axis, math.rad(-(66.010989)), math.rad(548.000000))
		Turn(rleg3, z_axis, math.rad(-(0.000000)), math.rad(84.000000))
		Turn(rleg2, z_axis, math.rad(-(-63.010989)), math.rad(288.000000))
		Turn(rleg1, z_axis, math.rad(-(0.000000)), math.rad(94.000000))
		
		Sleep(150)

		Turn(base, x_axis, math.rad(-1.000000), math.rad(3.000000))
		Turn(base, y_axis, math.rad(-1.000000), math.rad(6.000000))
		Turn(rupleg1, y_axis, math.rad(-20.000000), math.rad(69.000000))
		Turn(rupleg2, y_axis, math.rad(17.000000), math.rad(83.000000))
		Turn(rupleg2, z_axis, math.rad(-(8.000000)), math.rad(454.000000))
		Turn(rupleg3, y_axis, math.rad(-20.000000), math.rad(55.000000))
		Turn(lupleg1, y_axis, math.rad(-10.000000), math.rad(118.000000))
		Turn(lupleg1, z_axis, math.rad(-(-14.000000)), math.rad(499.000000))
		Turn(lupleg2, y_axis, math.rad(31.005495), math.rad(104.000000))
		Turn(lupleg3, y_axis, math.rad(-15.000000), math.rad(55.000000))
		Turn(lupleg3, z_axis, math.rad(-(-10.000000)), math.rad(646.000000))
		Turn(lleg3, z_axis, math.rad(-(17.000000)), math.rad(454.000000))
		Turn(lleg1, z_axis, math.rad(-(10.000000)), math.rad(555.000000))
		Turn(rleg2, z_axis, math.rad(-(-9.000000)), math.rad(534.000000))
		
		Sleep(151)
	
		Turn(base, x_axis, 0, math.rad(7.000000))
		Turn(base, y_axis, 0, math.rad(10.000000))
		Turn(rupleg1, y_axis, math.rad(-13.000000), math.rad(70.000000))
		Turn(rupleg1, z_axis, math.rad(-(39.005495)), math.rad(393.000000))
		Turn(rupleg2, y_axis, math.rad(11.000000), math.rad(59.000000))
		Turn(rupleg2, z_axis, math.rad(-(-2.000000)), math.rad(105.000000))
		Turn(rupleg3, y_axis, math.rad(-3.000000), math.rad(168.000000))
		Turn(rupleg3, z_axis, math.rad(-(28.005495)), math.rad(284.000000))
		Turn(lupleg1, y_axis, 0, math.rad(101.000000))
		Turn(lupleg1, z_axis, math.rad(-(2.000000)), math.rad(165.000000))
		Turn(lupleg2, y_axis, math.rad(19.000000), math.rad(116.000000))
		Turn(lupleg2, z_axis, math.rad(-(-40.005495)), math.rad(407.000000))
		Turn(lupleg3, y_axis, math.rad(-7.000000), math.rad(84.000000))
		Turn(lupleg3, z_axis, math.rad(-(4.000000)), math.rad(151.000000))
		Turn(lleg3, z_axis, math.rad(-(0.000000)), math.rad(179.000000))
		Turn(lleg2, z_axis, math.rad(-(32.005495)), math.rad(327.000000))
		Turn(lleg1, z_axis, math.rad(-(0.000000)), math.rad(105.000000))
		Turn(rleg3, z_axis, math.rad(-(-17.000000)), math.rad(175.000000))
		Turn(rleg2, z_axis, math.rad(-(0.000000)), math.rad(98.000000))
		Turn(rleg1, z_axis, math.rad(-(-19.000000)), math.rad(196.000000))
		
		Sleep(150)
	
		Turn(base, x_axis, 0, math.rad(14.000000))
		Turn(base, y_axis, math.rad(1.000000), math.rad(14.000000))
		Turn(rupleg1, y_axis, math.rad(8.000000), math.rad(210.000000))
		Turn(rupleg1, z_axis, math.rad(-(52.010989)), math.rad(133.000000))
		Turn(rupleg2, y_axis, 0, math.rad(112.000000))
		Turn(rupleg3, y_axis, math.rad(15.000000), math.rad(189.000000))
		Turn(rupleg3, z_axis, math.rad(-(48.010989)), math.rad(196.000000))
		Turn(lupleg1, y_axis, math.rad(9.000000), math.rad(98.000000))
		Turn(lupleg2, y_axis, math.rad(3.000000), math.rad(158.000000))
		Turn(lupleg2, z_axis, math.rad(-(-68.016484)), math.rad(277.000000))
		Turn(lupleg3, y_axis, math.rad(1.000000), math.rad(91.000000))
		Turn(lleg3, z_axis, math.rad(-(-10.000000)), math.rad(101.000000))
		Turn(lleg2, z_axis, math.rad(-(64.010989)), math.rad(316.000000))
		Turn(lleg1, z_axis, math.rad(-(-5.000000)), math.rad(59.000000))
		Turn(rleg3, z_axis, math.rad(-(-52.010989)), math.rad(348.000000))
		Turn(rleg2, z_axis, math.rad(-(3.000000)), math.rad(35.000000))
		Turn(rleg1, z_axis, math.rad(-(-50.010989)), math.rad(309.000000))
		
		Sleep(150)
	
		Turn(base, x_axis, math.rad(1.000000), math.rad(7.000000))
		Turn(base, y_axis, math.rad(1.000000), math.rad(3.000000))
		Turn(rupleg1, y_axis, math.rad(16.000000), math.rad(84.000000))
		Turn(rupleg1, z_axis, math.rad(-(39.005495)), math.rad(133.000000))
		Turn(rupleg2, y_axis, math.rad(-11.000000), math.rad(112.000000))
		Turn(rupleg3, y_axis, math.rad(24.005495), math.rad(87.000000))
		Turn(rupleg3, z_axis, math.rad(-(28.005495)), math.rad(196.000000))
		Turn(lupleg1, y_axis, math.rad(20.000000), math.rad(105.000000))
		Turn(lupleg2, y_axis, math.rad(-3.000000), math.rad(77.000000))
		Turn(lupleg2, z_axis, math.rad(-(-40.005495)), math.rad(277.000000))
		Turn(lupleg3, y_axis, math.rad(18.000000), math.rad(165.000000))
		Turn(lleg3, z_axis, math.rad(-(0.000000)), math.rad(101.000000))
		Turn(lleg2, z_axis, math.rad(-(37.005495)), math.rad(267.000000))
		Turn(lleg1, z_axis, math.rad(-(0.000000)), math.rad(59.000000))
		Turn(rleg3, z_axis, math.rad(-(-17.000000)), math.rad(348.000000))
		Turn(rleg2, z_axis, math.rad(-(0.000000)), math.rad(35.000000))
		Turn(rleg1, z_axis, math.rad(-(-23.005495)), math.rad(267.000000))
		Sleep(150)
	end

end

local function UnBurrow()
	Signal(SIG_BURROW)
	burrowed = false
	GG.SetWantedCloaked(unitID, 0)
	Spring.UnitScript.SetUnitValue(stealth, 0)
	Move(base, y_axis, 0.000000, 2.000000)
	Turn(base, x_axis, 0, math.rad(60.000000))
	
	--Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 0.2)
	--Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 5)
	--GG.UpdateUnitAttributes(unitID)
	
	Sleep(600)
	
	--Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", 1)
	--Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", 1)
	--GG.UpdateUnitAttributes(unitID)
	EmitSfx(digger, GG.Script.UNIT_SFX1)
	
	StartThread(Walk)
end

function script.StartMoving()
	Signal(SIG_BURROW)
	if burrowed then
		StartThread(UnBurrow)
	else
		StartThread(Walk)
	end
end

function script.StopMoving()
	StartThread(Burrow)
end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.StartStopMovingControl, unitID, script.StartMoving, script.StopMoving, nil, true)
	if not Spring.GetUnitIsStunned(unitID) then
		Burrow()
	end
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.NONE)
	Explode(head, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lleg1, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lleg2, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lleg3, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lupleg1, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lupleg2, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(lupleg3, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rleg1, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rleg2, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rleg3, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rupleg1, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rupleg2, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	Explode(rupleg3, SFX.FALL, SFX.FIRE, SFX.SMOKE)
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
