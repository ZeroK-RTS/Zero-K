function widget:GetInfo()
   return {
      name      = "Unit gl uniform updater",
      desc      = "Maintains unit and feature GL uniforms",
      author    = "Amnykon",
      date      = "Jan 2025",
      license   = "GNU GPL v2 or later",
      layer     = -100,
      enabled   = true
   }
end

local ceil = math.ceil
local updateCount = 0

-----------------------------------------------------------------
-- Units
-----------------------------------------------------------------

local empDecline = 1 / Game.paralyzeDeclineRate
local gameSpeed = Game.gameSpeed
local paralyzeOnMaxHealth = Game.paralyzeOnMaxHealth
local myAllyTeamID = Spring.GetMyAllyTeamID()

local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir.."gl_uniform_channels.lua")

local GetUnitDefID            = Spring.GetUnitDefID
local GetUnitIsStunned        = Spring.GetUnitIsStunned
local GetUnitHealth           = Spring.GetUnitHealth
local GetUnitWeaponState      = Spring.GetUnitWeaponState
local GetUnitShieldState      = Spring.GetUnitShieldState
local GetUnitStockpile        = Spring.GetUnitStockpile
local GetUnitRulesParam       = Spring.GetUnitRulesParam
local glSetUnitBufferUniforms = gl.SetUnitBufferUniforms

local unitUpdateRate = 10
local units = {}
local unitsCount = 0
local unitPosition = {}
local currentUnit = 1

-- Written as two blocks to preserve channel 10 (morph), managed by gui_healthbars_gl4
local unitUniformLow    = {0, 0, 0, 0, 0, 0, 0, 0, 0} -- channels 1-9
local unitUniformHealth = {0}                           -- channel 11

