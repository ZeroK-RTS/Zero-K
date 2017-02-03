-- WARNING: This is a temporary file. Please modify as you see fit! --
function widget:GetInfo()
	return {
		name	= "Chili Share menu v1.21",
		desc	= "Press H to bring up the chili share menu.",
		author	= "_Shaman",
		date	= "12-3-2016",
		license	= "Do whatever with it (cuz a license isn't going to stop you ;) )",
		layer	= 2000,
		enabled	= true,
	}
end
local automergeid = -1
local players = {}
local needsremerging = false
local invites = {}
local givemebuttons = {}
local buildframe = -1
local built = false
local sharemode = false
local deadinvites = {}
local playerlist, chili, window, screen0,updateme
local showing = false
local playerfontsize = {}
local mycurrentteamid = 0
local myoldteam = {}
local images = {
	inviteplayer = 'LuaUI/Images/Commshare.png',
	accept = 'LuaUI/Images/epicmenu/check.png',
	decline = 'LuaUI/Images/advplayerslist/cross.png',
	pending = 'LuaUI/Images/epicmenu/questionmark.png',
	leave = 'LuaUI/Images/epicmenu/exit.png',
	kick = 'LuaUI/Images/advplayerslist/cross.png', -- REPLACE ME
	merge = 'LuaUI/Images/Commshare_Merge.png',
	give = 'LuaUI/Images/gift2.png',
	giftmetal = 'LuaUI/Images/ibeam.png',
	giftenergy = 'LuaUI/Images/energy.png',
}
local defaultamount = 100

function BringUpShareMenu()
	if window then
		window:ToggleVisibility()
	end
end

