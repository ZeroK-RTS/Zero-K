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

local smokePiece = {base}
local movingData = {}

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
	Move(base, y_axis, -1.5, 1.5)
	Turn(base, x_axis, math.rad(-20), math.rad(20))
	
	if(burrowed == true) then
		GG.SetWantedCloaked(unitID, 1)
	end
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while true do
	
		Turn(base, x_axis, math.rad(2))
		Turn(base, x_axis, 0, math.rad(21))
		Turn(base, y_axis, math.rad(1))
		Turn(base, y_axis, 0, math.rad(3))
		Turn(rupleg1, y_axis, math.rad(27))
		Turn(rupleg1, y_axis, math.rad(7), math.rad(198))
		Turn(rupleg2, y_axis, math.rad(-13))
		Turn(rupleg2, z_axis, 0)
		Turn(rupleg2, z_axis, math.rad(-27), math.rad(276))
		Turn(rupleg3, y_axis, math.rad(28))
		Turn(rupleg3, y_axis, math.rad(7), math.rad(205))
		Turn(lupleg1, y_axis, math.rad(21))
		Turn(lupleg1, z_axis, 0)
		Turn(lupleg1, z_axis, math.rad(24), math.rad(247))
		Turn(lupleg2, y_axis, math.rad(-14))
		Turn(lupleg2, y_axis, 0, math.rad(138))
		Turn(lupleg2, z_axis, math.rad(-7))
		Turn(lupleg2, z_axis, 0, math.rad(74))
		Turn(lupleg3, y_axis, math.rad(13))
		Turn(lupleg3, z_axis, 0)
		Turn(lupleg3, z_axis, math.rad(45), math.rad(456))
		Turn(lleg3, z_axis, 0)
		Turn(lleg3, z_axis, math.rad(-35), math.rad(357))
		Turn(lleg2, z_axis, 0)
		Turn(lleg2, z_axis, math.rad(11), math.rad(120))
		Turn(lleg1, z_axis, 0)
		Turn(lleg1, z_axis, math.rad(-11), math.rad(116))
		Turn(rleg3, z_axis, 0)
		Turn(rleg3, z_axis, math.rad(-8), math.rad(84))
		Turn(rleg2, z_axis, 0)
		Turn(rleg2, z_axis, math.rad(34), math.rad(350))
		Turn(rleg1, z_axis, 0)
		Turn(rleg1, z_axis, math.rad(-9), math.rad(95))
		
		Sleep(149)
	
		Turn(base, x_axis, math.rad(-1), math.rad(10))
		Turn(base, y_axis, 0, math.rad(10))
		Turn(rupleg1, y_axis, math.rad(-13), math.rad(207))
		Turn(rupleg2, y_axis, math.rad(8), math.rad(221))
		Turn(rupleg2, z_axis, math.rad(-54), math.rad(267))
		Turn(rupleg3, y_axis, math.rad(-14), math.rad(218))
		Turn(lupleg1, y_axis, math.rad(1), math.rad(200))
		Turn(lupleg1, z_axis, math.rad(64), math.rad(400))
		Turn(lupleg2, y_axis, math.rad(20), math.rad(214))
		Turn(lupleg3, y_axis, math.rad(-10), math.rad(235))
		Turn(lupleg3, z_axis, math.rad(75), math.rad(305))
		Turn(lleg3, z_axis, math.rad(-63), math.rad(281))
		Turn(lleg2, z_axis, 0, math.rad(119))
		Turn(lleg1, z_axis, math.rad(-66), math.rad(548))
		Turn(rleg3, z_axis, 0, math.rad(84))
		Turn(rleg2, z_axis, math.rad(63), math.rad(288))
		Turn(rleg1, z_axis, 0, math.rad(94))
		
		Sleep(150)

		Turn(base, x_axis, math.rad(-1), math.rad(3))
		Turn(base, y_axis, math.rad(-1), math.rad(6))
		Turn(rupleg1, y_axis, math.rad(-20), math.rad(69))
		Turn(rupleg2, y_axis, math.rad(17), math.rad(83))
		Turn(rupleg2, z_axis, math.rad(-8), math.rad(454))
		Turn(rupleg3, y_axis, math.rad(-20), math.rad(55))
		Turn(lupleg1, y_axis, math.rad(-10), math.rad(118))
		Turn(lupleg1, z_axis, math.rad(14), math.rad(499))
		Turn(lupleg2, y_axis, math.rad(31), math.rad(104))
		Turn(lupleg3, y_axis, math.rad(-15), math.rad(55))
		Turn(lupleg3, z_axis, math.rad(10), math.rad(646))
		Turn(lleg3, z_axis, math.rad(-17), math.rad(454))
		Turn(lleg1, z_axis, math.rad(-10), math.rad(555))
		Turn(rleg2, z_axis, math.rad(9), math.rad(534))
		
		Sleep(151)
	
		Turn(base, x_axis, 0, math.rad(7))
		Turn(base, y_axis, 0, math.rad(10))
		Turn(rupleg1, y_axis, math.rad(-13), math.rad(70))
		Turn(rupleg1, z_axis, math.rad(-39), math.rad(393))
		Turn(rupleg2, y_axis, math.rad(11), math.rad(59))
		Turn(rupleg2, z_axis, math.rad(2), math.rad(105))
		Turn(rupleg3, y_axis, math.rad(-3), math.rad(168))
		Turn(rupleg3, z_axis, math.rad(-28), math.rad(284))
		Turn(lupleg1, y_axis, 0, math.rad(101))
		Turn(lupleg1, z_axis, math.rad(-2), math.rad(165))
		Turn(lupleg2, y_axis, math.rad(19), math.rad(116))
		Turn(lupleg2, z_axis, math.rad(40), math.rad(407))
		Turn(lupleg3, y_axis, math.rad(-7), math.rad(84))
		Turn(lupleg3, z_axis, math.rad(-4), math.rad(151))
		Turn(lleg3, z_axis, 0, math.rad(179))
		Turn(lleg2, z_axis, math.rad(-32), math.rad(327))
		Turn(lleg1, z_axis, 0, math.rad(105))
		Turn(rleg3, z_axis, math.rad(17), math.rad(175))
		Turn(rleg2, z_axis, 0, math.rad(98))
		Turn(rleg1, z_axis, math.rad(19), math.rad(196))
		
		Sleep(150)
	
		Turn(base, x_axis, 0, math.rad(14))
		Turn(base, y_axis, math.rad(1), math.rad(14))
		Turn(rupleg1, y_axis, math.rad(8), math.rad(210))
		Turn(rupleg1, z_axis, math.rad(-52), math.rad(133))
		Turn(rupleg2, y_axis, 0, math.rad(112))
		Turn(rupleg3, y_axis, math.rad(15), math.rad(189))
		Turn(rupleg3, z_axis, math.rad(-48), math.rad(196))
		Turn(lupleg1, y_axis, math.rad(9), math.rad(98))
		Turn(lupleg2, y_axis, math.rad(3), math.rad(158))
		Turn(lupleg2, z_axis, math.rad(68), math.rad(277))
		Turn(lupleg3, y_axis, math.rad(1), math.rad(91))
		Turn(lleg3, z_axis, math.rad(10), math.rad(101))
		Turn(lleg2, z_axis, math.rad(-64), math.rad(316))
		Turn(lleg1, z_axis, math.rad(5), math.rad(59))
		Turn(rleg3, z_axis, math.rad(52), math.rad(348))
		Turn(rleg2, z_axis, math.rad(-3), math.rad(35))
		Turn(rleg1, z_axis, math.rad(50), math.rad(309))
		
		Sleep(150)
	
		Turn(base, x_axis, math.rad(1), math.rad(7))
		Turn(base, y_axis, math.rad(1), math.rad(3))
		Turn(rupleg1, y_axis, math.rad(16), math.rad(84))
		Turn(rupleg1, z_axis, math.rad(-39), math.rad(133))
		Turn(rupleg2, y_axis, math.rad(-11), math.rad(112))
		Turn(rupleg3, y_axis, math.rad(24), math.rad(87))
		Turn(rupleg3, z_axis, math.rad(-28), math.rad(196))
		Turn(lupleg1, y_axis, math.rad(20), math.rad(105))
		Turn(lupleg2, y_axis, math.rad(-3), math.rad(77))
		Turn(lupleg2, z_axis, math.rad(40), math.rad(277))
		Turn(lupleg3, y_axis, math.rad(18), math.rad(165))
		Turn(lleg3, z_axis, 0, math.rad(101))
		Turn(lleg2, z_axis, math.rad(-37), math.rad(267))
		Turn(lleg1, z_axis, 0, math.rad(59))
		Turn(rleg3, z_axis, math.rad(17), math.rad(348))
		Turn(rleg2, z_axis, 0, math.rad(35))
		Turn(rleg1, z_axis, math.rad(23), math.rad(267))
		Sleep(150)
	end

end

local function UnBurrow()
	Signal(SIG_BURROW)
	burrowed = false
	GG.SetWantedCloaked(unitID, 0)
	Move(base, y_axis, 0, 2)
	Turn(base, x_axis, 0, math.rad(60))
	
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
	movingData.moving = true
	Signal(SIG_BURROW)
	if burrowed then
		StartThread(UnBurrow)
	else
		StartThread(Walk)
	end
end

function script.StopMoving()
	movingData.moving = false
	StartThread(Burrow)
end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(GG.StartStopMovingControl, unitID, script.StartMoving, script.StopMoving, nil, true, movingData)
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
