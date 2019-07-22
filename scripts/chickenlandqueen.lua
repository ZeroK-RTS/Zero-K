include "constants.lua"

local spGetUnitHealth = Spring.GetUnitHealth

--pieces
local body, head, tail, leftWing1, rightWing1, leftWing2, rightWing2 = piece("body","head","tail","lwing1","rwing1","lwing2","rwing2")
local leftThigh, leftKnee, leftShin, leftFoot, rightThigh, rightKnee, rightShin, rightFoot = piece("lthigh", "lknee", "lshin", "lfoot", "rthigh", "rknee", "rshin", "rfoot")
local lforearml,lbladel,rforearml,rbladel,lforearmu,lbladeu,rforearmu,rbladeu = piece("lforearml", "lbladel", "rforearml", "rbladel", "lforearmu", "lbladeu", "rforearmu", "rbladeu")
local spike1, spike2, spike3, firepoint, spore1, spore2, spore3 = piece("spike1", "spike2", "spike3", "firepoint", "spore1", "spore2", "spore3")

local smokePiece = {}

local turretIndex = {
}

local bladeAngle = math.rad(140)

local jaws = {
	{forearm = lforearmu, blade = lbladeu, angle = bladeAngle},
	{forearm = lforearml, blade = lbladel, angle = bladeAngle},
	{forearm = rforearmu, blade = rbladeu, angle = -bladeAngle},
	{forearm = rforearml, blade = rbladel, angle = -bladeAngle},
}

--constants
local wingAngle = math.rad(40)
local wingSpeed = math.rad(120)
local tailAngle = math.rad(20)

local bladeExtendSpeed = math.rad(600)
local bladeRetractSpeed = math.rad(120)

local PACE = 0.6

--variables
local isMoving = false
local feet = true
local jawNum = 1

local malus = GG.malus or 1

--maximum HP for additional weapons
local healthSpore3 = 0.55
local healthStomp = 0.7
local healthDodoDrop = 0.6
local healthBasiliskDrop = 0.45
local healthTiamatDrop = 0.2

--signals
local SIG_Aim = {
	[1] = 1,
	[2] = 2,
}
local SIG_Move = 16


----------------------------------------------------------
local function RestoreAfterDelay()
	Sleep(1000)
end

local function DropDodoLoop()
	while true do
		local health, maxHealth = spGetUnitHealth(unitID)
		if (health/maxHealth) < healthDodoDrop then
			for i=1,malus do
				EmitSfx(tail, 2048+6)
				Sleep(500)
			end
		end
		Sleep(6000)
	end
end

local function DropBasiliskLoop()
	while true do
		local health, maxHealth = spGetUnitHealth(unitID)
		 if (health/maxHealth) < healthTiamatDrop then
			for i=1,malus do
				EmitSfx(tail, 2048+8)
				Sleep(1000)
			end
		elseif (health/maxHealth) < healthBasiliskDrop then
			for i=1,malus do
				EmitSfx(tail, 2048+7)
				Sleep(1000)
			end		
		end
		Sleep(8000)
	end
end

-- used for queen morph
function MorphFunc()
	--Move(body, y_axis, 100)
	--Sleep(33)
	--Move(body, y_axis, 0, 60)
end

local function Stomp(piece)
	local health, maxHealth = spGetUnitHealth(unitID)
	if (health/maxHealth) < healthStomp then EmitSfx(piece, 4096 + 5) end
end

