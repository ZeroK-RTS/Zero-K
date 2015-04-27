-- $Id$
local versionNumber = "1.03"

function widget:GetInfo()
	return {
		name      = "Ghost Site",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Displays ghosted buildings in progress and features",
		author    = "very_bad_soldier",
		date      = "April 7, 2009",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

-- CONFIGURATION
local debug = false    --generates debug message
local updateInt = 1    --seconds for the ::update loop
-- END OF CONFIG

local PARAM_DEFID   = 4
local PARAM_TEAMID  = 5
local PARAM_TEXTURE = 6
local PARAM_RADIUS  = 7

local updateTimer = 0
local ghostSites = {}
local ghostFeatures = {}
local scanForRemovalUnits    = {}
local scanForRemovalFeatures = {}
local dontCheckFeatures = {}

local gaiaTeamID = ((Game.version:find('91.0') == 1)) and -1 or Spring.GetGaiaTeamID()

local DrawGhostFeatures
local DrawGhostSites
local ScanFeatures
local DeleteGhostFeatures
local DeleteGhostSites
local ResetGl
local CheckSpecState
local printDebug


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
	if Spring.IsUnitAllied( unitID ) then
		return
	end

	local _,_,_,_,buildProgress = Spring.GetUnitHealth( unitID )
	local udid = Spring.GetUnitDefID(unitID)
	local udef = UnitDefs[udid]

	if ( udef.isBuilding == true or udef.isFactory == true or udef.speed == 0) and buildProgress ~= 1  then
		printDebug( "Ghost added")
		local x, _, z = Spring.GetUnitPosition(unitID)
		local y = Spring.GetGroundHeight(x,z) + 16 -- every single model is offset by 16, pretty retarded if you ask me.
		ghostSites[unitID] = { x, y, z, udid, unitTeam, "%"..udid..":0", udef.radius + 100 }
	end
end

function DrawGhostFeatures()
	gl.Color(1.0, 1.0, 1.0, 0.35 )
  
	--gl.Texture(0,"$units1") --.3do texture atlas for .3do model
	--gl.Texture(1,"$units1")

	gl.TexEnv( GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 34160 ) --34160 = GL_COMBINE_RGB_ARB
	--use the alpha given by glColor for the outgoing alpha, else it would interpret the teamcolor channel as alpha one and make model transparent.
	gl.TexEnv( GL.TEXTURE_ENV, 34162, GL.REPLACE ) --34162 = GL_COMBINE_ALPHA
	gl.TexEnv( GL.TEXTURE_ENV, 34184, 34167 ) --34184 = GL_SOURCE0_ALPHA_ARB, 34167 = GL_PRIMARY_COLOR_ARB
	
	--------------------------Draw-------------------------------------------------------------
	local lastTexture = ""
	for featureID, ghost in pairs( ghostFeatures ) do
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
			gl.Translate( x, y, z)

			gl.FeatureShape(ghost[PARAM_DEFID], ghost[PARAM_TEAMID] )

			gl.PopMatrix()
		else
			scanForRemovalFeatures[featureID] = true
		end
	end

	--------------------------Clean up-------------------------------------------------------------
	gl.TexEnv( GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 8448 ) --8448 = GL_MODULATE
	--use the alpha given by glColor for the outgoing alpha.
	gl.TexEnv( GL.TEXTURE_ENV, 34162, 8448 ) --34162 = GL_COMBINE_ALPHA, 8448 = GL_MODULATE
	--gl.TexEnv( GL.TEXTURE_ENV, 34184, 5890 ) --34184 = GL_SOURCE0_ALPHA_ARB, 5890 = GL_TEXTURE
end

function DrawGhostSites()
	gl.Color(0.3, 1.0, 0.3, 0.25)
	gl.DepthTest(true)

	for unitID, ghost in pairs( ghostSites ) do
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)

		if not losState and Spring.IsSphereInView(x,y,z,ghost[PARAM_RADIUS]) then
			--glow effect?
			--gl.Blending(GL.SRC_ALPHA, GL.ONE)

			gl.PushMatrix()
			gl.Translate( x, y - 17, z)

			gl.UnitShape(ghost[PARAM_DEFID], ghost[PARAM_TEAMID] )

			gl.PopMatrix()
		else
			scanForRemovalUnits[unitID] = true
		end
	end
end

function ScanFeatures()
	for _, fID in ipairs(Spring.GetAllFeatures()) do
		if not (dontCheckFeatures[fID] or ghostFeatures[fID]) then
			local fAllyID = Spring.GetFeatureAllyTeam(fID)
			local fTeamID = Spring.GetFeatureTeam(fID)

			if ( fTeamID ~= gaiaTeamID and fAllyID and fAllyID >= 0 ) then
				local fDefId  = Spring.GetFeatureDefID(fID)
				local x, y, z = Spring.GetFeaturePosition(fID)
				ghostFeatures[fID] = { x, y, z, fDefId, fTeamID, "%-"..fDefId..":0", FeatureDefs[fDefId].radius + 100 }
			else
				dontCheckFeatures[fID] = true
			end
		end
	end
end

function DeleteGhostFeatures()
	if not next(scanForRemovalFeatures) then
		return
	end

	for featureID in pairs(scanForRemovalFeatures) do
		local ghost   = ghostFeatures[featureID]
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)

		local featDefID = Spring.GetFeatureDefID(featureID)

		if (not featDefID and losState) then
			printDebug("Ghost Feature deleted: " .. featureID )
			ghostFeatures[featureID] = nil
		end
	end
	scanForRemovalFeatures = {}
end

function DeleteGhostSites()
	if not next(scanForRemovalUnits) then
		return
	end

	for unitID in pairs(scanForRemovalUnits) do
		local ghost   = ghostSites[unitID]
		local x, y, z = ghost[1], ghost[2], ghost[3]
		local _, losState = Spring.GetPositionLosState(x, y, z)
		local udefID = Spring.GetUnitDefID(unitID)
		local _,_,_,_,buildProgress = Spring.GetUnitHealth( unitID )
	
		if losState and ((not udefID) or (buildProgress == 1)) then
			printDebug("Ghost deleted: " .. unitID )
			ghostSites[unitID] = nil
		end
	end
	scanForRemovalUnits = {}
end

--Commons
function ResetGl()
	gl.Color(1.0, 1.0, 1.0, 1.0)
	gl.Texture(false)
end

function CheckSpecState()
	local playerID = Spring.GetMyPlayerID()
	local _, _, spec = Spring.GetPlayerInfo(playerID)

	if spec then
		Spring.Echo("<Ghost Site> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
		return false
	end

	return true
end

function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then Spring.Echo( "true" )
				else Spring.Echo("false") end
		elseif ( type(value ) == "table" ) then
			Spring.Echo("Dumping table:")
			for key,val in pairs(value) do 
				Spring.Echo(key,val) 
			end
		else
			Spring.Echo( value )
		end
	end
end