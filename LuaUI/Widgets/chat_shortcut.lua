local version = 'v1.101'

function widget:GetInfo()
	return {
		name = "Chat Shortcut",
		desc = version .. " Append chat console with player's names, unit's name, or whisper command OR display them on-screen using simple mouse button click" ,
		author = "xponen",
		date = "24 February 2012",
		license = "Public domain",
		layer = 0,
		enabled = false
	}
end
--------------------------------------------------------------------------------
-- Spring Function:
local spGetUnitsInRectangle  = Spring.GetUnitsInRectangle
local spGetUnitTeam = Spring.GetUnitTeam 
local spGetTeamInfo  = Spring.GetTeamInfo 
local spGetUnitDefID = Spring.GetUnitDefID
local spGetPlayerInfo  = Spring.GetPlayerInfo 
local spSendCommands = Spring.SendCommands
local spTraceScreenRay = Spring.TraceScreenRay
local spValidUnitID  = Spring.ValidUnitID 
local spGetCameraPosition		= Spring.GetCameraPosition
local spGetCameraFOV = Spring.GetCameraFOV
local tan				= math.tan
local atan				= math.atan
local GL_LINE_STRIP = GL.LINE_STRIP
local glPushMatrix	= gl.PushMatrix
local glColor	= gl.Color
local glBeginEnd	= gl.BeginEnd
local glPopMatrix	= gl.PopMatrix
local glVertex = gl.Vertex
local spWorldToScreenCoords  = Spring.WorldToScreenCoords
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitPosition = Spring.GetUnitPosition
--------------------------------------------------------------------------------
-- Constant:
local pasteCommand = "PasteText "
local whisper = "PasteText /WByNum "
-- Variables:
local gameID_to_playerName_gbl = {}
local boxSize_gbl = {0,{0,0,0}}
local fillingDistance_gbl = 1500 --//camera distance in which an algorithm will start scalling up the detection box for each distance, arbitrarily tuned at 60 degree FOV
local seconds = 0
local drawText = {false, "", {0,0,0}}
--------------------------------------------------------------------------------
-- Methods:
-- Processes:
function widget:Initialize()
	local gameID_to_playerName = gameID_to_playerName_gbl
	----
	local teamList = Spring.GetTeamList() --//check teamIDlist for AI, retrieve all names
	for j= 1, #teamList do
		local teamID = teamList[j]
		local _,playerID, _, isAI = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local _, aiName = Spring.GetAIInfo(teamID)
			gameID_to_playerName[teamID+1] = aiName
		elseif not isAI then
			local playerName = Spring.GetPlayerInfo(playerID, false)
			gameID_to_playerName[teamID+1] = playerName or "Gaia"
		end
	end
	----
	gameID_to_playerName_gbl = gameID_to_playerName
end

function widget:Update(n)
	seconds = seconds + n
	if  seconds >= 1 then
		seconds = 0
	else
		return
	end
	drawText[1]=false
end