local function Walk()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	while true do
		Turn(leftThigh, x_axis, math.rad(70), math.rad(115) * PACE)
		Turn(leftKnee, x_axis, math.rad(-40), math.rad(145) * PACE)
		Turn(leftShin, x_axis, math.rad(20), math.rad(145) * PACE)
		Turn(leftFoot, x_axis, math.rad(-50), math.rad(210) * PACE)
		Turn(rightThigh, x_axis, math.rad(-20), math.rad(210) * PACE)
		Turn(rightKnee, x_axis, math.rad(-60), math.rad(210) * PACE)
		Turn(rightShin, x_axis, math.rad(50), math.rad(210) * PACE)
		Turn(rightFoot, x_axis, math.rad(30), math.rad(210) * PACE)
			
		Turn(body, z_axis, math.rad(-(5)), math.rad(20))
		Turn(leftThigh, z_axis, math.rad(-(-5)), math.rad(20) * PACE)
		Turn(rightThigh, z_axis, math.rad(-(-5)), math.rad(20) * PACE)
		Move(body, y_axis, 10, 20)			
		Turn(tail, y_axis, math.rad(20), math.rad(40))
		Turn(head, x_axis, math.rad(-10), math.rad(20))
		Turn(tail, y_axis, math.rad(20), math.rad(20))
		WaitForTurn(leftThigh, x_axis)
		Sleep(0)	-- needed to prevent anim breaking, DO NOT REMOVE
		
		Stomp(leftFoot)
		Turn(leftThigh, x_axis, math.rad(-10), math.rad(160))
		Turn(leftKnee, x_axis, math.rad(15), math.rad(145) * PACE)
		Turn(leftShin, x_axis, math.rad(-60), math.rad(250) * PACE)
		Turn(leftFoot, x_axis, math.rad(30), math.rad(145) * PACE)
		Turn(rightThigh, x_axis, math.rad(40), math.rad(145) * PACE)
		Turn(rightKnee, x_axis, math.rad(-35), math.rad(145) * PACE)
		Turn(rightShin, x_axis, math.rad(-40), math.rad(145) * PACE)
		Turn(rightFoot, x_axis, math.rad(35), math.rad(145) * PACE)
		Move(body, y_axis, 0, 20)
		Turn(head, x_axis, math.rad(10), math.rad(20))
		Turn(tail, y_axis, math.rad(-20), math.rad(20))
		WaitForTurn(leftShin, x_axis)
		Sleep(0)
			
		Turn(rightThigh, x_axis, math.rad(70), math.rad(115) * PACE)
		Turn(rightKnee, x_axis, math.rad(-40), math.rad(145) * PACE)
		Turn(rightShin, x_axis, math.rad(20), math.rad(145) * PACE)
		Turn(rightFoot, x_axis, math.rad(-50), math.rad(210) * PACE)
		Turn(leftThigh, x_axis, math.rad(-20), math.rad(210) * PACE)
		Turn(leftKnee, x_axis, math.rad(-60), math.rad(210) * PACE)
		Turn(leftShin, x_axis, math.rad(50), math.rad(210) * PACE)
		Turn(leftFoot, x_axis, math.rad(30), math.rad(210) * PACE)
		Turn(tail, y_axis, math.rad(-20), math.rad(40))
		Turn(body, z_axis, math.rad(-(-5)), math.rad(20))
		Turn(leftThigh, z_axis, math.rad(-(5)), math.rad(20) * PACE)
		Turn(rightThigh, z_axis, math.rad(-(5)), math.rad(20) * PACE)
		Move(body, y_axis, 10, 20)
		Turn(head, x_axis, math.rad(-10), math.rad(20))
		Turn(tail, y_axis, math.rad(20), math.rad(20))
		WaitForTurn(rightThigh, x_axis)
		Sleep(0)
		
		Stomp(rightFoot)
		Turn(rightThigh, x_axis, math.rad(-10), math.rad(160) * PACE)
		Turn(rightKnee, x_axis, math.rad(15), math.rad(145) * PACE)
		Turn(rightShin, x_axis, math.rad(-60), math.rad(250) * PACE)
		Turn(rightFoot, x_axis, math.rad(30), math.rad(145) * PACE)
		Turn(leftThigh, x_axis, math.rad(40), math.rad(145) * PACE)
		Turn(leftKnee, x_axis, math.rad(-35), math.rad(145) * PACE)
		Turn(leftShin, x_axis, math.rad(-40), math.rad(145) * PACE)
		Turn(leftFoot, x_axis, math.rad(35), math.rad(145) * PACE)
		Move(body, y_axis, 0, 20)
		Turn(head, x_axis, math.rad(10), math.rad(20))
		Turn(tail, y_axis, math.rad(-20), math.rad(20))
		WaitForTurn(rightShin, x_axis)
		Sleep(0)
	end
end

local function StopWalk()
	Signal(SIG_Move)
	SetSignalMask(SIG_Move)
	Turn(rightThigh, x_axis, 0, math.rad(160))
	Turn(rightKnee, x_axis, 0, math.rad(145))
	Turn(rightShin, x_axis, 0, math.rad(250))
	Turn(rightFoot, x_axis, 0, math.rad(145))
	Turn(leftThigh, x_axis, 0, math.rad(145))
	Turn(leftKnee, x_axis, 0, math.rad(145))
	Turn(leftShin, x_axis, 0, math.rad(145))
	Turn(leftFoot, x_axis, 0, math.rad(145))
	Move(body, y_axis, 0, 20)
end

function script.StartMoving()
	isMoving = true
	StartThread(Walk)
