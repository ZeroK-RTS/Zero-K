
function widget:GetInfo()
	return {
		name      = "Ghost Site",
		desc      = "[v1.03] Displays ghosted buildings in progress and features",
		author    = "very_bad_soldier",
		date      = "April 7, 2009",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

-- CONFIGURATION
local updateInt = 1    --seconds for the ::update loop
-- END OF CONFIG

local PARAM_DEFID   = 4
local PARAM_TEAMID  = 5
local PARAM_TEXTURE = 6
local PARAM_RADIUS  = 7
local PARAM_FACING  = 8

local updateTimer = 0
local ghostSites = {}
local ghostFeatures = {}
local scanForRemovalUnits    = {}
local scanForRemovalFeatures = {}
local dontCheckFeatures = {}

local gaiaTeamID = Spring.GetGaiaTeamID()

local shaderObj
function InitShader()
	local shaderTemplate = include("Widgets/Shaders/default_tint.lua")

    local shader = gl.CreateShader(shaderTemplate)
    if not shader then
        Spring.Echo("Ghost Site shader compilation failed: " .. gl.GetShaderLog())
        return
    end
    shaderObj = {
        shader = shader,
        teamColorID = gl.GetUniformLocation(shader, "teamColor"),
        tint = gl.GetUniformLocation(shader, "tint")
    }
end

local function DrawGhostFeatures()
	gl.Color(1.0, 1.0, 1.0, 0.35)
  
	--gl.Texture(0,"$units1") --.3do texture atlas for .3do model
	--gl.Texture(1,"$units1")

	gl.TexEnv(GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 34160) --34160 = GL_COMBINE_RGB_ARB
	--use the alpha given by glColor for the outgoing alpha, else it would interpret the teamcolor channel as alpha one and make model transparent.
	gl.TexEnv(GL.TEXTURE_ENV, 34162, GL.REPLACE) --34162 = GL_COMBINE_ALPHA
	gl.TexEnv(GL.TEXTURE_ENV, 34184, 34167) --34184 = GL_SOURCE0_ALPHA_ARB, 34167 = GL_PRIMARY_COLOR_ARB
	
	--------------------------Draw-------------------------------------------------------------
	local lastTexture = ""
	for featureID, ghost in pairs(ghostFeatures) do
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)

		if not losState and Spring.IsSphereInView(x,y,z,ghost[PARAM_RADIUS]) then
			--glow effect?
			--gl.Blending(GL.SRC_ALPHA, GL.ONE)
			if (lastTexture ~= ghost[PARAM_TEXTURE]) then
				lastTexture = ghost[PARAM_TEXTURE]
				gl.Texture(0, lastTexture) -- no 3do support!
			end

			gl.PushMatrix()
			gl.Translate(x, y, z)

			gl.FeatureShape(ghost[PARAM_DEFID], ghost[PARAM_TEAMID], false, true, false)

			gl.PopMatrix()
		else
			scanForRemovalFeatures[featureID] = true
		end
	end

	--------------------------Clean up-------------------------------------------------------------
	gl.TexEnv(GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 8448) --8448 = GL_MODULATE
	--use the alpha given by glColor for the outgoing alpha.
	gl.TexEnv(GL.TEXTURE_ENV, 34162, 8448) --34162 = GL_COMBINE_ALPHA, 8448 = GL_MODULATE
	--gl.TexEnv(GL.TEXTURE_ENV, 34184, 5890) --34184 = GL_SOURCE0_ALPHA_ARB, 5890 = GL_TEXTURE
end