options_path = 'Settings/HUD Panels/Share Menu' 
--[[ Change path if necessary. I just dumped it here because it made sense.
Note: remerge is used in case of bugs! Feel free to remove it in a few stables.]]
options = {
		automation_clanmerge = {
			name = 'Auto clan merge',
			desc = 'Automatically merge with clan members.',
			type = 'bool',
			value = false,
			noHotkey = true,
		},
        remerge = {
                name = 'Manual Remerge',
                desc = 'Use this in case you weren\'t remerged automatically.',
                type = 'button',
                OnChange = function() Spring.SendLuaRulesMsg("sharemode remerge") end,
        },
        sharemenu = {
                name = 'Bring up share menu',
                desc = 'Press this button to bring up the share menu.',
                type = 'button',
				hotkey = "H",
				OnChange = function() BringUpShareMenu() end,
        },
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

local function SetUpVisibility(playerID,metal,energy,unit,commshare,kick,accept)
	givemebuttons[playerID]["metal"]:SetVisibility(metal)
	givemebuttons[playerID]["energy"]:SetVisibility(energy)
	givemebuttons[playerID]["unit"]:SetVisibility(unit)
	givemebuttons[playerID]["commshare"]:SetVisibility(commshare)
	givemebuttons[playerID]["kick"]:SetVisibility(kick)
	givemebuttons[playerID]["accept"]:SetVisibility(accept)
end

local function UpdatePlayer(playerID)
	if givemebuttons[playerID] == nil or built == false then
		local name = select(1,Spring.GetPlayerInfo(playerID))
		--Spring.Echo("player" .. playerID .. "( " .. name .. ") is not a player!")
		return
	end
	local name,active,spec,teamid,allyteam,_ = Spring.GetPlayerInfo(playerID)
	local leader = select(2,Spring.GetTeamInfo(teamid))
	local texty = givemebuttons[playerID]["text"].y
	local sizefont = playerfontsize[playerID]
	local playerpanel = givemebuttons[playerID]["text"].parent
	-- we do disposes on these because there's a lack of SetTextColor (to my knowledge)
	if playerID ~= Spring.GetMyPlayerID() and spec then
		givemebuttons[playerID]["text"]:Dispose()
		givemebuttons[playerID]["text"] = chili.TextBox:New{parent=playerpanel,height='100%',width='40%',fontsize=sizefont,x='60%',text=name .. " (RSGN)", textColor={1,0,0,1},y=texty}
		SetUpVisibility(playerID,false,false,false,false,false,false)
	elseif active and not spec then
		if playerID == Spring.GetMyPlayerID()  then
			local r,g,b,a = Spring.GetTeamColor(teamid)
			givemebuttons[playerID]["text"]:Dispose()
			givemebuttons[playerID]["text"] = chili.TextBox:New{parent=playerpanel,height='100%',width='40%',fontsize=sizefont,x='60%',text=name, textColor={r,g,b,a},y=texty}
			if leader ~= Spring.GetMyPlayerID() then
				givemebuttons[playerID]["leave"]:SetVisibility(true)
				return
			else
				givemebuttons[playerID]["leave"]:SetVisibility(false)
				return
			end
		end
		local r,g,b,a = Spring.GetTeamColor(teamid)
		givemebuttons[playerID]["text"]:Dispose()
		givemebuttons[playerID]["text"] = chili.TextBox:New{parent=playerpanel,height='100%',width='40%',fontsize=sizefont,x='60%',text=name, textColor={r,g,b,a},y=texty}
		if teamid == Spring.GetMyTeamID() and leader == Spring.GetMyPlayerID() then
			SetUpVisibility(playerID,false,false,false,false,true,false)
		elseif teamid == Spring.GetMyTeamID() and leader ~= Spring.GetMyPlayerID() then
			SetUpVisibility(playerID,false,false,false,false,false,false)
		elseif leader ~= playerID then
			SetUpVisibility(playerID,false,false,false,false,false,false)
		else
			SetUpVisibility(playerID,true,true,true,true,false,false)
		end
	elseif not active and not spec then
		SetUpVisibility(playerID,false,false,false,false,false,false)
		givemebuttons[playerID]["text"]:SetText(name .. "(QUIT)")
	end
	if sharemode == false and playerID ~= Spring.GetMyPlayerID() then
		givemebuttons[playerID]["commshare"]:SetVisibility(false)
		givemebuttons[playerID]["accept"]:SetVisibility(false)
		givemebuttons[playerID]["kick"]:SetVisibility(false)
	end
end

local function InvitePlayer(playerid)
	local name = select(1,Spring.GetPlayerInfo(playerid))
	local teamID = select(4,Spring.GetPlayerInfo(playerid))
	local leaderID = select(2,Spring.GetTeamInfo(teamID))
	Spring.SendLuaRulesMsg("sharemode invite " .. playerid)
	if #Spring.GetPlayerList(select(4,Spring.GetPlayerInfo(playerid))) > 1 and playerid == leaderID then
		Spring.SendCommands("say a:I invited " .. name .. "'s squad to a merger.")
	else
		Spring.SendCommands("say a:I invited " .. name .. " to join my squad.")
	end
end

local function MergeWithClanMembers()
	local playerID = Spring.GetMyPlayerID()
	local customKeys = select(10, Spring.GetPlayerInfo(playerID)) or {}
	local myclanShort = customKeys.clan     or ""
	local myclanLong  = customKeys.clanfull or ""
	if myclanShort ~= "" then
		Spring.Echo("[Share menu] Searching for clan members belonging to " .. myclanLong)
		local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
		local clanmembers = {}
		for i=1, #teamlist do
			local players = Spring.GetPlayerList(teamlist[i],true)
			for j=1, #players do
				local customKeys = select(10, Spring.GetPlayerInfo(players[j])) or {}
				local clanShort = customKeys.clan     or ""
				local clanLong  = customKeys.clanfull or ""
				--Spring.Echo(select(1,Spring.GetPlayerInfo(players[j])) .. " : " .. clanLong)
				if clanLong == myclanLong and players[j] ~= Spring.GetMyPlayerID() and select(4,Spring.GetPlayerInfo(players[j])) ~= Spring.GetMyTeamID() then
					clanmembers[#clanmembers+1] = players[j]
				end
			end
			if #clanmembers > 0 then
				local lowestid = playerID
				local recipent = false
				for i=1, #clanmembers do
					if lowestid > clanmembers[i] then
						recipent = true
						lowestid = clanmembers[i]
					end
				end
				if recipent == false then
					for i=1, #clanmembers do
						Spring.SendLuaRulesMsg("sharemode invite " .. clanmembers[i])
					end
				else
					automergeid = lowestid
				end
			end
		end
	end
end
	

local function LeaveMySquad()
	local leader = select(2,Spring.GetTeamInfo(Spring.GetMyTeamID()))
	local name = select(1,Spring.GetPlayerInfo(leader))
	Spring.SendCommands("say a: I left " .. name .. "'s squad.")
	Spring.SendLuaRulesMsg("sharemode unmerge")
end

local function InviteChange(playerid)
	local name = select(1,Spring.GetPlayerInfo(playerid))
	Spring.SendLuaRulesMsg("sharemode accept " .. playerid)
	--Spring.SendCommands("say a:I have joined " .. name .. "'s squad.") -- Removed to reduce information overload.
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
	target = select(4,Spring.GetPlayerInfo(target))
	local num = Spring.GetSelectedUnitsCount()
	if num == 0 then
		Spring.Echo("game_message: You should probably select some units first before you try to give some away.")
		--TODO: Remove this, grey out button.
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
	target = select(4,Spring.GetPlayerInfo(target))
	local alt,ctrl,_,shift = Spring.GetModKeyState()
	if alt then mod = "all"
	elseif ctrl then mod = defaultamount/5
	elseif shift then mod = defaultamount*5
	else mod = defaultamount end
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

local function SetUpInitialStates()
	local myplayerID = Spring.GetMyPlayerID()
	local myteamID = Spring.GetMyTeamID()
	local amiteamleader = (select(2,Spring.GetTeamInfo(myteamID)) == myplayerID)
	--Spring.Echo("I am leader: " .. tostring(amiteamleader))
	for i=1,#players do
		local playerID = players[i].id
		local teamID = players[i].team
		if playerID then
			if playerID == myplayerID and (players[i].teamleader or sharemode == false) then
				givemebuttons[playerID]["leave"]:SetVisibility(false)
			elseif playerID == myplayerID and not players[i].teamleader and #Spring.GetPlayerList(myteamID) > 1 and sharemode then
				givemebuttons[playerID]["leave"]:SetVisibility(true)
			elseif playerID ~= myplayerID then -- other people's stuff.
				givemebuttons[playerID]["accept"]:SetVisibility(false)
				if teamID == myteamID then
					if amiteamleader then
						givemebuttons[playerID]["kick"]:SetVisibility(true)
						givemebuttons[playerID]["commshare"]:SetVisibility(false)
						givemebuttons[playerID]["accept"]:SetVisibility(false)
						givemebuttons[playerID]["metal"]:SetVisibility(false)
						givemebuttons[playerID]["energy"]:SetVisibility(false)
						givemebuttons[playerID]["unit"]:SetVisibility(false)
					else
						givemebuttons[playerID]["kick"]:SetVisibility(true)
						givemebuttons[playerID]["commshare"]:SetVisibility(false)
						givemebuttons[playerID]["accept"]:SetVisibility(false)
						givemebuttons[playerID]["metal"]:SetVisibility(false)
						givemebuttons[playerID]["energy"]:SetVisibility(false)
						givemebuttons[playerID]["unit"]:SetVisibility(false)
					end
					if sharemode == false then
						givemebuttons[playerID]["commshare"]:SetVisibility(false)
						givemebuttons[playerID]["accept"]:SetVisibility(false)
						givemebuttons[playerID]["kick"]:SetVisibility(false)
					end
				else
					givemebuttons[playerID]["kick"]:SetVisibility(false)
					if players[i].teamleader == false then
						givemebuttons[playerID]["commshare"]:SetVisibility(false)
						givemebuttons[playerID]["metal"]:SetVisibility(false)
						givemebuttons[playerID]["energy"]:SetVisibility(false)
						givemebuttons[playerID]["unit"]:SetVisibility(false)
					end
				end
			end
		end
	end
	buildframe = Spring.GetGameFrame()
	players = nil
end

local function Buildme()
	--Spring.Echo("Screen0 size: " .. screen0.width .. "x" .. screen0.height)
	window = chili.Window:New{ -- Just awful whitespace....
		classname = "main_window",
		parent = screen0, dockable = false, width = '30%', height = '60%', draggable = false, resizable = false, tweakDraggable = false,tweakResizable = false, minimizable = false, x ='35%',y='20%',visible=true}
	--Spring.Echo("Window size: " .. window.width .. "x" .. window.height)
	chili.TextBox:New{parent=window, width = '80%',height = '20%',x='25%',y='1%',text="Unit, Control, and Resource sharing",fontsize=17,textColor={1.0,1.0,1.0,1.0}}
	local playerlistsize = 91
	chili.Button:New{parent=window,width = '60%',height = '3.5%',x='20%',y='96.5%',caption="Close",OnClick={function () Hideme(); end},tooltip="Closes this window"}
	local playersonteam = {}
	local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
	local teamleaderid = 0
	for i=1, #teamlist do
		if teamlist[i] ~= nil then
			playersonteam = Spring.GetPlayerList(teamlist[i],true)
			teamleaderid = select(2,Spring.GetTeamInfo(teamlist[i]))
			--Spring.Echo(teamlist[i] .. ": leader: " .. teamleaderid)
			if select(4,Spring.GetTeamInfo(teamlist[i])) then -- this is an ai
				players[#players+1] = {name = select(2,Spring.GetAIInfo(teamlist[i])),active=false,team=teamlist[i],isai=true}
			end
			for s=1,#playersonteam do
				if playersonteam[s] ~= nil then
					players[#players+1] = {id= playersonteam[s],name = select(1,Spring.GetPlayerInfo(playersonteam[s])),spec = select(3,Spring.GetPlayerInfo(playersonteam[s])), team = teamlist[i], teamleader = false}
					--Spring.Echo("player " .. players[#players].id .. ": " .. players[#players].name)
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
		local playerID = players[i].id
		repeat
			--Spring.Echo("Fontsize for " .. players[i].name .. ": " .. sizefont)
			if sizefont*((string.len(players[i].name)+5.5)/4.25) > playerpanels[i].width*0.8 then
				sizefont = sizefont - 0.5
			end
		until sizefont*((string.len(players[i].name)+5.5)/4.25) <= playerpanels[i].width*0.8
		playerfontsize[playerID] = sizefont
		givemebuttons[playerID] = {}
		if players[i].id ~= Spring.GetMyPlayerID() then
			givemebuttons[playerID]["unit"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x='2%',y= newy..'%',OnClick= {function () GiveUnit(playerID) end}, padding={5,5,5,5}, children = {chili.Image:New{file=images.give,width='100%',height='100%'}},tooltip="Give selected units.",caption=" "}
			givemebuttons[playerID]["metal"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '13%',y=newy..'%',OnClick = {function () GiveResource(playerID,"metal") end}, padding={2,2,2,2}, tooltip = "Give 100 metal.\nHolding ctrl will give 20.\nHolding shift will give 500.\nHolding alt will give all.", children={chili.Image:New{file=images.giftmetal,width='100%',height='100%'}},caption=" "}
			givemebuttons[playerID]["energy"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '24%',y=newy..'%',OnClick = {function () GiveResource(playerID,"energy") end}, padding={1,1,1,1}, tooltip = "Give 100 energy.\nHolding ctrl will give 20.\nHolding shift will give 500.\nHolding alt will give all.", children={chili.Image:New{file=images.giftenergy,width='100%',height='100%'}},caption=" "}
			givemebuttons[playerID]["commshare"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '35%',y=newy..'%',OnClick = {function () InvitePlayer(playerID,false) end}, padding={1,1,1,1}, tooltip = "Invite this player to join your squad.\nPlayers on a squad share control of units and have access to all resources each individual player would have/get normally.\nOnly invite people you trust. Use with caution!", children={chili.Image:New{file=images.inviteplayer,width='100%',height='100%'}},caption=" "}
			givemebuttons[playerID]["accept"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '35%',y=newy..'%',OnClick = {function () InviteChange(playerID,true) end}, padding={1,1,1,1}, tooltip = "Click this to accept this player's invite!", children={chili.Image:New{file=images.merge,width='100%',height='100%'}},caption=" "}
			givemebuttons[playerID]["kick"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '2%',y=newy..'%',OnClick = {function () KickPlayer(playerID) end}, padding={1,1,1,1}, tooltip = "Kick this player from your squad.", children={chili.Image:New{file=images.kick,width='100%',height='100%'}},caption=" "}
		end
		if playerID == Spring.GetMyPlayerID() then
			givemebuttons[playerID]["leave"] = chili.Button:New{parent = playerpanels[i],height = buttonsize .. '%', width = '11%',x= '2%',y=newy..'%',OnClick = {function () LeaveMySquad() end}, padding={1,1,1,1}, tooltip = "Leave your squad.", children={chili.Image:New{file=images.leave,width='90%',height='90%',x='5%',y='5%'}},caption=" "}
		end
		r,g,b,a = Spring.GetTeamColor(players[i].team)
		--Spring.Echo("Playerpanel size: " .. playerpanels[i].width .. "x" .. playerpanels[i].height .. "\nTextbox size: " .. playerpanels[i].width*0.4 .. "x" .. playerpanels[i].height)
		local texty = 35.5
		if #players < 3 then
			texty = 44.5
		end
		if not players[i].spec then
			givemebuttons[playerID]["text"] = chili.TextBox:New{parent=playerpanels[i],height='100%',width='45%',fontsize=sizefont,x='50%',text=players[i].name, textColor={r,g,b,a},y=texty..'%'}
		end
	end
	window:SetVisibility(false)
	SetUpInitialStates()
end

local function UpdateInviteTable()
	if mycurrentteamid ~= Spring.GetMyTeamID() then
		--Spring.Echo("Removing invites!")
		for playerID,_ in pairs(invites) do
			givemebuttons[playerID]["accept"]:SetVisibility(false)
			givemebuttons[playerID]["commshare"]:SetVisibility(true)
			invites[playerID] = nil
			mycurrentteamid = Spring.GetMyTeamID()
		end
	end
	local myPlayerID = Spring.GetMyPlayerID()
	for i=1,Spring.GetPlayerRulesParam(myPlayerID, "commshare_invitecount") do
		local playerID = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_id")
		local timeleft = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_timeleft") or 0
		--Spring.Echo("Invite from: " .. tostring(playerID) .. "\nTime left: " .. timeleft)
		if playerID == automergeid then
			InviteChange(playerID)
			return
		end
		--Spring.Echo("Invite: " .. playerID .. " : " .. timeleft)
		if invites[playerID] == nil and timeleft > 1 and deadinvites[playerID] ~= timeleft then
			invites[playerID] = timeleft
			givemebuttons[playerID]["accept"]:SetVisibility(true)
			givemebuttons[playerID]["commshare"]:SetVisibility(false)
		elseif invites[playerID] == timeleft then
			invites[playerID] = nil -- dead invite
			deadinvites[playerID] = timeleft
			givemebuttons[playerID]["accept"]:SetVisibility(false)
			givemebuttons[playerID]["commshare"]:SetVisibility(true)
		elseif timeleft == 1 then
			givemebuttons[playerID]["accept"]:SetVisibility(false)
			givemebuttons[playerID]["commshare"]:SetVisibility(true)
			invites[playerID] = nil
		elseif invites[playerID] and timeleft > 1 then
			invites[playerID] = timeleft
			if givemebuttons[playerID]["accept"].visible == false then
				givemebuttons[playerID]["accept"]:SetVisibility(true)
				givemebuttons[playerID]["commshare"]:SetVisibility(false)
			end
		end
	end
end

function widget:PlayerAdded(playerID)
	UpdatePlayer(playerID)
end

function widget:TeamChanged(teamID)
	--Spring.Echo("TeamChanged: " .. teamID)
	if Spring.AreTeamsAllied(teamID,Spring.GetMyTeamID()) then
		local playerlist = Spring.GetPlayerList(teamID,true)
		for i=1,#playerlist do
			UpdatePlayer(playerlist[i])
		end
	end
end

function widget:PlayerChanged(playerID)
	--Spring.Echo("PlayerChanged: " .. playerID)
	if playerID == Spring.GetMyPlayerID() then
		--Spring.Echo("I changed teams!")
		UpdatePlayer(playerID)
		local playerlist = Spring.GetPlayerList(Spring.GetMyTeamID(),true)
		for i=1,#playerlist do
			UpdatePlayer(playerlist[i])
		end
		if #myoldteam > 1 then
			for i=1,#myoldteam do
				UpdatePlayer(myoldteam[i])
			end
		end
		myoldteam = playerlist
	end
	local allyteam = select(5,Spring.GetPlayerInfo(playerID))
	if allyteam == Spring.GetMyAllyTeamID() and built then
		UpdatePlayer(playerID)
	end
	if id == Spring.GetMyPlayerID() and select(3,Spring.GetPlayerInfo(playerID)) then
		Spring.Echo("Detected spectator mode. Removing Share menu.")
		widgetHandler:RemoveWidget() -- resigned?
	end
end

function widget:GameProgress(serverFrameNum)
	if needsremerging and serverFrameNum - Spring.GetGameFrame() < 90 then
		needsremerging = false
		Spring.SendLuaRulesMsg("sharemode remerge")
		--Spring.Echo("Sent remerge request")
	end
end

function widget:GameFrame(f)
	if f == 1 then
		mycurrentteamid = Spring.GetMyTeamID()
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		--Spring.Echo("Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		modOptions = nil
		Buildme()
	end
	if buildframe > -1 and f == buildframe + 1 then
		built = true -- block PlayerChanged from doing anything until we've set up initial states.
		local modOptions = {}
		local iscommsharing = Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"isCommsharing")
		modOptions = Spring.GetModOptions()
		--Spring.Echo("Automerge: " .. tostring(options.automation_clanmerge.value) .. "\niscommsharing: " .. tostring(iscommsharing == 1))
		if sharemode and not iscommsharing and options.automation_clanmerge.value == true then
			--Spring.Echo("Clan merge is enabled!")
			MergeWithClanMembers()
		end
	end
	if f%30 == 0 then -- Update my invite table.
		local invitecount = Spring.GetPlayerRulesParam(Spring.GetMyPlayerID(), "commshare_invitecount")
		if invitecount and invitecount > 0 and built then
			UpdateInviteTable()
		end
	end
end

function widget:Initialize()
	local spectating = Spring.GetSpectatingState()
	chili = WG.Chili
	screen0 = chili.Screen0
	if Spring.GetActionHotKeys("sharedialog")[1] ~= nil then
		local hotkey = Spring.GetActionHotKeys("sharedialog")[1]
		Spring.Echo("[Share menu] Unbinding sharedialog hotkey. Key is bound to: " .. hotkey)
		--Spring.SendCommands("unbind " .. hotkey .. " sharedialog") --Does not work!
		WG.crude.SetHotkey("sharedialog","")
	end
	if Spring.GetGameFrame() > 1 then
		mycurrentteamid = Spring.GetMyTeamID()
		local iscommsharing = Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"isCommsharing")
		--Spring.Echo("isCommsharing: " .. tostring(iscommsharing))
		if iscommsharing then
			needsremerging = true
		end
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		--Spring.Echo("Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		Buildme()
	end
	if spectating or select(3,Spring.GetPlayerInfo(Spring.GetMyPlayerID())) then
		Spring.Echo("[Share menu] Spectator mode detected. Shutting down.")
		widgetHandler:RemoveWidget()
	end
end