function updateUnit(unitID, unitDefID)
	for i = 1, 9 do unitUniformLow[i] = 0 end
	unitUniformHealth[1] = 0

	local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
	paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage or 0

	if (not maxHealth) or (maxHealth < 1) then maxHealth = 1 end
	if not build then build = 1 end

	local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
	local emp = paralyzeDamage / empHP
	local hp = (health or 0) / maxHealth

	--// HEALTH (channel 11)
	unitUniformHealth[1] = 1 - hp

	--// BUILD
	unitUniformLow[unitBuildChannel] = 1 - build

	--// PARALYZE
	local stunned = GetUnitIsStunned(unitID)
	stunned = stunned and paralyzeDamage >= empHP
	if stunned then
		emp = (paralyzeDamage - empHP) / (maxHealth * empDecline) + 1
	elseif emp > 1 then
		emp = 1
	end
	unitUniformLow[unitParalyzeChannel] = emp

	--// CAPTURE
	unitUniformLow[unitCaptureChannel] = capture or 0

	--// DISARM
	local gameFrame = Spring.GetGameFrame()
	local disarmFrame = GetUnitRulesParam(unitID, "disarmframe")
	if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
		local disarmProp = (disarmFrame - gameFrame) / 1200
		if disarmProp < 1 then
			if disarmProp > emp + 0.014 then -- 16 gameframes of emp buffer
				unitUniformLow[unitDisarmChannel] = disarmProp
			end
		else
			unitUniformLow[unitDisarmChannel] = (disarmFrame - gameFrame - 1200) / gameSpeed + 1
		end
	end

	--// SLOW
	unitUniformLow[unitSlowChannel] = GetUnitRulesParam(unitID, "slowState") or 0

	--// RELOAD (primary weapon or script reload, mutually exclusive per unit)
	if unitDefPrimaryWeapon[unitDefID] then
		local _, _, reloadFrame = GetUnitWeaponState(unitID, unitDefPrimaryWeapon[unitDefID])
		unitUniformLow[unitReloadChannel] = -(reloadFrame or 0)
	elseif unitDefScriptReload[unitDefID] then
		unitUniformLow[unitReloadChannel] = -(GetUnitRulesParam(unitID, "scriptReloadFrame") or 0)
	end

	--// DGUN
	if unitDefDgun[unitDefID] then
		local _, _, reloadFrame = GetUnitWeaponState(unitID, unitDefDgun[unitDefID])
		unitUniformLow[unitDgunChannel] = -(reloadFrame or 0)
	end

	--// CHANNEL 7: ability/teleport/heat/speed/reammo/goo/jump/captureReload (mutually exclusive per unit)
	if unitDefHasAbility[unitDefID] then
		unitUniformLow[unitAbilityChannel] = GetUnitRulesParam(unitID, "specialReloadRemaining") or 0
	elseif unitDefHasTeleport[unitDefID] then
		local teleportEnd  = GetUnitRulesParam(unitID, "teleportend") or 0
		local teleportCost = GetUnitRulesParam(unitID, "teleportcost") or 1
		unitUniformLow[unitTeleportChannel] = 1 - (teleportEnd - gameFrame) / teleportCost
	elseif unitDefHasHeat[unitDefID] then
		unitUniformLow[unitHeatChannel] = GetUnitRulesParam(unitID, "heat_bar") or 0
	elseif unitDefHasSpeed[unitDefID] then
		unitUniformLow[unitSpeedChannel] = GetUnitRulesParam(unitID, "speed_bar") or 0
	elseif unitDefHasReammo[unitDefID] then
		unitUniformLow[unitReammoChannel] = GetUnitRulesParam(unitID, "reammoProgress") or 0
	elseif unitDefHasGoo[unitDefID] then
		unitUniformLow[unitGooChannel] = GetUnitRulesParam(unitID, "gooState") or 0
	elseif unitDefHasJump[unitDefID] then
		unitUniformLow[unitJumpChannel] = GetUnitRulesParam(unitID, "jumpReload") or 0
	elseif unitDefHasCaptureReload[unitDefID] then
		unitUniformLow[unitCaptureReloadChannel] = -(GetUnitRulesParam(unitID, "captureRechargeFrame") or 0)
	end

	--// CHANNEL 8: shield or stockpile (mutually exclusive per unit)
	if unitDefHasShield[unitDefID] then
		local shieldOn, shieldPower = GetUnitShieldState(unitID)
		if shieldOn == false then shieldPower = 0.0 end
		unitUniformLow[unitShieldChannel] = 1 - ((shieldPower or 0) / unitDefHasShield[unitDefID])
	elseif unitDefCanStockpile[unitDefID] then
		local _, _, stockpileBuild = GetUnitStockpile(unitID)
		local unitDef = UnitDefs[unitDefID]
		if unitDef.customParams and unitDef.customParams.stockpiletime then
			stockpileBuild = GetUnitRulesParam(unitID, "gadgetStockpile")
		end
		unitUniformLow[unitStockpileProgressChannel] = stockpileBuild or 0
	end

	glSetUnitBufferUniforms(unitID, unitUniformLow, 1)
	glSetUnitBufferUniforms(unitID, unitUniformHealth, unitHealthChannel)
end

function updateUnits()
	local nextBlock = currentUnit + unitUpdateRate - 1
	if nextBlock > unitsCount then
		nextBlock = unitsCount
	end
	for i = currentUnit, nextBlock do
		local unitID = units[i]
		if Spring.ValidUnitID(unitID) then
			updateUnit(unitID, GetUnitDefID(unitID))
		end
	end
	currentUnit = nextBlock + 1
	if currentUnit > unitsCount then
		currentUnit = 1
	end
end

function addUnit(unitID, unitDefID)
	if unitPosition[unitID] ~= nil then return end
	unitsCount = unitsCount + 1
	units[unitsCount] = unitID
	unitPosition[unitID] = unitsCount
	updateUnit(unitID, unitDefID)
end

function removeUnit(unitID)
	local position = unitPosition[unitID]
	if position == nil then return end
	local lastUnit = units[unitsCount]
	units[position] = lastUnit
	unitPosition[lastUnit] = position
	units[unitsCount] = nil
	unitPosition[unitID] = nil
	unitsCount = unitsCount - 1
