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

-- TODO, maybe we want to have a priority system between different sources of highlight?
-- The widget could at least ensure that if two highlights are added, then one is removed
-- the other source of highlight reasserts itself.

local function HighlightUnitCus(unitID, value)
	unitBufferUniformCache[1] = value
	if Spring.ValidUnitID(unitID) then
		gl.SetUnitBufferUniforms(unitID, unitBufferUniformCache, SELECTEDNESS_UNIFORM)
	end
end

local function HighlightFeatureCus(featureID, value)
	unitBufferUniformCache[1] = value
	if Spring.ValidFeatureID(featureID) then
		gl.SetFeatureBufferUniforms(featureID, unitBufferUniformCache, SELECTEDNESS_UNIFORM)
	end
end

function widget:Initialize()
	WG.HighlightUnitCus = HighlightUnitCus
	WG.HighlightFeatureCus = HighlightFeatureCus
end
