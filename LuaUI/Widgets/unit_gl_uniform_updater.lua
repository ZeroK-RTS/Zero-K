function widget:GetInfo()
   return {
      name      = "Unit gl uniform updater",
      desc      = "Maintains sl unit and feature uniforms",
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

local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir.."gl_uniform_channels.lua")
--[[
local unitBuildChannel = 1
local unitParalyzeChannel = 2
local unitDisarmChannel = 3
local unitSlowChannel = 4
local unitReloadChannel = 5
local unitDgunChannel = 6
local unitTeleportChannel = 7
local unitHeatChannel = 7
local unitSpeedChannel = 7
local unitReammoChannel = 7
local unitGooChannel = 7
local unitJumpChannel = 7
local unitCaptureReloadChannel = 7
local unitAbilityChannel = 7
local unitStockpileProgressChannel = 7
local unitStockpileAmountChannel = 8
local unitShieldChannel = 8
local unitCaptureChannel = 9
local unitMorphChannel = 10
local unitHealthChannel = 11 -- if its =20, then its health/maxhealth
--]]

local GetVisibleUnits = Spring.GetVisibleUnits
local GetUnitDefID = Spring.GetUnitDefID

local GetUnitIsStunned     = Spring.GetUnitIsStunned
local GetUnitHealth        = Spring.GetUnitHealth
local glSetUnitBufferUniforms = gl.SetUnitBufferUniforms
local GetUnitRulesParam    = Spring.GetUnitRulesParam
local GetVisibleUnits      = Spring.GetVisibleUnits

local unitUpdateRate = 10
local units = {}
local unitsCount = 0
local unitPosition = {}
local currentUnit = 1

local unitUniform = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
function updateUnit(unitID, unitDefID)
	local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
	paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage or 0

	if (not maxHealth)or(maxHealth < 1) then
		maxHealth = 1
	end

	if (not build) then
		build = 1
	end

	local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
	local emp = paralyzeDamage/empHP
	local hp  = (health or 0)/maxHealth

	--// HEALTH
	unitUniform[unitHealthChannel] = 1 - hp

	--// BUILD
	unitUniform[unitBuildChannel] = 1 - build

	--// PARALYZE
	local paraTime = false
	local stunned = GetUnitIsStunned(unitID)
	stunned = stunned and paralyzeDamage >= empHP
	if (stunned) then
		emp = (paralyzeDamage-empHP)/(maxHealth*empDecline) + 1
	else
		if (emp > 1) then
			emp = 1
		end
	end
	unitUniform[unitParalyzeChannel] = emp

	--// CAPTURE
	capture = capture or 0
	unitUniform[unitCaptureChannel] = capture

	--// DISARM
	local disarmFrame = GetUnitRulesParam(unitID, "disarmframe")
	if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
		local disarm
		local disarmProp = (disarmFrame - gameFrame)/1200
		if disarmProp < 1 then
			if (not paraTime) and disarmProp > emp + 0.014 then -- 16 gameframes of emp time
				disarm = disarmProp
			end
		else
			local disarmTime = (disarmFrame - gameFrame - 1200)/gameSpeed
			if (not paraTime) or disarmTime > paraTime + 0.5 then
				disarm = disarmTime + 1
			end
		end
		unitUniform[unitDisarmChannel] = disarm
	end

	--// SLOW
	-- for unitID, oldSlow in pairs(unitSlowWatch) do
	local slow = GetUnitRulesParam(unitID, "slowState") or 0
	unitUniform[unitSlowChannel] = slow

	glSetUnitBufferUniforms(unitID, unitUniform , 1)
end

function updateUnits()
	local nextBlock = currentUnit + unitUpdateRate - 1
	if nextBlock > unitsCount then
		nextBlock = unitsCount
	end
	for i = currentUnit, nextBlock do
		local unitID = units[i]
		updateUnit(unitID, GetUnitDefID(unitID))
	end
	currentUnit = nextBlock + 1
	if currentUnit > unitsCount then
		currentUnit = 1
	end
end

function addUnit(unitID, unitDefID)
	if unitPosition[unitID] ~= nil then return end
	Spring.Echo("addUnit(" .. unitID .. ")")
	unitsCount = unitsCount + 1
	units[unitsCount] = unitID
	unitPosition[unitID] = unitsCount
	updateUnit(unitID, unitDefID)
end

function removeUnit(unitID)
	local position = unitPosition[unitID]
	if position == nil then return end
	Spring.Echo("removeUnit(" .. unitID .. ")")
	local lastUnit = units[unitsCount]
	units[position] = lastUnit
	unitPosition[lastUnit] = postion
	units[unitsCount] = nil
	unitPosition[unitID] = nil
	unitsCount = unitsCount - 1
end

function resetUnits()
	Spring.Echo("resetUnits()")
	units = {}
	unitsCount = 0
	unitPosition = {}
	currentUnit = 1

	local spec, fullview = Spring.GetSpectatingState()

	local allUnits = Spring.GetAllUnits()
	local unitID, unitDefID
	for i = 1, #allUnits do
		unitID = allUnits[i]
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
local featureHealthChannel = 1
local featureResurrectChannel = 2
local featureReclaimChannel = 3

local GetVisibleFeatures   = Spring.GetVisibleFeatures
local GetFeatureDefID      = Spring.GetFeatureDefID
local GetFeatureHealth     = Spring.GetFeatureHealth
local GetFeaturePosition   = Spring.GetFeaturePosition
local GetFeatureResources  = Spring.GetFeatureResources
local glSetFeatureBufferUniforms = gl.SetFeatureBufferUniforms

local trackedFeatures = {}
for i = 1, #FeatureDefs do
	trackedFeatures[i] = FeatureDefs[i].destructable and FeatureDefs[i].drawTypeString == "model"
end

local features = {}

local featureUpdateRate = 200.0

local featureUniform = {0, 0, 0}
function updateFeature(featureID)
	local health, maxHealth, resurrect, reclaim
	health, maxHealth, resurrect = GetFeatureHealth(featureID)
	_, _, _, _, reclaim = GetFeatureResources(featureID)
	featureUniform[featureHealthChannel] = (health or 0)/(maxHealth or 1)
	featureUniform[featureResurrectChannel] = resurrect
	featureUniform[featureReclaimChannel] = reclaim
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
		featureID = visibleFeatures[i]
		featureDefID = GetFeatureDefID(featureID) or -1
		if trackedFeatures[featureDefID] then
			if removedFeatures[featureID] then
				if (updateCount + featureID) % updatePercent == 0 then
					updateFeature(featureID)
				end
				removedFeatures[featureID] = nil
			else
				addFeature(featureID, featureDefID)
			end
		end
	end

	for featureID, val in pairs(removedFeatures) do
		if val ~= nil then
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
