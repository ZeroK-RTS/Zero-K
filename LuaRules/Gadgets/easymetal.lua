-- $Id: easymetal.lua 4046 2009-03-08 17:33:45Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Easy Metal",
    desc      = "Restricts mex placement on pre-analyzed flagged metal spots. Also provides snap-to placement.",
    author    = "CarRepairer",
    date      = "2008-09-25",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetGroundHeight		= Spring.GetGroundHeight

local floor					= math.floor

local snapDist			= 10000
local mexSize			= 25
local mexRad			= Game.extractorRadius > 125 and Game.extractorRadius or 125


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-- BEGIN SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetGroundInfo		= Spring.GetGroundInfo
local spGiveOrderToUnit 	= Spring.GiveOrderToUnit
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam

local gridSize			= 4
local threshFraction	= 0.4
local metalExtraction	= 0.004

local mapWidth 			= floor(Game.mapSizeX)
local mapHeight 		= floor(Game.mapSizeZ)
local mapWidth2 		= floor(Game.mapSizeX / gridSize)
local mapHeight2 		= floor(Game.mapSizeZ / gridSize)

local metalMap 			= {}
local maxMetal 			= 0


local flagCount			= 0

local metalData 		= {}
local metalDataCount 	= 0

local mexes = {}

local flags = {}

local function round(num, idp)
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end


local function mergeToFlag(flagNum, px, pz, pWeight)
	local fx = flags[flagNum].x
	local fz = flags[flagNum].z
	local fWeight = flags[flagNum].weight
	
	local avgX, avgZ
	
	if fWeight > pWeight then
		local fStrength = round(fWeight / pWeight)
		avgX = (fx*fStrength + px) / (fStrength +1)
		avgZ = (fz*fStrength + pz) / (fStrength +1)
	else
		local pStrength = (pWeight / fWeight)
		avgX = (px*pStrength + fx) / (pStrength +1)
		avgZ = (pz*pStrength + fz) / (pStrength +1)		
	end
	
	flags[flagNum].x = avgX
	flags[flagNum].z = avgZ
	flags[flagNum].weight = fWeight + pWeight
end


local function NearFlag(px, pz, dist)
	for k, flag in pairs(flags) do
		local fx, fz = flag.x, flag.z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return k
		end
	end
	return false
end


local function AnalyzeMetalMap()	
	for mx_i = 1, mapWidth2 do
		metalMap[mx_i] = {}
		for mz_i = 1, mapHeight2 do
			local mx = mx_i * gridSize
			local mz = mz_i * gridSize
			local _, curMetal = spGetGroundInfo(mx, mz)
			curMetal = floor(curMetal * 100)
			metalMap[mx_i][mz_i] = curMetal
			if (curMetal > maxMetal) then
				maxMetal = curMetal
			end	
		end
	end
	
	local lowMetalThresh = floor(maxMetal * threshFraction)
	
	for mx_i = 1, mapWidth2 do
		for mz_i = 1, mapHeight2 do
			local mCur = metalMap[mx_i][mz_i]
			if mCur > lowMetalThresh then
				metalDataCount = metalDataCount +1
				
				metalData[metalDataCount] = {
					x = mx_i * gridSize,
					z = mz_i * gridSize,
					metal = mCur
				}
				
			end
		end
	end
	
	table.sort(metalData, function(a,b) return a.metal > b.metal end)
	
	for index = 1, metalDataCount do
		
		local mx = metalData[index].x
		local mz = metalData[index].z
		local mCur = metalData[index].metal
		
		local nearFlagNum = NearFlag(mx, mz, mexRad*mexRad)
	
		if nearFlagNum then
			mergeToFlag(nearFlagNum, mx, mz, mCur)
		else
			flagCount = flagCount + 1
			flags[flagCount] = {
				x = mx,
				z = mz,
				weight = mCur
			}
			
		end
	end

end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		
	if cmdID < 0 and UnitDefs[-cmdID].extractsMetal > 0 then		
		local mx, mz = cmdParams[1],  cmdParams[3]
		
		local flagNum = NearFlag(mx, mz, snapDist)
		local flag = flags[flagNum]
		
		if flag then
			local fx,fz = flag.x, flag.z
			local fy = spGetGroundHeight(fx,fz)+1
			
			if (fx == mx and fz == mz) then
				return true
			end

			local opts = {}
			table.insert(opts, "shift") -- appending
			if (cmdOptions.alt)   then table.insert(opts, "alt")   end
			if (cmdOptions.ctrl)  then table.insert(opts, "ctrl")  end
			if (cmdOptions.right) then table.insert(opts, "right") end
			spGiveOrderToUnit(unitID, cmdID, {fx,fy,fz, cmdParams[4]}, opts)
		end
		
		return false
	end

	return true
end

function gadget:Initialize()
	
	AnalyzeMetalMap()
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in pairs(allUnits) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
	
	
	_G.mexes = mexes
	_G.flags = flags
	
