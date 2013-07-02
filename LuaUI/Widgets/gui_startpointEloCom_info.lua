local version= "v0.945"
function widget:GetInfo()
  return {
    name      = "Comm-n-Elo Startpos. Info",
    desc      = version .. " Show Commander information and Elo icons before game start.",
    author    = "msafwan",
    date      = "2013 July 3",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

---------------------------------------------------------------------------------------------
local maxComLevel = 5 --commander level to be displayed at game start. Possible value: 0,1,2.. n-th
local rankTextures = {}
do
	local rankTexBase = 'LuaUI/Images/Ranks/' 
	rankTextures = {
	  [0] = nil,
	  [1] = rankTexBase .. 'dude_smurf.png', --dude-icon added by Sprung/Gnurps for theme consistency
	  [2] = rankTexBase .. 'dude_user.png',
	  [3] = rankTexBase .. 'dude_soldier.png',
	  [4] = rankTexBase .. 'dude_napoleon.png',
	  -- [1] = rankTexBase .. 'rank1.png', --this use unit-rank as user's rank (by xponen/msafwan)
	  -- [2] = rankTexBase .. 'rank2.png',
	  -- [3] = rankTexBase .. 'rank3.png',
	  -- [4] = rankTexBase .. 'star.png',	  
	} --reference: unit_rank_icons.lua
end
--[[
options_path = 'Settings/Interface/Comm-n-Elo Startpos. Info'
options_order = { 'showeloicon',}
options = {
	showeloicon = {
		name = 'Show elo icon for everyone',
		desc = 'Show elo icon under player name before game start',
		type = 'bool',
		value = false,
	},
}
--]]
---------------------------------------------------------------------------------------------
local playerInfo ={} --store commander name, commander defID, elo, playerID, and teamID
local elapsedSecond = 0 --to control update rate
-----------------------------------------------------------------------------------------------

function widget:GameStart()
	widgetHandler:RemoveWidget()
end

function widget:Shutdown() 
	--clean up WG.customToolTip as much as possible
	--
	
	local tableLenght = 0 --measure WG.customToolTip to find out if its empty
	for i=1, #playerInfo do
		tableLenght = 0
		for name, _ in pairs(WG.customToolTip) do --clean WG.customToolTip after use. Find any index with same comm name as ours and delete it.
			tableLenght = tableLenght + 1
			if name == playerInfo[i].comDefName then
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
	--check for gamestart, initialize CommSelection event, get player list, get player info, initialize WG.customTooltip.
	--
	
	if Spring.GetGameFrame()>0 then
		widgetHandler:RemoveWidget()
		Spring.Echo("\"Comm-n-Elo Startpos. Info\" widget removed after game start.")
		return
	end

	widgetHandler:RegisterGlobal("CommSelection", CommSelection) --Receive commander data from "start_unit_setup.lua" gadget. Reference: http://springrts.com/phpbb/viewtopic.php?f=23&t=24781 "Gadget and Widget Cross Communication"
	local teamList = {}
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		teamList = Spring.GetTeamList()
	else
		local allyID = Spring.GetMyAllyTeamID()
		teamList = Spring.GetTeamList(allyID)
	end
	for i=1, #teamList do
		local teamID = teamList[i]
		local x,y,z = Spring.GetTeamStartPosition(teamID) --get player's start position (if available).
		local playerList = Spring.GetPlayerList(teamID)--get player(s) in a team
		for j=1, #playerList do
			local playerID = playerList[j]
			local _,_,spec,_,_,_,_,_,_,customKey = Spring.GetPlayerInfo(playerID) --get customPlayerKey
			local elo = (customKey and tonumber(customKey.elo)) or nil
			local eloLevel = (elo and math.min(4, math.max(1, math.floor((elo-1000) / 200)))) or nil -- for example: elo= 1500. elo 1500 minus 1000 = 500. 500 divide by 200 = 2.5. Floor 2.5 = 2. Thus show 2 bar. If less than 1 show 1 (math.max), if greater than 4 show 4 (math.min)
			local validEntry = not (x==y and x==z) and elo and (not spec) -- invalidate same coordinate (since they are not humanly possible), and also invalidate entry with "nil" elo, and invalidate spec
			playerInfo[#playerInfo +1] = {elo=elo, eloLevel=eloLevel,xyz={x,y,z},playerID=playerID,teamID=teamID, validEntry=validEntry, comDefName=nil,comDefId=nil, comDefNamePrvs= {}} 
		end
	end
	WG.customToolTip = WG.customToolTip or {} --initialize table to communicate to other widget of our custom Tooltips points
end

function widget:Update(dt)
	--update startposition, update WG.customTooltip
	--
	
	elapsedSecond = elapsedSecond + dt
	if elapsedSecond>=0.66 then --update every 0.66 second (reason: 0.66 felt not long and not quick)
		for i=1, #playerInfo do
			local teamID = playerInfo[i].teamID
			local elo = playerInfo[i].eloLevel
			local playerID = playerInfo[i].playerID
			local comDefName = playerInfo[i].comDefName
			local prvsComDefName = playerInfo[i].comDefNamePrvs --reference to this table (this is not a value)
			local _,active,spec = Spring.GetPlayerInfo(playerID)
			local x,y,z = Spring.GetTeamStartPosition(teamID) --update player's start position (if available).
			x,y,z = x or 0 ,y or 0, z or 0 --safety for spectating using restricted LOS
			local validEntry = not (x==y and x==z) and elo and active and (not spec) -- invalidate symmetrical coordinate (since they are not humanly possible, probably indicate issues), and invalidate "nil" elo, and invalidate disconnected players, and invalid spec
			playerInfo[i].xyz = {x,y,z}
			playerInfo[i].validEntry = validEntry
			if comDefName then
				WG.customToolTip[comDefName] = {box={x1 = x-25, x2 = x+25, z1= z-25, z2= z+25},tooltip="Build  ".. comDefName .. " - "} --update tooltip box position. We also added code in "gui_chili_selections_and_cursortip.lua" and "gui_contextmenu.lua" to find detect information.
			end
			--Spring.Echo(teamID .. " " .. #prvsComDefName)
			for i=#prvsComDefName,1,-1 do --start at end of table, iterate downward while emptying table content
				local previousCom = prvsComDefName[i]
				prvsComDefName[i]=nil
				if previousCom ~= comDefName then
					WG.customToolTip[previousCom] = nil --empty this tooltip entry
				end
			end
		end
		elapsedSecond = 0
	end
end

function CommSelection(playerID, commSeries) --receive from start_unit_setup.lua gadget.
	--find commander unitDefID, remember commander name
	--
	
	local sixthDefName = commSeries .. " level ".. maxComLevel --used concenatted 'commSeries'
	local comDefId
	for id,unitDef in pairs(UnitDefs) do
		if unitDef.humanName == sixthDefName then
			comDefId = id
		end
	end
	for i=1, #playerInfo do
		if playerID == playerInfo[i].playerID then
			local previousCom = playerInfo[i].comDefName
			local tableIndex = #playerInfo[i].comDefNamePrvs
			playerInfo[i].comDefNamePrvs[tableIndex + 1] = previousCom --store list of previous selection. ie {com1, com2, com1,...}
			playerInfo[i].comDefName = sixthDefName
			playerInfo[i].comDefId = comDefId
		end
	end
end

function widget:DrawScreenEffects() --Show icons on the screen. Reference: unit_icons.lua by carrepairer and googlefrog.
	--draw elo icon under player's name at startposition
	--

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
		local validEntry = playerInfo[i].validEntry --contain valid coordinate and texture
		if validEntry then
			local eloLevel = playerInfo[i].eloLevel
			local x = playerInfo[i].xyz[1]
			local y = playerInfo[i].xyz[2]
			local z = playerInfo[i].xyz[3]
			local height = y + (119) --got this exact height of the startpoint thru trial-n-error
			--//The following config is suitable for unit-rank icon only:
			--local size = 59
			--local scrnVertOffset = 19
			--local scrnHorzOffset = 0
			--//
			--//The following config is suitable for dude-icon:
			local size = 23
			local scrnVertOffset = 35
			local scrnHorzOffset = 0
			--//
			x,height,z = Spring.WorldToScreenCoords(x,height,z) --convert unit position into screen coordinate
			gl.Texture( rankTextures[eloLevel] ) --the icon (4 to choose from)
			gl.PushMatrix()
			gl.Translate(x,height,z) --move icon into screen coordinate
			gl.TexRect(-size*0.5+scrnHorzOffset, -size+scrnVertOffset, size*0.5+scrnHorzOffset, scrnVertOffset) --place this icon just below the player's name
			gl.PopMatrix()
		end
	end
	
	gl.Texture(false)
	
	gl.AlphaTest(false)
	gl.DepthTest(false)
	gl.DepthMask(false)
end

--[[
local function SetupModelDrawing() --copied from gui_transporting.lua, SetupModelDrawing()
	gl.DepthTest(true) 
	gl.DepthMask(true)
	--gl.Culling(GL.FRONT)
	gl.Lighting(true)
	gl.Blending(false)
	gl.Material({
		ambient  = { 0.2, 0.2, 0.2, 1.0 },
		diffuse  = { 1.0, 1.0, 1.0, 1.0 },
		emission = { 0.0, 0.0, 0.0, 1.0 },
		specular = { 0.2, 0.2, 0.2, 1.0 },
		shininess = 16.0
	})
end

local function RevertModelDrawing()
	gl.Blending(true)
	gl.Lighting(false)
	--gl.Culling(false)
	gl.DepthMask(false)
	gl.DepthTest(false)
end
--]]

--//Draw commander. Reference: unit_ghostRadar.lua by very_bad_soldier
function widget:DrawWorldPreUnit()
	--draw commander at startposition
	--
	
	--SetupModelDrawing()
	gl.Color(1, 1, 1, 0.5)
	for i = 1, #playerInfo do
		local validEntry = playerInfo[i].validEntry --contain valid coordinate
		if validEntry then
			local comDefName = playerInfo[i].comDefName
			if comDefName then
				local x = playerInfo[i].xyz[1]
				local y = playerInfo[i].xyz[2]
				local z = playerInfo[i].xyz[3]
				local teamID = playerInfo[i].teamID				
				local comDefId = playerInfo[i].comDefId
				if comDefId then
					gl.PushMatrix()
					gl.Translate( x, y + 5 , z)
					gl.Scale(1.4,1.4,1.4)
					gl.UnitShape( comDefId, teamID )
					gl.PopMatrix()
				end
			end
		end
	end
	gl.Color(1, 1, 1, 1)
	--RevertModelDrawing()
end