local function DrawGhostSites()
	gl.Color(0.3, 1.0, 0.3, 0.25)
	gl.DepthTest(true)

	for unitID, ghost in pairs(ghostSites) do
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)

		if not losState and Spring.IsSphereInView(x,y,z,ghost[PARAM_RADIUS]) then
			--glow effect?
			--gl.Blending(GL.SRC_ALPHA, GL.ONE)

			local ghostTeamColor = {Spring.GetTeamColor(ghost[PARAM_TEAMID])}
			gl.PushMatrix()
			gl.Translate(x, y, z)
			gl.Rotate(ghost[PARAM_FACING], 0, 1, 0)
			
			if shaderObj then
				gl.UseShader(shaderObj.shader)
				gl.Uniform(shaderObj.teamColorID, ghostTeamColor[1], ghostTeamColor[2], ghostTeamColor[3], 0.25)
				gl.Uniform(shaderObj.tint, 0.1, 1, 0.2)
			end

			gl.UnitShapeTextures(ghost[PARAM_DEFID], true)
			gl.UnitShape(ghost[PARAM_DEFID], ghost[PARAM_TEAMID], true)
			gl.UnitShapeTextures(ghost[PARAM_DEFID], false)

			if shaderObj then
				gl.UseShader(0)
			end

			gl.PopMatrix()
		else
			scanForRemovalUnits[unitID] = true
		end
	end
end

local function ScanFeatures()
	for _, fID in ipairs(Spring.GetAllFeatures()) do
		if not (dontCheckFeatures[fID] or ghostFeatures[fID]) then
			local fAllyID = Spring.GetFeatureAllyTeam(fID)
			local fTeamID = Spring.GetFeatureTeam(fID)

			if (fTeamID ~= gaiaTeamID and fAllyID and fAllyID >= 0) then
				local fDefId  = Spring.GetFeatureDefID(fID)
				local x, y, z = Spring.GetFeaturePosition(fID)
				ghostFeatures[fID] = { x, y, z, fDefId, fTeamID, "%-"..fDefId..":0", FeatureDefs[fDefId].radius + 100 }
			else
				dontCheckFeatures[fID] = true
			end
		end
	end
end

local function DeleteGhostFeatures()
	if not next(scanForRemovalFeatures) then
		return
	end

	for featureID in pairs(scanForRemovalFeatures) do
		local ghost   = ghostFeatures[featureID]
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)

		local featDefID = Spring.GetFeatureDefID(featureID)

		if (not featDefID and losState) then
			ghostFeatures[featureID] = nil
		end
	end
	scanForRemovalFeatures = {}
end

local function DeleteGhostSites()
	if not next(scanForRemovalUnits) then
		return
	end

	for unitID in pairs(scanForRemovalUnits) do
		local ghost   = ghostSites[unitID]
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)
		local udefID = Spring.GetUnitDefID(unitID)
		local _,_,_,_, buildProgress = Spring.GetUnitHealth(unitID)
	
		if losState and ((not udefID) or (buildProgress == 1)) then
			ghostSites[unitID] = nil
		end
	end
	scanForRemovalUnits = {}
end

--Commons
local function ResetGl()
	gl.Color(1.0, 1.0, 1.0, 1.0)
	gl.Texture(false)
end

local function CheckSpecState()
	local playerID = Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(playerID, false)

	if spec then
		Spring.Echo("<Ghost Site> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
		return false
	end

	return true
end


function widget:Update(dt)
	updateTimer = updateTimer + dt
	if (updateTimer < updateInt) then
		return
	end
	updateTimer = 0

	if not CheckSpecState() then
		return false
	end

	ScanFeatures()
	DeleteGhostSites()
	DeleteGhostFeatures()
end

function widget:DrawWorld()
	DrawGhostSites()
	DrawGhostFeatures()
	ResetGl()
end

function widget:DrawWorldRefraction()
	DrawGhostSites()
	DrawGhostFeatures()
	ResetGl()
end

function widget:UnitEnteredLos(unitID, unitTeam)
	if Spring.IsUnitAllied(unitID) then
		return
	end

	local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
	local udid = Spring.GetUnitDefID(unitID)
	local udef = UnitDefs[udid]

	if udef.isImmobile and buildProgress ~= 1 then
		local x, _, z = Spring.GetUnitPosition(unitID)
		local facing = Spring.GetUnitBuildFacing(unitID)
		local y = Spring.GetGroundHeight(x,z) -- every single model is offset by 16, pretty retarded if you ask me.
		ghostSites[unitID] = {x, y, z, udid, unitTeam, "%"..udid..":0", udef.radius + 100, facing * 90}
	end
end

function widget:Initialize()
	if gl.CreateShader then
		InitShader()
	end
end
