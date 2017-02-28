-- WARNING: This is a temporary file. Please modify as you see fit! --
function widget:GetInfo()
	return {
		name	= "Chili Share menu v1.22",
		desc	= "Press H to bring up the chili share menu.",
		author	= "Commshare by _Shaman, Playerlist by DeinFreund",
		date	= "12-3-2016",
		license	= "Do whatever with it (cuz a license isn't going to stop you ;) )",
		layer	= 2000,
		enabled	= true,
	}
end

local automergeid = -1
local subjects = {}
local needsremerging = false
local invites = {}
local givemebuttons = {}
local givemepanel = {}
local givemesubjects = {}
local buildframe = -2
local built = false
local sharemode = false
local deadinvites = {}
local playerlist, chili, window, screen0,updateme
local showing = false
local playerfontsize = {}
local mycurrentteamid = 0
local myoldteam = {}
local PlayerNameY = -1
local mySubjectID = -1
local fontSize = 18
local badgeWidth = 59
local badgeHeight = 24
local color2incolor = nil
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


options_path = 'Settings/HUD Panels/Player List' 
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
	fixHotkeys = {
		name  = "Fix hotkeys on start",
		type  = "bool", 
		value = true, 
		desc = "Fixes old hotkey issues once and then disables.",
		advanced = true,
		noHotkey = true,
	},
	sharemenu = {
		name = 'Show Player List',
		desc = 'Hold this button to bring up the Player List.',
		type = 'button',
		hotkey = "tab",
		OnChange = function(self)
			if window then
				window:SetVisibility(true)
			end
		end,
	},
}

