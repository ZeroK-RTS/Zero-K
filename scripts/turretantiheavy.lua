local base = piece 'base'
local arm = piece 'arm'
local turret = piece 'turret'
local gun = piece 'gun'
local ledgun = piece 'ledgun'
local radar = piece 'radar'
local barrel = piece 'barrel'
local fire = piece 'fire'
local antenna = piece 'antenna'
local door1 = piece 'door1'
local door2 = piece 'door2'

local smokePiece = {base, turret}

include "constants.lua"

local spGetUnitRulesParam = Spring.GetUnitRulesParam

-- Signal definitions
local SIG_AIM = 2
local SIG_OPEN = 1

local open = true
local firing = false

local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Spring.SetUnitArmored(unitID,false)	--broken
	Spring.SetUnitCOBValue(unitID, COB.ARMORED, 0)
	Turn(door1, z_axis, 0, math.rad(80))
	Turn(door2, z_axis, 0, math.rad(80))
	WaitForTurn(door1, z_axis)
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	
	Move(arm, y_axis, 0, 12)
	Turn(antenna, x_axis, 0, math.rad(50))
	Sleep(200)
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	
	Move(barrel, z_axis, 0, 7)
	Move(ledgun, z_axis, 0, 7)
	WaitForMove(barrel, z_axis)
	WaitForMove(ledgun, z_axis)
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	
	open = true
end

local function Close()
	open = false
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	Turn(turret, y_axis, 0, math.rad(50))
	Turn(gun, x_axis, 0, math.rad(40))
	Move(barrel, z_axis, -24, 7)
	Move(ledgun, z_axis, -15, 7)
	Turn(antenna, x_axis, math.rad(90), math.rad(50))
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	
	Move(arm, y_axis, -50, 12)
	WaitForMove(arm, y_axis)
	while spGetUnitRulesParam(unitID, "lowpower") == 1 do
		Sleep(500)
	end
	
	
	Turn(door1, z_axis, math.rad(-(90)), math.rad(80))
	Turn(door2, z_axis, math.rad(-(-90)), math.rad(80))
	WaitForTurn(door1, z_axis)
	WaitForTurn(door2, z_axis)
	
	Spring.SetUnitArmored(unitID,true)
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end
function script.Activate()
	Spin(radar, y_axis, math.rad(100))
	StartThread(Open)
end

function script.Deactivate()
	StopSpin(radar, y_axis)
	Signal(SIG_AIM)
	Turn(radar, y_axis, 0, math.rad(100))
	StartThread(Close)
end

function script.AimWeapon(weaponNum, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	while (not open) or firing or (spGetUnitRulesParam(unitID, "lowpower") == 1) do
		Sleep (100)
	end

	GG.DontFireRadar_CheckAim(unitID)
	
	Turn(turret, y_axis, heading, math.rad(50))
	Turn(gun, x_axis, 0 - pitch, math.rad(40))
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	return (spGetUnitRulesParam(unitID, "lowpower") == 0) --checks for sufficient energy in grid
end

local beam_duration = WeaponDefs[UnitDef.weapons[1].weaponDef].beamtime * 1000
function script.FireWeapon()
	firing = true
	Sleep (beam_duration)
	firing = false
end

function script.BlockShot(num, targetID)
	-- partial OKP damage because long beam means the unit can dodge and just get grazed
	-- Underestimate beam time so that fully-hit targets always have more pending damage in reality than in theory.
	return targetID and (GG.DontFireRadar_CheckBlock(unitID, targetID) or GG.OverkillPrevention_CheckBlock(unitID, targetID, 1000, 20))
end

--[[
-- multi-emit workaround
function script.BlockShot(num)
	local px, py, pz = Spring.GetUnitPosition(unitID)
	Spring.PlaySoundFile("sounds/weapon/laser/heavy_laser6.wav", 10, px, py, pz)
	return false
end

function script.Shot(weaponNum)
	EmitSfx(fire, GG.Script.FIRE_W1)
	EmitSfx(fire, GG.Script.FIRE_W1)
	EmitSfx(fire, GG.Script.FIRE_W1)
	EmitSfx(fire, GG.Script.FIRE_W1)
end
--]]

function script.AimFromWeapon(weaponNum)
	return barrel
end

function script.QueryWeapon(weaponNum)
	return fire
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(arm, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(gun, SFX.NONE)
		Explode(ledgun, SFX.NONE)
		Explode(radar, SFX.NONE)
		Explode(barrel, SFX.NONE)
		Explode(fire, SFX.NONE)
		Explode(antenna, SFX.NONE)
		Explode(door1, SFX.NONE)
		Explode(door2, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(arm, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(gun, SFX.SHATTER)
		Explode(ledgun, SFX.NONE)
		Explode(radar, SFX.NONE)
		Explode(barrel, SFX.FALL)
		Explode(fire, SFX.NONE)
		Explode(antenna, SFX.FALL)
		Explode(door1, SFX.FALL)
		Explode(door2, SFX.FALL)
		return 1
	elseif severity <= .99 then
		Explode(base, SFX.NONE)
		Explode(arm, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(gun, SFX.SHATTER)
		Explode(ledgun, SFX.NONE)
		Explode(radar, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(fire, SFX.NONE)
		Explode(antenna, SFX.FALL)
		Explode(door1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(door2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	else
		Explode(base, SFX.NONE)
		Explode(arm, SFX.NONE)
		Explode(turret, SFX.NONE)
		Explode(gun, SFX.SHATTER)
		Explode(ledgun, SFX.NONE)
		Explode(radar, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(barrel, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(fire, SFX.NONE)
		Explode(antenna, SFX.FALL)
		Explode(door1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(door2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		return 2
	end
end
