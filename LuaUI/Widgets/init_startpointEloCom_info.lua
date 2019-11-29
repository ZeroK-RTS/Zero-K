local version= "v0.945"
function widget:GetInfo()
  return {
    name      = "Comm-n-Elo Startpos. Info",
    desc      = version .. " Show Commander information and Rank icons before game start.",
    author    = "msafwan",
    date      = "2013 July 3",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

VFS.Include ("LuaRules/Utilities/lobbyStuff.lua")
VFS.Include("LuaRules/Configs/start_setup.lua")

--[[
options_path = 'Settings/Interface/Pregame Setup'
options_order = { 'showrankicon',}
options = {
	showrankicon = {
		name = 'Show rank icon for everyone',
		desc = 'Show rank icon under player name before game start',
		type = 'bool',
		value = false,
	},
}
--]]
---------------------------------------------------------------------------------------------
local playerInfo ={} --store commander name, commander defID, rank, playerID, and teamID
local elapsedSecond = 0 --to control update rate
-----------------------------------------------------------------------------------------------

function widget:GameStart()
	widgetHandler:RemoveWidget()
end

function widget:Initialize()

	if Spring.GetGameFrame()>0 then
		widgetHandler:RemoveWidget()
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
			local _,_,spec,_,_,_,_,_,_,_,customKey = Spring.GetPlayerInfo(playerID) --get customPlayerKey -- oh really? no fucking shit sherlock
			local icon = 'LuaUI/Images/LobbyRanks/' .. (customKey and customKey.icon or "0_0") .. '.png'
			local validEntry = not (x==y and x==z) and (not spec)
			playerInfo[#playerInfo +1] = {icon=icon, xyz={x,y,z},playerID=playerID,teamID=teamID, validEntry=validEntry,
				comDefName=DEFAULT_UNIT_NAME,
				comDefId=DEFAULT_UNIT
			}
		end
	end
end

function widget:Update(dt)
	if Spring.GetGameRulesParam("totalSaveGameFrame") then
		widgetHandler:RemoveWidget(self)
		return
	end

	elapsedSecond = elapsedSecond + dt
	if elapsedSecond>=0.1 then --update every 0.66 second (reason: 0.66 felt not long and not quick)
		for i=1, #playerInfo do
			local teamID = playerInfo[i].teamID
			local playerID = playerInfo[i].playerID
			local comDefName = playerInfo[i].comDefName
			local _,active,spec = Spring.GetPlayerInfo(playerID, false)
			local x,y,z = Spring.GetTeamStartPosition(teamID) --update player's start position (if available).
			x,y,z = x or 0 ,y or 0, z or 0 --safety for spectating using restricted LOS
			local validEntry = not (x==y and x==z) and active and (not spec) -- invalidate symmetrical coordinate (since they are not humanly possible, probably indicate issues), and invalidate "nil" rank, and invalidate disconnected players, and invalid spec
			playerInfo[i].xyz = {x,y,z}
			playerInfo[i].validEntry = validEntry
		end
		elapsedSecond = 0
	end
end

function CommSelection(playerID, startUnit) --receive from start_unit_setup.lua gadget.
	--find commander unitDefID, remember commander name
	--

	if not startUnit then
		return
	end
	
	local commProfile
	if UnitDefNames[startUnit] then
		local commProfileDef = WG.ModularCommAPI.GetProfileIDByBaseDefID(UnitDefNames[startUnit].id)
		if commProfileDef then
			commProfile = WG.ModularCommAPI.GetCommProfileInfo(commProfileDef)
		end
	elseif UnitDefs[startUnit] then
		local commProfileDef = WG.ModularCommAPI.GetProfileIDByBaseDefID(UnitDefs[startUnit].id)
		if commProfileDef then
			commProfile = WG.ModularCommAPI.GetCommProfileInfo(commProfileDef)
		end
	end
	
	if not commProfile then
		return
	end
	
	for i = 1, #playerInfo do
		if playerID == playerInfo[i].playerID then
			playerInfo[i].comDefName = commProfile.name or ""
			local unitDef = UnitDefNames["dyn" .. (commProfile.chassis or "strike").. "5"]
			
			if unitDef and unitDef.id then
				playerInfo[i].comDefId = unitDef.id
			else
				playerInfo[i].comDefId = UnitDefNames["dynstrike5"].id
			end
		end
	end
end

function widget:DrawScreenEffects()

	if Spring.IsGUIHidden() then
		return
	end
	if (#playerInfo <= 0) then
		return -- avoid unnecessary GL calls
	end

	gl.Color(1,1,1,1)
	-- gl.DepthMask(true)
	gl.DepthTest(true)
	gl.AlphaTest(GL.GREATER, 0.001)
	
	for i = 1, #playerInfo do
		local validEntry = playerInfo[i].validEntry
		if validEntry then
			local icon = playerInfo[i].icon
			local x = playerInfo[i].xyz[1]
			local y = playerInfo[i].xyz[2]
			local z = playerInfo[i].xyz[3]
			local height = y + (120) --got this exact height of the startpoint from minimap_startbox.lua
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
			x,height,z = Spring.WorldToScreenCoords(x,height,z)
			gl.Texture(playerInfo[i].icon)
			gl.PushMatrix()
			gl.Translate(x,height,z)
			gl.TexRect(-size*0.5+scrnHorzOffset, -size+scrnVertOffset, size*0.5+scrnHorzOffset, scrnVertOffset) --place this icon just below the player's name
			gl.PopMatrix()
		end
	end
	
	gl.Texture(false)
	
	gl.AlphaTest(false)
	gl.DepthTest(false)
	-- gl.DepthMask(false)
end
