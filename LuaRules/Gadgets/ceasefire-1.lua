function gadget:GetInfo()
  return {
    name      = "Ceasefire-old",
    desc      = "Handles reciprocating ceasefires with a voting system.",
    author    = "CarRepairer",
    date      = "2009-01-15",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true -- loaded by default?
  }
end

local testMode = false
local testOnce = true

if tobool(Spring.GetModOptions().noceasefire) or Spring.FixedAllies() then
  return
end 

local Echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

local rzRadius			= 200
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitIsActive     = Spring.GetUnitIsActive
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spGetTeamUnitCount	= Spring.GetTeamUnitCount
local spInsertUnitCmdDesc	= Spring.InsertUnitCmdDesc
local spGetAllyTeamList		= Spring.GetAllyTeamList

local CMD_ONOFF             = CMD.ONOFF
local CMD_ATTACK            = CMD.ATTACK

local cfData = {}
local cloakedUnits = {}
local gaiaAlliance, gaiaTeam
local CMD_ANTINUKEZONE = 35130

local antinukeDefs = {}
local antinukeNames = {'armamd', 'armscab', 'cormabm', 'corfmd', 'cornukesub', 'armcarry'}
local nukeDefs = {}
local nukeNames = {'armsilo', 'corsilo'}
local antinukeZones = {}

local antinukeZoneCmdDesc = {
  id      = CMD_ANTINUKEZONE,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Antinuke Zone',
  cursor  = 'CloakShield', 
  action  = 'antinukezone',
  tooltip = 'NoNuke zone: Nuke attacks within range of this unit will break ceasefires.',
  params  = {'0', 'NoNukeZone', 'NoNukeZone' }
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function AddAntinukeZoneCmdDesc(unitID)
  local insertID = 123456 -- back of the pack
  spInsertUnitCmdDesc(unitID, insertID + 1, antinukeZoneCmdDesc)
end

local function AddZone(unitID, cmdParams, range)
	if (type(cmdParams[1]) ~= 'number') then
		return false
	end
	
	local allianceID = spGetUnitAllyTeam(unitID)
	local state = (cmdParams[1] == 1)
	
	if state then
		local x,_,z = spGetUnitPosition(unitID)
		antinukeZones[unitID] = {
			allianceID=allianceID, x=x,z=z,range=range
		}		
	else
		antinukeZones[unitID] = nil
	end
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_ANTINUKEZONE)
	if (cmdDescID) then
		antinukeZoneCmdDesc.params[1] = (state and '1') or '0'
		spEditUnitCmdDesc(unitID, cmdDescID, { params = antinukeZoneCmdDesc.params})
	end	
end

function clearVotes(alliance, enAlliance)
	local teamList = cfData[alliance][enAlliance].votes
	for teamID,_ in pairs(teamList) do
		cfData[alliance][enAlliance].votes[teamID] = false
		if testMode and alliance == 2 and testOnce then	
			Echo('Ceasefire: test votes!', alliance, enAlliance)
			testOnce = false
			cfData[alliance][enAlliance].votes[teamID] = true
		end
	end
end

function checkOffers()
	for alliance,aData in pairs(cfData) do
		for enAlliance,enData in pairs(aData) do
			--both sides offer, set ceasefire
			if enData.ceasefireOffered and cfData[enAlliance][alliance].ceasefireOffered then
				
				if not enData.lastCfState then
					enData.lastCfState = true
					enData.ceasefired = true
					clearVotes(alliance, enAlliance)
					SendToUnsynced('ceasefire', alliance, enAlliance, true) 
				end
			--one side not offering, break ceasefires if they exist
			else
				if enData.lastCfState then
					enData.lastCfState = false
					enData.ceasefired = false
					enData.ceasefireOffered = false
					
					SendToUnsynced('ceasefire', alliance, enAlliance, false)
				end
			end
		end
	end
end

function checkVotes()
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do			
			local yesVotes,totalVotes = 0,0
			for teamID, vote in pairs(enData.votes) do
				totalVotes = totalVotes + 1
				if vote then yesVotes = yesVotes + 1 end
			end
			enData.yesVotes = yesVotes
			enData.totalVotes = totalVotes
			
			if not enData.ceasefired then	
				--100%
				if yesVotes == totalVotes then 
					cfData[enAlliance][alliance].ceasefireOffered = true
				else
					cfData[enAlliance][alliance].ceasefireOffered = false
				end
			end
		end
	end			
