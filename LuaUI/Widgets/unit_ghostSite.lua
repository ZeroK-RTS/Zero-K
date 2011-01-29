-- $Id$
local versionNumber = "1.0"

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
local debug = false		--generates debug message
local updateInt = 1 	--seconds for the ::update loop
-- END OF CONFIG

local lastTime
local ghostSites = {}
local ghostFeatures = {}

local floor                 = math.floor
local udefTab				= UnitDefs
local glColor               = gl.Color
local glDepthTest           = gl.DepthTest
local glTexture             = gl.Texture
local glTexEnv				= gl.TexEnv
local glLineWidth           = gl.LineWidth
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glFeatureShape		= gl.FeatureShape
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetMyPlayerID       = Spring.GetMyPlayerID
local spGetPlayerInfo       = Spring.GetPlayerInfo
local spGetAllFeatures		= Spring.GetAllFeatures
local spGetFeaturePosition  = Spring.GetFeaturePosition
local spGetFeatureDefID		= Spring.GetFeatureDefID
local spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
local spGetFeatureAllyTeam	= Spring.GetFeatureAllyTeam
local spGetFeatureTeam		= Spring.GetFeatureTeam
local spGetUnitHealth 		= Spring.GetUnitHealth
local spGetFeatureHealth 	= Spring.GetFeatureHealth
local spGetFeatureResurrect = Spring.GetFeatureResurrect
local spGetPositionLosState = Spring.GetPositionLosState
local spIsUnitAllied		= Spring.IsUnitAllied
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitHealth 	    = Spring.GetUnitHealth
local spEcho                = Spring.Echo
local spGetUnitDefID        = Spring.GetUnitDefID

local DrawGhostFeatures
local DrawGhostSites
local ScanFeatures
local DeleteGhostFeatures
local DeleteGhostSites
local ResetGl
local CheckSpecState
local printDebug


function widget:Update()
	local timef = spGetGameSeconds()
	local time = floor(timef)

	-- update timers once every <updateInt> seconds
	if (time % updateInt == 0 and time ~= lastTime) then	
		lastTime = time
		--do update stuff:
		
		if ( CheckSpecState() == false ) then
			return false
		end
		
		ScanFeatures()
		
		DeleteGhostSites()
		DeleteGhostFeatures()
	end
end

function widget:DrawWorld()
	DrawGhostSites()
	
	DrawGhostFeatures()
	
	ResetGl()
end

function widget:UnitEnteredLos(unitID, allyTeam)
	
	if ( spIsUnitAllied( unitID ) ) then
		return
	end
	
	local _,_,_,_,buildProgress = spGetUnitHealth( unitID )
	local udef = udefTab[spGetUnitDefID(unitID)]
		
	if ( udef.isBuilding == true or udef.isFactory == true or udef.speed == 0) and buildProgress ~= 1  then
		printDebug( "Ghost added")
		local x, _, z = spGetUnitPosition(unitID)
		local y = Spring.GetGroundHeight(x,z) + 16 -- every single model is offset by 16, pretty retarded if you ask me.
		ghostSites[unitID] = { unitDefId = spGetUnitDefID(unitID), pos = {x, y, z}, teamId = allyTeam }
	end
end

function DrawGhostFeatures()
	glColor(1.0, 1.0, 1.0, 0.35 )
  
	glTexture(0,"$units1")
	--glTexture(1,"$units1")

	glTexEnv( GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 34160 )				--GL_COMBINE_RGB_ARB
	--use the alpha given by glColor for the outgoing alpha.
	glTexEnv( GL.TEXTURE_ENV, 34162, GL.REPLACE )			--GL_COMBINE_ALPHA
	glTexEnv( GL.TEXTURE_ENV, 34184, 34167 )			--GL_SOURCE0_ALPHA_ARB			GL_PRIMARY_COLOR_ARB
	
	--------------------------Draw-------------------------------------------------------------
	for unitID, ghost in pairs( ghostFeatures ) do
		--	printDebugTable( weapon )
		local x, y, z = ghost["pos"][1], ghost["pos"][2], ghost["pos"][3]
		local a, b, c = spGetPositionLosState(x, y, z)
		local losState = b
	
		if ( losState == false ) then
			--glow effect?
			--gl.Blending(GL.SRC_ALPHA, GL.ONE)
			    
			glPushMatrix()
			glTranslate( x, y, z)

			glFeatureShape(ghost["featDefId"], ghost["teamId"] )
			  
			glPopMatrix()
		end
	end

	--------------------------Clean up-------------------------------------------------------------
	glTexEnv( GL.TEXTURE_ENV, GL.TEXTURE_ENV_MODE, 8448 )				--GL_MODULATE
	--use the alpha given by glColor for the outgoing alpha.
	glTexEnv( GL.TEXTURE_ENV, 34162, 8448 )											--GL_MODULATE
	----gl.TexEnv( GL.TEXTURE_ENV, 34184, 5890 )			--GL_SOURCE0_ALPHA_ARB			GL_TEXTURE
