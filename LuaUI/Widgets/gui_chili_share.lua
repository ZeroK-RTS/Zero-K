-- WARNING: This is a temporary file. Please modify as you see fit! --
function widget:GetInfo()
	return {
		name	= "Chili Share menu",
		desc	= "Press H to bring up the chili share menu.",
		author	= "_Shaman",
		date	= "12-3-2016",
		license	= "Do whatever with it (cuz a license isn't going to stop you ;) )",
		layer	= 2000,
		enabled	= true,
	}
end

local invites = {}
local built = false
local sharemode = false
local playersingame = {}
include("keysym.h.lua")
local playerlist, chili, window, screen0,updateme,invitelist,invwindow
local keytopress = KEYSYMS.H
local showing = false
local sizefontcache = {}
local images = {
	inviteplayer = 'LuaUI/Images/epicmenu/whiteflag_check.png',
	accept = 'LuaUI/Images/epicmenu/check.png',
	decline = 'LuaUI/Images/advplayerslist/cross.png',
	pending = 'LuaUI/Images/epicmenu/questionmark.png',
	leave = 'LuaUI/Images/epicmenu/exit.png',
	kick = 'LuaUI/Images/advplayerslist/cross.png', -- REPLACE ME
	leader = 'LuaUI/Images/Ranks/star.png',
	join = 'LuaUI/Images/epicmenu/people.png', -- REPLACE ME
	give = 'LuaUI/Images/gift2.png',
	giftmetal = 'LuaUI/Images/ibeam.png',
	giftenergy = 'LuaUI/Images/energy.png',
}
local amounts = {
	default = 100,
	shift = 20,
}