end


function gadget:GameFrame(n)
	--[[
	local frame64 = (n) % 64
	if frame64 < 0.1 then
		local flagsString = ''
		for _,coord in pairs(flags) do
			flagsString =  flagsString ..coord.x ..',' ..coord.z ..'|'		
		end
		flagsString = flagsString:sub(1, -2)
		SendToUnsynced("GetFlags", flagsString)	
		
	end
	--]]
	
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	
	local ud = UnitDefs[unitDefID]
	if ud then
		
		if ud.extractsMetal > 0 then
			local x,_,z = spGetUnitPosition(unitID)
			local nearFlag = NearFlag(x, z, mexSize*mexSize)
			local alliance = spGetUnitAllyTeam(unitID)
			mexes[unitID] = {
				team = unitTeam,
				alliance = alliance,
				flag = nearFlag,
			}
			flags[nearFlag].mex = unitID	
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	--Only triggers for allied units
	if mexes[unitID] then
		local nearFlag = mexes[unitID].flag
		flags[nearFlag].mex = false
		mexes[unitID] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else
-- END SYNCED
-- BEGIN UNSYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetActiveCommand	= Spring.GetActiveCommand
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetGameFrame    	= Spring.GetGameFrame
local spGetMouseState		= Spring.GetMouseState
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetMapDrawMode		= Spring.GetMapDrawMode
local spGetPositionLosState = Spring.GetPositionLosState
local spWorldToScreenCoords	= Spring.WorldToScreenCoords
local spSendCommands		= Spring.SendCommands
local spTestBuildOrder 		= Spring.TestBuildOrder
local spGetUnitTeam			= Spring.GetUnitTeam
local spGetUnitLosState		= Spring.GetUnitLosState

local spGetTeamColor		= Spring.GetTeamColor
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spGetTeamInfo			= Spring.GetTeamInfo
local spGetTeamList			= Spring.GetTeamList

local glDrawGroundCircle	= gl.DrawGroundCircle 
local glDepthTest			= gl.DepthTest
local glLineWidth			= gl.LineWidth
local glScale				= gl.Scale
local glColor				= gl.Color
local glPushMatrix        	= gl.PushMatrix
local glPopMatrix         	= gl.PopMatrix
local glTranslate         	= gl.Translate
local glBillboard         	= gl.Billboard
local glAlphaTest      		= gl.AlphaTest
local GL_GREATER       		= GL.GREATER
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local GL_LINE_LOOP	 		= GL.LINE_LOOP
local glVertex		 		= gl.Vertex
local glBeginEnd	 		= gl.BeginEnd

LUAUI_DIRNAME = 'LuaUI/'
local fontHandler	= loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
local metalFont		= "LuaUI/Fonts/FreeSansBold_16"
local fhDrawCentered = fontHandler.DrawCentered

local showMetal, showMetalTemp, toggleMetal, showCursorIcon

local snapSteps = 30

local mexes
local msx,msz

local flags, hoverFlagNum, hoverFlagInLOS
local myAllyID, myTeamID
local gaiaTeamID			= Spring.GetGaiaTeamID()