end

function checkAllianceSizes()
	local allianceList = spGetAllyTeamList()
	for _, alliance in ipairs(allianceList) do
		
		local teamList = spGetTeamList(alliance)
		local livingTeam = false
		for _,teamID in ipairs(teamList) do
			local teamNum, leader, isDead = spGetTeamInfo(teamID)
			if not isDead then livingTeam = true end
		end
		if not livingTeam then
			cfData[alliance] = nil
			for _, aData in pairs(cfData) do
				aData[alliance] = nil
			end
		end
	end
end

local function distSqr(x1,z1,  x2,z2)
	return (x2-x1)*(x2-x1) + (z2-z1)*(z2-z1)
end

local function checkNukeAttack(unitID, cmdParams)
	local allianceID = spGetUnitAllyTeam(unitID)
	local x,z
	if cmdParams[2] then
		x,z = cmdParams[1],cmdParams[3]
	else
		x,_,z = spGetUnitPosition(cmdParams[1])
	end
	if not x then return false end
	for _, anzData in pairs(antinukeZones) do
		local aData1 = cfData[allianceID][anzData.allianceID]
		if aData1 and aData1.ceasefired then
			local aData2 = cfData[anzData.allianceID][allianceID]
			if distSqr(anzData.x,anzData.z,  x,z) < anzData.range*anzData.range then
				aData1.ceasefireOffered = false
				aData2.ceasefireOffered = false
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:TeamDied(deadTeamID)
	for alliance, aData in pairs(cfData) do
		for enAlliance, enData in pairs(aData) do
			enData.votes[deadTeamID] = nil
		end
	end
	checkAllianceSizes()
end

function gadget:RecvLuaMsg(msg, playerID)
	if (msg:find("ceasefire:",1,true)) then
		local _,_,_,teamID, allianceID = spGetPlayerInfo(playerID)
		local actionAlliance = tonumber(msg:sub(11,11))
		if cfData[allianceID] and cfData[allianceID][actionAlliance] then
			if cfData[allianceID][actionAlliance].ceasefired then
				cfData[allianceID][actionAlliance].ceasefireOffered = false
				cfData[actionAlliance][allianceID].ceasefireOffered = false
			else
				cfData[allianceID][actionAlliance].votes[teamID] = not cfData[allianceID][actionAlliance].votes[teamID]
			end
		end
	end
end

function gadget:GameFrame(f)
	if (f%32) < 0.1 then
		checkVotes()
		checkOffers()
		local teamList = spGetTeamList()
		for _,teamID in ipairs(teamList) do
			if spGetTeamUnitCount(teamID) == 0 then
				gadget:TeamDied(teamID)
			end
		end
	end
end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
	local allianceList = spGetAllyTeamList()
	local enAllianceList = spGetAllyTeamList()
	
	for _, alliance in ipairs(allianceList) do
		if alliance ~= gaiaAlliance then
			cfData[alliance] = {}
			for _, enAlliance in ipairs(enAllianceList) do
				if enAlliance ~= alliance and enAlliance ~= gaiaAlliance then
					cfData[alliance][enAlliance] = {}
					cfData[alliance][enAlliance].votes = {}
					local teamList = spGetTeamList(alliance)
					for _,teamID in ipairs(teamList) do
						cfData[alliance][enAlliance].votes[teamID] = false
						if testMode and alliance == 2 then
							cfData[alliance][enAlliance].votes[teamID] = true
						end
					end
				end
			end
		end
	end

	for _,name in pairs(antinukeNames) do
		local ud = UnitDefNames[name]
		if ud then
			local weaponDef = ud.weapons[1].weaponDef
			local coverage = WeaponDefs[weaponDef].coverageRange
			antinukeDefs[ud.id] = coverage
		end
	end
	for _,name in pairs(nukeNames) do
		local ud = UnitDefNames[name]
		nukeDefs[ud.id] = true
	end
	
	gadgetHandler:RegisterCMDID(CMD_ANTINUKEZONE)
	local allUnits = spGetAllUnits()
	for _, unitID in ipairs(allUnits) do
		local unitDefID = spGetUnitDefID(unitID)
		if (antinukeDefs[unitDefID]) then
			AddAntinukeZoneCmdDesc(unitID)
		end
	end

	checkAllianceSizes()
	checkVotes()
	_G.cfData = cfData

