local version= "v0.91"
function widget:GetInfo()
  return {
    name      = "Comm-n-Elo Startpos. Info",
    desc      = version .. " Insert Commander information and Elo icons at players startpoints (will shutdown after GameStart)",
    author    = "msafwan",
    date      = "2012 Nov 2",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end
---------------------------------------------------------------------------------------------
local playerInfo ={}
local elapsedSecond = 0
local rankTextures = {}
do --perform the following task locally:
	local rankTexBase = 'LuaUI/Images/Ranks/' 
	rankTextures = {
	  [0] = nil,
	  [1] = rankTexBase .. 'rank1.png',
	  [2] = rankTexBase .. 'rank2.png',
	  [3] = rankTexBase .. 'rank3.png',
	  [4] = rankTexBase .. 'star.png',
	} --reference: unit_rank_icons.lua
end
local commList ={}
-----------------------------------------------------------------------------------------------

function widget:GameStart()
	widgetHandler:RemoveWidget()
end

function widget:Shutdown() --clean up WG.customToolTip as much as possible
	--Use:
	--commList
	--WG.customToolTip
	local tableLenght = 0 --measure WG.customToolTip to find out if its empty
	for i=1, #commList do
		tableLenght = 0
		for name, _ in pairs(WG.customToolTip) do --clean WG.customToolTip after use. Find any index with same comm name as ours and delete it.
			tableLenght = tableLenght + 1
			if name == commList[i][2] then
				WG.customToolTip[name] = nil --empty this entry
				tableLenght = tableLenght - 1
			end
		end
	end
	if tableLenght == 0 then --delete table completely if empty
		WG.customToolTip = nil
	end
end

function widget:Initialize()
	--Use:	
	--playerInfo
	--WG.customToolTip
	if Spring.GetGameFrame()>0 then
		widgetHandler:RemoveWidget()
		Spring.Echo("\"Comm-n-Elo Startpos. Info\" widget will not function after game start, now shutting down.")
		return
	end

	widgetHandler:RegisterGlobal("CommSelection", CommSelection) --Receive commander data from "start_unit_setup.lua" gadget. Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
	local playerList = {}
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		playerList = Spring.GetTeamList()
	else
		local allyID = Spring.GetMyAllyTeamID()
		playerList = Spring.GetTeamList(allyID)
	end
	for i=1, #playerList do
		local teamID = playerList[i]
		local x,y,z = Spring.GetTeamStartPosition(teamID) --get player's start position (if available).
		local leadPlayerID = select(2,Spring.GetTeamInfo(teamID)) --leader
		local customKey = select(10,Spring.GetPlayerInfo(leadPlayerID)) --get customPlayerKey
		local elo = (customKey and tonumber(customKey.elo)) or nil
		local eloLevel = (elo and math.min(4, math.max(1, math.floor((elo-1000) / 200)))) or nil -- for example: elo= 1500. elo 1500 minus 1000 = 500. 500 divide by 200 = 2.5. Floor 2.5 = 2. Thus show 2 bar. If less than 1 show 1 (math.max), if greater than 4 show 4 (math.min)
		local validEntry = not (x==y and x==z) and elo -- invalidate same coordinate (since they are not humanly possible), and also invalidate entry with "nil" elo.
		playerInfo[#playerInfo +1] = {elo, eloLevel,{x,y,z},leadPlayerID,teamID, validEntry} 
	end
	WG.customToolTip = WG.customToolTip or {} --initialize table to communicate to other widget of our custom Tooltips points
end

function widget:Update(dt)
	--Use:
	--elapsedSecond
	--playerInfo
	--commList
	--WG.customToolTip
	elapsedSecond = elapsedSecond + dt
	if elapsedSecond>=0.66 then --update every 0.66 second (reason: 0.66 felt not long and not quick)
		for i=1, #playerInfo do
			local teamID = playerInfo[i][5]
			local elo = playerInfo[i][1]
			local leadPlayerID = playerInfo[i][4]
			local active = select(2,Spring.GetPlayerInfo(leadPlayerID))
			local x,y,z = Spring.GetTeamStartPosition(teamID) --update player's start position (if available).
			local validEntry = not (x==y and x==z) and elo and active -- invalidate symmetrical coordinate (since they are not humanly possible), and invalidate "nil" elo, and invalidate disconnected players
			playerInfo[i][3] = {x,y,z}
			playerInfo[i][6] = validEntry
			for i=1, #commList do --update custom tooltip points
				--playerID = commList[i][1]
				if commList[i][1] == leadPlayerID then --if this com belong to this playerID then:
					local comDefName = commList[i][2] --get tier5 com name. We use comm name as index & also for tooltip. 
					WG.customToolTip[comDefName] = {box={x1 = x-25, x2 = x+25, z1= z-25, z2= z+25},tooltip="Build  ".. comDefName .. " - "} --update tooltip box position. We also added code in "gui_chili_selections_and_cursortip.lua" and "gui_contextmenu.lua" to find detect information.
					break
				end
			end
		end
		elapsedSecond = 0
	end
end

function CommSelection(playerID, commSeries, comDefNames)
	--Use:
	--commList
	local sixthDefName = commSeries .. " level 5" --comDefNames[#comDefNames] --used concenatted 'commSeries' instead of 'comDefNames' because of problem in transfering table from SYNCED to UNSYNCED in gadget.
	commList[#commList+1] =  {playerID, sixthDefName}
end

function widget:DrawScreenEffects() --Show icons on the screen. Reference: unit_icons.lua by carrepairer and googlefrog.
	--Use:
	--playerInfo
	--rankTextures
	if Spring.IsGUIHidden() then 
		return
	end
	if (#playerInfo <= 0) then
		return -- avoid unnecessary GL calls
	end

	gl.Color(1,1,1,1)
	gl.DepthMask(true)
	gl.DepthTest(true)
	gl.AlphaTest(GL.GREATER, 0.001)
	
	for i = 1, #playerInfo do
		local validEntry = playerInfo[i][6] --contain valid coordinate and texture
		if validEntry then
			local eloLevel = playerInfo[i][2]
			local x = playerInfo[i][3][1]
			local y = playerInfo[i][3][2]
			local z = playerInfo[i][3][3]
			local height = y + (119) --got this exact height of the startpoint thru trial-n-error
			gl.Texture( rankTextures[eloLevel] ) --the icon (4 to choose from)
			
			gl.PushMatrix()
			x,height,z = Spring.WorldToScreenCoords(x,height,z) --convert unit position into screen coordinate
			gl.Translate(x,height,z) --move icon into screen coordinate
			--local size = 59
			gl.TexRect(-59*0.5, -59+19, 59*0.5, 19) --place this icon just below the player's name
			gl.PopMatrix()
		end
	end
	
	gl.Texture(false)
	
	gl.AlphaTest(false)
	gl.DepthTest(false)
	gl.DepthMask(false)
end