--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Highlight CUS API",
		desc      = "Protects other widgets from knowing how CUS works.",
		author    = "GoogleFrog",
		date      = "21 October 2024", --last update: 29 January 2014
		license   = "GNU GPL, v2 or later",
		api       = true,
		layer     = -100, -- Before gfx_highlight_api_gl4
		enabled   = true,  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitBufferUniformCache = {0}
local SELECTEDNESS_UNIFORM = 6

local highlightPriory = {}
local unitHighlights = {}

-- TODO, maybe we want to have a priority system between different sources of highlight?
-- The widget could at least ensure that if two highlights are added, then one is removed
-- the other source of highlight reasserts itself.

function WG.SetHighlightPriority(name, priority)
	highlightPriory[name] = priority
end

local function ApplyUnitHiglight(unitID, value)
	if Spring.ValidUnitID(unitID) then
		unitBufferUniformCache[1] = value
		gl.SetUnitBufferUniforms(unitID, unitBufferUniformCache, SELECTEDNESS_UNIFORM)
	end
end

local function HighlightUnitCus(unitID, name, value)
	--Spring.Utilities.UnitEcho(unitID, name .. " " .. value)
	unitHighlights[unitID] = unitHighlights[unitID] or {}
	unitHighlights[unitID][name] = value
	local highValue, highPriority = false, false
	for name, value in pairs(unitHighlights[unitID]) do
		if value and value ~= 0 then
			if highlightPriory[name] > (highPriority or 0) then
				highPriority = highlightPriory[name]
				highValue = value
			end
		end
	end
	if not highValue then
		ApplyUnitHiglight(unitID, 0)
		unitHighlights[unitID] = nil
		return
	end
	ApplyUnitHiglight(unitID, highValue)
end

local function HighlightFeatureCus(featureID, value)
	unitBufferUniformCache[1] = value
	if Spring.ValidFeatureID(featureID) then
		gl.SetFeatureBufferUniforms(featureID, unitBufferUniformCache, SELECTEDNESS_UNIFORM)
	end
end

function widget:UnitDestroyed(unitID)
	unitHighlights[unitID] = nil
end

function widget:UnitLeftLos(unitID)
	if unitHighlights[unitID] then
		ApplyUnitHiglight(unitID, 0)
		unitHighlights[unitID] = nil
	end
end

function widget:Initialize()
	WG.HighlightUnitCus = HighlightUnitCus
	WG.HighlightFeatureCus = HighlightFeatureCus
end
