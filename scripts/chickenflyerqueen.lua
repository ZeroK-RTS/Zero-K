include "constants.lua"

local spGetUnitHealth = Spring.GetUnitHealth

--pieces
local body, head, tail, leftWing, rightWing = piece("body","head","tail","lwing","rwing")
local leftThigh, leftKnee, leftShin, leftFoot, rightThigh, rightKnee, rightShin, rightFoot = piece("lthigh", "lknee", "lshin", "lfoot", "rthigh", "rknee", "rshin", "rfoot")
local lforearml,lbladel,rforearml,rbladel,lforearmu,lbladeu,rforearmu,rbladeu = piece("lforearml", "lbladel", "rforearml", "rbladel", "lforearmu", "lbladeu", "rforearmu", "rbladeu")
local spike1, spike2, spike3, firepoint, spore1, spore2, spore3 = piece("spike1", "spike2", "spike3", "firepoint", "spore1", "spore2", "spore3")

smokePiece = {}

local turretIndex = {
}

--constants
local wingAngle = math.rad(40)
local wingSpeed = math.rad(120)
local tailAngle = math.rad(20)

local bladeExtendSpeed = math.rad(600)
local bladeRetractSpeed = math.rad(120)
local bladeAngle = math.rad(140)

--variables
local isMoving = false
local feet = true

local malus = GG.malus or 1

--maximum HP for additional weapons
local healthSpore3 = 0.55
local healthDodoDrop = 0.65
local healthDodo2Drop = 0.3
local healthBasiliskDrop = 0.5
local healthTiamatDrop = 0.2

--signals
local SIG_Aim = 1
local SIG_Aim2 = 2
local SIG_Move = 16

--cob values


----------------------------------------------------------
local function RestoreAfterDelay()
	Sleep(1000)
end

-- used for queen morph - blank in this case as it does nothing
function MorphFunc()
end

local function Fly()
	if (isMoving) then
		Turn(leftWing, z_axis, -wingAngle, wingSpeed)
		Turn(rightWing, z_axis, wingAngle, wingSpeed)
		Turn(tail, x_axis, tailAngle, math.rad(40))
		Move(body, y_axis, -60, 45)
		WaitForTurn(leftWing, z_axis)
		Turn(leftWing, z_axis, wingAngle, wingSpeed)
		Turn(rightWing, z_axis, -wingAngle, wingSpeed)
		Turn(tail, x_axis, -tailAngle, math.rad(40))
		Move(body, y_axis, 0, 45)
--		EmitSfx(body, 4096+5) --Queen Crush
		WaitForTurn(leftWing, z_axis)
		Fly()
	end
end

local function StopFly()
	Turn(leftWing, z_axis, 0, 200)
	Turn(rightWing, z_axis, 0, 200)
end

local function DropDodoLoop()
	while true do
		local health, maxHealth = spGetUnitHealth(unitID)
		if (health/maxHealth) < healthDodoDrop then
			for i=1,malus do
				if (feet) then EmitSfx(leftFoot,2048+4)
				else EmitSfx(rightFoot,2048+4) end
				feet = not feet
				Sleep(500)
			end
		end
		Sleep(1500)
		if (health/maxHealth) < healthDodo2Drop then
			for i=1,malus do
				if (feet) then EmitSfx(leftFoot,2048+4)
				else EmitSfx(rightFoot,2048+4) end
				feet = not feet
				Sleep(500)
			end
		end
		Sleep(4500)
	end
end

local function DropBasiliskLoop()
	while true do
		local health, maxHealth = spGetUnitHealth(unitID)
		if (health/maxHealth) < healthBasiliskDrop and (health/maxHealth) > healthTiamatDrop then
			for i=1,malus do
				EmitSfx(body,2048+5)
				Sleep(1000)
			end
		elseif (health/maxHealth) < healthTiamatDrop then
			for i=1,malus do
				EmitSfx(body,2048+6)
				Sleep(1000)
			end		
		end
		Sleep(8000)
	end
end

function script.StartMoving()
	isMoving = true
	StartThread(Fly)
	Turn(leftFoot, x_axis, math.rad(-20), math.rad(420))
	Turn(rightFoot, x_axis, math.rad(-20), math.rad(420))
	Turn(leftShin, x_axis, math.rad(-40), math.rad(420))
	Turn(rightShin, x_axis, math.rad(-40), math.rad(420))