end

function script.StopMoving()
	isMoving = false
	StartThread(StopWalk)
end

function script.Create()
	Turn(rightWing1, x_axis, math.rad(15), math.rad(45))
	Turn(leftWing1, x_axis, math.rad(15), math.rad(45))
	Turn(rightWing1, z_axis, math.rad(-40), math.rad(45))
	Turn(rightWing2, z_axis, math.rad(80), math.rad(60))
	Turn(leftWing1, z_axis, math.rad(40), math.rad(45))
	Turn(leftWing2, z_axis, math.rad(-80), math.rad(60))
	EmitSfx(body, 1026)
	EmitSfx(head, 1026)
	EmitSfx(tail, 1026)
	EmitSfx(firepoint, 1026)
	EmitSfx(leftWing1, 1026)
	EmitSfx(rightWing1, 1026)
	EmitSfx(spike1, 1026)
	EmitSfx(spike2, 1026)
	EmitSfx(spike3, 1026)
	Turn(spore1, x_axis, math.rad(90))
	Turn(spore2, x_axis, math.rad(90))
	Turn(spore3, x_axis, math.rad(90))
	
	StartThread(DropDodoLoop)
	StartThread(DropBasiliskLoop)
end

--weapon code
--weapons (in order): spikes, firegoo, spores (3)

function script.AimFromWeapon(weaponNum)
	if weaponNum == 1 or weaponNum == 2 then return firepoint
	elseif weaponNum == 3 then return spore1
	elseif weaponNum == 4 then return spore2
	elseif weaponNum == 5 then return spore3
	--elseif weaponNum == 5 then return body
	else return body end
end

function script.AimWeapon(weaponNum, heading, pitch)
	if weaponNum == 1 or weaponNum == 2 then
		Signal(SIG_Aim[weaponNum])
		SetSignalMask(SIG_Aim[weaponNum])
		Turn(head, y_axis, heading, math.rad(250))
		Turn(head, x_axis, -pitch, math.rad(200))
		
		WaitForTurn(head, y_axis)
		WaitForTurn(head, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif weaponNum == 5 then
		local health, maxHealth = spGetUnitHealth(unitID)
		if (health/maxHealth) < healthSpore3 then return true end
	elseif weaponNum >= 3 and weaponNum <= 5 then return true
	else return false
	end
end

function script.QueryWeapon(weaponNum)
	if weaponNum == 1 or weaponNum == 2 then return firepoint
	elseif weaponNum == 3 then return spore1
	elseif weaponNum == 4 then return spore2
	elseif weaponNum == 5 then return spore3
	--elseif weaponNum == 5 then
	--	if feet then return leftFoot
	--	else return rightFoot end
	else return body end
end

local function JawAnim()
	jawNum = jawNum + 1
	if jawNum == 3 then jawNum = 1 end
	local num = jawNum
	local num2 = jawNum + 2
	Turn(jaws[num].forearm, y_axis, -(jaws[num].angle), bladeExtendSpeed)
	Turn(jaws[num].blade, y_axis, jaws[num].angle, bladeExtendSpeed)
	Turn(jaws[num2].forearm, y_axis, -(jaws[num2].angle), bladeExtendSpeed)
	Turn(jaws[num2].blade, y_axis, jaws[num2].angle, bladeExtendSpeed)
	Sleep(600)
	Turn(jaws[num2].forearm, y_axis, 0, bladeExtendSpeed)
	Turn(jaws[num2].blade, y_axis, 0, bladeExtendSpeed)
	Turn(jaws[num].forearm, y_axis, 0, bladeExtendSpeed)
	Turn(jaws[num].blade, y_axis, 0, bladeExtendSpeed)
end

function script.Shot(weaponNum)
	if weaponNum == 1 then
		StartThread(JawAnim)
	end
	return true
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Explode(body, SFX.FALL)
	Explode(head, SFX.FALL)
	Explode(tail, SFX.FALL)
	Explode(leftWing1, SFX.FALL)
	Explode(rightWing1, SFX.FALL)
	Explode(spike1, SFX.FALL)
	Explode(spike2, SFX.FALL)
	Explode(spike3, SFX.FALL)
	Explode(leftThigh, SFX.FALL)
	Explode(rightThigh, SFX.FALL)
	Explode(leftShin, SFX.FALL)
	Explode(rightShin, SFX.FALL)
end

function script.HitByWeapon(x, z, weaponID, damage)
	EmitSfx(body, 1024)
	--return 100
end