end

function resetUnits()
	units = {}
	unitsCount = 0
	unitPosition = {}
	currentUnit = 1

	local spec, fullview = Spring.GetSpectatingState()
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		if fullview or Spring.GetUnitLosState(unitID, myAllyTeamID).los then
			addUnit(unitID, GetUnitDefID(unitID))
		end
	end
end

function widget:VisibleUnitAdded(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID)
end

function widget:VisibleUnitRemoved(unitID)
	removeUnit(unitID)
end

function widget:PlayerChanged(playerID)
	myAllyTeamID = Spring.GetMyAllyTeamID()
	resetUnits()
end

function widget:VisibleUnitsChanged(visibleUnits, numVisibleUnits)
	resetUnits()
end

function initUnits()
	resetUnits()
end

-----------------------------------------------------------------
-- Features
-----------------------------------------------------------------

local GetVisibleFeatures        = Spring.GetVisibleFeatures
local GetFeatureDefID           = Spring.GetFeatureDefID
local GetFeatureHealth          = Spring.GetFeatureHealth
local GetFeatureResources       = Spring.GetFeatureResources
local glSetFeatureBufferUniforms = gl.SetFeatureBufferUniforms

local trackedFeatures = {}
for i = 1, #FeatureDefs do
	trackedFeatures[i] = FeatureDefs[i].destructable and FeatureDefs[i].drawTypeString == "model"
end

local features = {}
local featureUpdateRate = 200.0

local featureUniform = {0, 0, 0}
function updateFeature(featureID)
	local health, maxHealth, resurrect = GetFeatureHealth(featureID)
	local _, _, _, _, reclaim = GetFeatureResources(featureID)
	featureUniform[featureHealthChannel]    = (health or 0) / (maxHealth or 1)
	featureUniform[featureResurrectChannel] = resurrect or 0
	featureUniform[featureReclaimChannel]   = reclaim or 0
	glSetFeatureBufferUniforms(featureID, featureUniform, 1)
end

function addFeature(featureID, defID)
	features[featureID] = defID
	updateFeature(featureID)
	for _, callback in pairs(WG.GlUnionUpdaterAddFeatureCallbacks) do
		callback(featureID)
	end
end

function removeFeature(featureID)
	features[featureID] = nil
	for _, callback in pairs(WG.GlUnionUpdaterRemoveFeatureCallbacks) do
		callback(featureID)
	end
end

function updateFeatures()
	local visibleFeatures = GetVisibleFeatures(-1, nil, false, false)
	local removedFeatures = {}

	local updatePercent = ceil(#visibleFeatures / featureUpdateRate)
	for featureID, _ in pairs(features) do
		removedFeatures[featureID] = true
	end

	local cnt = #visibleFeatures
	for i = 1, cnt do
		local featureID = visibleFeatures[i]
		local featureDefID = GetFeatureDefID(featureID) or -1
		if trackedFeatures[featureDefID] then
			if removedFeatures[featureID] then
				if updatePercent < 2 or (updateCount + featureID) % updatePercent == 0 then
					updateFeature(featureID)
				end
				removedFeatures[featureID] = nil
			else
				addFeature(featureID, featureDefID)
			end
		end
	end

	for featureID, val in pairs(removedFeatures) do
		if val then
			removeFeature(featureID)
		end
	end
end

-----------------------------------------------------------------
-- Widget
-----------------------------------------------------------------

function widget:Update()
	updateCount = updateCount + 1
	updateUnits()
	updateFeatures()
end

function widget:Initialize()
	WG.GlUnionUpdaterAddFeatureCallbacks = WG.GlUnionUpdaterAddFeatureCallbacks or {}
	WG.GlUnionUpdaterRemoveFeatureCallbacks = WG.GlUnionUpdaterRemoveFeatureCallbacks or {}
	initUnits()
end

function widget:Shutdown()
end
