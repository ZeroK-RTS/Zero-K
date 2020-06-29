include "constants.lua"

local spGetUnitRulesParam = Spring.GetUnitRulesParam

local base, shield, front, bottom, back = piece('base', 'shield', 'front', 'bottom', 'back')
local rim1, door1, rim2, door2 = piece('rim1', 'door1', 'rim2', 'door2')
local turretbase, turret, gun, pads, flare1, flare2 = piece('turretbase', 'turret', 'gun', 'pads', 'flare1', 'flare2')
local ground1 = piece 'ground1'

local wakes = {}
for i = 1, 8 do
	wakes[i] = piece ('wake' .. i)
end

local SIG_HIT = 2

local function WobbleUnit()
	while true do
		Move(base, y_axis, 0.8, 1.2)
		Sleep(750)
		Move(base, y_axis, -0.80, 1.2)
		Sleep(750)
	end
end

function HitByWeaponThread(x, z)
	Signal(SIG_HIT)
	SetSignalMask(SIG_HIT)
	Turn(base, z_axis, math.rad(-z), math.rad(105))
	Turn(base, x_axis, math.rad(x), math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn(base, z_axis, 0, math.rad(30))
	Turn(base, x_axis, 0, math.rad(30))
end

local sfxNum = 0
function script.setSFXoccupy(num)
	sfxNum = num
end

local function MoveScript()
	while Spring.GetUnitIsStunned(unitID) do
		Sleep(2000)
	end
	while true do
		if not Spring.GetUnitIsCloaked(unitID) then
			if (sfxNum == 1 or sfxNum == 2) and select(2, Spring.GetUnitPosition(unitID)) == 0 then
				for i = 1, 8 do
					EmitSfx(wakes[i], 3)
				end
			else
				EmitSfx(ground1, 1024)
			end
		end
		Sleep(150)
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
local landRange = WeaponDefNames["hoverdepthcharge_fake_depthcharge"].range
local seaRange  = WeaponDefNames["hoverdepthcharge_depthcharge"].range

local function WeaponRangeUpdate()
	while true do
		local x, _, z = Spring.GetUnitPosition(unitID)
		local height = Spring.GetGroundHeight(x, z)
		if height > -5 then
			Spring.SetUnitMaxRange(unitID, landRange)
			Spring.SetUnitWeaponState(unitID, 1, "range", landRange)
		else
			Spring.SetUnitMaxRange(unitID, seaRange)
			Spring.SetUnitWeaponState(unitID, 1, "range", seaRange)
		end
		Sleep(500)
	end
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

function script.Create()
	Hide(flare1)
	Hide(flare2)
	Hide(turret)
	Hide(pads)
	Hide(door1)
	Hide(door2)
	Hide(bottom)
	
	Move(base, x_axis, -3)
	Move(base, z_axis, -6)
	
	Move(gun, y_axis, 2)
	Turn(base, y_axis, math.rad(180))

	Move(turretbase, y_axis, 12)
	Turn(turretbase, x_axis, math.rad(180))
	Turn(turretbase, y_axis, math.rad(180))
	
	Move(pads, z_axis, 10)
	Turn(pads, x_axis, math.rad(50))
	
	Move(back, y_axis, 5)
	Move(back, x_axis, 0)
	Move(back, z_axis, 33.5)
	
	
	Turn(rim1, y_axis, math.rad(-35))
	Turn(rim2, y_axis, math.rad(35))
	
	StartThread(GG.Script.SmokeUnit, unitID, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
	StartThread(WeaponRangeUpdate)
end

function script.QueryWeapon(num)
	return pads
end

function script.AimFromWeapon(num)
	return pads
end

function script.AimWeapon(num)
	return num ~= 3
end

local function ShotThread()
	Move(gun, y_axis, -2, 40)
	Turn(turretbase, x_axis, math.rad(145), math.rad(400))
	Sleep(100)
	Turn(turretbase, x_axis, math.rad(180), math.rad(60))
	Move(gun, y_axis, 2, 2)
end

function script.Shot(num)
	StartThread(ShotThread)
end

local spGetUnitWeaponState = Spring.GetUnitWeaponState
local spSetUnitWeaponState = Spring.SetUnitWeaponState
local spGetGameFrame = Spring.GetGameFrame

local depthchargeWeaponDef = WeaponDefNames["hoverdepthcharge_depthcharge"]
local RELOAD = math.ceil(depthchargeWeaponDef.reload * Game.gameSpeed)

function ShootDepthcharge()
	EmitSfx(pads, GG.Script.FIRE_W3)
	StartThread(ShotThread)
	Move(gun, y_axis, -2)
	Move(gun, y_axis, 2, 2)

	GG.PokeDecloakUnit(unitID,100)
end

local function FakeWeaponShoot(targetID)
	local reloaded = select(2, spGetUnitWeaponState(unitID,1))
	if reloaded then
		local x,y,z = Spring.GetUnitPosition(unitID)
		local h = Spring.GetGroundHeight(x,z)
		if h > -5 and not GG.OverkillPrevention_CheckBlock(unitID, targetID, 400, 30) then
			local gameFrame = spGetGameFrame()
			local reloadMult = spGetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1.0
			local reloadFrame = gameFrame + RELOAD / reloadMult
			spSetUnitWeaponState(unitID, 1, {reloadFrame = reloadFrame})
			
			ShootDepthcharge()
		end
	end
end

function script.BlockShot(num, targetID)
	if num == 1 then
		-- Underestimate damage and flight time. The aim here really is just to avoid every Claymore unloading on a single
		-- target at the same time. They are a bit too random for anything more precise.
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 500, 60)
	end
	if num == 2 then
		FakeWeaponShoot(targetID)
	end
	return true
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if severity <= 0.25 then
		Explode(base, SFX.NONE)
		Explode(door1, SFX.NONE)
		Explode(door2, SFX.NONE)
		Explode(back, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(base, SFX.NONE)
		Explode(door1, SFX.NONE)
		Explode(door2, SFX.NONE)
		Explode(back, SFX.NONE)
		Explode(rim1, SFX.SHATTER)
		Explode(rim2, SFX.SHATTER)
		return 1
	end
	Explode(door1, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(door2, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(back, SFX.SMOKE + SFX.FALL + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(rim1, SFX.SHATTER)
	Explode(rim2, SFX.SHATTER)
	return 2
end