local function deepcompare(t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
	local v2 = t2[k1]
	if v2 == nil or not deepcompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
	local v1 = t1[k2]
	if v1 == nil or not deepcompare(v1,v2) then return false end
	end
	return true
end


function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end


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

function round(num, numDecimalPlaces)
  return (string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function RenderName(subject)
	--Spring.Echo("rendername " .. subject.name .. ":" ..subject.id)
	local name = subject.name
	local active = subject.ai or subject.active
	--Spring.Echo("active " .. tostring(active))
	local spec = not subject.ai and subject.spec
	local sizefont = playerfontsize[subject.id]
	local playerpanel = givemepanel[subject.id]
	--Spring.Echo("render parent is " .. tostring(playerpanel))
	if (not givemebuttons[subject.id]["text"]) then
		givemebuttons[subject.id]["text"] = chili.TextBox:New{
			parent=playerpanel,
			height='100%',
			width='40%',
			fontsize=sizefont,
			x=219,
			text=name .. " ",
			y=5
		}
	end
	if not spec and subject.id ~= mySubjectID and (subject.allyteam == subjects[mySubjectID].allyteam or subjects[mySubjectID].spec) then 
		local amt, stor = Spring.GetTeamResources(subject.team, "metal")
		stor = stor - 9999
		--Spring.Echo("metal: " .. amt .. "/" .. stor)
		local delta = amt - givemebuttons[subject.id]["metalbar"].value * stor
		local color = '\255\1\255\1'
		if (delta < 0) then
			color = '\255\255\1\1'
		end
		if (not givemebuttons[subject.id]["metalin"]) then 
			givemebuttons[subject.id]["metalin"] = chili.TextBox:New{
				parent=playerpanel,
				height='50%',
				width=50,
				fontsize=sizefont/2 + 2,
				x=givemebuttons[subject.id]["metalbar"].x + givemebuttons[subject.id]["metalbar"].width + 2,
				text=delta,y=givemebuttons[subject.id]["metalbar"].y + 1
			}
		end
		delta = round(delta, 1)
		givemebuttons[subject.id]["metalin"]:SetText(color .. delta)
		givemebuttons[subject.id]["metalbar"]:SetValue(math.min(1,amt / stor))
		local amt, stor = Spring.GetTeamResources(subject.team, "energy")
		stor = stor - 9999
		--Spring.Echo("energy: " .. amt .. "/" .. stor)
		local delta = amt - givemebuttons[subject.id]["energybar"].value * stor
		local color = '\255\1\255\1'
		if (delta < 0) then
			color = '\255\255\1\1'
		end
		if (not givemebuttons[subject.id]["energyin"]) then 
			givemebuttons[subject.id]["energyin"] = chili.TextBox:New{
				parent=playerpanel,
				height='50%',
				width=50,
				fontsize=sizefont/2 + 2,
				x=givemebuttons[subject.id]["energybar"].x + givemebuttons[subject.id]["energybar"].width + 2,
				text=delta,
				y=givemebuttons[subject.id]["energybar"].y+1
			}
		end
		delta = round(delta, 1)
		givemebuttons[subject.id]["energyin"]:SetText(color .. delta)
		givemebuttons[subject.id]["energybar"]:SetValue(math.min(1,amt / stor))
	end
	if spec then
		givemebuttons[subject.id]["text"]:SetText('\255\255\255\255' .. name)
	elseif active and not spec then
		givemebuttons[subject.id]["text"]:SetText(color2incolor(Spring.GetTeamColor(subject.team)) .. name)
	elseif not active and not spec then
		givemebuttons[subject.id]["text"]:SetText('\255\255\255\255' .. name .. " (QUIT)")
	end
end

local oldSubjects = {}

local function UpdatePlayer(subject)
	--Spring.Echo("playerupdate " .. subject.name)
	if givemebuttons[subject.id] == nil or built == false then
		local name = subject.name
		--Spring.Echo("player" .. subject.id .. "( " .. name .. ") is not a player!")
		return
	end
	if (false and oldSubjects[subject.id] and deepcompare(oldSubjects[subject.id], subject)) then
		--Spring.Echo("Nothing changed")
		return
	end
	oldSubjects[subject.id] = subject
	local myPlayerID = Spring.GetMyPlayerID()
	local mySpec = subjects[mySubjectID].spec
	local myteamID = Spring.GetMyTeamID()
	local myallyteamID = Spring.GetMyAllyTeamID()
	local amiteamleader = (select(2,Spring.GetTeamInfo(myteamID)) == myPlayerID)
	--Spring.Echo("I am spec " .. tostring(mySpec))
	--Spring.Echo(subject.name)
	local teamID = subject.team
	local allyteamID = subject.allyteam
	local teamLeader = subject.player and select(2, Spring.GetTeamInfo(teamID)) == subject.player
	--Spring.Echo("leader: " .. tostring(teamLeader))
	--Spring.Echo("ai: " .. tostring(subject.ai))
	--Spring.Echo("allyteam: " .. allyteamID)
	--Spring.Echo("myallyteam: " .. myallyteamID)
	if subject.player and subject.player == myPlayerID and (teamLeader or sharemode == false or subject.spec) then
		--Spring.Echo("dec1")
		givemebuttons[subject.id]["leave"]:SetVisibility(false)
	elseif subject.player and subject.player == myPlayerID and not teamLeader and #Spring.GetPlayerList(myteamID) > 1 and sharemode then
		--Spring.Echo("dec2")
		givemebuttons[subject.id]["leave"]:SetVisibility(true)
	elseif subject.ai then
		--Spring.Echo("dec3")
		givemebuttons[subject.id]["metalbar"]:SetVisibility(true)
		givemebuttons[subject.id]["energybar"]:SetVisibility(true)
		givemebuttons[subject.id]["metal"]:SetVisibility(true)
		givemebuttons[subject.id]["energy"]:SetVisibility(true)
		givemebuttons[subject.id]["unit"]:SetVisibility(true)
		if subject.allyteam ~= myallyteamID or mySpec then -- hostile ai's stuff.
			--Spring.Echo("dec4")
			givemebuttons[subject.id]["metal"]:SetVisibility(false)
			givemebuttons[subject.id]["energy"]:SetVisibility(false)
			givemebuttons[subject.id]["unit"]:SetVisibility(false)
			if (not mySpec ) then
				--Spring.Echo("dec5")
				givemebuttons[subject.id]["metalbar"]:SetVisibility(false)
				givemebuttons[subject.id]["energybar"]:SetVisibility(false)
			end
		end
	elseif subject.allyteam ~= myallyteamID or mySpec then -- hostile people's stuff.
		--Spring.Echo("dec6")
		givemebuttons[subject.id]["kick"]:SetVisibility(false)
		givemebuttons[subject.id]["commshare"]:SetVisibility(false)
		givemebuttons[subject.id]["accept"]:SetVisibility(false)
		givemebuttons[subject.id]["metal"]:SetVisibility(false)
		givemebuttons[subject.id]["energy"]:SetVisibility(false)
		givemebuttons[subject.id]["unit"]:SetVisibility(false)
		if (not mySpec or subject.spec) then
			--Spring.Echo("dec7")
			givemebuttons[subject.id]["metalbar"]:SetVisibility(false)
			givemebuttons[subject.id]["energybar"]:SetVisibility(false)
		end
	else -- other people's stuff.
		if teamID == myteamID then
			if amiteamleader then
				--Spring.Echo("dec8")
				givemebuttons[subject.id]["kick"]:SetVisibility(true)
				givemebuttons[subject.id]["commshare"]:SetVisibility(false)
				givemebuttons[subject.id]["metal"]:SetVisibility(false)
				givemebuttons[subject.id]["energy"]:SetVisibility(false)
				givemebuttons[subject.id]["unit"]:SetVisibility(false)
			else
				--Spring.Echo("dec9")
				givemebuttons[subject.id]["kick"]:SetVisibility(false)
				givemebuttons[subject.id]["commshare"]:SetVisibility(false)
				givemebuttons[subject.id]["metal"]:SetVisibility(false)
				givemebuttons[subject.id]["energy"]:SetVisibility(false)
				givemebuttons[subject.id]["unit"]:SetVisibility(false)
			end
			if sharemode == false then
				--Spring.Echo("dec10")
				givemebuttons[subject.id]["commshare"]:SetVisibility(false)
				givemebuttons[subject.id]["kick"]:SetVisibility(false)
				givemebuttons[subject.id]["metal"]:SetVisibility(true)
				givemebuttons[subject.id]["energy"]:SetVisibility(true)
				givemebuttons[subject.id]["unit"]:SetVisibility(true)
			end
		else
			givemebuttons[subject.id]["kick"]:SetVisibility(false)
			if teamLeader == false then
				--Spring.Echo("dec11")
				givemebuttons[subject.id]["commshare"]:SetVisibility(false)
				givemebuttons[subject.id]["metal"]:SetVisibility(false)
				givemebuttons[subject.id]["energy"]:SetVisibility(false)
				givemebuttons[subject.id]["unit"]:SetVisibility(false)
			else
				--Spring.Echo("dec12")
				givemebuttons[subject.id]["commshare"]:SetVisibility(true)
				givemebuttons[subject.id]["metal"]:SetVisibility(true)
				givemebuttons[subject.id]["energy"]:SetVisibility(true)
				givemebuttons[subject.id]["unit"]:SetVisibility(true)
			end
		end
	end
	RenderName(subject)
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
		--Spring.Echo("[Share menu] Searching for clan members belonging to " .. myclanLong)
		local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
		local clanmembers = {}
		for i=1, #teamlist do
			local players = Spring.GetPlayerList(teamlist[i],true)
			for j=1, #players do
				local customKeys = select(10, Spring.GetPlayerInfo(players[j])) or {}
				local clanShort = customKeys.clan     or ""
				local clanLong  = customKeys.clanfull or ""
				----Spring.Echo(select(1,Spring.GetPlayerInfo(players[j])) .. " : " .. clanLong)
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

local function BattleKickPlayer(subject)
	Spring.SendCommands("say !kick " .. subject.name)
end

local function GiveUnit(target)
	local num = Spring.GetSelectedUnitsCount()
	if num == 0 then
		--Spring.Echo("game_message: You should probably select some units first before you try to give some away.")
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


local function InitName(subject, playerPanel)
	--Spring.Echo("Initializing " .. subject.name .. " with parent " .. tostring(playerPanel))
	local buttonsize = fontSize + 4
	local barWidth = 40
	playerfontsize[subject.id] = fontSize
	givemebuttons[subject.id] = {}
	givemepanel[subject.id] = playerPanel
	if subject.ai or subject.player ~= Spring.GetMyPlayerID() then
		givemebuttons[subject.id]["unit"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=0,
			y=1,
			OnClick= {function () GiveUnit(subject.team) end},
			padding={5,5,5,5},
			children = {chili.Image:New{file=images.give,
			width='100%',
			height='100%'}},
			tooltip="Give selected units.",
			caption=" "
		}
		givemebuttons[subject.id]["metal"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=buttonsize*1,
			y=1,
			OnClick = {
				function () 
					GiveResource(subject.team,"metal") 
				end
			},
			padding={2,2,2,2},
			tooltip = "Give 100 metal.\nHolding ctrl will give 20.\nHolding shift will give 500.\nHolding alt will give all.",
			children={
				chili.Image:New{
					file=images.giftmetal,
					width='100%',
					height='100%'
				}
			},
			caption=" "
		}
		givemebuttons[subject.id]["energy"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=buttonsize*2,
			y=1,
			OnClick = {
				function () 
					GiveResource(subject.team,"energy") 
				end
			},
			padding={1,1,1,1},
			tooltip = "Give 100 energy.\nHolding ctrl will give 20.\nHolding shift will give 500.\nHolding alt will give all.",
			children={
				chili.Image:New{
					file=images.giftenergy,
					width='100%',
					height='100%'
				}
			},
			caption=" "
		}
		givemebuttons[subject.id]["metalbar"] = chili.Progressbar:New{
			parent = playerPanel,
			height = 9,
			y= 12,
			autosize= false,
			min=0,
			max=1,
			width = barWidth,
			x=buttonsize*3,
			color={0.5,0.5,0.5,1},
			tooltip = "Your ally's metal."
		}
		givemebuttons[subject.id]["energybar"] = chili.Progressbar:New{
			parent = playerPanel,
			height = 9,
			y= 0,
			autosize= false,
			min=0,
			max=1,
			width = barWidth,
			x=buttonsize*3,
			color={1,1,0,1},
			tooltip = "Your ally's metal."
		}
		if (subject.player) then
			-- screw this.
			givemebuttons[subject.id]["commshare"] = chili.Button:New{
				parent = playerPanel,
		height = buttonsize,
		width = buttonsize,
		x= 695 - 1 * buttonsize,
		y=1,
		OnClick = {function () InvitePlayer(subject.player,
		false) end},
		padding={1,
		1,
		1,
		1},
		tooltip = "Invite this player to join your squad.\nPlayers on a squad share control of units and have access to all resources each individual player would have/get normally.\nOnly invite people you trust. Use with caution!",
		children={chili.Image:New{file=images.inviteplayer,
		width='100%',
		height='100%'}},
		caption=" "}
		givemebuttons[subject.id]["accept"] = chili.Button:New{parent = playerPanel,
		height = buttonsize,
		width = buttonsize,
		x= 695 - 2 * buttonsize,
		y=1,
		OnClick = {function () InviteChange(subject.player,
		true) end},
		padding={1,
		1,
		1,
		1},
		tooltip = "Click this to accept this player's invite!",
		children={chili.Image:New{file=images.merge,
		width='100%',
		height='100%'}},
		caption=" "}
		givemebuttons[subject.id]["kick"] = chili.Button:New{parent = playerPanel,
		height = buttonsize,
		width = buttonsize,
		x=695 - 2 * buttonsize,
		y=1,
		OnClick = {function () KickPlayer(subject.player) end},
		padding={1,
		1,
		1,
		1},
		tooltip = "Kick this player from your squad.",
		children={chili.Image:New{file=images.kick,
		width='100%',
		height='100%'}},
		caption=" "}
		givemebuttons[subject.id]["battlekick"] = chili.Button:New{parent = playerPanel,
		height = buttonsize,
		width = buttonsize,
		x= 695 - 3 * buttonsize,
		y=1,
		OnClick = {function () BattleKickPlayer(subject) end},
		padding={1,
		1,
		1,
		1},
		tooltip = "Kick this player from the battle.",
		children={chili.Image:New{file=images.kick,
		width='100%',
		height='100%'}},
		caption=" "}
		end
		else
		givemebuttons[subject.id]["leave"] = chili.Button:New{parent = playerPanel,
		height = buttonsize,
		width = buttonsize,
		x= 695 - 2 * buttonsize,
		y=1,
		OnClick = {function () LeaveMySquad() end},
		padding={1,
		1,
		1,
		1},
		tooltip = "Leave your squad.",
		children={chili.Image:New{file=images.leave,
		width='100%',
		height='100%',
		x='0%',
		y=0}},
		caption=" "}
	end
	if (subject.player) then
		local pdata = select(10, Spring.GetPlayerInfo(subject.player))
		local country = select(8, Spring.GetPlayerInfo(subject.player))
		local elo, xp = Spring.Utilities.TranslateLobbyRank(tonumber(pdata.elo), tonumber(pdata.level))
		local badges = pdata.badges
		--Spring.Echo("badges: " .. tostring(badges))
		local rankImg = "LuaUI/Images/LobbyRanks/" .. xp .. "_" .. elo .. ".png"
		local countryImg = country and country ~= '' and country ~= '??' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
		local clanImg = nil
		local avatarImg = nil
		if pdata.clan and pdata.clan ~= "" then 
			clanImg = "LuaUI/Configs/Clans/" .. pdata.clan ..".png"
		elseif pdata.faction and pdata.faction ~= "" then
			clanImg = "LuaUI/Configs/Factions/" .. pdata.faction ..".png"
		end
		if pdata.avatar then
			avatarImg = ""
		end
		if (badges) then
			for i, badge in ipairs(badges:split(",")) do
				if (badge ~= "") then
					local badgeImg = "LuaUI/Images/badges/" .. badge .. ".png"
					chili.Image:New{parent=playerPanel,
						file=badgeImg,
						width=badgeWidth,
						x = 695 - 3 * buttonsize - badgeWidth * i - 3,
						y = 0,
						height=badgeHeight
					}
				end
			end
		end
		if (xp > 0 or elo > 0) then
			chili.Image:New{parent=playerPanel,
				file=rankImg,
				width=buttonsize,
				height=buttonsize,
				x = buttonsize*7 + barWidth * 1,
				y = 0
			}
		end
		if (countryImg) then
			chili.Image:New{parent=playerPanel,
				file=countryImg,
				width=buttonsize -6 ,
				height= buttonsize-6,
				x = buttonsize*6 + barWidth * 1+3,
				y = 3
			}
		end
		if (clanImg) then
			chili.Image:New{parent=playerPanel,
 file=clanImg,
 width=buttonsize -6 ,
 height= buttonsize-6,
 x = buttonsize*5 + barWidth * 1+3,
 y = 3}
		end
	end
	----Spring.Echo("Playerpanel size: " .. playerPanel.width .. "x" .. playerPanel.height .. "\nTextbox size: " .. playerPanel.width*0.4 .. "x" .. playerPanel.height)
	local isSpec = select(3,Spring.GetPlayerInfo(subject.id))
	--if not isSpec then
		RenderName(subject)
	--end
end


local function Buildme()
	--Spring.Echo("Initializing for " .. #subjects)
	--Spring.Echo("Screen0 size: " .. screen0.width .. "x" .. screen0.height)
	if (window) then
		window:Dispose()
	end
	windowWidth = 768 
	windowHeight = 666
	----Spring.Echo("Window size: " .. window.width .. "x" .. window.height)
	
	local playerpanels = {}
	local allypanels = {}
	local allpanels = {}
	for _, subject in ipairs(subjects) do
		if (not playerpanels[subject.allyteam]) then
			playerpanels[subject.allyteam] = {}
		end
		playerpanels[subject.allyteam][#playerpanels[subject.allyteam] + 1] = chili.Panel:New{backgroundColor={1,
0,
0,
0},
 height = fontSize + 17,
 width='100%',
 x = 0,
 y = #playerpanels[subject.allyteam] * (fontSize + 17)}
		InitName(subject, playerpanels[subject.allyteam][#playerpanels[subject.allyteam]])
	end
	local allyteams = Spring.GetAllyTeamList()
	allyteams[#allyteams + 1] = 100
	local heightOffset = 0
	local titleSize = 25
	for _, subject in ipairs(subjects) do
		allyteamID = subject.allyteam
		if (playerpanels[allyteamID]) then
			--Spring.Echo(playerpanels[allyteamID])	
			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyteamID)
			if (not name) then 
				name = "Team " .. allyteamID
			end
			if (allyteamID >= 100) then 
				name = "Spectators"
			end
			local height = #playerpanels[allyteamID] * (fontSize + 17) + 10
			local color = {0,1,0,0.6}
			if (allyteamID ~= Spring.GetMyAllyTeamID()) then
				color = {1,0,0,0.6}
			end
			if (allyteamID >= 100) then
				color = {1,1,1,0.6}
			end
			local label = chili.Label:New{
				width='100%',
				height = titleSize,
				x = '0%',
				y = heightOffset + 10,caption=name,fontsize=titleSize - 4,textColor=color,
				align='center'
			}
			allypanels[#allypanels + 1] = label
			heightOffset = heightOffset + titleSize + 15
			allypanels[#allypanels + 1] = chili.Control:New{
				backgroundColor=color,
				borderColor=color,
				children=playerpanels[allyteamID],
				width=725,
				height = height,
				x = 0,
				y = heightOffset
			}
			local width  = math.max(200,
			label.font:GetTextWidth(name) + 50)
			allypanels[#allypanels + 1] = chili.Control:New{
				width=width,
				height = titleSize + 22,
				x = (windowWidth - width ) / 2 - 13,
				y = heightOffset - titleSize - 15,
				children = {
					chili.Line:New{
						x = 10,
						right = 10,
						bottom = 3,
						height = 3,
					}
				}
			}
			heightOffset = heightOffset + height + 10
			playerpanels[allyteamID] = nil
		end
	end
	windowHeight = math.min(screen0.height - 100, heightOffset + 60)
	window = chili.Window:New{
		classname = "main_window",
		parent = screen0,
		dockable = false,
		width = windowWidth,
		height = windowHeight,
		draggable = false,
		resizable = false,
		tweakDraggable = false,
		tweakResizable = false,
		minimizable = false,
		x = (screen0.width - windowWidth)/2,
		y = (screen0.height - windowHeight)/2,
		visible = true
	}
	chili.TextBox:New{
		parent=window,
		width = '80%',
		height = '20%',
		x='43%',
		y=10,
		text="P L A Y E R S",
		fontsize=17,
		textColor={1.0,1.0,1.0,1.0}
	}
	chili.ScrollPanel:New{
		parent=window,
		y=30,
		verticalScrollbar=true,
		horizontalScrollbar=false,
		width='100%',
		bottom = 10,
		scrollBarSize=20,
		children=allypanels,
		backgroundColor= {0,0,0,0},
		borderColor= {0,0,0,0}
	}
	window:SetVisibility(false)
	buildframe = Spring.GetGameFrame()
	--Spring.Echo("window " .. tostring(window.parent))	
	--Spring.Echo("Succesfully initialized")
end

local function UpdateInviteTable()
	local myPlayerID = Spring.GetMyPlayerID()
	for i=1,Spring.GetPlayerRulesParam(myPlayerID, "commshare_invitecount") do
		local playerID = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_id")
		local timeleft = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_timeleft") or 0
		----Spring.Echo("Invite from: " .. tostring(playerID) .. "\nTime left: " .. timeleft)
		if playerID == automergeid then
			InviteChange(playerID)
			return
		end
		----Spring.Echo("Invite: " .. playerID .. " : " .. timeleft)
		if invites[playerID] == nil and timeleft > 1 and deadinvites[playerID] ~= timeleft then
			invites[playerID] = timeleft
			givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(true)
		elseif invites[playerID] == timeleft then
			invites[playerID] = nil -- dead invite
			deadinvites[playerID] = timeleft
			givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(false)
		elseif timeleft == 1 then
			givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(false)
			invites[playerID] = nil
		elseif invites[playerID] and timeleft > 1 then
			invites[playerID] = timeleft
			if givemebuttons[playerID]["accept"].visible == false then
				givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(true)
			end
		end
	end
end

local function UpdatePlayers()
	if (mySubjectID < 0) then
		--Spring.Echo("Invalid subject id")
		return
	end
	--Spring.Echo("Updating players")
	for _, subject in ipairs(subjects) do
		UpdatePlayer(subject)
	end
end


function widget:GameProgress(serverFrameNum)
	if needsremerging and serverFrameNum - Spring.GetGameFrame() < 90 then
		needsremerging = false
		Spring.SendLuaRulesMsg("sharemode remerge")
		----Spring.Echo("Sent remerge request")
	end
end

local function EloComparator(subject1, subject2)
	if (not subject2.player and not subject1.player) then return subject1.id > subject2.id end
	if (not subject2.player) then return true end
	if (not subject1.player) then return false end
	local elo1 = select(10,Spring.GetPlayerInfo(subject1.player)).elo
	local elo2 = select(10,Spring.GetPlayerInfo(subject2.player)).elo
	if (not elo2 and not elo1) then return subject1.id > subject2.id end
	if (not elo2) then return true end
	if (not elo1) then return false end
	return elo1 > elo2
end

local function UpdateAllyTeam(allyTeam)
	----Spring.Echo("Updating subject team " .. allyTeam)
	local temp = {}
	for _, teamID in ipairs(Spring.GetTeamList(allyTeam)) do
		local _, leader, dead, ai = Spring.GetTeamInfo(teamID)
		if (ai) then 
			temp[#temp + 1] = {id = #temp + 1, team = teamID, ai = true, name = select(2, Spring.GetAIInfo(teamID)), allyteam = allyTeam, dead = dead}
		else
			for _, playerID in ipairs(Spring.GetPlayerList(teamID)) do
				local name,active,spec = Spring.GetPlayerInfo(playerID)
				if not spec then
					temp[#temp + 1] = {id = #temp + 1, team = teamID, player = playerID, name = name, allyteam = allyTeam, active = active, spec = spec, dead = dead}
				end
			end
		end
	end
	table.sort(temp, EloComparator)
	
	for _, subject in ipairs(temp) do
		subjects[#subjects+1] = subject
		subjects[#subjects].id = #subjects
		if (subject.player) then
			if (subject.player == Spring.GetMyPlayerID()) then
				mySubjectID = #subjects
			end
			givemesubjects[subject.player] = subjects[#subjects]		
		end
	end
end

local function UpdateSubjects()
	--Spring.Echo("Updating subjects")
	mySubjectID = -1
	local oldnum = #subjects
	subjects = {}
	UpdateAllyTeam(Spring.GetMyAllyTeamID())
	for _, allyteamID in ipairs(Spring.GetAllyTeamList()) do
		if (allyteamID ~= Spring.GetMyAllyTeamID()) then
			UpdateAllyTeam(allyteamID)
		end
	end
	for _, playerID in ipairs(Spring.GetPlayerList()) do 
		local name,active,spec, teamID, allyTeam = Spring.GetPlayerInfo(playerID)
		if spec and active then
			if (playerID == Spring.GetMyPlayerID()) then
				mySubjectID = #subjects + 1
			end
			subjects[#subjects + 1] = {id = #subjects + 1, team = teamID, player = playerID, name = name, allyteam = 100, active = active, spec = spec, dead = dead}
		end
	end
	--Spring.Echo("My subject ID is " .. mySubjectID)
	--Spring.Echo("Subject count " .. #subjects)
	if (#subjects ~= oldnum and built and mySubjectID >= 0) then
		--Spring.Echo("Rebuilding")
		Buildme()
	end
end

function widget:PlayerChanged(playerID)
	if (built) then
		UpdateSubjects()
		if ( mySubjectID >= 0) then
			--Spring.Echo("Rebuilding")
			Buildme()
		end
	end
end


local lastUpdate = -100
local dtSum = 0


function widget:Update(dt)
	local f = Spring.GetGameFrame()
	local alt,ctrl,_,shift = Spring.GetModKeyState()
	if window and window.visible then
		local showkey = string.lower(WG.crude.GetHotkey("epic_chili_share_menu_v1.22_sharemenu"))
		--Spring.Echo(showkey)
		if (Spring.GetKeyState(Spring.GetKeyCode(showkey)) ~= window.visible) then
			window:ToggleVisibility()
		end
	end
	dtSum = dtSum + dt
	if (f - lastUpdate >= 30 or dtSum >= 2) then
		dtSum = 0
		lastUpdate = f
		local invitecount = Spring.GetPlayerRulesParam(Spring.GetMyPlayerID(), "commshare_invitecount")
		
		for _, subject in ipairs(subjects) do
			if (givemebuttons[subject.id] and givemebuttons[subject.id]["accept"]) then
				givemebuttons[subject.id]["accept"]:SetVisibility(false)
			end
		end
		if invitecount and built then
			--Spring.Echo("There are " .. invitecount .. " invites")
			UpdateInviteTable()
		end
		UpdateSubjects()
		if (built and mySubjectID >= 0) then
			UpdatePlayers()
		end
	end
	if buildframe < -1 and mySubjectID >= 0 then
		mycurrentteamid = Spring.GetMyTeamID()
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		----Spring.Echo("Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		modOptions = nil
		UpdateSubjects()
		Buildme()
		UpdatePlayers()
	end
	if buildframe > -1 and not built then
		built = true -- block PlayerChanged from doing anything until we've set up initial states.
		local modOptions = {}
		local iscommsharing = Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"isCommsharing")
		modOptions = Spring.GetModOptions()
		----Spring.Echo("Automerge: " .. tostring(options.automation_clanmerge.value) .. "\niscommsharing: " .. tostring(iscommsharing == 1))
		if sharemode and not iscommsharing and options.automation_clanmerge.value == true then
			----Spring.Echo("Clan merge is enabled!")
			MergeWithClanMembers()
		end
	end
end

function widget:Initialize()
	local spectating = Spring.GetSpectatingState()
	chili = WG.Chili
	color2incolor = chili.color2incolor
	screen0 = chili.Screen0
	if options.fixHotkeys.value then
		WG.crude.SetHotkey("toggleoverview","ctrl+tab")
		WG.crude.SetHotkey("sharedialog","")
		options.fixHotkeys.value = false
	end
end