end

function gadget:AllowCommand(unitID, unitDefID, teamID,cmdID, cmdParams, cmdOptions)
	local range = antinukeDefs[unitDefID]
	if cmdID == CMD_ANTINUKEZONE and range then
		AddZone(unitID, cmdParams, range)  
		return false  -- command was used
	elseif cmdID == CMD_ATTACK and nukeDefs[unitDefID] then
		checkNukeAttack(unitID, cmdParams)
	end
	return true  -- command was not used
end

function gadget:UnitCreated(unitID, unitDefID)
	if antinukeDefs[unitDefID] then
		AddAntinukeZoneCmdDesc(unitID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	antinukeZones[unitID] = nil
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


local spGetGameFrame 		= Spring.GetGameFrame
local SendLuaRulesMsg 		= Spring.SendLuaRulesMsg
local spSendCommands		= Spring.SendCommands
local spGetSpectatingState 	= Spring.GetSpectatingState
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID

local CallAsTeam = CallAsTeam

local glPushMatrix			= gl.PushMatrix
local glPopMatrix			= gl.PopMatrix
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local glTranslate			= gl.Translate
local glColor				= gl.Color
local glBeginEnd			= gl.BeginEnd
local glVertex				= gl.Vertex
local GL_QUADS     			= GL.QUADS
local glDrawGroundCircle	= gl.DrawGroundCircle
local glLineWidth			= gl.LineWidth
local glDepthTest			= gl.DepthTest

LUAUI_DIRNAME = 'LuaUI/'
local fontHandler   = loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
local bigFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_14"
local smallFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_12"
local fhDraw    		= fontHandler.Draw
local fhDrawCentered	= fontHandler.DrawCentered

local iWidth, iHeight 	= 32,38
local margin 			= 5
local buttonHoverMain 	= false
local buttonCaught 		= false
local bMainX, bMainY 	= 300, 300
local bMainW, bMainH 	= iWidth, iHeight
local winW, winH 		= 100,100
local expand 			= false
local inRightHalf 		= false
local moving 			= false
local tHeight			= 14
local linefeeds 		= 0
local expandWidth 		= 210
local clickCoords 		= {}
local sectionHover 		= 0
local blink 			= true
local cycle				= 1
local rZonePlaceMode	= false
local rZones			= {}
local rZoneSize			= 250
local rZoneCount		= 0
local spec				= true

local myAllyID 		= spGetLocalAllyTeamID()
local myTeamID 		= spGetLocalTeamID()
local myCeasefires 	= {}

local inColors, teamNames = {}, {}
local notifies, notify = {}, true
local cfData
local ACTION_SETRZONES = -1
local myCfData

--------------------------------------------------------

function lineFeed()
	glTranslate(0,-tHeight,0)
	linefeeds = linefeeds + 1
end

function printTeamList(alliance)
	teamList = spGetTeamList(alliance)	
	for k,teamID in ipairs(teamList) do
		if teamNames[teamID] then
			lineFeed()
			fhDraw('        '..inColors[teamID] ..'<> \255\255\255\255'.. teamNames[teamID],0,0)
		end
	end
	local cfFriends = '\255\255\255\255Friends: \255\0\255\0'
	for enAlliance, enData in spairs(cfData[alliance]) do
		if enData.ceasefired then
			cfFriends = cfFriends .. enAlliance .. ', '
		end
	end
	lineFeed()
	fhDraw(cfFriends ,0,0)
end
				
local function DrawBox(x1,y1,x2,y2)	
	glVertex(x1, y1)
	glVertex(x2, y1)
	glVertex(x2, y2)
	glVertex(x1, y2)	
end

--called from synced
local function ceasefire(_, a1, a2, onoff)
	if not spec and myAllyID == a1 then
		if onoff then
			spSendCommands({'ally '.. a2 .. ' 1'})
			myCeasefires[a2] = true
		else
			spSendCommands({'ally '.. a2 .. ' 0'})
			myCeasefires[a2] = nil
		end
	end
end

local function FindClosestRZone(sx, _, sz)
	local closestDistSqr = math.huge
	local cx, cy, cz  --  closest coordinates
	for rZoneID, pos in pairs(rZones) do
		local hx, hy, hz = pos[1], pos[2], pos[3]
		if hx then 
			local dSquared = (hx - sx)^2 + (hz - sz)^2
			if (dSquared < closestDistSqr) then
				closestDistSqr = dSquared
				cx = hx; cy = hy; cz = hz
				cRZoneID = rZoneID
			end
		end
	end
	if (not cx) then return -1, -1, -1, -1 end
	return cx, cy, cz, closestDistSqr, cRZoneID
end

local function addRZone(x, y, z)
	rZoneCount = rZoneCount + 1
	rZones[#rZones+1] = {x, y, z}
end

local function removeRZone(rZoneID)
	if rZones[rZoneID] then
		rZoneCount = rZoneCount - 1
	end
	rZones[rZoneID] = nil
end

function inRZones(cAlliance)
	local teamList = spGetTeamList(cAlliance)
	for _,teamID in ipairs(teamList) do
		for rZoneID, pos in pairs(rZones) do
			local units = CallAsTeam(myTeamID, function () return spGetUnitsInCylinder(pos[1], pos[3], rzRadius, teamID) end)
			if units and units[1] then
				return true
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------
							
function gadget:IsAbove(x,y)
	self:IsAboveMainButton(x,y)
	gadget:IsAboveActionButtons(x,y)
end

function gadget:IsAboveMainButton(x,y)
	local above = (x > bMainX) and (x < bMainX+bMainW) and (y > bMainY) and (y < bMainY+bMainH) 
	buttonHoverMain = above
	return above
end

function gadget:IsAboveActionButtons(x,y)
	sectionHover = false
	if expand then
		for action,yCoords in pairs(clickCoords) do
			local aboveCur
			if inRightHalf then
				aboveCur = (x > bMainX-expandWidth-margin*2) and (x < bMainX) and (y > bMainY+iHeight+margin*2 - yCoords.y1) and (y < bMainY+iHeight+margin*2 - yCoords.y2)
			else
				aboveCur = (x > bMainX+iWidth+margin*2) and (x < bMainX+iWidth+margin*2+expandWidth) and (y > bMainY+iHeight+margin*2 - yCoords.y1) and (y < bMainY+iHeight+margin*2 - yCoords.y2)
			end
			if aboveCur then
				sectionHover = action
			end
		end
	end
	return sectionHover
end

function gadget:MousePress(x,y,button)
	if (button==1) then
		if self:IsAboveMainButton(x,y) then
			buttonCaught = true
			cx = x-bMainX
			cy = y-bMainY
			caught = true
			return true
		elseif spec then
			return false
		elseif self:IsAboveActionButtons(x,y) then
			if sectionHover == ACTION_SETRZONES	then
				rZonePlaceMode = not rZonePlaceMode
				Echo('Restricted Zone Place Mode is '.. (rZonePlaceMode and 'ON.' or 'OFF.'))
			else
				SendLuaRulesMsg('ceasefire:'..sectionHover)
			end
			return true
		elseif rZonePlaceMode then
			local _,pos = spTraceScreenRay(x,y,true)
			if pos then
				local wx,wy,wz = pos[1], pos[2], pos[3]
				local _, _, _, dSquared, closestRZoneID = FindClosestRZone(wx,wy,wz)
				if dSquared ~= -1 and dSquared < rZoneSize*rZoneSize then
					removeRZone(closestRZoneID)
				else
					addRZone(wx,wy,wz)
				end
				return true
			end
		end
	end
	return false
end

function gadget:MouseRelease(x,y,button)
	if (button==1) then
		if buttonCaught then
			if not moving then
				expand = not expand
			end

			moving = false
			buttonCaught = false
			return true
		end
	end
	return false
end

function gadget:MouseMove(x,y,button)
	if buttonCaught then
		moving = true
		
		bMainX = x-cx
		if bMainX < 0 then
			bMainX = 1
		elseif bMainX+iWidth+margin*2 > winW then 
			bMainX = winW-iWidth-margin*2-1
		end
	
		bMainY = y-cy
		if bMainY < 0 then
			bMainY = 1
		elseif bMainY+iHeight+margin*2 > winH then
			bMainY = winH-iHeight-margin*2-1
		end
	
		inRightHalf = false
		if bMainX > winW / 2 then
			inRightHalf = true
		end
		return true
	else
		return false
	end
end

function gadget:DrawScreen()
	glPushMatrix()
	
	-- Main Button
	glTranslate(bMainX,bMainY, 0)
	glColor(0.2, 0.2, 0.2, 0.9)
	glBeginEnd(GL_QUADS, DrawBox, 0,0,iWidth+margin*2,iHeight+margin*2)
	
	if notify and blink then
		glColor(1,0,0,1)
	elseif buttonHoverMain then
		glColor(0,1,1,1)
	else
		glColor(1,1,1,1)
	end
	glTexture('LuaRules/Images/ceasefire/scroll.png')
	glTexRect(margin, margin, iWidth+margin, iHeight+margin )
	glTexture(false)
	
	-- Expansion
	if not expand then
		rZonePlaceMode = false
	else
				
		notify = false
		if inRightHalf then
			glTranslate(0-expandWidth-iWidth-margin*4,0, 0)
		end
	
		glColor(0.2, 0.2, 0.2, 0.9)
		glTranslate(iWidth+margin*2,iHeight+margin*2, 0)
		glBeginEnd(GL_QUADS, DrawBox, 0,0,expandWidth+margin*2,linefeeds * (-tHeight) - margin*2)
		glTranslate(margin,-margin, 0)
		linefeeds = 0
			
		glColor(1,1,1,1)
		fontHandler.DisableCache()
		fontHandler.UseFont(bigFont)
		
		if myCfData then
			for alliance, aData in spairs(myCfData) do
			
				local isAbove = false
				
				if sectionHover == alliance then
					isAbove = true
				end
				
				clickCoords[alliance] = {}
				clickCoords[alliance].y2 = (linefeeds) * tHeight
					
				if aData.ceasefired then
					lineFeed()
					fhDraw('Alliance '.. alliance ..' - \255\0\255\0Ceasefired',0,0)
					
					fontHandler.UseFont(smallFont)
					printTeamList(alliance)
					
					lineFeed()
					glColor(1,0,0,1)
					if not isAbove or blink then
						fhDraw('>> Break ceasefire?',0,0)
					else
						fhDraw('     Break ceasefire?',0,0)
					end
				else
					lineFeed()
					if aData.ceasefireOffered then
						fhDraw('Alliance '.. alliance ..' - \255\255\100\0Ceasefire offered',0,0)
					else
						fhDraw('Alliance '.. alliance ..' - \255\255\0\0No Ceasefire',0,0)
					end
					
					fontHandler.UseFont(smallFont)
					
					printTeamList(alliance)
					glColor(1,1,0,1)
					
					if aData.ceasefireOffered then
						lineFeed()	
						if aData.totalVotes == 1 then
							fhDraw('Accept ceasefire?',0,0)
						else
							fhDraw('Vote to accept ceasefire('.. aData.yesVotes ..'/'.. aData.totalVotes ..')?',0,0)
						end
					else
						lineFeed()
						if aData.totalVotes == 1 then
							fhDraw('Offer ceasefire?',0,0)
						else
							fhDraw('Vote to offer ceasefire('.. aData.yesVotes ..'/'.. aData.totalVotes ..')?',0,0)
						end
					end
					
					for teamID, vote in spairs(aData.votes) do
						lineFeed()
						if teamID ~= myTeamID then
							local _, leaderPlayerID = spGetTeamInfo(teamID)
							local leadPlayerName = spGetPlayerInfo(leaderPlayerID) or 'Rob P.'
							fhDraw(inColors[teamID].. '     <> \255\255\255\0'..leadPlayerName ..': '.. (vote and 'Y' or 'N') ,0,0)
						else
							--glColor(1,0.4,0,1)
							if not isAbove or blink then
								if aData.totalVotes == 1 then
									fhDraw('>> (Click to change) '..(vote and 'Yes' or 'No') ,0,0)
								else
									fhDraw('>> '..inColors[teamID].. '<> \255\255\255\0Your vote: '.. (vote and 'Y' or 'N') ,0,0)
								end
							else
								if aData.totalVotes == 1 then
									fhDraw('     (Click to change) '..(vote and 'Yes' or 'No') ,0,0)
								else
									fhDraw('     '..inColors[teamID]..'<> \255\255\255\0Your vote: '.. (vote and 'Y' or 'N') ,0,0)
								end
							end
							glColor(1,1,0,1)
						end
					end
					if aData.totalVotes == aData.yesVotes then
						lineFeed()
						glColor(0,1,1,1)
						fhDraw('Offering ceasefire to alliance '.. alliance,0,0)		
					end
				end
				
				clickCoords[alliance].y1 = (linefeeds+1) * tHeight	
				
				glColor(1,1,1,1)
				lineFeed()
				fhDraw('------------------------------------------',0,0)
				
			end
		end
		
		clickCoords[ACTION_SETRZONES] = {}
		clickCoords[ACTION_SETRZONES].y2 = (linefeeds) * tHeight
		lineFeed()
		local rZonePlaceModeText = rZonePlaceMode and blink and '' or 'Place Restricted Zones'
		if sectionHover == ACTION_SETRZONES and blink then
			fhDraw('     '..rZonePlaceModeText,0,0)
		else
			fhDraw('>> '..rZonePlaceModeText,0,0)
		end
		clickCoords[ACTION_SETRZONES].y1 = (linefeeds+1) * tHeight
		
	end
	
	glColor(1,1,1,1)
	glPopMatrix()
end

function gadget:DrawWorld()
	if rZonePlaceMode then
		glDepthTest(true)
		for _,pos in pairs(rZones) do
			glLineWidth(4)
			if blink then 
				glColor(1,0,0,1)
			else
				glColor(1,1,0,1)
			end
			glDrawGroundCircle(pos[1],0,pos[3], rZoneSize, 32)
			glLineWidth(2)
			if blink then 
				glColor(1,1,0,1)
			else
				glColor(1,0,0,1)
			end
			
			glDrawGroundCircle(pos[1],0,pos[3], rZoneSize, 32)
		end
		glDepthTest(false)
		glLineWidth(1)
	end
end

function gadget:ViewResize(vsx, vsy)
	winW = vsx
	winH = vsy
	bMainX = vsx/3
	bMainY = vsy/3
end
gadget:ViewResize(Spring.GetViewGeometry())

function gadget:Initialize()
	gadgetHandler:AddSyncAction('ceasefire', ceasefire)
	gadgetHandler:AddSyncAction('manualBreak', manualBreak)

	local teamList = spGetTeamList()
	for _,teamID in ipairs(teamList) do
		local _, leaderPlayerID = spGetTeamInfo(teamID)
		if leaderPlayerID and leaderPlayerID ~= -1 then
			
			teamNames[teamID] = spGetPlayerInfo(leaderPlayerID) or '?? Rob P. ??'
			local r,g,b,a = Spring.GetTeamColor(teamID)
			inColors[teamID] = '\\255\\255\\255\\255'
			if r then
				inColors[teamID] = string.char(a*255) .. string.char(r*255) ..  string.char(g*255) .. string.char(b*255)
			end
		end
	end
end

function gadget:Update()
	cycle = cycle % 32 + 1
	
	if SYNCED.cfData then
		cfData = SYNCED.cfData
	else
		return
	end
	

	spec = spGetSpectatingState()
	
	if cycle == 1 then
		blink = not blink
		myAllyID = spGetLocalAllyTeamID()
		myTeamID = spGetLocalTeamID()
		myCfData = cfData[myAllyID]
		
		if not spec then
			for cAlliance, _ in pairs(myCeasefires) do
				if inRZones(cAlliance) then
					SendLuaRulesMsg('ceasefire:'..cAlliance)
				end
				local cTeamList = spGetTeamList(cAlliance)	
				if not spAreTeamsAllied(cTeamList[1], myTeamID) then
					spSendCommands({'ally '.. cAlliance .. ' 1'})
					Echo('Ceasefire: Please use the control panel to break ceasefires, '..teamNames[myTeamID] ..'!!')
				end
			end
			
			if not myCfData then return end
			for alliance, aData in spairs(myCfData) do
				if aData.ceasefired then
					if not notifies[alliance] then
						notifies[alliance] = true
						notify = true
					end
				else
					if aData.ceasefireOffered then
						if not notifies[alliance] then
							notifies[alliance] = true
							notify = true
						end
					else
						if notifies[alliance] then
							notifies[alliance] = nil
							notify = true
						end
					end
				end
			end
		
		end
	end

end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end