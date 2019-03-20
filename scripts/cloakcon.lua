include "constants.lua"

local head = piece 'head' 
local hips = piece 'hips' 
local chest = piece 'chest' 
local rthigh = piece 'rthigh' 
local lthigh = piece 'lthigh' 
local lshin = piece 'lshin' 
local rshin = piece 'rshin' 
local rfoot = piece 'rfoot' 
local lfoot = piece 'lfoot' 
local larm = piece 'larm' 
local rupperarm = piece 'rupperarm' 
local claw1 = piece 'claw1' 
local claw2 = piece 'claw2' 
local rshoulder = piece 'rshoulder' 
local rforearm = piece 'rforearm' 

local thigh = {lthigh, rthigh}
local shin = {lshin, rshin}
local foot = {lfoot, rfoot}

-- Signal definitions
local SIG_IDLE = 1
local SIG_WALK = 2

local moving = false

-- future-proof running animation against balance tweaks
local runspeed = 1.37 * (UnitDefs[unitDefID].speed / 57)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetSpeedMod()
	return (Spring.GetUnitRulesParam(unitID, "totalMoveSpeedChange") or 1)
end

local function IsBuilding()
	return GetUnitValue(COB.INBUILDSTANCE) == 1
end

local function Idle()
	Signal(SIG_IDLE)
	SetSignalMask(SIG_IDLE)

	if moving or IsBuilding() then return end

	Sleep(3000)

	local rand = math.random()
	local dir = 1
	if rand > 0.5 then dir = -1 end
	while true do
		Sleep(3000 * rand)

		Turn(head, y_axis, math.rad(30)*dir, math.rad(30))
		dir = dir * -1

		Sleep(3000)
	end
end

local function Walk()
	Signal(SIG_IDLE)
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	moving = true

	for i = 1, 2 do
		Turn(thigh[i], y_axis, 0, math.rad(135))
		Turn(thigh[i], z_axis, 0, math.rad(135))
		Turn(foot[i], z_axis, 0, math.rad(135))
	end

	local side = 1
	local sway = 1
	-- randomly lead with either foot
	if math.random() > 0.5 then
		side = 2
		sway = -1
	end

	while true do
		local speedmod = GetSpeedMod()
		local truespeed = runspeed * speedmod

		Turn(chest, x_axis, math.rad(2), truespeed*math.rad(12))

		Turn(hips, z_axis, math.rad(-2)*sway, truespeed*math.rad(5))

		if not IsBuilding() then
			Turn(head, y_axis, math.rad(8)*sway, truespeed*math.rad(23))
			Turn(chest, y_axis, math.rad(-8)*sway, truespeed*math.rad(23))
			Turn(larm, x_axis, math.rad(35)*sway, truespeed*math.rad(80))
			Turn(rshoulder, x_axis, math.rad(-20)*sway, truespeed*math.rad(60))
		end

		Turn(thigh[side], x_axis, math.rad(-50), truespeed*math.rad(150))
		Turn(shin[side], x_axis, math.rad(75), truespeed*math.rad(240))
		Turn(foot[side], x_axis, math.rad(0), truespeed*math.rad(50))

		Turn(thigh[3-side], x_axis, math.rad(50), truespeed*math.rad(150))
		Turn(shin[3-side], x_axis, math.rad(0), truespeed*math.rad(240))
		Turn(foot[3-side], x_axis, math.rad(20), truespeed*math.rad(50))

		Move(hips, y_axis, 0, truespeed*6)
		WaitForMove(hips, y_axis)

		Turn(shin[side], x_axis, math.rad(0), truespeed*math.rad(60))
		Turn(foot[side], x_axis, math.rad(-20), truespeed*math.rad(50))
		Move(hips, y_axis, -0.5, truespeed*3)
		WaitForMove(hips, y_axis)

		Move(hips, y_axis, -1.5, truespeed*9)

		WaitForTurn(thigh[side], x_axis)

		side = 3 - side
		sway = sway * -1
	end
end

local function StopWalk ()
	Signal(SIG_WALK)
	moving = false

	Turn(chest, x_axis, 0, math.rad(120))
	Turn(hips, z_axis, 0, math.rad(80))
	Move(hips, y_axis, 0.0, 10.0)

	Turn(rthigh, y_axis, math.rad(-10), math.rad(135))
	Turn(lthigh, y_axis, math.rad(10), math.rad(130))
	Turn(rthigh, z_axis, math.rad(-3), math.rad(135))
	Turn(lthigh, z_axis, math.rad(3), math.rad(130))
	Turn(lfoot, z_axis, math.rad(-3), math.rad(130))
	Turn(rfoot, z_axis, math.rad(3), math.rad(130))

	if not IsBuilding() then
		Turn(chest, y_axis, 0, math.rad(120))
		Turn(larm, x_axis, 0, math.rad(80))
		Turn(rshoulder, x_axis, 0, math.rad(60))
	end

	for side = 1, 2 do
		Turn(foot[side], x_axis, 0, math.rad(130))
		Turn(thigh[side], x_axis, 0, math.rad(130))
		Turn(shin[side], x_axis, 0, math.rad(130))
	end

	StartThread(Idle)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(StopWalk)
end

function script.StartBuilding(heading, pitch)
	Signal(SIG_IDLE)
	SetUnitValue(COB.INBUILDSTANCE, 1)
	Turn(head, y_axis, 0, math.rad(115))
	Turn(chest, y_axis, heading, math.rad(150))
	Turn(larm, x_axis, 0, math.rad(80))
	Turn(rshoulder, x_axis, math.rad(-90) - pitch, math.rad(150))
	Turn(rforearm, x_axis, 0, math.rad(150))
	Spin(rforearm, y_axis, math.rad(180))
	Turn(claw1, x_axis, math.rad(-30), math.rad(150))
	Turn(claw2, x_axis, math.rad(30), math.rad(150))
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	Turn(rshoulder, x_axis, 0, math.rad(150))
	Turn(rforearm, x_axis, 0, math.rad(150))
	Turn(rforearm, y_axis, 0, math.rad(180))
	Turn(chest, y_axis, 0, math.rad(150))
	Turn(rshoulder, x_axis, 0, math.rad(100))
	Turn(claw1, x_axis, 0, math.rad(100))
	Turn(claw2, x_axis, 0, math.rad(100))

	StartThread(Idle)
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID), claw1)
	return claw1
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, {chest})
	Turn(rthigh, y_axis, math.rad(-20))
	Turn(lthigh, y_axis, math.rad(20))
	Turn(rthigh, z_axis, math.rad(-3))
	Turn(lthigh, z_axis, math.rad(3))
	Turn(lfoot, z_axis, math.rad(-3))
	Turn(rfoot, z_axis, math.rad(3))
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	local corpseType = 1
	if severity <= .25 then
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SHATTER)
		Explode(head, SFX.FALL + SFX.FIRE)
	elseif severity <= .50 then
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SHATTER)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	else
		corpseType = 2
		Explode(hips, SFX.SHATTER)
		Explode(chest, SFX.SHATTER)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	end
	return corpseType
end