local teamNames		= {}
local teamColors	= {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function NearFlag(px, pz, dist)
	if not flags then return false end
	for k, flag in spairs(flags) do		
		local fx, fz = flag.x, flag.z
		if (px-fx)^2 + (pz-fz)^2 < dist then
			return k
		end
	end
	return false
end

local DrawBox = function(x,z)
	local y = spGetGroundHeight(x,z)+3
	glVertex(x-mexSize, y, z-mexSize)
	glVertex(x+mexSize, y, z-mexSize)
	glVertex(x+mexSize, y, z+mexSize)
	glVertex(x-mexSize, y, z+mexSize)
	
end

local function DrawSnap(x1,z1,x2,z2)
	--local green = hoverFlagInLOS and 1 or 0
	--local blue = 1-green
	
	for i=1,snapSteps do
		local x = (x1*i + x2*(snapSteps-i)) / snapSteps
		local z = (z1*i + z2*(snapSteps-i)) / snapSteps
		glColor(0, 1, 0, 1-i/snapSteps)
		DrawBox(x,z)
	end
	
end				

function gadget:Initialize()
	myAllyID = Spring.GetLocalAllyTeamID()
	myTeamID = Spring.GetLocalTeamID()
	SetupTeams()
end


function gadget:Update()
	if spGetMapDrawMode() == 'metal' then
		spSendCommands({'ShowMetalMap'})
		toggleMetal = true
	end	

	local gameFrame = spGetGameFrame()
	local frame4 = (gameFrame) % 4
		
	if (frame4 < 0.1) then	
		local mx, my = spGetMouseState()
		local _,pos = spTraceScreenRay(mx,my,true)	
		if pos then
			 msx,msz = pos[1], pos[3]
		end
	
		if not flags then
			flags = SYNCED.flags
		end
		if not mexes then 
			mexes = SYNCED.mexes
		end
	
		local activeCmdIndex,activeid ,_,buildUnitName = spGetActiveCommand()
		local buildUnitDef = buildUnitName and UnitDefNames[buildUnitName]
		
		hoverFlagNum = false
		if pos and buildUnitDef and buildUnitDef.extractsMetal > 0 then			
			showCursorIcon = true
			toggleMetal = false
			if not showMetal then
				showMetalTemp = true
				showMetal = true
			end
			
			hoverFlagNum = NearFlag(msx,msz, snapDist)
			
			if hoverFlagNum then
				local msy = spGetGroundHeight(msx,msz)+1
				_, hoverFlagInLOS = spGetPositionLosState(msx,msy,msz, myAllyID)
				
				
				local testBuilding = buildUnitDef.id
				
				local blocking
			    CallAsTeam({ ['read'] = myTeamID }, function()
					blocking = spTestBuildOrder(testBuilding, flags[hoverFlagNum].x, 1, flags[hoverFlagNum].z, 1)
		        end)
				
				if blocking == 0 then					
					hoverFlagNum = false
				end
			end
		else
			if showMetalTemp then
				showMetal = false
				showMetalTemp = false
			end
			showCursorIcon = false
		end
		
		if toggleMetal then
			toggleMetal = false
			showMetal = not showMetal
		end

		if showMetal then
			-- update colors
			SetupTeams()
		end

	end --every 4 frames
	
end
function gadget:DrawWorld()	
	if showMetal and flags then
		
		fontHandler.UseFont(metalFont)
		glLineWidth(1)
		for k, flag in spairs(flags) do
			local fx,fz = flag.x, flag.z
			local fy = spGetGroundHeight(fx,fz)+45
			
			glColor(1, 1, 0, 0.3)
			glDepthTest(true)
			glDrawGroundCircle(fx, 1, fz, 40, 32)
			glDepthTest(false)
			
			glPushMatrix()
			
			if hoverFlagNum == k and msx then
				glBeginEnd(GL_LINE_LOOP, DrawSnap, msx, msz, fx, fz)
			else 
				--Draw mex info
				local mexOnFlag = flag.mex and mexes and mexes[flag.mex]
				
				glTranslate(fx,fy,fz)
				glBillboard()
				glScale(.6, .6, .6)
				local _, curFlagInLOS = spGetPositionLosState(fx,fy,fz, myAllyID)
				local mColor
				if curFlagInLOS then					
					if mexOnFlag then
						if mexOnFlag.alliance == myAllyID then
							mColor = {1, 1, 0, 0.7}
						else
							mColor = {1, 0, 0, 0.7}
						end
					else
						mColor = {1, 1, 1, 0.7}
					end
					
					
					if flag.mex then
						local curMex = mexes[flag.mex]
						glColor(teamColors[curMex.team])
						fhDrawCentered(teamNames[curMex.team], 0,0,0)
						
					end
				else
					mColor = {0.3, 0.2, 1, 0.7}
				end
				
				--Draw M's
				glColor(mColor)
				glScale(3, 3, 3)
				fhDrawCentered('M', 0,5,0)
			
			end
			
			
			
			glPopMatrix()
		end	-- for every flag
		
		glLineWidth(0)
		glColor(1,1,1,1)
		
	end --if show metal map
	
end

function gadget:DrawScreen() 
	if showCursorIcon then
		local mx, my = spGetMouseState()
		glPushMatrix()
		if hoverFlagNum then
			if hoverFlagInLOS then
				glColor(0,1,0,1)
			else
				glColor(0.3,0.2,1,1)
			end
			
			glAlphaTest(GL_GREATER, 0)
			glTexture('LuaRules/Images/easymetal/yes.png')
			local flag = flags[hoverFlagNum]
			local fx,fz = flag.x, flag.z
			local fy = spGetGroundHeight(fx,fz)+1
			local sx,sy,_ = spWorldToScreenCoords(fx,fy,fz)
			glTexRect(sx-mexSize, sy-mexSize, sx+mexSize, sy+mexSize)
		else
			glColor(1,0,0,1)
			glAlphaTest(GL_GREATER, 0)
			glTexture('LuaRules/Images/easymetal/no.png')
			glTexRect(mx-mexSize, my-mexSize, mx+mexSize, my+mexSize)
		end
		
		glPopMatrix()
		
		glAlphaTest(false)
		glColor(1,1,1,1)
	end --if show
	
end

function SetupTeams()
	
	local totalTeamList = spGetTeamList()
	
	for _,team in ipairs(totalTeamList) do
		local _, leaderPlayerID = spGetTeamInfo(team)
		teamNames[team] = spGetPlayerInfo(leaderPlayerID)
		teamColors[team]  = {spGetTeamColor(team)}
		
	end
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

end
