--x_axis = 1
--y_axis = 2
--z_axis = 3
--local common = include("evoHeader.lua")

if GG.Script then
	return
end

GG.Script = GG.Script or {}

GG.Script.CRASHING = 97

-- What is this?
--SFXTYPE_VTOL = 0
----SFXTYPE_THRUST = 1
--SFXTYPE_WAKE1 = 2
--SFXTYPE_WAKE2 = 3
--SFXTYPE_REVERSEWAKE1 = 4
--SFXTYPE_REVERSEWAKE2 = 5

-- Maths
GG.Script.tau = math.pi*2

GG.Script.toDegrees = 180/math.pi
GG.Script.frameToMs = 1000/30
GG.Script.msToFrame = 30/1000

GG.Script.headingToRad = 1/32768*math.pi

-- Explosion generators
GG.Script.UNIT_SFX1 = 1024
GG.Script.UNIT_SFX2 = 1025
GG.Script.UNIT_SFX3 = 1026
GG.Script.UNIT_SFX4 = 1027
GG.Script.UNIT_SFX5 = 1028
GG.Script.UNIT_SFX6 = 1029
GG.Script.UNIT_SFX7 = 1030
GG.Script.UNIT_SFX8 = 1031

-- Weapons
GG.Script.FIRE_W1 = 2048
GG.Script.FIRE_W2 = 2049
GG.Script.FIRE_W3 = 2050
GG.Script.FIRE_W4 = 2051
GG.Script.FIRE_W5 = 2052
GG.Script.FIRE_W6 = 2053
GG.Script.FIRE_W7 = 2054
GG.Script.FIRE_W8	= 2055

GG.Script.DETO_W1 = 4096
GG.Script.DETO_W2 = 4097
GG.Script.DETO_W3 = 4098
GG.Script.DETO_W4 = 4099
GG.Script.DETO_W5 = 4100
GG.Script.DETO_W6 = 4101
GG.Script.DETO_W7 = 4102
GG.Script.DETO_W8 = 4103

GG.Script.SMOKEPUFF = 258

-- useful functions
function GG.Script.SmokeUnit(unitID, smokePiece, multiplier)
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
			EmitSfx(smokePiece[math.random(1,#smokePiece)], GG.Script.SMOKEPUFF)
		end
		Sleep((8*healthPercent + math.random(100,200)) / multiplier)
	end
end

function GG.Script.onWater(unitID)
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

function GG.Script.NonBlockingWaitTurn(piece, axis, angle, leeway)
	local rot = select(axis, Spring.UnitScript.GetPieceRotation(piece))
	leeway = leeway or 0.1
	
	angle = (angle - rot)%GG.Script.tau
	if angle > leeway and angle < GG.Script.tau - leeway then
		WaitForTurn(piece, axis)
	end
end

function GG.Script.DelayTrueDeath(unitID, unitDefID, recentDamage, maxHealth, KillFunc, delayTime)
	
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

function GG.Script.InitializeDeathAnimation(unitID)
	local paralyzeDamage = select(3, Spring.GetUnitHealth(unitID))
	Spring.SetUnitRulesParam(unitID, "real_para", paralyzeDamage or 0)
end