local function StringToTable(str)
	local strtbl = {}
	local num = 0
	for w in string.gmatch(str, "%S+") do
		num = num+1
		strtbl[num] = {}
		w = string.gsub(w,","," ")
		for x in string.gmatch(w,"%S+") do
			strtbl[num][#strtbl[num]+1] = x
		end
	end
	return strtbl
end

local function InvitePlayer(playerid,request)
	local name = select(1,Spring.GetPlayerInfo(playerid))
	if request == true then -- we're asking to join the player's team
		Spring.SendLuaRulesMsg("sharemode invite " .. playerid .. " " .. playerid)
		Spring.SendCommands("say a:I sent a request to join " .. name .."'s squad.")
	else
		Spring.SendLuaRulesMsg("sharemode invite " .. playerid .. " " .. Spring.GetMyPlayerID())
		if #Spring.GetPlayerList(select(4,Spring.GetPlayerInfo(playerid))) > 1 then
			Spring.SendCommands("say a:I invited " .. name .. "'s squad to a merger.")
		else
			Spring.SendCommands("say a:I invited " .. name .. " to join my squad.")
		end
	end
end

local function LeaveMySquad()
	Spring.SendCommands("say a: I left " .. select(1,Spring.GetPlayerInfo(select(2,Spring.GetTeamInfo(Spring.GetMyTeamID())))) .. "'s squad.") -- this line is a mess D:
	Spring.SendLuaRulesMsg("sharemode unmerge")
end

local function InviteChange(playerid,success,merge)
	local name = select(1,Spring.GetPlayerInfo(playerid))
	if success == true then
		Spring.SendLuaRulesMsg("sharemode accept " .. playerid)
		if merge == true then
			Spring.SendCommands("say a:I have joined " .. name .. "'s team.")
		else
			Spring.SendCommands("say a:I have accepted " .. name .. "'s request. Welcome aboard.")
		end
	else
		Spring.SendLuaRulesMsg("sharemode decline " .. playerid)
		if merge == true then
			Spring.SendCommands("say a:I have declined " .. name .. "'s invite.")
		else
			Spring.SendCommands("say a:I have declined " .. name .. "'s request.")
		end
	end
end

local function Hideme()
	window:Hide()
	showing = false
end

local function KickPlayer(playerid)
	Spring.SendCommands("say a: I kicked " .. select(1,Spring.GetPlayerInfo(playerid)) .. " from my squad.")
	Spring.SendLuaRulesMsg("sharemode kick " .. playerid)
end

local function GiveUnit(target)
	local num = Spring.GetSelectedUnitsCount()
	if num == 0 then
		Spring.Echo("game_message: You should probably select some units first before you try to give some away.")
		return
	end
	local playerslist = Spring.GetPlayerList(target)
	local units = "units"
	if num == 1 then
		units = "unit"
	end
	local leader = select(2,Spring.GetTeamInfo(target))
	local name = select(1,Spring.GetPlayerInfo(leader))
	if select(4,Spring.GetTeamInfo(target)) then
		name = select(2,Spring.GetAIInfo(target))
	end
	if #playerslist > 1 then
		name = name .. "'s squad"
	end
	Spring.SendCommands("say a: I gave " .. num .. " " .. units .. " to " .. name .. ".")
	Spring.ShareResources(target,"units")
end

local function GiveResource(target,kind)
	--mod = 20,500,all
	local alt,ctrl,_,shift = Spring.GetModKeyState()
	if alt then mod = "all"
	elseif ctrl then mod = 500
	elseif shift then mod = 20
	else mod = 100 end
	local leader = select(2,Spring.GetTeamInfo(target))
	local name = select(1,Spring.GetPlayerInfo(leader))
	if select(4,Spring.GetTeamInfo(target)) then
		name = select(2,Spring.GetAIInfo(target))
	end
	local playerslist = Spring.GetPlayerList(target,true)
	if #playerslist > 1 then
		name = name .. "'s squad"
	end
	local num = 0
	if mod == "all" then
		num = Spring.GetTeamResources(select(1,Spring.GetMyTeamID(),kind))
	elseif mod ~= nil then
		num = mod
	else
		return
	end
	Spring.SendCommands("say a: I gave " .. math.floor(num) .. " " .. kind .. " to " .. name .. ".")
	Spring.ShareResources(target,kind,num)
end

local function GetPlayers()
	local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
	local playersonteam = {}
	for i=1, #teamlist do
		if teamlist[i] ~= nil then
			playersonteam = Spring.GetPlayerList(teamlist[i])
			for s=1,#playersonteam do
				Spring.Echo("Player info for " .. playersonteam[s] .. "(" .. select(1,Spring.GetPlayerInfo(playersonteam[s])) .. "):" .. tostring(select(2,Spring.GetPlayerInfo(playersonteam[s]))))
				if playersonteam[s] ~= nil  and select(2,Spring.GetPlayerInfo(playersonteam[s])) == true then
					playersingame[playersonteam[s]] = true
				end
			end
		end
	end
end


local function HideInvites()
	invwindow:Hide()
	window:Show()
end

local function BuildInvites()
	if sharemode then
		invwindow = chili.Window:New{parent = screen0, dockable = false, width = '30%', height = '60%', draggable = false, resizable = false, tweakDraggable = false,tweakResizable = false, minimizable = false, x ='35%',y='20%',visible=true}
		chili.Button:New{parent=invwindow,width = '60%',height = '3.5%',x='20%',y='96.5%',caption="Back",OnClick={function () HideInvites(); end},tooltip="Return to menu."}
		chili.TextBox:New{parent=invwindow, width = '80%',height = '20%',x='40%',y='1%',text="Pending Invites",fontsize=17,textColor={1.0,1.0,1.0,1.0}}
		invwindow:Hide()
	end
end

local function Buildme()
	Spring.Echo("Screen0 size: " .. screen0.width .. "x" .. screen0.height)
	window = chili.Window:New{parent = screen0, dockable = false, width = '30%', height = '60%', draggable = false, resizable = false, tweakDraggable = false,tweakResizable = false, minimizable = false, x ='35%',y='20%',visible=true}
	Spring.Echo("Window size: " .. window.width .. "x" .. window.height)
	chili.TextBox:New{parent=window, width = '80%',height = '20%',x='25%',y='1%',text="Unit, Control, and Resource sharing",fontsize=17,textColor={1.0,1.0,1.0,1.0}}
	local playerlistsize = 91
	chili.Button:New{parent=window,width = '60%',height = '3.5%',x='20%',y='96.5%',caption="Close",OnClick={function () Hideme(); end},tooltip="Closes this window"}
	local players = {}
	local playersonteam = {}
	local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
	local teamleaderid = 0
	for i=1, #teamlist do
		if teamlist[i] ~= nil then
			playersonteam = Spring.GetPlayerList(teamlist[i])
			teamleaderid = select(2,Spring.GetTeamInfo(teamlist[i]))
			Spring.Echo(teamlist[i] .. ": leader: " .. teamleaderid)
			if select(4,Spring.GetTeamInfo(teamlist[i])) then -- this is an ai
				players[#players+1] = {name = select(2,Spring.GetAIInfo(teamlist[i])),active=false,team=teamlist[i],isai=true}
			end
			for s=1,#playersonteam do
				if playersonteam[s] ~= nil and playersingame[playersonteam[s]] then
					players[#players+1] = {id= playersonteam[s],name = select(1,Spring.GetPlayerInfo(playersonteam[s])),spec = select(3,Spring.GetPlayerInfo(playersonteam[s])), team = teamlist[i], teamleader = false}
					Spring.Echo("player " .. players[#players].id .. ": " .. players[#players].name)
					if teamleaderid == playersonteam[s] then
						players[#players].teamleader = true
					end
				end
			end
		end
	end
	playersonteam,teamlist,teamleaderid = nil
	local playerpanels = {}
	for i=1, #players do
		playerpanels[i] = chili.Panel:New{backgroundColor={0,0,0,0}}
	end
	if #players > 8 or (playerlistsize == 40 and #players > 5) then 
		chili.ScrollPanel:New{parent=window,y='5%',verticalScrollbar=true,horizontalScrollbar=false,width='100%',height= playerlistsize .. '%',scrollBarSize=20,children={chili.Grid:New{columns=1,x=0,y=0,children=playerpanels,itemPadding={0,0,0,0},height=9900,width='100%',centerItems=false,resizeItems=true,maxHeight=575,minHeight=575}},backgroundColor= {0,0,0,0}}
	else
		chili.Panel:New{parent=window,y='5%',width='100%',height= playerlistsize .. '%',children={chili.Grid:New{columns=1,x=0,y=0,children=playerpanels,itemPadding={0,0,0,0},height=1700,width='100%',centerItems=false,resizeItems=true,maxHeight=475,minHeight=300}},padding={0,0,0,0}}
	end
	local r,g,b,a,newy,sizefont,wantedfs,distance,numbuttons,wide
	if playerlistsize == 91 then
		numbuttons = 3
	else
		numbuttons = 5
	end
	wantedfs = 22
	local buttonsize = math.min(100,60 + -1*((4-#players)*10))
	if buttonsize ~= 100 then
		newy = (100-buttonsize)/2 -- this centers it on the Y axis. So 75% button size would be 12.5% on the y axis
	else
		newy = 0
	end
	for i=1,#players do
		sizefont = wantedfs
		repeat
			Spring.Echo("Fontsize for " .. players[i].name .. ": " .. sizefont)
			if sizefont*((string.len(players[i].name)+5.5)/4.25) > playerpanels[i].width*0.6 then
				sizefont = sizefont - 0.5
			end
		until sizefont*((string.len(players[i].name)+5.5)/4.25) <= playerpanels[i].width*0.6
		if players[i].id ~= Spring.GetMyPlayerID() then
			if players[i].isai or (select(2,Spring.GetPlayerInfo(players[i].id)) and players[i].teamleader) then -- Padding is ~2% between buttons.
				chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x='2%',y= newy..'%',OnClick= {function () GiveUnit(players[i].team) end}, padding={5,5,5,5}, children = {chili.Image:New{file=images.give,width='100%',height='100%'}},tooltip="Give selected units.",caption=" "}
				chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '12%',y=newy..'%',OnClick = {function () GiveResource(players[i].team,"metal") end}, padding={2,2,2,2}, tooltip = "Give 100 metal.\nHolding ctrl will give 500.\nHolding shift will give 20.\nHolding alt will give all.", children={chili.Image:New{file=images.giftmetal,width='100%',height='100%'}},caption=" "}
				chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '22%',y=newy..'%',OnClick = {function () GiveResource(players[i].team,"energy") end}, padding={1,1,1,1}, tooltip = "Give 100 energy.\nHolding ctrl will give 500.\nHolding shift will give 20.\nHolding alt will give all.", children={chili.Image:New{file=images.giftenergy,width='100%',height='100%'}},caption=" "}
			end
			if sharemode and select(4,Spring.GetTeamInfo(players[i].team)) == false and select(2,Spring.GetPlayerInfo(players[i].id)) then
				if players[i].teamleader and players[i].team ~= Spring.GetMyTeamID() then
					chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '32%',y=newy..'%',OnClick = {function () InvitePlayer(players[i].id,false) end}, padding={1,1,1,1}, tooltip = "Invite this player to join your squad.\nPlayers on a squad share control of units and have access to all resources each individual player would have/get normally.\nOnly invite people you trust. Use with caution!", children={chili.Image:New{file=images.inviteplayer,width='100%',height='100%'}},caption=" "}
					chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '42%',y=newy..'%',OnClick = {function () InvitePlayer(players[i].id,true) end}, padding={1,1,1,1}, tooltip = "Request to join this player's squad.\nPlayers on a squad share control of units and have access to all resources each individual player would have/get normally.", children={chili.Image:New{file=images.join,width='90%',height='90%',x='5%',y='5%'}},caption=" "}
				elseif select(2,Spring.GetTeamInfo(Spring.GetMyTeamID())) == Spring.GetMyPlayerID() and players[i].id ~= Spring.GetMyPlayerID() then
					chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '32%',y=newy..'%',OnClick = {function () KickPlayer(players[i].id) end}, padding={1,1,1,1}, tooltip = "Kick this player from your squad.", children={chili.Image:New{file=images.kick,width='100%',height='100%'}},caption=" "}
				end
			end
		end
		if players[i].id == Spring.GetMyPlayerID() and select(2,Spring.GetTeamInfo(Spring.GetMyTeamID())) ~= Spring.GetMyPlayerID() then
			chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '10%',x= '2%',y=newy..'%',OnClick = {function () LeaveMySquad() end}, padding={1,1,1,1}, tooltip = "Leave your squad.", children={chili.Image:New{file=images.leave,width='90%',height='90%',x='5%',y='5%'}},caption=" "}
		end
		if sharemode and players[i].id == Spring.GetMyPlayerID() and select(2,Spring.GetTeamInfo(Spring.GetMyTeamID())) == Spring.GetMyPlayerID() then
			updateme = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '50%',x='2%',y=newy..'%',caption="Invites [0]",OnClick={function () Hideme(); invwindow:Show(); end},tooltip="Contains invites you currently have."}
		end
		r,g,b,a = Spring.GetTeamColor(players[i].team)
		Spring.Echo("Playerpanel size: " .. playerpanels[i].width .. "x" .. playerpanels[i].height .. "\nTextbox size: " .. playerpanels[i].width*0.4 .. "x" .. playerpanels[i].height)
		local texty = 35.5
		if #players < 3 then
			texty = 44.5
		end
		if players[i].spec then
			chili.TextBox:New{parent=playerpanels[i],height='100%',width='40%',fontsize=sizefont,x='60%',text=players[i].name .. "(RSGN)", textColor={0.5,0,0,1},y=texty..'%'}
		elseif not players[i].isai and not select(2,Spring.GetPlayerInfo(players[i].id)) then
			chili.TextBox:New{parent=playerpanels[i],height='100%',width='40%',fontsize=sizefont,x='60%',text=players[i].name .. "(QUIT)", textColor={1,0,0,1},y=texty..'%'}
		else
			chili.TextBox:New{parent=playerpanels[i],height='100%',width='40%',fontsize=sizefont,x='60%',text=players[i].name, textColor={r,g,b,a},y='33%',y=texty..'%'}
		end
	end
	if showing then
		window:Show()
	else
		window:Hide()
	end
	if invites and #invites > 0 then
		updateme:SetCaption("Invites [" .. #invites .. "]")
	end
	built = true
end

local function InvitesChanged()
	window:ClearChildren()
	window:Dispose()
	Buildme()
end

local function UpdateInviteTable()
	for i=1,Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_count") do
		invites[i] = {
			id= Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_"..i.."_id"),
			timeleft = Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_"..i.."_timeleft"),
			controller=Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_"..i.."_controller")
			}
	end
	if invites == nil or #newinvites ~= #invites then
		invites = newinvites
		InvitesChanged()
	end
	if invitelist then
		invitelist:Dispose()
	end
	local invitetab = {}
	for i=1,#invites do
		invitetab[#invitetab+1] = chili.Panel:New{backgroundColor={0,0,0,0}}
	end
	invitelist = chili.ScrollPanel:New{parent=invwindow,y='5%',verticalScrollbar=true,horizontalScrollbar=false,width='100%',height= 90 .. '%',scrollBarSize=20,children={chili.Grid:New{columns=2,x=0,y=0,children=invitetab,itemPadding={0,0,0,0},height=1700,width='100%',centerItems=false,resizeItems=true,maxHeight=65,minHeight=65}},padding={0,0,0,0}}
	local merge = false
	local r,g,b,a
	for i=1,#invitetab do
		if invites[i].controller == Spring.GetMyPlayerID() then
			merge = true
		else
			merge = false
		end
		r,g,b,a = Spring.GetTeamColor(select(4,Spring.GetPlayerInfo(invites[i].id)))
		chili.Button:New{parent = invitetab[i],height = 100 .. '%', width = '10%',x= '2%',y='0%',OnClick = {function ()  InviteChange(invites[i].id,true,merge) end}, padding={1,1,1,1}, tooltip = "Accept this invite", children={chili.Image:New{file=images.accept,width='100%',height='100%'}},caption=" "}
		chili.Button:New{parent = invitetab[i],height = 100 .. '%', width = '10%',x= '13%',y='0%',OnClick = {function () InviteChange(invites[i].id,false,merge) end}, padding={1,1,1,1}, tooltip = "Reject this invite", children={chili.Image:New{file=images.kick,width='100%',height='100%'}},caption=" "}
		if merge == true then
			chili.TextBox:New{parent= invitetab[i],height='100%',width='70%',fontsize=16.5,x='26%',text=select(1,Spring.GetPlayerInfo(invites[i].id)) .. " (merge)", textColor={r,g,b,a},y='35%'}
		else
			chili.TextBox:New{parent= invitetab[i],height='100%',width='70%',fontsize=16.5,x='26%',text=select(1,Spring.GetPlayerInfo(invites[i].id)) .. " (join)", textColor={r,g,b,a},y='35%'}
		end
	end
end

function widget:KeyPress(key,mod,repeating)
	if key == keytopress and not showing and not repeating and window ~= nil then
		if invwindow ~= nil and invwindow.visible then
			invwindow:Hide()
		end
		showing = true
		window:Show()
		return true
	elseif key == keytopress and showing and not repeating and window ~= nil then
		showing = false
		window:Hide()
		return true
	end
	return false
end

function widget:PlayerRemoved(playerID)
	local team = select(4,Spring.GetPlayerInfo(playerID))
	if team == Spring.GetMyAllyTeamID() and showing then
		window:ClearChildren()
		window:Dispose()
		Buildme()
	end
end

function widget:TeamChanged()
	window:ClearChildren()
	window:Dispose()
	Buildme()
end

function widget:PlayerChanged(id)
	local team = select(5,Spring.GetPlayerInfo(id))
	if team == Spring.GetMyAllyTeamID() and built then
		window:ClearChildren()
		window:Dispose()
		Buildme()
	end
	if id == Spring.GetMyPlayerID() and select(3,Spring.GetPlayerInfo(id)) then
		Spring.Echo("Detected spectator mode. Removing Share menu.")
		widgetHandler:RemoveWidget() -- resigned?
	end
end

function widget:GameFrame(f)
	if f == 2 then
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		Spring.Echo("game_message: Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		modOptions = nil
		GetPlayers()
		Buildme()
		BuildInvites()
	end
	if f%30 == 1 then -- Update my invite table.
		if Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_count") and Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"commshare_invite_count") > 1 then
			UpdateInviteTable()
		end
	end
end

function widget:Initialize()
	local spectating = Spring.GetSpectatingState()
	chili = WG.Chili
	screen0 = chili.Screen0
	if Spring.GetGameFrame() > 2 then
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		Spring.Echo("game_message: Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		GetPlayers()
		Buildme()
		BuildInvites()
	end
	if spectating or select(3,Spring.GetPlayerInfo(Spring.GetMyPlayerID())) then
		Spring.Echo("Spectator mode detected. Removing Share menu.")
		widgetHandler:RemoveWidget()
	end
end