end

function DrawGhostSites()
	glColor(0.3, 1.0, 0.3, 0.25)
	glDepthTest(true)

	for unitID, ghost in pairs( ghostSites ) do
		--	printDebugTable( weapon )
		local x, y, z = ghost["pos"][1], ghost["pos"][2], ghost["pos"][3]
		local a, b, c = spGetPositionLosState(x, y, z)
		local losState = b
	
		if ( losState == false) then
			--glow effect?
			--gl.Blending(GL.SRC_ALPHA, GL.ONE)
			    
			glPushMatrix()
			glTranslate( x, y - 17, z)

			gl.UnitShape(ghost["unitDefId"], ghost["teamId"] )
			      
			glPopMatrix()
		end
	end
end

function ScanFeatures()	
	local features = spGetAllFeatures()

	for _, fID in ipairs(features) do
		local fDefId = spGetFeatureDefID(fID)
		local fName = FeatureDefs[fDefId].name
	
		local myAllyID = spGetMyAllyTeamID()
		local fAllyID = spGetFeatureAllyTeam(fID)
		local fTeamID = spGetFeatureTeam( fID )
		local resName, _ = spGetFeatureResurrect(fID)

		--printDebug( "FID: " .. fDefId .. " Name: " .. fName .. " Team: " .. fTeamID .. " Res: " .. resName )

		if ( resName == "" and fAllyID >= 0 and myAllyID ~= fAllyID and ghostFeatures[fID] == nil ) then
			--printDebug( FeatureDefs[fDefId] )
			local x, y, z = spGetFeaturePosition(fID)
			--printDebug("Feature added: " .. fName .. " ID: " .. fID .. " Pos: " .. x .. ":" .. y .. ":" .. z .. " Ally: " .. fAllyID .. " Team: " .. fTeamID  )
			ghostFeatures[fID] = { featDefId = fDefId, pos = {x, y, z}, teamId = fTeamID }
		end
	end
end

function DeleteGhostFeatures()
	for featureID, ghost in pairs(ghostFeatures) do
		local x, y, z = ghost["pos"][1], ghost["pos"][2], ghost["pos"][3]
		local a, b, c = spGetPositionLosState(x, y, z)
		local losState = b
		local featDefID = spGetFeatureDefID(featureID)
			
		--local health,_,_ = spGetFeatureHealth( unitID )
	
		if ( featDefID == nil and losState) then	
			printDebug("Ghost Feature deleted: " .. featureID )
			ghostFeatures[featureID] = nil
		end
	end
end

function DeleteGhostSites()
	for unitID, ghost in pairs(ghostSites) do
		local x, y, z = ghost["pos"][1], ghost["pos"][2], ghost["pos"][3]
		local a, b, c = spGetPositionLosState(x, y, z)
		local losState = b
		local udefID = spGetUnitDefID(unitID)
			
		local _,_,_,_,buildProgress = spGetUnitHealth( unitID )
	
		if ( ( udefID == nil or buildProgress == 1 ) and losState) then	
			printDebug("Ghost deleted: " .. unitID )
			ghostSites[unitID] = nil
		end
	end
end

--Commons
function ResetGl() 
	glColor( { 1.0, 1.0, 1.0, 1.0 } )
	glLineWidth( 1.0 )
	glDepthTest(false)
	glTexture(false)
end

function CheckSpecState()
	local playerID = spGetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(playerID)
		
	if ( spec == true ) then
		spEcho("<Ghost Site> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
		return false
	end
	
	return true	
end

function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then spEcho( "true" )
				else spEcho("false") end
		elseif ( type(value ) == "table" ) then
			spEcho("Dumping table:")
			for key,val in pairs(value) do 
				spEcho(key,val) 
			end
		else
			spEcho( value )
		end
	end
end