function widget:MousePress(x, y, button)
	local gameID_to_playerName = gameID_to_playerName_gbl
	local boxSize = boxSize_gbl
	local fillingDistance = fillingDistance_gbl
	----
	local _, mpos = spTraceScreenRay(x, y, true) --//convert UI coordinate into ground coordinate. Reference: gfx_stereo3d.lua (CarRepairer, jK)
	if mpos == nil then --//if mouse position return false (eg: on UI), then skip
		return false
	end
	local _,cy,_= spGetCameraPosition()
	local y = spGetGroundHeight(mpos[1], mpos[3]) + 3
	fillingDistance = AdjustForFOV(fillingDistance)
	local addedSize = MaintainUnitSize(40, fillingDistance, cy)
	local unit = spGetUnitsInRectangle( mpos[1]-40-addedSize, mpos[3]-40-addedSize, mpos[1]+40+addedSize,mpos[3]+40+addedSize) 
	boxSize[1] = 40+addedSize
	boxSize[2] = {mpos[1],y,mpos[3]}
	local unitID = unit[1] --//only take 1st row because since the box is quite small it could only fit 1 unit. 1 unit is a reasonable assumption.
	local validUnitID = spValidUnitID(unitID)
	if validUnitID == false or validUnitID == nil then --//if not valid unitID, then skip
		return false
	end
	_,y,_ = spGetUnitPosition(unitID)
	boxSize[2][2] = y
	local teamID = spGetUnitTeam(unitID)
	
	local leftButton = 1
	local middleButton = 2
	local rightButton = 3
	if button == leftButton then
		local unitDefID = spGetUnitDefID(unitID)
		local unitDefinition = UnitDefs[unitDefID]
		if unitDefinition ~= nil then --//if unit is an unknown radar blip, then skip 
			local unitHumanName = unitDefinition.humanName
			local textToBePasted = pasteCommand .. unitHumanName .. "," --//paste unitName
			spSendCommands(textToBePasted)
			local scrnX, scrnY = spWorldToScreenCoords(mpos[1],y,mpos[3])
			drawText={true, unitHumanName, {scrnX,y,scrnY}}
		end
	end
	if button == rightButton then
		--local playerName = spGetPlayerInfo(playerID, false)
		local playerName = gameID_to_playerName[teamID+1]
		local textToBePasted = pasteCommand .. playerName .. "," --//paste playerName
		spSendCommands(textToBePasted)
		local scrnX, scrnY = spWorldToScreenCoords(mpos[1],y,mpos[3])
		drawText={true, playerName, {scrnX,y,scrnY}}
	end
	if button == middleButton then
		local _,playerID = spGetTeamInfo(teamID, false) --//definition of playerID in this context refer to: http://springrts.com/wiki/Lua_SyncedRead#Player.2CTeam.2CAlly_Lists.2FInfo
		if playerID>=0 then --//if playerID==-1 then skip
			local textToBePasted = whisper .. playerID .. " ," --//paste whisper
			spSendCommands(textToBePasted)
			local scrnX, scrnY = spWorldToScreenCoords(mpos[1],y,mpos[3])
			drawText={true, playerID, {scrnX,y,scrnY}}
		end
	end
	----
	boxSize_gbl = boxSize
end

function AdjustForFOV(fillingDistance)
	local fieldOfView = spGetCameraFOV()
	local factor = fieldOfView/60 --//find the factor of current FOV with-respect-to the tuned FOV (60)
	fillingDistance = fillingDistance/factor --//scale down/up the camera distance based on factor (eg: IF twice the tuning FOV, then camera distance start at half the original)
	return fillingDistance
end

function MaintainUnitSize(unitOriginalSize, originalViewHeight, currentViewHeight) --//from gui_flat2DView.lua (xponen)
	if (currentViewHeight >originalViewHeight) then
		local viewAngle= atan(unitOriginalSize/originalViewHeight)
		local newSize = tan(viewAngle)*currentViewHeight
		local addedSize = newSize- unitOriginalSize
		return addedSize
	end
	return 0
end
-- Draw:
function widget:DrawWorld()
	local boxSize = boxSize_gbl
	----
	if boxSize[1] ~= 0 then
		glPushMatrix()
		glColor(1, 1, 1, 0.30)
		glBeginEnd(GL_LINE_STRIP, DrawOutline, boxSize[1], boxSize[1], boxSize[2][1], boxSize[2][2], boxSize[2][3]) --from "central_build_AI.lua", by  Troy H. Cheek
		glColor(1, 1, 1, 1)
		glPopMatrix()
		boxSize[1] = 0
		boxSize[2] = {0,0,0}
	end
	----
	boxSize_gbl = boxSize
end

function widget:DrawScreen()
	if drawText[1] ==true then
		glPushMatrix()
		glColor(1, 1, 1, 1)
		gl.Text(drawText[2], drawText[3][1], drawText[3][3], 12, "on")
		glPopMatrix()
	end
end

--from "central_build_AI.lua", a widget by Troy H. Cheek
function DrawOutline(xSize, zSize,x,y,z)
	local baseX= xSize
	local baseZ= zSize
	
	glVertex(x-baseX,y,z-baseZ)
	glVertex(x-baseX,y,z+baseZ)
	glVertex(x+baseX,y,z+baseZ)
	glVertex(x+baseX,y,z-baseZ)
	glVertex(x-baseX,y,z-baseZ)
end
--
