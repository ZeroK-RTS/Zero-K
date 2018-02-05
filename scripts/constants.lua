--x_axis = 1
--y_axis = 2
--z_axis = 3
local common = include("evoHeader.lua")

SetSFXOccupy = setSFXoccupy		--standard case for function names

GetPieceRotation = Spring.UnitScript.GetPieceRotation

CRASHING = 97

SFXTYPE_VTOL = 0
--SFXTYPE_THRUST = 1
SFXTYPE_WAKE1 = 2
SFXTYPE_WAKE2 = 3
SFXTYPE_REVERSEWAKE1 = 4
SFXTYPE_REVERSEWAKE2 = 5

--SFXTYPE_POINTBASED		256
--TBD

sfxNone 		= SFX.NONE
sfxExplode 		= SFX.EXPLODE
--sfxBitmap 		= SFX.BITMAP_ONLY -- This is not a thing
sfxShatter		= SFX.SHATTER
sfxFall	 		= SFX.FALL
sfxSmoke 		= SFX.SMOKE
sfxFire			= SFX.FIRE
sfxExplodeOnHit = SFX.EXPLODE_ON_HIT

-- Maths
tau = math.pi*2
pi = math.pi
hpi = math.pi*0.5
pi34 = math.pi*1.5

rad = math.rad
abs = math.abs
toDegrees = 180/pi
frameToMs = 1000/30
msToFrame = 30/1000

cos = math.cos
sin = math.sin

headingToRad = 1/32768*math.pi

-- Explosion generators
UNIT_SFX1 = 1024
UNIT_SFX2 = 1025
UNIT_SFX3 = 1026
UNIT_SFX4 = 1027
UNIT_SFX5 = 1028
UNIT_SFX6 = 1029
UNIT_SFX7 = 1030
UNIT_SFX8 = 1031

-- Weapons
FIRE_W1 = 2048
FIRE_W2 = 2049
FIRE_W3 = 2050
FIRE_W4 = 2051
FIRE_W5 = 2052
FIRE_W6 = 2053
FIRE_W7 = 2054
FIRE_W8	= 2055

DETO_W1 = 4096
DETO_W2 = 4097
DETO_W3 = 4098
DETO_W4 = 4099
DETO_W5 = 4100
DETO_W6 = 4101
DETO_W7 = 4102
DETO_W8 = 4103

local SMOKEPUFF = 258

-- useful functions
function SmokeUnit(smokePiece, multiplier)
	multiplier = multiplier or 1
	local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
	
	if not (smokePiece and smokePiece[1]) then 
		return 
	end
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do
		Sleep(400) 
	end
	--Smoke loop
	while true do
		--How is the unit doing?
		local healthPercent = GetUnitValue(COB.HEALTH)
		if (healthPercent < 66) and not spGetUnitIsCloaked(unitID) then -- only smoke if less then 2/3rd health left
			--common.CustomEmitter(smokePiece[math.random(1,#smokePiece)], "blacksmoke")
			EmitSfx(smokePiece[math.random(1,#smokePiece)], SMOKEPUFF)
		end
		Sleep((8*healthPercent + math.random(100,200)) / multiplier)
	end
end

function onWater()
	local spGetUnitPosition = Spring.GetUnitPosition
	local spGetGroundHeight = Spring.GetGroundHeight
	local x,_,z = spGetUnitPosition(unitID)
	if x then
		h = spGetGroundHeight(x,z)
		if h and h < 0 then
			return true
		end
	end
	return false
end

function NonBlockingWaitTurn(piece, axis, angle, leeway)
	local rot = select(axis, Spring.UnitScript.GetPieceRotation(piece))
	leeway = leeway or 0.1
	
	angle = (angle - rot)%tau
	if angle > leeway and angle < tau - leeway then
		WaitForTurn(piece, axis)
	end
end

local function noFunc()
end

function DelayTrueDeath(recentDamage, maxHealth, KillFunc, delayTime)
	
	local wreckLevel = KillFunc(recentDamage, maxHealth)

	local ud = UnitDefs[unitDefID]
	local x, y, z = Spring.GetUnitPosition(unitID)

	-- hide unit
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitNoDraw(unitID, true)
	Spring.SetUnitNoMinimap(unitID, true)
	Spring.SetUnitSensorRadius(unitID, "los", 0)
	Spring.SetUnitSensorRadius(unitID, "airLos", 0)
	Spring.MoveCtrl.Enable(unitID, true)
	Spring.MoveCtrl.SetNoBlocking(unitID, true)
	Spring.MoveCtrl.SetPosition(unitID, x, Spring.GetGroundHeight(x, z) - 1000, z)

	-- spawn wreck
	local makeRezzable = (wreckLevel == 1)
	local wreckDef = FeatureDefNames[ud.wreckName]
	while (wreckLevel > 1 and wreckDef) do
		wreckDef = FeatureDefs[ wreckDef.deathFeatureID ]
		wreckLevel = wreckLevel - 1
	end
	if (wreckDef) then
		local heading = Spring.GetUnitHeading(unitID)
		local teamID	= Spring.GetUnitTeam(unitID)
		local featureID = Spring.CreateFeature(wreckDef.id, x, y, z, heading, teamID)
		if makeRezzable then
			Spring.SetFeatureResurrect(featureID, ud.name)
		end
		-- engine also sets speed and smokeTime for wrecks, but there are no lua functions for these
	end
	
	Sleep(delayTime) -- wait until all waves hit
	return 10 -- don't spawn second wreck
end

function InitializeDeathAnimation()
	local paralyzeDamage = select(3, Spring.GetUnitHealth(unitID))
	Spring.SetUnitRulesParam(unitID, "real_para", paralyzeDamage or 0)
end

Spring.SetUnitNanoPieces = Spring.SetUnitNanoPieces or noFunc