end

function script.StopMoving()
	isMoving = false
	StartThread(StopFly)
end

function script.Create()
	EmitSfx(body, 1026)
	EmitSfx(head, 1026)
	EmitSfx(tail, 1026)
	EmitSfx(firepoint, 1026)
	EmitSfx(leftWing, 1026)
	EmitSfx(rightWing, 1026)
	EmitSfx(spike1, 1026)
	EmitSfx(spike2, 1026)
	EmitSfx(spike3, 1026)
	Turn(spore1, x_axis, math.rad(90))
	Turn(spore2, x_axis, math.rad(90))
	Turn(spore3, x_axis, math.rad(90))
	
	StartThread(DropDodoLoop)
	StartThread(DropBasiliskLoop)
end

function script.AimFromWeapon(weaponNum)
	if weaponNum == 1 then return firepoint
	elseif weaponNum == 2 then return spore1
	elseif weaponNum == 3 then return spore2
	elseif weaponNum == 4 then return spore3
	--elseif weaponNum == 5 then return body
	else return body end
end

function script.AimWeapon(weaponNum, heading, pitch)
	if weaponNum == 1 then
		Signal(SIG_Aim)
		SetSignalMask(SIG_Aim)
		Turn(head, y_axis, heading, math.rad(250))
		Turn(head, x_axis, pitch, math.rad(200))
		
		WaitForTurn(head, y_axis)
		WaitForTurn(head, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	elseif weaponNum == 4 then
		local health, maxHealth = spGetUnitHealth(unitID)
		if (health/maxHealth) < healthSpore3 then return true end
	elseif weaponNum >= 2 and weaponNum <= 4 then return true
	else return false
	end
end

function script.QueryWeapon(weaponNum)
	if weaponNum == 1 then return firepoint
	elseif weaponNum == 2 then return spore1
	elseif weaponNum == 3 then return spore2
	elseif weaponNum == 4 then return spore3
	--elseif weaponNum == 5 then
	--	if feet then return leftFoot
	--	else return rightFoot end
	else return body end
end

function script.FireWeapon(weaponNum)
	if weaponNum == 1 then
		Turn(lforearmu, y_axis, -bladeAngle, bladeExtendSpeed)
		Turn(lbladeu, y_axis, bladeAngle, bladeExtendSpeed)
		Turn(lforearml, y_axis, -bladeAngle, bladeExtendSpeed)
		Turn(lbladel, y_axis, bladeAngle, bladeExtendSpeed)
		Turn(rforearmu, y_axis, bladeAngle, bladeExtendSpeed)
		Turn(rbladeu, y_axis, -bladeAngle, bladeExtendSpeed)
		Turn(rforearml, y_axis, bladeAngle, bladeExtendSpeed)
		Turn(rbladel, y_axis, -bladeAngle, bladeExtendSpeed)
		
		Sleep(500)
		
		Turn(lforearmu, y_axis, 0, bladeRetractSpeed)
		Turn(lbladeu, y_axis, 0, bladeRetractSpeed)
		Turn(lforearml, y_axis, 0, bladeRetractSpeed)
		Turn(lbladel, y_axis, 0, bladeRetractSpeed)
		Turn(rforearmu, y_axis, 0, bladeRetractSpeed)
		Turn(rbladeu, y_axis, 0, bladeRetractSpeed)
		Turn(rforearml, y_axis, 0, bladeRetractSpeed)
		Turn(rbladel, y_axis, 0, bladeRetractSpeed)
		--WaitForTurn(lbladeu, y_axis)
	end
	return true
end

function script.Killed(recentDamage, maxHealth)
	EmitSfx(body, 1025)
	Explode(body, sfxFall)
	Explode(head, sfxFall)
	Explode(tail, sfxFall)
	Explode(leftWing, sfxFall)
	Explode(rightWing, sfxFall)
	Explode(spike1, sfxFall)
	Explode(spike2, sfxFall)
	Explode(spike3, sfxFall)
	Explode(leftThigh, sfxFall)
	Explode(rightThigh, sfxFall)
	Explode(leftShin, sfxFall)
	Explode(rightShin, sfxFall)
end

function script.HitByWeapon(x, z, weaponID, damage)
	EmitSfx(body, 1024)
	--return 100
end
