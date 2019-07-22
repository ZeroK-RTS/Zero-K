include "constants.lua"
--include 'letsNotFailAtTrig.lua'
--------------------------------------------------------------------------------
--pieces
local hull, facframe = piece ("hull", "facframe")
local base = piece("base")
local engines = {}
local pads = {}
local docked = {}

-- 1, 2, 3, 4 = rear top, rear bottom, left nose, right nose turrets
local weapons = {}

for i=1,4 do
	engines[i] = piece("engine"..i)
	pads[i] = piece("pad"..i)
	local turretPiece = piece("turret"..i)
	weapons[i] = {
		aimFrom = turretPiece,
		yaw = turretPiece,
		pitch = turretPiece,
		flares = {piece("flare"..i.."_1", "flare"..i.."_2")},
		gunIndex = 1,
		sideways = (i >= 3),
	}
end
weapons[5] = {aimFrom = base, flares = {base}, gunIndex = 1}

for i=1,6 do
	docked[i] = piece("docked"..i)
end

local smokePiece = {hull, engines[2], engines[4], pads[3]};
--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------
local function EngineLoop()
	while true do
		local vx, vy, vz = Spring.GetUnitVelocity(unitID)
		local v2d = (vx^2 + vz^2)^0.5
		for i=1,4 do
			Turn(engines[i], x_axis, v2d*0.25, math.rad(30))
		end
		--Spring.Echo(GetUnitValue(COB.CURRENT_SPEED)/65536)
		Sleep(250)
	end
end

function script.Create()
	StartThread(EngineLoop)
	StartThread(GG.Script.SmokeUnit, smokePiece)
	--Turn(piece "turret3", z_axis, math.rad(-90))
	--Turn(piece "turret4", z_axis, math.rad(90))
	for i=1,2 do
		Turn(pads[i], y_axis, math.pi)
	end
end

function script.QueryWeapon(num) 
	local index = weapons[num].gunIndex
	return weapons[num].flares[index]
end

function script.AimFromWeapon(num) 
	return weapons[num].aimFrom
end

function script.AimWeapon(num, heading, pitch)
	if (GetUnitValue(COB.CRASHING) == 1) then
		return false
	end
	if num == 3 or num == 4 then
		if (heading/math.pi < 1.5 and heading/math.pi > 0.5) then
			if num == 4 then
			heading = -2*math.pi/2 + heading
			pitch = -pitch + math.pi 
			elseif num == 3 then
			heading = -2*math.pi/2 + heading
			pitch = -pitch + math.pi 
			end
		end
		Turn(weapons[num].pitch, x_axis, -pitch, math.rad(240))
		Turn(weapons[num].yaw, y_axis, heading, math.rad(120))
		WaitForTurn(weapons[num].yaw, x_axis)
		WaitForTurn(weapons[num].pitch, y_axis)
	else
		Turn(weapons[num].yaw, y_axis, heading, math.rad(240))
		Turn(weapons[num].pitch, x_axis, -pitch, math.rad(120))
		WaitForTurn(weapons[num].yaw, y_axis)
		WaitForTurn(weapons[num].pitch, x_axis)
	end
	return true
end

function script.Shot(num)
	local index = weapons[num].gunIndex % #weapons[num].flares + 1
	weapons[num].gunIndex = index
	EmitSfx(weapons[num].flares[index], GG.Script.UNIT_SFX1)
end

function script.BlockShot(num)
	return (GetUnitValue(COB.CRASHING) == 1)
end

function script.Killed(recentDamage, maxHealth)
	-- TBD
	local severity = (recentDamage/maxHealth) * 100
	if severity < 50 then
		EmitSfx(pads[math.random(#pads)], GG.Script.UNIT_SFX2)
		Sleep(300)
		
		local fallOff = math.random(#docked)
		EmitSfx(docked[fallOff], GG.Script.UNIT_SFX2)
		Explode(docked[fallOff], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		table.remove(docked, fallOff)
		Sleep(300)
		EmitSfx(engines[4], GG.Script.UNIT_SFX2)
		Explode(engines[4], SFX.SHATTER)
		Sleep(300)
		Explode(weapons[1].aimFrom, GG.Script.UNIT_SFX2)
		
		fallOff = math.random(#docked)
		EmitSfx(docked[fallOff], GG.Script.UNIT_SFX2)
		Explode(docked[fallOff], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		table.remove(docked, fallOff)
		Sleep(600)
		EmitSfx(facframe, GG.Script.UNIT_SFX3)
		Sleep(100)
		return 1
	else
		EmitSfx(hull, GG.Script.UNIT_SFX3)
		Explode(hull, SFX.SHATTER)
		for i=1,4 do
			Explode(engines[i], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		end
		for i=1,6 do
			Explode(docked[i], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		end
		return 2
	end
end
