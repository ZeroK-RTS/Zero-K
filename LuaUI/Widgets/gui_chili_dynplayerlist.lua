--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Dynamic Player List",
    desc      = "vX.XXX Dynamic Player List. Displays list of players with relevant information.",
    author    = "Aquanim",
    date      = "2018-12-26",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false,
  }
end

-- Mainly adapted from Deluxe Player List v0.210 by CarRepairer, KingRaptor, CrazyEddie
-- (which was based on v1.31 Chili Crude Player List by CarRepairer, KingRaptor, et al).
-- Commshare functionality adapted from Chili Share Menu v1.24 by _Shaman and DeinFreund.
-- Attrition counter functionality adapted from Attrition Counter v2.131 by Anarchid and Klon.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
VFS.Include("LuaRules/Configs/constants.lua")
VFS.Include("LuaRules/Utilities/lobbyStuff.lua")

local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

local Chili
local Line
local Image
local Button
local Checkbox
local Window
local Panel
local ScrollPanel
local StackPanel
local LayoutPanel
local Label
local screen0
local color2incolor
local incolor2color

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DEBUG = false

local UPDATE_FREQUENCY = 5	-- seconds

local cpuPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/cpu.png"
local pingPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/ping.png"

local timer = 0

--------------------------------------------------------------------------------
-- variables for game state and personal state

local IsMission
if VFS.FileExists("mission.lua") then
	IsMission = true
else
	IsMission = false
end

local ceasefireAvailable = (not Spring.FixedAllies()) and IsFFA()
local myTeam = 0
local myAllyTeam = 0
local myID
local myName
local iAmSpec
local drawTeamnames
local enableAttrition

--------------------------------------------------------------------------------
-- controls for large playerlist window

local plw = {
	windowPlayerlist = false,
	contentHolder = false,
	vcon_scrollPanel = false,
	vcon_allyTeamSummaries = false,
	vcon_allyTeamSummariesSep = false,
	vcon_attrition = false,
	vcon_playerList = false,
	vcon_spectatorList = false,
	vcon_playerHeader = false,
	vcon_spectatorHeader = false,
	exitButton = false,
	optionButton = false,
	debugButton = false,
	vcon_playerControls = {},
	vcon_spectatorControls = {},
	vcon_teamControls = {},
	vcon_allyTeamControls = {},
	vcon_allyTeamBarControls = {},
}

--------------------------------------------------------------------------------
-- controls for minimal playerlist

local mpl = {
	windowPlayerlist = false,
	contentHolder = false,
	vcon_scrollPanel = false,
	vcon_playerList = false,
	vcon_spectatorBar = false,
	vcon_playerControls = {},
	vcon_teamControls = {},
	vcon_allyTeamControls = {},
}

--------------------------------------------------------------------------------
-- variables for entity handling

-- entity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID or teamID (if AI) in humanLookup and aiLookup
-- Contains isAI, playerID (if not AI), teamID, allyTeamID, active, resigned TODO update this
local playerEntities = {}
local humanLookup = {}
local aiLookup = {}

-- spectatorEntity = player (NOT including specs), human or AI
-- indexed by numbers mapped to playerID in playerSpectatorLookup
-- Contains playerID, active TODO update this
local spectatorEntities = {}
local spectatorLookup = {}

--
local teamEntities = {}

-- allyTeamEntities = groups of allied players
-- indexed by allyTeamID TODO update this
local allyTeamEntities = {}

local playerlistNeedsFullVisUpdate = false
local speclistNeedsFullVisUpdate = false
local plw_scrollPanelsNeedReset = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for game interaction

local function GiveResource(target,kind)
	--mod = 20,500,all
	local defaultamount = 100
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

-- local function InviteChange(playerid)
	-- local name = select(1,Spring.GetPlayerInfo(playerid))
	-- Spring.SendLuaRulesMsg("sharemode accept " .. playerid)
	-- --Spring.SendCommands("say a:I have joined " .. name .. "'s squad.") -- Removed to reduce information overload.
-- end

-- local function UpdateInviteTable()
	-- local myPlayerID = Spring.GetMyPlayerID()
	-- for i=1,Spring.GetPlayerRulesParam(myPlayerID, "commshare_invitecount") do
		-- local playerID = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_id")
		-- local timeleft = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_timeleft") or 0
		-- if (givemebuttons[givemesubjects[playerID].id]) then
			-- --Spring.Echo("Invite from: " .. tostring(playerID) .. "\nTime left: " .. timeleft)
			-- if playerID == automergeid then
				-- InviteChange(playerID)
				-- return
			-- end
			-- --Spring.Echo("Invite: " .. playerID .. " : " .. timeleft)
			-- if invites[playerID] == nil and timeleft > 1 and deadinvites[playerID] ~= timeleft then
				-- invites[playerID] = timeleft
				-- givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(true)
			-- elseif invites[playerID] == timeleft then
				-- invites[playerID] = nil -- dead invite
				-- deadinvites[playerID] = timeleft
				-- givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(false)
			-- elseif timeleft == 1 then
				-- givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(false)
				-- invites[playerID] = nil
			-- elseif invites[playerID] and timeleft > 1 then
				-- invites[playerID] = timeleft
					-- givemebuttons[givemesubjects[playerID].id]["accept"]:SetVisibility(true)
					-- --Spring.Echo("showing")
			-- end
		-- else
			-- --Spring.Echo("No accept for player " .. select(1, Spring.GetPlayerInfo(playerID)))
		-- end
	-- end
-- end

-- local function MergeWithClanMembers()
	-- local playerID = Spring.GetMyPlayerID()
	-- local customKeys = select(10, Spring.GetPlayerInfo(playerID)) or {}
	-- local myclanShort = customKeys.clan     or ""
	-- local myclanLong  = customKeys.clanfull or ""
	-- if myclanShort ~= "" then
		-- local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
		-- local clanmembers = {}
		-- for i=1, #teamlist do
			-- local players = Spring.GetPlayerList(teamlist[i],true)
			-- for j=1, #players do
				-- local customKeys = select(10, Spring.GetPlayerInfo(players[j])) or {}
				-- local clanShort = customKeys.clan     or ""
				-- local clanLong  = customKeys.clanfull or ""
				-- --Spring.Echo(select(1,Spring.GetPlayerInfo(players[j])) .. " : " .. clanLong)
				-- if clanLong == myclanLong and players[j] ~= Spring.GetMyPlayerID() and select(4,Spring.GetPlayerInfo(players[j])) ~= Spring.GetMyTeamID() then
					-- clanmembers[#clanmembers+1] = players[j]
				-- end
			-- end
			-- if #clanmembers > 0 then
				-- local lowestid = playerID
				-- local recipent = false
				-- for i=1, #clanmembers do
					-- if lowestid > clanmembers[i] then
						-- recipent = true
						-- lowestid = clanmembers[i]
					-- end
				-- end
				-- if recipent == false then
					-- for i=1, #clanmembers do
						-- Spring.SendLuaRulesMsg("sharemode invite " .. clanmembers[i])
					-- end
				-- else
					-- automergeid = lowestid
				-- end
			-- end
		-- end
	-- end
-- end

-- local function InvitePlayer(playerid)
	-- local name = select(1,Spring.GetPlayerInfo(playerid))
	-- local teamID = select(4,Spring.GetPlayerInfo(playerid))
	-- local leaderID = select(2,Spring.GetTeamInfo(teamID))
	-- Spring.SendLuaRulesMsg("sharemode invite " .. playerid)
	-- if #Spring.GetPlayerList(select(4,Spring.GetPlayerInfo(playerid))) > 1 and playerid == leaderID then
		-- Spring.SendCommands("say a:I invited " .. name .. "'s squad to a merger.")
	-- else
		-- Spring.SendCommands("say a:I invited " .. name .. " to join my squad.")
	-- end
-- end

-- local function KickPlayer(playerid)
	-- Spring.SendCommands("say a: I kicked " .. select(1,Spring.GetPlayerInfo(playerid)) .. " from my squad.")
	-- Spring.SendLuaRulesMsg("sharemode kick " .. playerid)
-- end

-- local function LeaveMySquad()
	-- local leader = select(2,Spring.GetTeamInfo(Spring.GetMyTeamID()))
	-- local name = select(1,Spring.GetPlayerInfo(leader))
	-- Spring.SendCommands("say a: I left " .. name .. "'s squad.")
	-- Spring.SendLuaRulesMsg("sharemode unmerge")
-- end

local function SquadAction(eID)
	if not iAmSpec and playerEntities[eID].allyTeamID == myAllyTeam and playerEntities[eID].teamID ~= myTeam and not playerEntities[eID].isAI then
		Spring.Echo("DYNLIST Squad Action Player "..eID)
	else
		Spring.Echo("DYNLIST Fail Squad Action Player "..eID)
	end
end

local function UnitGiftAction(eID)
	if not iAmSpec and playerEntities[eID].allyTeamID == myAllyTeam and playerEntities[eID].teamID ~= myTeam then
		GiveUnit(playerEntities[eID].teamID)
		Spring.Echo("DYNLIST Unit Gift Player "..eID)
	else
		Spring.Echo("DYNLIST Fail Unit Gift Player "..eID)
	end
end

local function WhisperAction(eID)
	if not iAmSpec and not playerEntities[eID].isAI and playerEntities[eID].playerID ~= myID and (playerEntities[eID].allyTeamID == myAllyTeam or Spring.Utilities.GetTeamCount() > 2) then
		Spring.Echo("DYNLIST Whisper Player "..eID)
	else
		Spring.Echo("DYNLIST Fail Whisper Player "..eID)
	end
end

local function PlayerInteract(eID)
	local alt,ctrl,_,shift = Spring.GetModKeyState()
	if alt then SquadAction(eID)
	elseif ctrl then UnitGiftAction(eID)	
	else WhisperAction(eID) end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- utility functions

local function FormatMetalStats(stat, left)
	left = left or false

	--return stat < 1000 and string.format("%.0f", stat) or string.format("%.1f", stat/1000) .. "k"
	if stat < 1000 then
		if left then
			return string.format("%.0f", stat) .. " "
		else
			return " " .. string.format("%.0f", stat)
		end
	else
		return string.format("%.1f", stat/1000) .. "k"
	end
end

local function FormatIncomeStats(stat)
	--return stat < 1000 and string.format("%." .. (0) .. "f",stat) or string.format("%.1f", stat/1000) .. "k"
	return stat < 1000 and "" .. string.format("%." .. (0) .. "f",stat) or string.format("%.1f", stat/1000) .. "k"
end


local function SafeAddChild(child, adult)
	if child and adult then
		if child.parent then
			child.parent:RemoveChild(child)
		end
		adult:AddChild(child)
	else
		Spring.Echo("DYNLIST SafeAddChild Nil")
	end
end

local function SafeRemoveChild(child, adult)
	if child and adult then
		-- this test doesn't work properly for some reason
		--if child.parent == adult then
			adult:RemoveChild(child)
			adult:Invalidate()
		--else
		--	Spring.Echo("PLW ERROR SafeRemoveChild Parentage")
		--end
	else
		Spring.Echo("DYNLIST SafeRemoveChild Nil")
	end
end

local function FormatPingCpu(ping,cpu)
	-- guard against being called with nils
	ping = ping or 0
	cpu = cpu or 0
	-- guard against silly values
	ping = math.max(math.min(ping,999),0)
	cpu = math.max(math.min(cpu,9.99),0)

	local pingMult = 2/3	-- lower = higher ping needed to be red
	local pingCpuColors = {
		{0, 1, 0, 1},
		{0.7, 1, 0, 1},
		{1, 1, 0, 1},
		{1, 0.6, 0, 1},
		{1, 0, 0, 1}
	}

	local pingCol = pingCpuColors[ math.ceil( math.min(ping * pingMult, 1) * 5) ] or {.85,.85,.85,1}
	local cpuCol = pingCpuColors[ math.ceil( math.min(cpu, 1) * 5 ) ] or {.85,.85,.85,1}

	local pingText
	if ping < 1 then
		pingText = (math.floor(ping*1000) ..'ms')
	else
		pingText = ('' .. (math.floor(ping*100)/100)):sub(1,4) .. 's'
	end

	local cpuText = math.round(cpu*100) .. '%'
	
	return pingCol,cpuCol,pingText,cpuText
end

local function FormatCCR(clan, faction, country, level, elo, rank)
	local clanicon, countryicon, rankicon
	if clan and clan ~= "" then 
		clanicon = "LuaUI/Configs/Clans/" .. clan ..".png"
	elseif faction and faction ~= "" then
		clanicon = "LuaUI/Configs/Factions/" .. faction ..".png"
	end
	local countryicon = country and country ~= '' and country ~= '??' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
	if level and level ~= "" and elo and elo ~= "" then 
		--local trelo, xp = Spring.Utilities.TranslateLobbyRank(tonumber(elo), tonumber(level))
		--rankicon = "LuaUI/Images/LobbyRanks/" .. xp .. "_" .. trelo .. ".png"
		rankicon = "LuaUI/Images/LobbyRanks/" .. (rank or "0_0") .. ".png"
	end
	return clanicon, countryicon, rankicon
end

local function FormatStatus(active, resigned, ping, cpu, teamUnitCount)
	-- guard against being called with nils
	ping = ping or 0
	cpu = cpu or 0
	-- guard against silly values
	ping = math.max(math.min(ping,999),0)
	cpu = math.max(math.min(cpu,9.99),0)

	local teamStatusCol = {1,1,1,1}
	local teamStatusText = ""
	local teamStatusTooltip = ""

	if ping > 5 then
		teamStatusText = '→'
		teamStatusCol = {1,0.5,0.75,1}
		teamStatusTooltip = "Player catching up, has large ping time"
	end
	
	if resigned then
		teamStatusCol = {0.5,0.5,0.5,1}
		teamStatusTooltip = "Player resigned"
		if teamUnitCount > 0  then
			teamStatusText = 'X'
			teamStatusTooltip = teamStatusTooltip .. ", has units remaining"
		else
			teamStatusText = '—'
		end
	elseif not active then
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) or (cpuUsage and cpuUsage > 1) then 
			teamStatusText = '?'
			teamStatusCol = {1,1,0,1}
			teamStatusTooltip = "Player status unknown"
		else 
			teamStatusCol = {0.5,0.3,0.3,1}
			teamStatusTooltip = "Player disconnected"
			teamStatusText = '‡'
			if teamUnitCount > 0  then
				teamStatusTooltip = teamStatusTooltip .. ", has units remaining"
			end
		end
	end

	return teamStatusCol, teamStatusText, teamStatusTooltip
end

local function CompareAllyTeams(atID1, atID2)
	if allyTeamEntities[atID1] and allyTeamEntities[atID2] then
		local res1 = allyTeamEntities[atID1].resigned
		local res2 = allyTeamEntities[atID2].resigned
		local elo1 = allyTeamEntities[atID1].cumuelo
		local elo2 = allyTeamEntities[atID2].cumuelo
		if res2 then 
			return false
		elseif res1 then
			return true
		elseif not iAmSpec then
			if atID1 == myAllyTeam then return false
			elseif atID2 == myAllyTeam then return true
			end
		elseif elo1 and elo2 then
			if elo1 < elo2 then return true
			else return false
			end
		elseif atID2 < atID1 then
			return true
		end
	end
	return false
end

local function cap (x) return math.max(math.min(x,1),0) end

-- comparison function for allyteam bars, when they are displayed alone
function CompareAllyTeamBarVcons(vcon1, vcon2)
	if (not vcon1.options) or (not vcon1.options.atID) then -- separator bar should be at the bottom
		return true
	elseif (not vcon2.options) or (not vcon2.options.atID) then
		return false
	else
		return CompareAllyTeams(vcon1.options.atID, vcon2.options.atID)
	end
end

-- comparison function for allyteam boxes
function CompareAllyTeamVcons(vcon1, vcon2)
	if not vcon1.vID then -- the ally team bar should be at the top
		return false
	elseif not vcon2.vID then -- if neither of these are true, the vIDs should be allyteam IDs
		return true
	else
		return CompareAllyTeams(vcon1.vID, vcon2.vID)
	end
end

-- comparison function for team boxes
function CompareTeamVcons(vcon1, vcon2)
	if not vcon1.vID then -- check that these are vcons
		return false
	elseif not vcon2.vID then 
		return true
	elseif teamEntities[vcon1.vID] and teamEntities[vcon2.vID] then
		local elo1 = tonumber(teamEntities[vcon1.vID].elo)
		local res1 = teamEntities[vcon1.vID].resigned
		local elo2 = tonumber(teamEntities[vcon2.vID].elo)
		local res2 = teamEntities[vcon2.vID].resigned
		if res2 then 
			return false
		elseif res1 then
			return true
		end
		if not iAmSpec then
			if unsortYourself then
				if vcon1.vID == myTeam then return false
				elseif vcon2.vID == myTeam then return true
				end
			end
		end
		if elo1 and elo2 then
			if elo2 > elo1 then
				return true
			end
		end
	end
	return false
end

-- comparison function for spectator boxes
function CompareSpectatorVcons(vcon1, vcon2)
	if not vcon1.vID then
		return false
	elseif not vcon2.vID then
		return true
	elseif spectatorEntities[vcon1.vID] and spectatorEntities[vcon2.vID] then
		local name1 = spectatorEntities[vcon1.vID].name
		local name2 = spectatorEntities[vcon2.vID].name
		if name1 and name2 then
			if name2 == "unknown" then 
				return false
			elseif name1 == "unknown" or name1 > name2 then 
				return true
			end
		end
	end

	return false
end


-- comparison function for player boxes
function ComparePlayerVcons(vcon1, vcon2)
	if not vcon1.vID then -- check that these are vcons
		return false
	elseif not vcon2.vID then
		return true
	elseif playerEntities[vcon1.vID] and playerEntities[vcon2.vID] then
		local elo1 = tonumber(playerEntities[vcon1.vID].elo)
		local res1 = playerEntities[vcon1.vID].resigned
		local elo2 = tonumber(playerEntities[vcon2.vID].elo)
		local res2 = playerEntities[vcon2.vID].resigned
		if not iAmSpec then
			if unsortYourself then
				if playerEntities[vcon1.vID].playerID == myID then return false
				elseif playerEntities[vcon2.vID].playerID == myID then return true
				end
			end
		elseif res2 then 
			return false
		elseif res1 then
			return true
		elseif elo2 and (not elo1 or elo2 > elo1) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for managing vertically-stacked controls

--Defining all these nils is pointless, but they explain what a VControl *should* eventually have.
--vID is NOT a unique identifier; for a team Vcon it is the teamID, etc.
local function CreateVcon(id, m, s, tb, bb, opts)
	return { vID = id, main = m, subcon = s, parent = nil, above = nil, below = nil, firstChild = nil, lastChild = nil, topBuffer = tb, bottomBuffer = bb, isOuterScrollPanel = nil, options = opts}
end

-- puts all vcons below the changed one in their correct y-position
local function RealignVcons(changed)
	local vcontrol = changed
	
	local bbabove = 0
	if vcontrol.above then bbabove = vcontrol.above.bottomBuffer or 0
	elseif vcontrol.parent and vcontrol.parent.options then bbabove = vcontrol.parent.options.innerVBuf or 0
	end
	local ub = vcontrol.topBuffer or 0
	local bb = vcontrol.bottomBuffer or 0
	local ubbelow = 0
	if vcontrol.below then ubbelow = vcontrol.below.topBuffer or 0
	elseif vcontrol.parent and vcontrol.parent.options then ubbelow = vcontrol.parent.options.innerVBuf or 0
	end
	if vcontrol.above then 
		vcontrol.main:SetPos(vcontrol.main.x, vcontrol.above.main.y + vcontrol.above.main.height + bbabove + ub, vcontrol.main.width, vcontrol.main.height)
	elseif vcontrol.parent then
		vcontrol.main:SetPos(vcontrol.main.x, ub + bbabove, vcontrol.main.width, vcontrol.main.height)
	end
	local continue = true
	while continue do
		bbabove = 0
		if vcontrol.above then bbabove = vcontrol.above.bottomBuffer or 0 
		elseif vcontrol.parent and vcontrol.parent.options then bbabove = vcontrol.parent.options.innerVBuf or 0
		end
		ub = vcontrol.topBuffer or 0
		bb = vcontrol.bottomBuffer or 0
		ubbelow = 0
		if vcontrol.below then ubbelow = vcontrol.below.topBuffer or 0 
		elseif vcontrol.parent and vcontrol.parent.options then ubbelow = vcontrol.parent.options.innerVBuf or 0
		end
		if vcontrol.below then
			vcontrol.below.main:SetPos(vcontrol.below.main.x, vcontrol.main.y + vcontrol.main.height + bb + ubbelow ,vcontrol.below.main.width, vcontrol.below.main.height)
			vcontrol = vcontrol.below
		elseif (not vcontrol.parent) or (vcontrol.parent.isOuterScrollPanel) then 
			continue = false
		else
			vcontrol.parent.main:SetPos(vcontrol.parent.main.x, vcontrol.parent.main.y, vcontrol.parent.main.width, vcontrol.parent.lastChild.main.y + vcontrol.parent.lastChild.main.height + bb + ubbelow)
			vcontrol = vcontrol.parent
		end
	end
end

-- removes a vcon
local function RemoveVcon(target)
	if (not target) then Spring.Echo ("DYNLIST RemoveVcon Nil Target"); return end
	if (not target.parent) then Spring.Echo ("DYNLIST RemoveVcon Nil Parent"); return end
	local parent = target.parent
	if parent then
		if target == parent.firstChild then
			parent.firstChild = target.below
		end
		if target == target.parent.lastChild then
			parent.lastChild = target.above
		end
	end
	if target.below then
		target.below.above = target.above
	end
	if target.above then
		target.above.below = target.below
	end
	target.parent = nil
	target.above = nil
	target.below = nil
	if parent.firstChild then RealignVcons(parent.firstChild) end
end

-- inserts a new vcon as the first child of a parent
local function InsertTopVconChild(new, parent)
	if (not new) or (not parent) then Spring.Echo ("DYNLIST InsertTopVconChild"); return end
	new.below = parent.firstChild
	new.above = nil
	new.parent = parent
	if new.below then new.below.above = new end
	parent.firstChild = new
	if (not parent.lastChild) then parent.lastChild = new end
	RealignVcons(new)
end

-- inserts a new vcon as the last child of a parent
local function InsertBottomVconChild(new, parent)
	if (not new) or (not parent) then Spring.Echo ("DYNLIST InsertBottomVconChild"); return end
	new.above = parent.lastChild
	new.below = nil
	new.parent = parent
	if new.above then new.above.below = new end
	parent.lastChild = new
	if (not parent.firstChild) then parent.firstChild = new end
	RealignVcons(new)
end

-- inserts a new vcon before some other one
local function InsertVconBefore(new, nextCon)
	if (not new) or (not parent) then Spring.Echo ("DYNLIST InsertVconBefore"); return end
	new.parent = nextCon.parent
	new.below = nextCon
	new.above = nextCon.above
	if new.above then new.above.below = new end
	new.below.above = new
	if new.parent.firstChild == nextCon then new.parent.firstChild = new end
	RealignVcons(new)
end

-- switch a vcon with the one below it
local function SwitchVconDown(moving)
	if (not moving) or (not moving.below) then Spring.Echo ("DYNLIST SwitchVconDown"); return end
	local pos1, pos2, pos3, pos4
	pos1 = moving.above
	pos3 = moving
	pos2 = moving.below
	pos4 = moving.below.below
	if pos1 then pos1.below = pos2 end
	pos2.above = pos1
	pos2.below = pos3
	pos3.above = pos2
	pos3.below = pos4
	if pos4 then pos4.above = pos3 end
	if moving.parent.firstChild == pos3 then moving.parent.firstChild = pos2 end
	if moving.parent.lastChild == pos2 then moving.parent.lastChild = pos3 end
	RealignVcons(pos2)
end

-- sorts a single vcon down or up
local function SortSingleVcon(startVCon, endVCon, SwapFunction, sortUpwards, stopAtFirstFail)
	-- SwapFunction should return true if the first should NOT be above the second.
	local vcon = startVCon
	if vcon then
		local nextVCon = sortUpwards and vcon.above or vcon.below
		local continue = true
		while vcon and nextVCon and nextVCon ~= endVCon and continue do
			if sortUpwards then
				if SwapFunction(nextVCon, vcon) then
					SwitchVconDown(nextVCon)
				else
					vcon = nextVCon
					if stopAtFirstFail then continue = false end
				end
				nextVCon = vcon.above
			else
				if SwapFunction(vcon, nextVCon) then
					SwitchVconDown(vcon)
				else
					vcon = nextVCon
					if stopAtFirstFail then continue = false end
				end
				nextVCon = vcon.below
			end
		end
	end
	return vcon
end

-- performs a bubble sort on vcons
local function SortVcons(startVCon, SwapFunction, sortUpwards)
	-- SwapFunction should return true if the first should NOT be above the second.
	local vcon = startVCon
	local endcon = nil
	while vcon ~= endcon do
		endcon = SortSingleVcon(vcon, endcon, SwapFunction, sortUpwards, false)
		vcon = startVCon
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for window playerlist 

local plw_conf = {
	sectionheader_display = false,
	playerbar_added_height = false,
	plw_border_slack = false,
	plw_y_buffer = false,
	plw_headerTextHeight = false,
	plw_teamboxpadding = false,
	x_window_begin = false,
	x_ccr_begin = false,
	x_ccr_width = false,
	x_name_begin = false,
	x_name_width = false,
	x_playerstate_begin = false,
	x_playerstate_width = false,
	x_resourcestate_begin = false,
	x_resourcestate_width = false,
	x_actions_begin = false,
	x_actions_width = false,
	x_cpuping_begin = false,
	x_cpuping_width = false,
	x_window_width = false,
	x_icon_clan_width = false,
	x_icon_country_width = false,
	x_icon_rank_width = false,
	x_name_width = false,
	x_playerstate_width = false,
	x_m_mobiles_width = false,
	x_m_defense_width = false,
	x_m_income_width = false,
	x_e_income_width = false,
	x_m_fill_width = false,
	x_e_fill_width = false,
	x_cpu_width = false,
	x_ping_width = false,
	x_icon_clan_offset = false,
	x_icon_country_offset = false,
	x_icon_rank_offset = false,
	x_name_offset = false,
	x_playerstate_offset = false,
	x_m_mobiles_offset = false,
	x_m_defense_offset = false,
	x_m_income_offset = false,
	x_e_income_offset = false,
	x_m_fill_offset = false,
	x_e_fill_offset = false,
	x_cpu_offset = false,
	x_ping_offset = false,
	sectionheader_offset = false,
	subsectionheader_offset = false,
	x_name_spectator_width = false,
	x_playerstate_spectator_width = false,
	x_cpuping_spectator_width = false,
	x_actions_spectator_width = false,

	x_name_spectator_begin = false,
	x_name_spectator_offset = false,
	x_playerstate_spectator_begin = false,
	x_playerstate_spectator_offset = false,
	x_playerstate_actions_begin = false,
	x_cpuping_spectator_begin = false,
	x_cpu_spectator_offset = false,
	x_ping_spectator_offset = false,
	x_cpu_spectator_width = false,
	x_ping_spectator_width = false,

	linebuffer = false,

	header_icon_width = false,
	header_icon_height = false,
	x_mobile_icon = false,
	x_defence_icon = false,
	x_metal_icon = false,
	x_energy_icon = false,
	x_cpu_icon = false,
	x_ping_icon = false,
	plw_y_endbuffer = false,
	plw_attrition_namew = false,
}

local function PLW_AutoSetHeight()
	local height = plw.vcon_scrollPanel.lastChild.main.y + plw.vcon_scrollPanel.lastChild.main.height + plw_conf.plw_y_endbuffer
	if not height or height > (options.plw_maxWindowHeight.value or 600) then height = (options.plw_maxWindowHeight.value or 600) end
	plw.windowPlayerlist:SetPos(plw.windowPlayerlist.x, plw.windowPlayerlist.y, plw_conf.x_window_width + 30,height)
end

local function PLW_UpdateVisibility()
	if screen0 and plw.windowPlayerlist then
		if options.plw_visible.value then
			SafeAddChild(plw.windowPlayerlist,screen0)
		else
			screen0:RemoveChild(plw.windowPlayerlist)
			--SafeRemoveChild(plw.windowPlayerlist,screen0)
		end
	end
end

local function PLW_CalculateDimensions()
	plw_conf = {}

	plw_conf.sectionheader_display = true

	plw_conf.playerbar_text_height = options.plw_textHeight.value
	plw_conf.playerbar_image_height = options.plw_textHeight.value + 2
	plw_conf.playerbar_height = plw_conf.playerbar_text_height + 4
	plw_conf.playerbar_text_y = 2
	plw_conf.plw_headerTextHeight = math.floor(options.plw_textHeight.value * 1.8)

	plw_conf.plw_border_slack = 15
	
	plw_conf.plw_y_buffer = 7

	plw_conf.x_icon_clan_width = 22
	plw_conf.x_icon_country_width = 24
	plw_conf.x_icon_rank_width = 20
	plw_conf.x_name_width = options.plw_namewidth.value * options.plw_textHeight.value / 2
	plw_conf.x_playerstate_width = 20
	plw_conf.x_addedline_width = 4
	if options.plw_show_netWorth.value == 'disable' then plw_conf.x_m_mobiles_width = 0
	else plw_conf.x_m_mobiles_width = 5 * options.plw_textHeight.value / 2 + 10 end
	if options.plw_show_netWorth.value == 'all' then plw_conf.x_m_defense_width = 5 * options.plw_textHeight.value / 2 + 10
	else plw_conf.x_m_defense_width = 0 end
	plw_conf.x_m_income_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_conf.x_e_income_width = 5 * options.plw_textHeight.value / 2 + 10
	plw_conf.x_m_fill_width = 5 * options.plw_textHeight.value / 2
	plw_conf.x_e_fill_width = 5 * options.plw_textHeight.value / 2
	
	if options.plw_cpuPlayerDisp.value == 'icon' then plw_conf.x_cpu_width = 20
	elseif options.plw_cpuPlayerDisp.value == 'text' then plw_conf.x_cpu_width = 30
	else plw_conf.x_cpu_width = 0 end
	if options.plw_pingPlayerDisp.value == 'icon' then plw_conf.x_ping_width = 20
	elseif options.plw_pingPlayerDisp.value == 'text' then plw_conf.x_ping_width = 44
	else plw_conf.x_ping_width = 0 end
	
	if options.plw_cpuSpecDisp.value == 'icon' then plw_conf.x_cpu_spectator_width = 20
	elseif options.plw_cpuSpecDisp.value == 'text' then plw_conf.x_cpu_spectator_width = 30
	else plw_conf.x_cpu_spectator_width = 0 end
	if options.plw_pingSpecDisp.value == 'icon' then plw_conf.x_ping_spectator_width = 20
	elseif options.plw_pingSpecDisp.value == 'text' then plw_conf.x_ping_spectator_width = 44
	else plw_conf.x_ping_spectator_width = 0 end

	plw_conf.x_window_begin = 0
	
	plw_conf.x_ccr_begin = plw_conf.x_window_begin
	plw_conf.x_icon_clan_offset = 0
	plw_conf.x_icon_country_offset = plw_conf.x_icon_clan_offset + (options.plw_showClan.value and plw_conf.x_icon_clan_width or 0)
	plw_conf.x_icon_rank_offset = plw_conf.x_icon_country_offset + (options.plw_showCountry.value and plw_conf.x_icon_country_width or 0)
	plw_conf.x_ccr_width = plw_conf.x_icon_rank_offset + (options.plw_showRank.value and plw_conf.x_icon_rank_width or 0) + 5
	
	plw_conf.x_name_offset = 0
	plw_conf.x_name_begin = plw_conf.x_ccr_begin + plw_conf.x_ccr_width
	
	plw_conf.x_playerstate_begin = plw_conf.x_name_begin + plw_conf.x_name_width
	plw_conf.x_playerstate_offset = 0
	
	plw_conf.x_addedline_begin = plw_conf.x_playerstate_begin + plw_conf.x_playerstate_width
	plw_conf.x_addedline_offset = 1
	
	plw_conf.x_resourcestate_begin = plw_conf.x_addedline_begin + plw_conf.x_addedline_width
	plw_conf.x_m_mobiles_offset = 0
	if options.plw_show_netWorth.value == 'disable' then plw_conf.x_m_defense_offset = plw_conf.x_m_mobiles_offset
	else plw_conf.x_m_defense_offset = plw_conf.x_m_mobiles_offset + plw_conf.x_m_mobiles_width + 5 end
	
	if options.plw_show_netWorth.value == 'all' then plw_conf.x_m_income_offset = plw_conf.x_m_defense_offset + plw_conf.x_m_defense_width + 5
	else plw_conf.x_m_income_offset = plw_conf.x_m_defense_offset end
	
	plw_conf.x_m_fill_offset = plw_conf.x_m_income_offset + (options.plw_show_resourceStatus.value and (plw_conf.x_m_income_width + 5) or 0)
	plw_conf.x_e_income_offset = plw_conf.x_m_fill_offset + plw_conf.x_m_fill_width + 5
	plw_conf.x_e_fill_offset = plw_conf.x_e_income_offset + (options.plw_show_resourceStatus.value and (plw_conf.x_e_income_width + 5) or 0)
	plw_conf.x_resourcestate_width = plw_conf.x_e_fill_offset + plw_conf.x_e_fill_width + 5
	
	--plw_conf.x_actions_begin = plw_conf.x_resourcestate_begin + (options.plw_show_resourceStatus.value and plw_conf.x_resourcestate_width or 0)
	plw_conf.x_actions_begin = plw_conf.x_resourcestate_begin + plw_conf.x_resourcestate_width
	plw_conf.x_actions_width = 0
	
	plw_conf.x_cpuping_begin = plw_conf.x_actions_begin + plw_conf.x_actions_width
	plw_conf.x_cpu_offset = 0
	plw_conf.x_ping_offset = plw_conf.x_cpu_offset + plw_conf.x_cpu_width
	plw_conf.x_cpuping_width = plw_conf.x_ping_offset + plw_conf.x_ping_width
	
	plw_conf.x_window_width = plw_conf.x_cpuping_begin + plw_conf.x_cpuping_width

	plw_conf.x_name_spectator_begin = plw_conf.x_window_begin
	plw_conf.x_name_spectator_offset = 10
	plw_conf.x_name_spectator_width = options.plw_namewidth.value * options.plw_textHeight.value / 2 + plw_conf.x_name_spectator_offset
	
	plw_conf.x_playerstate_spectator_begin = plw_conf.x_name_spectator_begin + plw_conf.x_name_spectator_width
	plw_conf.x_playerstate_spectator_offset = 0
	plw_conf.x_playerstate_spectator_width = 0
	
	plw_conf.x_actions_spectator_begin = plw_conf.x_playerstate_spectator_begin + plw_conf.x_playerstate_spectator_width
	plw_conf.x_actions_spectator_width = 0
	
	plw_conf.x_cpuping_spectator_begin = plw_conf.x_actions_spectator_begin + plw_conf.x_actions_spectator_width
	plw_conf.x_cpu_spectator_offset = 0
	plw_conf.x_ping_spectator_offset = plw_conf.x_cpu_spectator_offset + plw_conf.x_cpu_spectator_width
	plw_conf.x_cpuping_spectator_width = plw_conf.x_ping_spectator_offset + plw_conf.x_ping_spectator_width

	plw_conf.sectionheader_offset = 20
	plw_conf.subsectionheader_offset = 40
	
	plw_conf.linebuffer = 6
	plw_conf.attition_barwidth = plw_conf.x_m_fill_width * 2
	plw_attrition_namew = plw_conf.x_window_width/2 - plw_conf.attition_barwidth/2 - plw_conf.linebuffer
	
	plw_conf.header_icon_width = plw_conf.playerbar_image_height
	plw_conf.header_icon_height = plw_conf.playerbar_image_height
	plw_conf.x_metal_icon = plw_conf.x_resourcestate_begin + (plw_conf.x_m_income_offset + plw_conf.x_m_fill_offset + plw_conf.x_m_fill_width - plw_conf.header_icon_width) * 0.5
	plw_conf.x_energy_icon = plw_conf.x_resourcestate_begin + (plw_conf.x_e_income_offset + plw_conf.x_e_fill_offset + plw_conf.x_e_fill_width - plw_conf.header_icon_width) * 0.5
	plw_conf.x_mobile_icon = plw_conf.x_resourcestate_begin + plw_conf.x_m_mobiles_offset + (plw_conf.x_m_mobiles_width - plw_conf.header_icon_width) * 0.5
	plw_conf.x_defence_icon = plw_conf.x_resourcestate_begin + plw_conf.x_m_defense_offset + (plw_conf.x_m_defense_width - plw_conf.header_icon_width) * 0.5
	plw_conf.x_cpu_icon = plw_conf.x_cpuping_begin + plw_conf.x_cpu_offset + ( plw_conf.x_cpu_width - plw_conf.header_icon_width) * 0.5
	plw_conf.x_ping_icon = plw_conf.x_cpuping_begin + plw_conf.x_ping_offset + ( plw_conf.x_ping_width - plw_conf.header_icon_width) * 0.5
	
	plw_conf.plw_y_endbuffer = 80
	
	plw_conf.plw_teamboxpadding = 5
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for window playerlist11

-- updates the contents of main panels
local function PLW_UpdateVolatileAttritionControl()
	if options.plw_showAttrition.value and enableAttrition and plw.vcon_attrition.parent then
	
		local kill1 = -1
		local loss1 = -1
		if iAmSpec or (myAllyTeam == plw.vcon_attrition.options.left) then
			kill1 = allyTeamEntities[plw.vcon_attrition.options.left].m_kill
			loss1 = allyTeamEntities[plw.vcon_attrition.options.left].m_loss
		else
			kill1 = allyTeamEntities[plw.vcon_attrition.options.right].m_loss
			loss1 = allyTeamEntities[plw.vcon_attrition.options.right].m_kill
		end
		local kill2 = 0
		local loss2 = 0
		if iAmSpec or (myAllyTeam == plw.vcon_attrition.options.right) then
			kill2 = allyTeamEntities[plw.vcon_attrition.options.right].m_kill
			loss2 = allyTeamEntities[plw.vcon_attrition.options.right].m_loss
		else
			kill2 = allyTeamEntities[plw.vcon_attrition.options.left].m_loss
			loss2 = allyTeamEntities[plw.vcon_attrition.options.left].m_kill
		end

		local rate = -1
		
		if loss1 and loss2 then
			if loss1 > 0 then
				rate = loss2 / loss1
			elseif loss2 > 0 then
				rate = 10
			end
		end
		
		plw.vcon_attrition.subcon.dest1:SetCaption(FormatMetalStats(kill1))
		plw.vcon_attrition.subcon.dest2:SetCaption(FormatMetalStats(kill2,true))
		
		if rate < 0 then 
			caption = 'N/A'; 
			plw.vcon_attrition.subcon.ratioT.font.color = {0.7,0.7,0.7,1}	
		elseif rate > 9.99 then 
			caption = 'PWN%'; 
			plw.vcon_attrition.subcon.ratioT.font.color = {0,1,1,1}
		else
			caption = tostring(math.floor(rate*100))..'%'
			plw.vcon_attrition.subcon.ratioT.font.color = {
				cap(3-rate*2),
				cap(2*rate-1),
				cap((rate-2) / 2),
				1}	
		end
		
		plw.vcon_attrition.subcon.ratioT:SetCaption(caption)
	
	end
	
end

local function PLW_UpdateStateAttritionControl()
	if options.plw_showAttrition.value and enableAttrition and plw.vcon_attrition.parent then
	
		local ca1 = allyTeamEntities[plw.vcon_attrition.options.left].ateamcolor.r or 1
		local ca2 = allyTeamEntities[plw.vcon_attrition.options.left].ateamcolor.g or 1
		local ca3 = allyTeamEntities[plw.vcon_attrition.options.left].ateamcolor.b or 1
		
		local cb1 = allyTeamEntities[plw.vcon_attrition.options.right].ateamcolor.r or 1
		local cb2 = allyTeamEntities[plw.vcon_attrition.options.right].ateamcolor.g or 1
		local cb3 = allyTeamEntities[plw.vcon_attrition.options.right].ateamcolor.b or 1
	
		local mincol = 1.2
		local amult = 1
		if ca1 + ca2 + ca3 < mincol then
			amult = (3 - mincol) / (3 - ca1 - ca2 - ca3)
		end
		
		local bmult = 1
		if cb1 + cb2 + cb3 < mincol then
			bmult = (3 - mincol) / (3 - cb1 - cb2 - cb3)
		end
	
		plw.vcon_attrition.subcon.name1:SetCaption(allyTeamEntities[plw.vcon_attrition.options.left].name)
		plw.vcon_attrition.subcon.name1.font:SetColor{1-(1-ca1)*amult,1-(1-ca2)*amult,1-(1-ca3)*amult,1}
		
		plw.vcon_attrition.subcon.name2:SetCaption(allyTeamEntities[plw.vcon_attrition.options.right].name)
		plw.vcon_attrition.subcon.name2.font:SetColor{1-(1-cb1)*bmult,1-(1-cb2)*bmult,1-(1-cb3)*bmult,1}
		
		plw.vcon_attrition.subcon.dest1.font:SetColor{0.7,0.7,0.7,1}
		plw.vcon_attrition.subcon.dest2.font:SetColor{0.7,0.7,0.7,1}
		
		local pronoun = allyTeamEntities[plw.vcon_attrition.options.left].name .. "'s "
		local pronoun2a = allyTeamEntities[plw.vcon_attrition.options.left].name
		local pronoun2b = allyTeamEntities[plw.vcon_attrition.options.right].name
		if not iAmSpec then
			if drawTeamnames then
				pronoun = "Your team's "
				pronoun2a = "your team"
			else
				pronoun = "Your "
				pronoun2a = "you"
			end
		end
		
		local tip1
		if iAmSpec or (myAllyTeam == plw.vcon_attrition.options.left) then
			tip1 = "Unit value of "..pronoun2b..(iAmSpec and "" or " confirmed to have been").." destroyed by "..pronoun2a.."."
		else
			tip1 = "Unit value lost by "..pronoun2b.."."
		end
		
		local tip2
		if iAmSpec or (myAllyTeam == plw.vcon_attrition.options.right) then
			tip2 = "Unit value of "..pronoun2a..(iAmSpec and "" or " confirmed to have been").." destroyed by "..pronoun2b.."."
		else
			tip2 = "Unit value lost by "..pronoun2a.."."
		end 
		
		
		tip3 = pronoun.."attrition rate against "..allyTeamEntities[plw.vcon_attrition.options.right].name
		if iAmSpec then
			tip3 = tip3.." (including self-inflicted)"
		else
			tip3 = tip3.." (based on known info)"
		end
		tip3 = tip3..".\n>100% is better for "..pronoun2a.."."
		
		plw.vcon_attrition.subcon.dest1.tooltip = tip1
		plw.vcon_attrition.subcon.dest2.tooltip = tip2
		plw.vcon_attrition.subcon.ratioT.tooltip = tip3
		
		--plw.vcon_attrition.subcon.dest1.font:SetColor{1-(1-ca1)*0.6,1-(1-ca2)*0.6,1-(1-ca3)*0.6,1}
		--plw.vcon_attrition.subcon.dest2.font:SetColor{1-(1-cb1)*0.6,1-(1-cb2)*0.6,1-(1-cb3)*0.6,1}
	end
	
	PLW_UpdateVolatileAttritionControl()
end

local function PLW_UpdateStatePlayerListControl()
	if not plw.vcon_playerList then
		return
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		local allyTeamVCon = plw.vcon_allyTeamControls[atID]
		if allyTeamVCon and allyTeamVCon.parent ~= plw.vcon_playerList then
			if allyTeamVCon.parent then
				-- TODO remove from ???
			end
			SafeAddChild(plw.vcon_allyTeamControls[atID].main, plw.vcon_playerList.main)
			InsertBottomVconChild(plw.vcon_allyTeamControls[atID], plw.vcon_playerList)
			SortSingleVcon(plw.vcon_allyTeamControls[atID], nil, CompareAllyTeamVcons, true, true)
		end
		
		
		if options.plw_allyteamBarLoc.value == 'above' and drawTeamnames then
			local allyTeamVConBar = plw.vcon_allyTeamBarControls[atID]
			if allyTeamVConBar and allyTeamVConBar.parent ~= plw.vcon_allyTeamSummaries then
				if allyTeamVConBar.parent then
					RemoveVcon(plw.vcon_allyTeamBarControls[atID])
					SafeRemoveChild(plw.vcon_allyTeamBarControls[atID].main, plw.vcon_allyTeamBarControls[atID].main.parent)
				end
				SafeAddChild(plw.vcon_allyTeamBarControls[atID].main, plw.vcon_allyTeamSummaries.main)
				InsertTopVconChild(plw.vcon_allyTeamBarControls[atID], plw.vcon_allyTeamSummaries)
				SortSingleVcon(plw.vcon_allyTeamBarControls[atID], nil, CompareAllyTeamBarVcons, false, false)
			end
			
		end
	end
	
	PLW_UpdateStateAttritionControl()
end

local function PLW_UpdateStateSpectatorListControl()
	if not plw.vcon_spectatorList then
		return
	end

	local nSpectators = 0
	for id, eID in pairs(spectatorLookup) do
		nSpectators = nSpectators + 1
	end
	if nSpectators > 0 then
		if not plw.vcon_spectatorHeader.main.parent then
			SafeAddChild(plw.vcon_spectatorHeader.main,plw.vcon_spectatorList.main)
			InsertTopVconChild(plw.vcon_spectatorHeader,plw.vcon_spectatorList)
		end
	else
		if plw.vcon_spectatorHeader.main.parent then
			RemoveVcon(plw.vcon_spectatorHeader)
			SafeRemoveChild(plw.vcon_spectatorHeader.main,plw.vcon_spectatorList.main)
		end
	end
	
	for id, eID in pairs(spectatorLookup) do
		local specVCon = plw.vcon_spectatorControls[eID]
		if specVCon and specVCon.parent ~= plw.vcon_spectatorList then
			if specVCon.parent then
				-- TODO remove from ???
			end
			SafeAddChild(plw.vcon_spectatorControls[eID].main,plw.vcon_spectatorList.main)
			InsertBottomVconChild(plw.vcon_spectatorControls[eID],plw.vcon_spectatorList)
			SortSingleVcon(plw.vcon_spectatorControls[eID], nil, CompareSpectatorVcons, true, true)
		end
	end
	
end


-- configures main panels and other stuff that doesn't move
local function PLW_ConfigureStaticControls()

	PLW_CalculateDimensions()
	
	if plw.windowPlayerlist then 
		plw.windowPlayerlist:SetPos(0, 55, plw_conf.x_window_width + 40, 160)
		plw.windowPlayerlist.minWidth = plw_conf.x_window_width + 40
		plw.windowPlayerlist.maxWidth = plw_conf.x_window_width + 40
		plw.windowPlayerlist.minHeight = 160
		--SafeAddChild(plw.windowPlayerlist, screen0)
	end
	
	if plw.contentHolder then
		plw.windowPlayerlist.color = {1, 1, 1, options.plw_backgroundOpacity.value}
	end
	
	if plw.vcon_scrollPanel.main then
		
		local playerHeaderHeight = plw_conf.plw_headerTextHeight + plw_conf.playerbar_image_height
		local specHeaderHeight = plw_conf.plw_headerTextHeight + plw_conf.plw_y_buffer
		
		if plw.vcon_playerList.main then
			plw.vcon_playerList.main:SetPos(0,plw_conf.plw_y_buffer,plw_conf.x_window_width,0)
			SafeAddChild(plw.vcon_playerList.main, plw.vcon_scrollPanel.main)
			InsertBottomVconChild(plw.vcon_playerList,plw.vcon_scrollPanel)
			if plw_conf.sectionheader_display then
				--if plw.vcon_playerHeader.main then plw.vcon_playerHeader.main:Dispose() end
				local phmain = plw.vcon_playerHeader.main
				local phtitle = plw.vcon_playerHeader.subcon.title
				local aa = plw.vcon_playerHeader.subcon.aIcon
				local dd = plw.vcon_playerHeader.subcon.dIcon
				local mm = plw.vcon_playerHeader.subcon.mIcon
				local ee = plw.vcon_playerHeader.subcon.eIcon
				local cc = plw.vcon_playerHeader.subcon.cpuIcon
				local pp = plw.vcon_playerHeader.subcon.pingIcon
				if phmain and phtitle then 
					phmain:SetPos(0,0,plw_conf.x_window_width,playerHeaderHeight)
					phtitle:SetPos(plw_conf.sectionheader_offset,0,plw_conf.x_name_width,headerHeight)
					phtitle:SetCaption("Players")
					SafeAddChild(phtitle,phmain)
					SafeAddChild(phmain, plw.vcon_playerList.main)
				end
				if aa then 
					SafeAddChild(aa, phmain)
					if options.plw_show_netWorth.value ~= 'disable' then
						aa:Show()
						aa:SetPos(plw_conf.x_mobile_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
						if options.plw_show_netWorth.value ~= 'sum' then
							aa.tooltip = "Total army value"
						else
							aa.tooltip = "Total army and defence value"
						end
					else
						--aa:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
						aa:Hide()
					end
					aa.file = "LuaUI/Images/commands/Bold/attack.png"
					
					function aa:HitTest(x,y) return self end
					-- aa.OnMouseDown = {function(self, x, y, mouse) Spring.Echo("Bung") end}
					-- aa.OnMouseUp = {function(self, x, y, mouse) Spring.Echo("Pung") end}
					-- aa.OnMouseMove = {function(self, x, y, mouse) Spring.Echo("Fung") end}
					--aa.OnClick = {function(self, x, y, mouse) Spring.Echo("Bung") end}
					
					aa:Invalidate()
				end
				if dd then 
					SafeAddChild(dd, phmain)
					if options.plw_show_netWorth.value == 'all' then
						dd:Show()
						dd:SetPos(plw_conf.x_defence_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
						dd.file = "LuaUI/Images/commands/Bold/guard.png"
						dd.tooltip = "Total defence value"
					else
						--dd:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
						dd:Hide()
					end
					function dd:HitTest(x,y) return self end
					dd:Invalidate()
				end
				if mm then 
					SafeAddChild(mm, phmain)
					if true then
						mm:Show()
						mm:SetPos(plw_conf.x_metal_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
					else
						mm:Hide()
						--mm:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
					end
					if options.plw_show_resourceStatus.value then
						mm.tooltip = "Metal income and storage"
					else
						mm.tooltip = "Metal storage"
					end
					
					function mm:HitTest(x,y) return self end
					mm.file = "LuaUI/Images/metalplus.png"
					mm:Invalidate()
				end
				if ee then 
					SafeAddChild(ee, phmain)
					if true then
						ee:Show()
						ee:SetPos(plw_conf.x_energy_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
					else
						ee:Hide()
						--ee:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
					end
					if options.plw_show_resourceStatus.value then
						ee.tooltip = "Energy income and storage"
					else
						ee.tooltip = "Energy storage"
					end
					function ee:HitTest(x,y) return self end
					ee.file = "LuaUI/Images/energyplus.png"
					ee:Invalidate()
				end
				if cc then 
					SafeAddChild(cc, phmain)
					cc.file = "LuaUI/Images/playerlist/cpu.png"
					if options.plw_cpuPlayerDisp.value == 'text' then
						cc:Show()
						cc:SetPos(plw_conf.x_cpu_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
					else
						cc:Hide()
						--cc:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
					end
					cc.tooltip = "CPU usage"
					function cc:HitTest(x,y) return self end
					cc:Invalidate()
				end
				if pp then 
					SafeAddChild(pp, phmain)
					pp.file = "LuaUI/Images/playerlist/ping.png"
					if options.plw_pingPlayerDisp.value == 'text' then
						pp:Show()
						pp:SetPos(plw_conf.x_ping_icon,plw_conf.plw_headerTextHeight,plw_conf.header_icon_width,plw_conf.header_icon_height)
					else
						pp:Hide()
						--pp:SetPos(-100,-100,plw_conf.header_icon_width,plw_conf.header_icon_height)
					end
					pp.tooltip = "Ping time"
					function pp:HitTest(x,y) return self end
					pp:Invalidate()
				end
				InsertTopVconChild(plw.vcon_playerHeader,plw.vcon_playerList)
			end
			if plw.vcon_allyTeamSummaries.main then
				if options.plw_allyteamBarLoc.value == 'above' and drawTeamnames then
					plw.vcon_allyTeamSummaries.main:SetPos(0,plw_conf.plw_y_buffer,plw_conf.x_window_width,0)
					SafeAddChild(plw.vcon_allyTeamSummaries.main, plw.vcon_playerList.main)
					InsertBottomVconChild(plw.vcon_allyTeamSummaries,plw.vcon_playerList)
					if plw.vcon_allyTeamSummaries.lastChild ~= plw.vcon_allyTeamSummariesSep then
						plw.vcon_allyTeamSummariesSep.main:SetPos(0,plw_conf.plw_y_buffer,plw_conf.x_window_width,10)
						SafeAddChild(plw.vcon_allyTeamSummariesSep.main, plw.vcon_allyTeamSummaries.main)
						InsertBottomVconChild(plw.vcon_allyTeamSummariesSep,plw.vcon_allyTeamSummaries)
						SafeAddChild(plw.vcon_allyTeamSummariesSep.subcon.line,plw.vcon_allyTeamSummariesSep.main)
						plw.vcon_allyTeamSummariesSep.subcon.line:SetPos(plw_conf.linebuffer,0,plw_conf.x_window_width - 2*plw_conf.linebuffer,1)
					end
				elseif plw.vcon_allyTeamSummaries.parent then
					RemoveVcon(plw.vcon_allyTeamSummaries)
					SafeRemoveChild(plw.vcon_allyTeamSummaries.main, plw.vcon_playerList.main)
				end
			end
		end
		
		if options.plw_showAttrition.value and enableAttrition then
			local count = 0
			local id1 = -1
			local id2 = -1
			for atID, _ in pairs(allyTeamEntities) do
				if count == 0 then
					id1 = atID
				end
				if count == 1 then
					id2 = atID
				end
				count = count + 1
			end
			
			if id1 >= 0 and id2 >= 0 then
				if CompareAllyTeams(id1, id2) then
					plw.vcon_attrition.options.left = id2
					plw.vcon_attrition.options.right = id1
				else
					plw.vcon_attrition.options.left = id1
					plw.vcon_attrition.options.right = id2
				end
				plw.vcon_attrition.main:SetPos(0,0,plw_conf.x_window_width,plw_conf.playerbar_height*3.5)
				SafeAddChild(plw.vcon_attrition.main, plw.vcon_scrollPanel.main)
				InsertBottomVconChild(plw.vcon_attrition,plw.vcon_scrollPanel)
				
				SafeAddChild(plw.vcon_attrition.subcon.line,plw.vcon_attrition.main)
				plw.vcon_attrition.subcon.line:SetPos(plw_conf.linebuffer,0,plw_conf.x_window_width - 2*plw_conf.linebuffer,1)
				
				plw.vcon_attrition.subcon.name1.align = 'right'
				SafeAddChild(plw.vcon_attrition.subcon.name1,plw.vcon_attrition.main)
				plw.vcon_attrition.subcon.name1:SetPos(0,plw_conf.playerbar_height - 4,plw_attrition_namew,playerbar_text_height)
				
				SafeAddChild(plw.vcon_attrition.subcon.name2,plw.vcon_attrition.main)
				plw.vcon_attrition.subcon.name2:SetPos(plw_conf.x_window_width - plw_attrition_namew,plw_conf.playerbar_height - 4,plw_attrition_namew,playerbar_text_height)
				
				plw.vcon_attrition.subcon.dest1.align = 'right'
				SafeAddChild(plw.vcon_attrition.subcon.dest1,plw.vcon_attrition.main)
				plw.vcon_attrition.subcon.dest1:SetPos(0,plw_conf.playerbar_height*2,plw_attrition_namew,playerbar_text_height)
				function plw.vcon_attrition.subcon.dest1:HitTest(x,y) return self end
				
				SafeAddChild(plw.vcon_attrition.subcon.dest2,plw.vcon_attrition.main)
				plw.vcon_attrition.subcon.dest2:SetPos(plw_conf.x_window_width - plw_attrition_namew,plw_conf.playerbar_height*2,plw_attrition_namew,plw_conf.playerbar_text_height)
				function plw.vcon_attrition.subcon.dest2:HitTest(x,y) return self end
				
				plw.vcon_attrition.subcon.ratioT.align = 'center'
				plw.vcon_attrition.subcon.ratioT:SetPos(plw_conf.x_window_width/2 - plw_conf.attition_barwidth/2,plw_conf.playerbar_height*1.25,plw_conf.attition_barwidth,plw_conf.playerbar_text_height*1.5)
				--plw.vcon_attrition.subcon.bar:SetValue(50)
				--plw.vcon_attrition.subcon.bar:SetColor{0,1,0,1}
				function plw.vcon_attrition.subcon.ratioT:HitTest(x,y) return self end
				SafeAddChild(plw.vcon_attrition.subcon.ratioT,plw.vcon_attrition.main)
			end
		end
		
		if enableAttrition and (not plw_attritionButton.parent) then
			SafeAddChild(plw_attritionButton,plw.contentHolder)
		end
		if not enableAttrition and plw_attritionButton.parent then
			SafeRemoveChild(plw_attritionButton,plw.contentHolder)
		end
		
		
		if plw.vcon_spectatorList.main and options.plw_showSpecs.value then
			plw.vcon_spectatorList.main:SetPos(0,0,plw_conf.x_window_width,0)
			SafeAddChild(plw.vcon_spectatorList.main, plw.vcon_scrollPanel.main)
			InsertBottomVconChild(plw.vcon_spectatorList,plw.vcon_scrollPanel)
			if plw_conf.sectionheader_display then
				--if plw.vcon_spectatorHeader.main then plw.vcon_spectatorHeader.main:Dispose() end
				plw.vcon_spectatorHeader.main:SetPos(0,0,plw_conf.x_window_width,specHeaderHeight)
				plw.vcon_spectatorHeader.subcon.title:SetPos(plw_conf.sectionheader_offset,0,plw_conf.x_name_width,headerHeight)
				plw.vcon_spectatorHeader.subcon.title:SetCaption("Spectators")
				SafeAddChild(plw.vcon_spectatorHeader.subcon.title,plw.vcon_spectatorHeader.main)
				-- SafeAddChild(plw.vcon_spectatorHeader.main,plw.vcon_spectatorList.main)
				-- InsertTopVconChild(plw.vcon_spectatorHeader,plw.vcon_spectatorList)
			end
			
		end
	end

	PLW_UpdateStatePlayerListControl()
	PLW_UpdateStateSpectatorListControl()
	
	PLW_UpdateVisibility()
end

-- creates main panels and other stuff that isn't dynamic
local function PLW_CreateStaticControls()
	
	PLW_CalculateDimensions()
	
	if plw.windowPlayerlist then
		plw.windowPlayerlist:Dispose()
	end
	
	plw.windowPlayerlist = Window:New{autosize = false, dockable = false, draggable = options.plw_windowDraggable.value, resizable = false, tweakDraggable = true, disableChildrenHitTest = false, tweakResizable = true, padding = {0, 0, 0, 0},
	}

	if plw.contentHolder then
		plw.contentHolder:Dispose()
	end
	
	plw.contentHolder = Panel:New{autosize = false, classname = options.plw_fancySkinning.value, x = 0, y = 0, right = 0, bottom = 0, padding = {0, 0, 0, 0}, disableChildrenHitTest = false, parent = plw.windowPlayerlist}
	
	plw.exitButton = Button:New{height=25;width=50;right=10;bottom=10;caption="Exit";OnClick = {function() PLW_Toggle() end}; parent = plw.contentHolder}
	
	local opt_tooltip = "Click on players' names to give units, join squads, etc.\nClick on allies' resource bars to give resources\nClick here to open options (simple settings must be disabled)"
	
	plw.optionButton = Button:New{height=25;width=25;x=10;bottom=10;caption="?";tooltip = opt_tooltip;OnClick = {
		function() 
			WG.crude.OpenPath("Settings/HUD Panels/Dynamic Player Lists")
			WG.crude.ShowMenu()
			end
		}; parent = plw.contentHolder 
	}
	
	plw_spectatorButton = Button:New{height=25;width=25;x=10+25+5;bottom=10;padding = {2, 2, 2, 2};margin = {0,0,0,0};caption="";tooltip = "Click to toggle spectator display";OnClick = {
		function() 
			WG.SetWidgetOption("Chili Dynamic Player List",'Settings/HUD Panels/Dynamic Player Lists/Window List/Spectator Display Options',"plw_showSpecs",not options.plw_showSpecs.value)
			end
		};
		children = {
			Chili.Image:New{
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				file = "LuaUI/Images/map/fow.png",
			} or nil
		},
		parent = plw.contentHolder 
	}
	
	plw_attritionButton = Button:New{height=25;width=25;x=10+25+5+25+5;bottom=10;padding = {2, 2, 2, 2};margin = {0,0,0,0};caption="";tooltip = "Click to toggle attrition counter (2 teams only)";OnClick = {
		function() 
			WG.SetWidgetOption("Chili Dynamic Player List",'Settings/HUD Panels/Dynamic Player Lists/Window List/Attrition Display Options',"plw_showAttrition",not options.plw_showAttrition.value)
			end
		};
		children = {
			Chili.Image:New{
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
				file = "LuaUI/Images/defense_ranges/defense_colors.png",
			} or nil
		},
	}
	
	if DEBUG then
		plw.debugButton = Button:New{
			height=25;
			width=50;
			right=70;
			bottom=10;
			caption="DEBUG",
			OnClick = {
				function() 
					Spring.Echo("iAmSpec: "..tostring(iAmSpec))
					Spring.Echo("myTeam: "..myTeam)
					Spring.Echo("myAllyTeam: "..myAllyTeam)
				
					for eID, data in pairs(playerEntities) do
						if not data.isAI then
							--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
							if playerEntities[eID].active then act = "true" else act = "false" end
							Spring.Echo("Playerlist Window Debug: "..data.name.." (Player) active:"..act.." playerID:"..data.playerID.." teamID:"..data.teamID.." elo:"..data.elo.." allyTeamID:"..data.allyTeamID)
						end
					end
					
					for eID, data in pairs(spectatorEntities) do
							--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(data.playerID)
							Spring.Echo("Playerlist Window Debug: "..data.name.." (Spectator)".." playerID:"..data.playerID.." teamID:"..data.teamID)
					end
					
					for tID, data in pairs(teamEntities) do
						Spring.Echo("Playerlist Window Debug: Team "..tID.." has ")
						Spring.Echo(" elo:"..tostring(data.elo).." resigned:"..tostring(data.resigned).." players:")
						if data.isAI then
							Spring.Echo(playerEntities[aiLookup[tID]].name)
						else
							for eID, _ in pairs(data.memberPEIDs) do
								Spring.Echo(playerEntities[eID].name)
							end
						end
					end
					
					for atID, data in pairs(allyTeamEntities) do
						Spring.Echo("Playerlist Window Debug: AllyTeam "..atID.." has name "..data.name.." elo: "..tostring(data.elo).." and players:")
						for tID, _ in pairs(data.memberTEIDs) do
							if teamEntities[tID].isAI then
								Spring.Echo(playerEntities[aiLookup[tID]].name)
							else
								for eID, _ in pairs(teamEntities[tID].memberPEIDs) do
									Spring.Echo(playerEntities[eID].name)
								end
							end
	
						end
					end
				end
			};
			parent = plw.contentHolder;
		}
		--SafeAddChild(plw.contentHolder,plw.debugButton)
	end
	
	local scr = ScrollPanel:New{
		--classname = 'panel',
		x = 10,
		y = 10,
		right = 10,
		bottom = 45,
		padding = {3, 3, 3, 3},
		backgroundColor = {1, 1, 1, 0.5},
		verticalSmartScroll = true,
		disableChildrenHitTest = false,
		parent = plw.contentHolder,
		--children = { plw.vcon_playerList.main, plw.vcon_spectatorList.main }
	}
	
	plw.vcon_scrollPanel = CreateVcon(nil, scr, nil, 0, 0, {})
	
	plw.vcon_scrollPanel.isOuterScrollPanel = true
	
	--if not plw.vcon_allyTeamSummaries then
	plw.vcon_allyTeamSummaries = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, 0, {})
		
	local sepline = Line:New{}
		
	plw.vcon_allyTeamSummariesSep = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {line = sepline}, 0, 0, {})
	
	local sepline2 = Line:New{fontsize = plw_conf.playerbar_text_height}
	local alabel1 = Label:New{fontsize = plw_conf.playerbar_text_height, autosize = false}
	local alabel2 = Label:New{fontsize = plw_conf.playerbar_text_height, autosize = false}
	local mlabel1 = Label:New{fontsize = plw_conf.playerbar_text_height}
	local mlabel2 = Label:New{fontsize = plw_conf.playerbar_text_height}
	local ratiotext = Label:New{fontsize = math.floor(plw_conf.playerbar_text_height*1.5 + 0.5)}
	
	plw.vcon_attrition = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {line = sepline2, name1 = alabel1, name2 = alabel2, dest1 = mlabel1, dest2 = mlabel2, ratioT = ratiotext }, 0, 0, {left = -1, right = -1})
	--end
	
	plw.vcon_playerList = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, plw_conf.plw_y_buffer, {})
	
	plw.vcon_spectatorList= CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, plw_conf.plw_y_buffer, {})
	
	local playTitle = Label:New{padding = {0, 0, 0, 0}, fontsize = plw_conf.plw_headerTextHeight, valign = "top"}
	
	local aa = Image:New{}
	local dd = Image:New{}
	local mm = Image:New{}
	local ee = Image:New{}
	local cc = Image:New{}
	local pp = Image:New{}
	
	plw.vcon_playerHeader = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {title = playTitle, aIcon = aa, dIcon = dd, mIcon = mm, eIcon = ee, cpuIcon = cc, pingIcon = pp}, plw_conf.plw_y_buffer, plw_conf.plw_y_buffer, {})
	
	local specTitle = Label:New{padding = {0, 0, 0, 0}, fontsize = plw_conf.plw_headerTextHeight, valign = "top",tooltip = "test1"}
	
	plw.vcon_spectatorHeader = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, {title = specTitle}, plw_conf.plw_y_buffer, plw_conf.plw_y_buffer, {}) 

	--SafeAddChild(plw_interactionMenu, plw.vcon_scrollPanel.main)
	
	PLW_ConfigureStaticControls()
end

-- updates volatile components of allyteam box
local function PLW_UpdateVolatileAllyTeamControls(allyTeamID)
	if (not allyTeamEntities[allyTeamID]) or (not plw.vcon_allyTeamControls[allyTeamID]) or (not plw.vcon_allyTeamControls[allyTeamID].subcon) then
		return
	end
	
	if allyTeamEntities[allyTeamID].resigned then
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetCaption("")
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:Invalidate()
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetCaption("")
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:Invalidate()
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetCaption("")
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:Invalidate()
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetCaption("")
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:Invalidate()
	else
		if allyTeamEntities[allyTeamID].m_mobiles then
			if options.plw_show_netWorth.value == 'sum' or options.plw_show_netWorth.value == 'army' then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal.tooltip = "Army value: "..FormatMetalStats(allyTeamEntities[allyTeamID].m_mobiles).."\nDefence value: "..FormatMetalStats(allyTeamEntities[allyTeamID].m_defence)
			end
			if options.plw_show_netWorth.value == 'sum' then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetCaption(FormatMetalStats(allyTeamEntities[allyTeamID].m_mobiles+allyTeamEntities[allyTeamID].m_defence))
			else
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetCaption(FormatMetalStats(allyTeamEntities[allyTeamID].m_mobiles))
			end
			--plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:Invalidate()
		end
		if allyTeamEntities[allyTeamID].m_defence then
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetCaption(FormatMetalStats(allyTeamEntities[allyTeamID].m_defence))
			--plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:Invalidate()
		end
		if allyTeamEntities[allyTeamID].m_income then
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetCaption(FormatIncomeStats(allyTeamEntities[allyTeamID].m_income))
			--plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:Invalidate()
		end
		if allyTeamEntities[allyTeamID].e_income then
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetCaption(FormatIncomeStats(allyTeamEntities[allyTeamID].e_income))
			--plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:Invalidate()
		end
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) then
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(0)
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("")
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(0)
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("")
		else
			if allyTeamEntities[allyTeamID].e_curr and allyTeamEntities[allyTeamID].e_stor then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(allyTeamEntities[allyTeamID].e_curr / ((allyTeamEntities[allyTeamID].e_stor > 0) and allyTeamEntities[allyTeamID].e_stor or 10000))
				if Spring.GetGameFrame() > 0 and allyTeamEntities[allyTeamID].e_stor > 0 then
					if allyTeamEntities[allyTeamID].e_curr < 0.1 * allyTeamEntities[allyTeamID].e_stor then
						plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("!")
					else
						plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("")
					end
				else
					plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetCaption("x")
					plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetValue(0)
				end
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar.tooltip = string.format("%.0f", (allyTeamEntities[allyTeamID].e_curr > allyTeamEntities[allyTeamID].e_stor) and allyTeamEntities[allyTeamID].e_stor or allyTeamEntities[allyTeamID].e_curr) .. "/" .. string.format("%.0f", allyTeamEntities[allyTeamID].e_stor)
			end
			
			if allyTeamEntities[allyTeamID].m_curr and allyTeamEntities[allyTeamID].m_stor then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(allyTeamEntities[allyTeamID].m_curr / ((allyTeamEntities[allyTeamID].m_stor > 0) and allyTeamEntities[allyTeamID].m_stor or 10000))
				if allyTeamEntities[allyTeamID].m_stor > 0 then
					if allyTeamEntities[allyTeamID].m_curr > 0.99 * allyTeamEntities[allyTeamID].m_stor then
						--plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetColor{.75,.5,.5,1}
						plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("!")
					else
						--plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetColor{.5,.5,.5,1}
						plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("")
					end
				else
					plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetCaption("x")
					plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetValue(0)
				end
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar.tooltip = string.format("%.0f", (allyTeamEntities[allyTeamID].m_curr > allyTeamEntities[allyTeamID].m_stor) and allyTeamEntities[allyTeamID].m_stor or allyTeamEntities[allyTeamID].m_curr) .. "/" .. string.format("%.0f", allyTeamEntities[allyTeamID].m_stor)
			end
		end
	end
end

-- updates allyteam box
local function PLW_UpdateStateAllyTeamControls(allyTeamID)
	if (not allyTeamEntities[allyTeamID]) or (not plw.vcon_allyTeamControls[allyTeamID]) or (not plw.vcon_allyTeamControls[allyTeamID].subcon) or (not plw.vcon_allyTeamBarControls[allyTeamID]) or (not plw.vcon_allyTeamBarControls[allyTeamID].subcon) then
		return
	end
	
	local namewidth
	
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.leftline:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(-100, -100, 1, 1)
	plw.vcon_allyTeamBarControls[allyTeamID].subcon.rightline:SetPos(-100, -100, 1, 1)
	
	
	if options.plw_allyteamBarLoc.value ~= 'disable' and drawTeamnames then
		-- this allyteam has a summary bar
		plw.vcon_allyTeamBarControls[allyTeamID].subcon.name.caption = allyTeamEntities[allyTeamID].name 
		namewidth = math.max(2, plw.vcon_allyTeamBarControls[allyTeamID].subcon.name.font:GetTextWidth(allyTeamEntities[allyTeamID].name))
		
		local clanicon = nil
		if allyTeamEntities[allyTeamID].clan and allyTeamEntities[allyTeamID].clan ~= "" then 
			clanicon = "LuaUI/Configs/Clans/" .. clan ..".png"
		end
		
		local ccrLineEnd = plw_conf.x_name_begin - plw_conf.linebuffer
		--local rightlinestart = plw_conf.x_name_begin + plw_conf.x_name_offset + namewidth + plw_conf.linebuffer
		local pingLineStart = plw_conf.x_cpuping_begin + plw_conf.linebuffer
		local afterNameLineStart = plw_conf.x_name_begin + plw_conf.x_name_offset + namewidth + plw_conf.linebuffer
		local afterNameLineEnd = plw_conf.x_resourcestate_begin - plw_conf.linebuffer
		if clanicon then 
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.clan.file = clanicon 
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.clan:Invalidate()
			ccrLineEnd = plw_conf.x_name_begin - plw_conf.x_icon_clan_width - plw_conf.linebuffer
		end
		
		if options.plw_allyteamBarLoc.value == 'with' then -- only draw lines if summary bars are inline
			if options.plw_showClan.value or options.plw_showCountry.value or options.plw_showRank.value then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.leftline:SetPos(plw_conf.linebuffer, plw_conf.playerbar_text_height * 0.25, ccrLineEnd - plw_conf.linebuffer, 1)
			end
			if allyTeamEntities[allyTeamID].drawTeamEcon and (iAmSpec or myAllyTeam == allyTeamID) then 
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(afterNameLineStart, plw_conf.playerbar_text_height * 0.25, afterNameLineEnd - afterNameLineStart, 1)
			
				if options.plw_cpuPlayerDisp.value ~= 'disable' or options.plw_pingPlayerDisp.value ~= 'disable' then
					plw.vcon_allyTeamBarControls[allyTeamID].subcon.rightline:SetPos(pingLineStart, plw_conf.playerbar_text_height * 0.25, plw_conf.x_window_width - pingLineStart - (plw_conf.linebuffer * 2), 1)
				end
			else
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.rightline:SetPos(-100, -100, 1, 1)
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.midline:SetPos(afterNameLineStart, plw_conf.playerbar_text_height * 0.25, plw_conf.x_window_width - afterNameLineStart - (plw_conf.linebuffer * 2), 1)
			end
		end
		
		local c1 = allyTeamEntities[allyTeamID].ateamcolor.r or 1
		local c2 = allyTeamEntities[allyTeamID].ateamcolor.g or 1
		local c3 = allyTeamEntities[allyTeamID].ateamcolor.b or 1
		
		local mincol = 1.2
		local mult = 1
		if c1 + c2 + c3 < mincol then
			mult = (3 - mincol) / (3 - c1 - c2 - c3)
		end
		
		if options.plw_allyteamBarLoc.value == 'above' then
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.name.font:SetColor{1-(1-c1)*mult*1.0,1-(1-c2)*mult*1.0,1-(1-c3)*mult*1.0,1}
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal.font:SetColor{1-(1-c1)*mult*0.6,1-(1-c2)*mult*0.6,1-(1-c3)*mult*0.6,1}
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal.font:SetColor{1-(1-c1)*mult*0.6,1-(1-c2)*mult*0.6,1-(1-c3)*mult*0.6,1}
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc.font:SetColor{1-(1-c1)*mult*0.6,1-(1-c2)*mult*0.6,1-(1-c3)*mult*0.6,1}
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc.font:SetColor{1-(1-c1)*mult*0.6,1-(1-c2)*mult*0.6,1-(1-c3)*mult*0.6,1}
		else
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.name.font:SetColor{1,1,1,1}
		end
		
		if allyTeamEntities[allyTeamID].drawTeamEcon and (iAmSpec or myAllyTeam == allyTeamID) then 
			
			if options.plw_show_netWorth.value ~= 'disable' then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_mobiles_offset, plw_conf.playerbar_text_y, plw_conf.x_m_mobiles_width, plw_conf.playerbar_text_height)
			end
			if options.plw_show_netWorth.value == 'all' then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_defense_offset, plw_conf.playerbar_text_y, plw_conf.x_m_defense_width, plw_conf.playerbar_text_height)
			end
			
			if options.plw_show_resourceStatus.value then
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_income_offset, plw_conf.playerbar_text_y, plw_conf.x_m_income_width, plw_conf.playerbar_text_height)
				plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_income_offset, plw_conf.playerbar_text_y, plw_conf.x_e_income_width, plw_conf.playerbar_text_height)
			end
			
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
			plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
		end
		
		if options.plw_allyteamBarLoc.value == 'with' and plw.vcon_allyTeamBarControls[allyTeamID].parent ~= plw.vcon_allyTeamControls[allyTeamID] then
			if plw.vcon_allyTeamBarControls[allyTeamID].parent then
				RemoveVcon(plw.vcon_allyTeamBarControls[allyTeamID])
				SafeRemoveChild(plw.vcon_allyTeamBarControls[allyTeamID].main, plw.vcon_allyTeamBarControls[allyTeamID].main.parent)
			end
			SafeAddChild(plw.vcon_allyTeamBarControls[allyTeamID].main,plw.vcon_allyTeamControls[allyTeamID].main)
			InsertTopVconChild(plw.vcon_allyTeamBarControls[allyTeamID], plw.vcon_allyTeamControls[allyTeamID])
		end
	else
		-- not drawing any summary bars
		if plw.vcon_allyTeamBarControls[allyTeamID].parent then
			SafeRemoveChild(plw.vcon_allyTeamBarControls[allyTeamID].main,plw.vcon_allyTeamBarControls[allyTeamID].parent.main)
			RemoveVcon(plw.vcon_allyTeamBarControls[allyTeamID])
		end
	end
	
	for tID, _ in pairs(allyTeamEntities[allyTeamID].memberTEIDs) do
		local nPlayers = 0
		for eID, _ in pairs(teamEntities[tID].memberPEIDs) do
			nPlayers = nPlayers + 1
		end
		local teamVCon = plw.vcon_teamControls[tID]
		
		if nPlayers == 0 and teamVCon and teamVCon.parent then
			SafeRemoveChild(teamVCon.main,teamVCon.parent.main)
			RemoveVcon(teamVCon)
			--teamVCon.main:SetPos(-2*plw_conf.x_window_width, teamVCon.main.y, teamVCon.main.width, teamVCon.main.height)			
			if plw.vcon_allyTeamControls[allyTeamID].firstChild then SortVcons(plw.vcon_allyTeamControls[allyTeamID].firstChild,CompareTeamVcons,false) end
		end
		
		if teamVCon and teamVCon.parent ~= plw.vcon_allyTeamControls[allyTeamID] then
			if teamVCon.parent then
				local oldparent = teamVCon.parent
				RemoveVcon(teamVCon)
				SafeRemoveChild(teamVCon.main,oldparent.main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,CompareTeamVcons,false) end
			end
			if nPlayers > 0 then
				SafeAddChild(teamVCon.main,plw.vcon_allyTeamControls[allyTeamID].main)
				InsertBottomVconChild(teamVCon, plw.vcon_allyTeamControls[allyTeamID])
				SortSingleVcon(teamVCon, nil, CompareTeamVcons, true, true)
			end
		end
	end
	
	-- try shifting this allyteam up and down
	SortSingleVcon(plw.vcon_allyTeamControls[allyTeamID], nil, CompareAllyTeamVcons, true, true)
	SortSingleVcon(plw.vcon_allyTeamControls[allyTeamID], nil, CompareAllyTeamVcons, false, true)
	
	-- if summary bars are separate sort them too
	if options.plw_allyteamBarLoc.value == 'above' and drawTeamnames then
		SortSingleVcon(plw.vcon_allyTeamBarControls[allyTeamID], nil, CompareAllyTeamBarVcons, true, false)
		SortSingleVcon(plw.vcon_allyTeamBarControls[allyTeamID], nil, CompareAllyTeamBarVcons, false, false)
	end
	
	PLW_UpdateVolatileAllyTeamControls(allyTeamID)
end


-- configures allyteam box
local function PLW_ConfigureAllyTeamControls(allyTeamID)
	if plw.vcon_allyTeamControls[allyTeamID] then
		local main = plw.vcon_allyTeamControls[allyTeamID].main
		
		if main then main:SetPos(0,0,plw_conf.x_window_width,0) end
	end
	
	if plw.vcon_allyTeamBarControls[allyTeamID] then
		local barMain = plw.vcon_allyTeamBarControls[allyTeamID].main
		local name = plw.vcon_allyTeamBarControls[allyTeamID].subcon.name
		local clan = plw.vcon_allyTeamBarControls[allyTeamID].subcon.clan
		local playerCount = plw.vcon_allyTeamBarControls[allyTeamID].subcon.playerCount
		local status = plw.vcon_allyTeamBarControls[allyTeamID].subcon.status
		local rightline = plw.vcon_allyTeamBarControls[allyTeamID].subcon.rightline
		local midline = plw.vcon_allyTeamBarControls[allyTeamID].subcon.midline
		local leftline = plw.vcon_allyTeamBarControls[allyTeamID].subcon.leftline
		local aVal = plw.vcon_allyTeamBarControls[allyTeamID].subcon.aVal
		local dVal = plw.vcon_allyTeamBarControls[allyTeamID].subcon.dVal
		local mInc = plw.vcon_allyTeamBarControls[allyTeamID].subcon.mInc
		local eInc = plw.vcon_allyTeamBarControls[allyTeamID].subcon.eInc
		local mBar = plw.vcon_allyTeamBarControls[allyTeamID].subcon.mBar
		local eBar = plw.vcon_allyTeamBarControls[allyTeamID].subcon.eBar
		
		function aVal:HitTest(x,y) return self end
		
		if barMain then barMain:SetPos(0, 0, plw_conf.x_window_width, plw_conf.playerbar_height + 3) end
		if name then 
			name:SetPos(plw_conf.x_name_begin + plw_conf.x_name_offset, plw_conf.playerbar_text_y, plw_conf.x_name_width, plw_conf.playerbar_text_height)
			name.font.size = plw_conf.playerbar_text_height
			name:SetCaption("ERROR")
			SafeAddChild(name,barMain)
		end
		if clan then
			clan:SetPos(plw_conf.x_name_begin - plw_conf.x_icon_clan_width - 5, 0, plw_conf.x_icon_clan_width, plw_conf.playerbar_image_height);
			SafeAddChild(clan, barMain)
		end
		if rightline then
			rightline.x = plw_conf.x_cpuping_begin + plw_conf.linebuffer
			rightline.y = plw_conf.playerbar_text_height * 0.25
			rightline.width = plw_conf.x_window_width - plw_conf.x_cpuping_begin - (plw_conf.linebuffer * 2)
			SafeAddChild(rightline, barMain)
		end
		if leftline then
			leftline.x = plw_conf.linebuffer
			leftline.y = plw_conf.playerbar_text_height * 0.25
			leftline.width = plw_conf.x_name_begin - (plw_conf.linebuffer * 2)
			SafeAddChild(leftline, barMain)
		end
		if midline then
			midline.x = plw_conf.linebuffer
			midline.y = plw_conf.playerbar_text_height * 0.25
			midline.width = plw_conf.x_name_begin - (plw_conf.linebuffer * 2)
			SafeAddChild(midline, barMain)
		end
		if aVal then 
			aVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_mobiles_offset, plw_conf.playerbar_text_y, plw_conf.x_m_mobiles_width, plw_conf.playerbar_text_height)
			aVal.font.size = plw_conf.playerbar_text_height
			if options.plw_dataTextColor.value == 'player' then aVal.font:SetColor{1,1,1,1}
			else aVal.font:SetColor{1,0.7,0.7,1} end
			aVal.align = 'right'
			aVal:SetCaption("E")
			SafeAddChild(aVal,barMain)
		end
		if dVal then 
			dVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_defense_offset, plw_conf.playerbar_text_y, plw_conf.x_m_defense_width, plw_conf.playerbar_text_height)
			dVal.font.size = plw_conf.playerbar_text_height
			if options.plw_dataTextColor.value == 'player' then dVal.font:SetColor{1,1,1,1}
			else dVal.font:SetColor{0.7,0.7,1,1} end
			
			dVal.align = 'right'
			dVal:SetCaption("E")
			SafeAddChild(dVal,barMain)
		end
		if mInc then 
			mInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_income_offset, plw_conf.playerbar_text_y, plw_conf.x_m_income_width, plw_conf.playerbar_text_height)
			mInc.font.size = plw_conf.playerbar_text_height
			if options.plw_dataTextColor.value == 'player' then mInc.font:SetColor{1,1,1,1}
			else mInc.font:SetColor{0.7,0.7,0.7,1} end
			mInc.align = 'right'
			mInc:SetCaption("E")
			SafeAddChild(mInc,barMain)
		end
		if eInc then 
			eInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_income_offset, plw_conf.playerbar_text_y, plw_conf.x_e_income_width, plw_conf.playerbar_text_height)
			eInc.font.size = plw_conf.playerbar_text_height
			if options.plw_dataTextColor.value == 'player' then eInc.font:SetColor{1,1,1,1}
			else eInc.font:SetColor{1,1,0.5,1} end
			eInc.align = 'right'
			eInc:SetCaption("E")
			SafeAddChild(eInc,barMain)
		end
		if mBar then
			mBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
			mBar:SetColor{.7,.7,.7,1}
			mBar.font:SetColor{1,.5,.5,1}
			mBar:SetMinMax(0,1)
			function mBar:HitTest(x,y) return self end
			SafeAddChild(mBar,barMain)
		end
		if eBar then
			eBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
			eBar:SetColor{1,1,0.5,1}
			eBar.font:SetColor{1,.5,.5,1}
			eBar:SetMinMax(0,1)
			function eBar:HitTest(x,y) return self end
			SafeAddChild(eBar,barMain)
		end
	end
	
	PLW_UpdateStateAllyTeamControls(allyTeamID)
end

-- creates allyteam box
local function PLW_CreateAllyTeamControls(allyTeamID)
	local mainControl = ""
	if options.plw_allyteamBoxes.value then
		mainControl = Panel:New{padding = {0,0,0,0},color = {0, 0, 0, 0}}
		
		plw.vcon_allyTeamControls[allyTeamID] = CreateVcon(allyTeamID, mainControl, {}, math.ceil(plw_conf.plw_y_buffer/2), math.ceil(plw_conf.plw_y_buffer/2), {innerVBuf = 5})
	else
		mainControl = Control:New{padding = {0,0,0,0},color = {0, 0, 0, 0}}
		
		plw.vcon_allyTeamControls[allyTeamID] = CreateVcon(allyTeamID, mainControl, {}, math.ceil(plw_conf.plw_y_buffer/2), math.ceil(plw_conf.plw_y_buffer/2), {})
	end

	local barMainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local clanImage = Image:New{}
	local nameLabel = Label:New{autosize = false}
	local playerCountLabel = Label:New{autosize = false}
	local statusImage = Image:New{}
	local leftLine = Line:New{}
	local midLine = Line:New{}
	local rightLine = Line:New{}
	local mArmy = Label:New{autosize = false}
	local mStatic = Label:New{autosize = false}
	local mIncome = Label:New{autosize = false}
	local eIncome = Label:New{autosize = false}
	local metalBar = Chili.Progressbar:New{}
	local energyBar = Chili.Progressbar:New{}
	
	local subcon = {name = nameLabel, clan = clanImage, playerCount = playerCountLabel, status = statusImage, aVal = mArmy, dVal = mStatic, mInc = mIncome, eInc = eIncome, mBar = metalBar, eBar = energyBar, rightline = leftLine, midline = midLine, leftline = rightLine}
	
	plw.vcon_allyTeamBarControls[allyTeamID] = CreateVcon(nil, barMainControl, subcon, 0, 0, {atID = allyTeamID})
	
	PLW_ConfigureAllyTeamControls(allyTeamID)
end



-- updates volatile components of team box
local function PLW_UpdateVolatileTeamControls(teamID)
	if (not teamEntities[teamID]) or (not plw.vcon_teamControls[teamID]) or (not plw.vcon_teamControls[teamID].subcon) then
		return
	end

	if teamEntities[teamID].resigned then
		plw.vcon_teamControls[teamID].subcon.aVal:SetCaption("")
		--plw.vcon_teamControls[teamID].subcon.aVal:Invalidate()
		plw.vcon_teamControls[teamID].subcon.dVal:SetCaption("")
		--plw.vcon_teamControls[teamID].subcon.dVal:Invalidate()
		plw.vcon_teamControls[teamID].subcon.mInc:SetCaption("")
		--plw.vcon_teamControls[teamID].subcon.mInc:Invalidate()
		plw.vcon_teamControls[teamID].subcon.eInc:SetCaption("")
		--plw.vcon_teamControls[teamID].subcon.eInc:Invalidate()
		plw.vcon_teamControls[teamID].subcon.mBar:SetPos(-100, -100, 1,1)
		plw.vcon_teamControls[teamID].subcon.eBar:SetPos(-100, -100, 1,1)
	else
		if teamEntities[teamID].m_mobiles then
			if options.plw_show_netWorth.value == 'sum' or options.plw_show_netWorth.value == 'army' then
				plw.vcon_teamControls[teamID].subcon.aVal.tooltip = "Army value: "..FormatMetalStats(teamEntities[teamID].m_mobiles).."\nDefence value: "..FormatMetalStats(teamEntities[teamID].m_defence)
			end
			if options.plw_show_netWorth.value == 'sum' then
				plw.vcon_teamControls[teamID].subcon.aVal:SetCaption(FormatMetalStats(teamEntities[teamID].m_mobiles+teamEntities[teamID].m_defence))
			else
				plw.vcon_teamControls[teamID].subcon.aVal:SetCaption(FormatMetalStats(teamEntities[teamID].m_mobiles))
			end
			--plw.vcon_teamControls[teamID].subcon.aVal:Invalidate()
		end
		if teamEntities[teamID].m_defence then
			plw.vcon_teamControls[teamID].subcon.dVal:SetCaption(FormatMetalStats(teamEntities[teamID].m_defence))
			--plw.vcon_teamControls[teamID].subcon.dVal:Invalidate()
		end
		if teamEntities[teamID].m_income then
			plw.vcon_teamControls[teamID].subcon.mInc:SetCaption(FormatIncomeStats(teamEntities[teamID].m_income))
			--plw.vcon_teamControls[teamID].subcon.mInc:Invalidate()
		end
		if teamEntities[teamID].e_income then
			plw.vcon_teamControls[teamID].subcon.eInc:SetCaption(FormatIncomeStats(teamEntities[teamID].e_income))
			--plw.vcon_teamControls[teamID].subcon.eInc:Invalidate()
		end
		if (Spring.GetGameSeconds() and Spring.GetGameSeconds() < 0.1) then
			plw.vcon_teamControls[teamID].subcon.eBar:SetValue(0)
			plw.vcon_teamControls[teamID].subcon.eBar:SetCaption("")
			plw.vcon_teamControls[teamID].subcon.mBar:SetValue(0)
			plw.vcon_teamControls[teamID].subcon.mBar:SetCaption("")
		else
			if teamEntities[teamID].e_curr and teamEntities[teamID].e_stor then
				plw.vcon_teamControls[teamID].subcon.eBar:SetValue(teamEntities[teamID].e_curr / ((teamEntities[teamID].e_stor > 0) and teamEntities[teamID].e_stor or 1000))
				if teamEntities[teamID].e_stor > 0 then
					if teamEntities[teamID].e_curr < 0.051 * teamEntities[teamID].e_stor then
						plw.vcon_teamControls[teamID].subcon.eBar:SetCaption("!")
					else
						plw.vcon_teamControls[teamID].subcon.eBar:SetCaption("")
					end
				else
					plw.vcon_teamControls[teamID].subcon.eBar:SetCaption("x")
					plw.vcon_teamControls[teamID].subcon.eBar:SetValue(0)
				end
				
				local ttip = string.format("%.0f", (teamEntities[teamID].e_curr > teamEntities[teamID].e_stor) and teamEntities[teamID].e_stor or teamEntities[teamID].e_curr) .. "/" .. string.format("%.0f", teamEntities[teamID].e_stor)
				if not iAmSpec and teamEntities[teamID].allyTeamID == myAllyTeam and teamID ~= myTeam then
					ttip = (ttip or "") .. "\nClick to give 100 energy\nCtrl = 20, Shift = 500, Alt = All"
				end 
				plw.vcon_teamControls[teamID].subcon.eBarB.tooltip  = ttip
				plw.vcon_teamControls[teamID].subcon.eBar.tooltip  = ttip
			end
			if teamEntities[teamID].m_curr and teamEntities[teamID].m_stor then
				plw.vcon_teamControls[teamID].subcon.mBar:SetValue(teamEntities[teamID].m_curr / ((teamEntities[teamID].m_stor > 0) and teamEntities[teamID].m_stor or 1000))
				if teamEntities[teamID].m_stor > 0 then
					if teamEntities[teamID].m_curr > 0.99 * teamEntities[teamID].m_stor then
						plw.vcon_teamControls[teamID].subcon.mBar:SetCaption("!")
						--plw.vcon_teamControls[teamID].subcon.mBar:SetColor{.75,.5,.5,1}
					else
						plw.vcon_teamControls[teamID].subcon.mBar:SetCaption("")
						--plw.vcon_teamControls[teamID].subcon.mBar:SetColor{.5,.5,.5,1}
					end
				else
					plw.vcon_teamControls[teamID].subcon.mBar:SetCaption("x")
					plw.vcon_teamControls[teamID].subcon.mBar:SetValue(0)
				end
				local ttip = string.format("%.0f", (teamEntities[teamID].m_curr > teamEntities[teamID].m_stor) and teamEntities[teamID].m_stor or teamEntities[teamID].m_curr) .. "/" .. string.format("%.0f", teamEntities[teamID].m_stor)
				if not iAmSpec and teamEntities[teamID].allyTeamID == myAllyTeam and teamID ~= myTeam then
					ttip = (ttip or "") .. "\nClick to give 100 metal\nCtrl = 20, Shift = 500, Alt = All"
				end 
				plw.vcon_teamControls[teamID].subcon.mBarB.tooltip = ttip
				plw.vcon_teamControls[teamID].subcon.mBar.tooltip = ttip
			end
		end
	end
end

-- updates team box
local function PLW_UpdateStateTeamControls(teamID)
	if (not teamEntities[teamID]) or (not plw.vcon_teamControls[teamID]) or (not plw.vcon_teamControls[teamID].subcon) then
		return
	end
	
	local nPlayers = 0
	if teamEntities[teamID].isAI then
		nPlayers = 1
		local eID = aiLookup[teamID]
		if plw.vcon_playerControls[eID] and plw.vcon_playerControls[eID].parent ~= plw.vcon_teamControls[teamID] then
			if plw.vcon_playerControls[eID].parent then
				local oldparent = plw.vcon_playerControls[eID].parent
				RemoveVcon(plw.vcon_playerControls[eID])
				SafeRemoveChild(plw.vcon_playerControls[eID].main,oldparent.main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,ComparePlayerVcons,false) end
			end
			InsertBottomVconChild(plw.vcon_playerControls[eID], plw.vcon_teamControls[teamID])
			SafeAddChild(plw.vcon_playerControls[eID].main,plw.vcon_teamControls[teamID].main)
			SortSingleVcon(plw.vcon_playerControls[eID], nil, ComparePlayerVcons, true, true)
		end
	else
		for eID, _ in pairs(teamEntities[teamID].memberPEIDs) do
			nPlayers = nPlayers + 1
			if plw.vcon_playerControls[eID] and plw.vcon_playerControls[eID].parent ~= plw.vcon_teamControls[teamID] then
				if plw.vcon_playerControls[eID].parent then
					local oldparent = plw.vcon_playerControls[eID].parent
					RemoveVcon(plw.vcon_playerControls[eID])
					SafeRemoveChild(plw.vcon_playerControls[eID].main,oldparent.main)
					if oldparent.firstChild then SortVcons(oldparent.firstChild,ComparePlayerVcons,false) end
				end
				InsertBottomVconChild(plw.vcon_playerControls[eID], plw.vcon_teamControls[teamID])
				SafeAddChild(plw.vcon_playerControls[eID].main,plw.vcon_teamControls[teamID].main)
				SortSingleVcon(plw.vcon_playerControls[eID], nil, ComparePlayerVcons, true, true)
			end
		end
	end
	
	if plw.vcon_teamControls[teamID] and plw.vcon_teamControls[teamID].subcon.rBar then
		if not teamEntities[teamID].resigned and (iAmSpec or myAllyTeam == teamEntities[teamID].allyTeamID) then
			plw.vcon_teamControls[teamID].subcon.rBar:SetPos(0,(nPlayers - 1) * plw_conf.playerbar_height * 0.5,plw_conf.x_window_width,plw_conf.playerbar_height)
			
			local mBar = plw.vcon_teamControls[teamID].subcon.mBar
			local mBarB = plw.vcon_teamControls[teamID].subcon.mBarB
			local eBar = plw.vcon_teamControls[teamID].subcon.eBar
			local eBarB = plw.vcon_teamControls[teamID].subcon.eBarB
			local aVal = plw.vcon_teamControls[teamID].subcon.aVal
			local dVal = plw.vcon_teamControls[teamID].subcon.dVal
			local mInc = plw.vcon_teamControls[teamID].subcon.mInc
			local eInc = plw.vcon_teamControls[teamID].subcon.eInc
			
			if not iAmSpec and teamEntities[teamID].allyTeamID == myAllyTeam and teamID ~= myTeam then
				mBarB:Show()
				eBarB:Show()
				mBarB:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
				eBarB:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
				function mBar:HitTest(x,y) return nil end
				function eBar:HitTest(x,y) return nil end
			else
				mBarB:SetPos(-100, -100, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
				eBarB:SetPos(-100, -100, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
				mBarB:Hide()
				eBarB:Hide()
				function mBar:HitTest(x,y) return self end
				function eBar:HitTest(x,y) return self end
			end
			
			-- local c1 = select(1,teamEntities[teamID].teamcolor)
			-- local c2 = select(2,teamEntities[teamID].teamcolor)
			-- local c3 = select(3,teamEntities[teamID].teamcolor)
			-- local c4 = select(4,teamEntities[teamID].teamcolor)
			
			local c1 = 1-(1-teamEntities[teamID].teamcolor.r)*0.8
			local c2 = 1-(1-teamEntities[teamID].teamcolor.g)*0.8
			local c3 = 1-(1-teamEntities[teamID].teamcolor.b)*0.8
			local c4 = 1-(1-teamEntities[teamID].teamcolor.a)*0.8
			
			if options.plw_dataTextColor.value == 'category' then aVal.font:SetColor{0.9,0.5,0.5,1}
			elseif options.plw_dataTextColor.value == 'player' then aVal.font:SetColor{c1,c2,c3,c4}
			else aVal.font:SetColor{1,1,1,1} end
			if options.plw_dataTextColor.value == 'category' then dVal.font:SetColor{0.5,0.5,0.9,1}
			elseif options.plw_dataTextColor.value == 'player' then dVal.font:SetColor{c1,c2,c3,c4}
			else dVal.font:SetColor{1,1,1,1} end
			if options.plw_dataTextColor.value == 'category' then mInc.font:SetColor{0.5,0.5,0.5,1}
			elseif options.plw_dataTextColor.value == 'player' then mInc.font:SetColor{c1,c2,c3,c4}
			else mInc.font:SetColor{1,1,1,1} end
			if options.plw_dataTextColor.value == 'category' then eInc.font:SetColor{0.85,0.85,0.6,1}
			elseif options.plw_dataTextColor.value == 'player' then eInc.font:SetColor{c1,c2,c3,c4}
			else eInc.font:SetColor{1,1,1,1} end

		else
			plw.vcon_teamControls[teamID].subcon.rBar:SetPos(0,-500,plw_conf.x_window_width,plw_conf.playerbar_height)
		end
	end
	
	if plw.vcon_teamControls[teamID] and plw.vcon_teamControls[teamID].subcon.line then
		if nPlayers > 1 then
			plw.vcon_teamControls[teamID].subcon.line:Show()
			plw.vcon_teamControls[teamID].subcon.line:SetPos(plw_conf.x_addedline_begin + plw_conf.x_addedline_offset,plw_conf.playerbar_height * 0.15, 1, plw_conf.playerbar_height * (nPlayers - 0.3))
		else
			plw.vcon_teamControls[teamID].subcon.line:SetPos(-100,plw_conf.playerbar_height * 0.15, 1, plw_conf.playerbar_height * 0.7)
			plw.vcon_teamControls[teamID].subcon.line:Hide()
		end		
	end

	-- try shifting this teambox up and down
	SortSingleVcon(plw.vcon_teamControls[teamID], nil, CompareTeamVcons, true, true)
	SortSingleVcon(plw.vcon_teamControls[teamID], nil, CompareTeamVcons, false, true)
	
	PLW_UpdateVolatileTeamControls(teamID)
end

-- configures team box
local function PLW_ConfigureTeamControls(teamID)
	if plw.vcon_teamControls[teamID] then
		local main = plw.vcon_teamControls[teamID].main
		local rBar = plw.vcon_teamControls[teamID].subcon.rBar
		local aVal = plw.vcon_teamControls[teamID].subcon.aVal
		local dVal = plw.vcon_teamControls[teamID].subcon.dVal
		local mInc = plw.vcon_teamControls[teamID].subcon.mInc
		local eInc = plw.vcon_teamControls[teamID].subcon.eInc
		local mBar = plw.vcon_teamControls[teamID].subcon.mBar
		local mBarB = plw.vcon_teamControls[teamID].subcon.mBarB
		local eBar = plw.vcon_teamControls[teamID].subcon.eBar
		local eBarB = plw.vcon_teamControls[teamID].subcon.eBarB
		local gLine = plw.vcon_teamControls[teamID].subcon.line
		
		function aVal:HitTest(x,y) return self end
		
		if main then main:SetPos(0,0,plw_conf.x_window_width,0) end
		if rBar then 
			rBar:SetPos(0,0,plw_conf.x_window_width,plw_conf.playerbar_height)
			SafeAddChild(rBar,main)
		end
		if aVal then 
			SafeAddChild(aVal,rBar)
			if options.plw_show_netWorth.value ~= 'disable' then
				aVal:Show()
				aVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_mobiles_offset, plw_conf.playerbar_text_y, plw_conf.x_m_mobiles_width, plw_conf.playerbar_text_height)
			else
				--aVal:SetPos(-100, -100, plw_conf.x_m_mobiles_width, plw_conf.playerbar_text_height)
				aVal:Hide()
			end
			aVal.font.size = plw_conf.playerbar_text_height
			
			aVal.align = 'right'
			aVal:SetCaption("E")
			
		end
		if dVal then 
			SafeAddChild(dVal,rBar)
			if options.plw_show_netWorth.value == 'all' then
				dVal:Show()
				dVal:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_defense_offset, plw_conf.playerbar_text_y, plw_conf.x_m_defense_width, plw_conf.playerbar_text_height)
			else
				--dVal:SetPos(-100, -100, plw_conf.x_m_defense_width, plw_conf.playerbar_text_height)
				dVal:Hide()
			end
			dVal.font.size = plw_conf.playerbar_text_height
			
			dVal.align = 'right'
			dVal:SetCaption("E")
		end
		if mInc then
			SafeAddChild(mInc,rBar)
			if options.plw_show_resourceStatus.value then
				mInc:Show()
				mInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_income_offset, plw_conf.playerbar_text_y, plw_conf.x_m_income_width, plw_conf.playerbar_text_height)
			else	
				--mInc:SetPos(-100, -100, plw_conf.x_m_income_width, plw_conf.playerbar_text_height)
				mInc:Hide()
			end
			mInc.font.size = plw_conf.playerbar_text_height
			
			mInc.align = 'right'
			mInc:SetCaption("E")
		end
		if eInc then 
			if options.plw_show_resourceStatus.value then
				eInc:Show()
				eInc:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_income_offset, plw_conf.playerbar_text_y, plw_conf.x_e_income_width, plw_conf.playerbar_text_height)
			else
				--eInc:SetPos(-100, -100, plw_conf.x_e_income_width, plw_conf.playerbar_text_height)
				eInc:Hide()
			end
			eInc.font.size = plw_conf.playerbar_text_height
			
			eInc.align = 'right'
			eInc:SetCaption("E")
			SafeAddChild(eInc,rBar)
		end
		if mBar then
			SafeAddChild(mBar,rBar)
			--if options.plw_show_resourceStatus.value then
			if true then
				mBar:Show()
				mBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
			else
				--mBar:SetPos(-100, -100, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
				mBar:Hide()
			end
			mBar:SetColor{.5,.5,.5,1}
			mBar.font:SetColor{1,.5,.5,1}
			mBar:SetMinMax(0,1)
			--function mBar:HitTest(x,y) return self end
		end
		if mBarB then 
			SafeAddChild(mBarB,rBar)
			--if options.plw_show_resourceStatus.value then
			if true then
				mBarB:Show()
				mBarB:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_m_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
			else
				--mBarB:SetPos(-100, -100, plw_conf.x_m_fill_width, plw_conf.playerbar_text_height - 2)
				mBarB:Hide()
			end
			--function mBarB:HitTest(x,y) return self end
			--mBarB.OnMouseDown = {function(self, x, y, mouse) Spring.Echo("Give Metal") end}
			mBarB:SetCaption("")
			mBarB.OnClick = {
				function(self, x, y, mouse) 
					if not iAmSpec then 
						GiveResource(teamID,"metal")
					end
				end}
		end
		if eBar then
			SafeAddChild(eBar,rBar)
			--if options.plw_show_resourceStatus.value then
			if true then
				eBar:Show()
				eBar:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
			else
				--eBar:SetPos(-100, -100, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
				eBar:Hide()
			end
			eBar:SetColor{0.85,0.85,0.6,1}
			eBar.font:SetColor{1,.5,.5,1}
			eBar:SetMinMax(0,1)
			--function eBar:HitTest(x,y) return self end
		end
		if eBarB then 
			SafeAddChild(eBarB,rBar)
			--if options.plw_show_resourceStatus.value then
			if true then
				eBarB:Show()
				eBarB:SetPos(plw_conf.x_resourcestate_begin + plw_conf.x_e_fill_offset, plw_conf.playerbar_text_y + 1, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
			else
				--eBarB:SetPos(-100, -100, plw_conf.x_e_fill_width, plw_conf.playerbar_text_height - 2)
				eBarB:Hide()
			end
			--function eBarB:HitTest(x,y) return self end
			--eBarB.OnMouseDown = {function(self, x, y, mouse) Spring.Echo("Give Metal") end}
			eBarB:SetCaption("")
			eBarB.OnClick = {
				function(self, x, y, mouse) 
					if not iAmSpec then 
						GiveResource(teamID,"energy")
					end
				end}
		end
		if gLine then
			SafeAddChild(gLine,main)
			gLine:Hide()
			--gLine:SetPos(-100,plw_conf.playerbar_height * 0.15, 1, plw_conf.playerbar_height * 0.7)
		end
	end
	
	PLW_UpdateStateTeamControls(teamID)
end

-- creates team box
local function PLW_CreateTeamControls(teamID)
	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local resBar = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	
	local mArmy = Label:New{autosize = false}
	local mStatic = Label:New{autosize = false}
	local mIncome = Label:New{autosize = false}
	local eIncome = Label:New{autosize = false}
	local metalBar = Chili.Progressbar:New{}
	local metalBarButton = Button:New{}
	local energyBar = Chili.Progressbar:New{}
	local energyBarButton = Button:New{}
	local groupLine = Line:New{style = "vertical"}
	
	local subcon = {rBar = resBar, aVal = mArmy, dVal = mStatic, mInc = mIncome, eInc = eIncome, mBar = metalBar, mBarB = metalBarButton, eBar = energyBar, eBarB = energyBarButton, line = groupLine}
	
	plw.vcon_teamControls[teamID] = CreateVcon(teamID, mainControl, subcon, 0, 0, {})
	
	PLW_ConfigureTeamControls(teamID)
end

-- updates player row
local function PLW_UpdateVolatilePlayerControls(eID)
	if (not playerEntities[eID]) or (not plw.vcon_playerControls[eID]) or (not plw.vcon_playerControls[eID].subcon) then
		return
	end
	
	-- TODO other player updates
	local teamStatusCol = {1,0,1,1}
	local teamStatusText = ""
	local statusTooltip = ""
	
	if playerEntities[eID].cpu and playerEntities[eID].ping and playerEntities[eID].teamID then 
		teamStatusCol, teamStatusText, statusTooltip = FormatStatus(playerEntities[eID].active, playerEntities[eID].resigned, playerEntities[eID].ping, playerEntities[eID].cpu, Spring.GetTeamUnitCount(playerEntities[eID].teamID))
		plw.vcon_playerControls[eID].subcon.statusText.font:SetColor(teamStatusCol)
		plw.vcon_playerControls[eID].subcon.statusText:SetCaption(teamStatusText)
		plw.vcon_playerControls[eID].subcon.statusText.tooltip = statusTooltip
		plw.vcon_playerControls[eID].subcon.statusText:Invalidate()
	else
		plw.vcon_playerControls[eID].subcon.statusText.font:SetColor({0,0,0,0})
		plw.vcon_playerControls[eID].subcon.statusText:SetCaption('Q')
		plw.vcon_playerControls[eID].subcon.statusText:Invalidate()
	end
	
	if playerEntities[eID].ping and playerEntities[eID].cpu then
		local pingCol, cpuCol, pingText, cpuTxt = FormatPingCpu(playerEntities[eID].ping,playerEntities[eID].cpu)
		if options.plw_cpuPlayerDisp.value == 'text' then
			plw.vcon_playerControls[eID].subcon.cpuText.font:SetColor(cpuCol)
			plw.vcon_playerControls[eID].subcon.cpuText:SetCaption(cpuTxt)
			plw.vcon_playerControls[eID].subcon.cpuText:Invalidate()
		elseif options.plw_cpuPlayerDisp.value == 'icon' then
			plw.vcon_playerControls[eID].subcon.cpuImage.color = cpuCol
			plw.vcon_playerControls[eID].subcon.cpuImage.tooltip = 'CPU: ' .. cpuTxt
			plw.vcon_playerControls[eID].subcon.cpuImage:Invalidate()
		end
		if options.plw_pingPlayerDisp.value == 'text' then
			plw.vcon_playerControls[eID].subcon.pingText.font:SetColor(pingCol)
			plw.vcon_playerControls[eID].subcon.pingText:SetCaption(pingText)
			plw.vcon_playerControls[eID].subcon.pingText:Invalidate()
		elseif options.plw_pingPlayerDisp.value == 'icon' then
			plw.vcon_playerControls[eID].subcon.pingImage.color = pingCol
			plw.vcon_playerControls[eID].subcon.pingImage.tooltip = 'Ping: ' .. pingText
			plw.vcon_playerControls[eID].subcon.pingImage:Invalidate()
		end
	end
	
	if playerEntities[eID].isLeader then 
		--plw.vcon_playerControls[eID].subcon.country:Show()
	else
		--plw.vcon_playerControls[eID].subcon.country:Hide()
	end
end

local function PLW_UpdateStatePlayerControls(eID)
	if (not playerEntities[eID]) or (not plw.vcon_playerControls[eID]) or (not plw.vcon_playerControls[eID].subcon) then
		return
	end
	
	if playerEntities[eID].name then 
		plw.vcon_playerControls[eID].subcon.name.caption = playerEntities[eID].name 
		local ttip = playerEntities[eID].name.."\n"
		if not iAmSpec and not playerEntities[eID].isAI and playerEntities[eID].playerID ~= myID then
			ttip = (ttip or "") .. "/w <name> to whisper this player\n"
		end
		if not iAmSpec and playerEntities[eID].allyTeamID == myAllyTeam and playerEntities[eID].teamID ~= myTeam then
			ttip = (ttip or "") .. "Ctrl-Click to give units\n"
			if not playerEntities[eID].isAI then
				ttip = (ttip or "") .. "Alt-Click to invite to squad\n"
			end
		end
		--ttip = (ttip or "") .. "Alt-Click to kick this player from your squad\n"
		--ttip = (ttip or "") .. "Alt-Click to leave your squad\n"
		--ttip = (ttip or "") .. "Alt-Click to accept this player's squad invite\n"
		plw.vcon_playerControls[eID].subcon.name.tooltip = ttip
		plw.vcon_playerControls[eID].subcon.name.OnMouseDown = {
			function(self, x, y, mouse) 
				PlayerInteract(eID)
			end}
	end
	if playerEntities[eID].teamcolor then
		if playerEntities[eID].resigned then
			plw.vcon_playerControls[eID].subcon.name.font.color = {0.5,0.5,0.5,1}
		else
			plw.vcon_playerControls[eID].subcon.name.font.color = playerEntities[eID].teamcolor
		end
	end
	plw.vcon_playerControls[eID].subcon.name:Invalidate()
	
	local clanicon, countryicon, rankicon = FormatCCR(playerEntities[eID].clan, playerEntities[eID].faction, playerEntities[eID].country, playerEntities[eID].level, playerEntities[eID].elo, playerEntities[eID].rank)
	if clanicon then 
		plw.vcon_playerControls[eID].subcon.clan.file = clanicon 
		plw.vcon_playerControls[eID].subcon.clan:Invalidate()
	end
	if countryicon then 
		plw.vcon_playerControls[eID].subcon.country.file = countryicon 
		plw.vcon_playerControls[eID].subcon.country:Invalidate()
	end 
	if rankicon then 
		plw.vcon_playerControls[eID].subcon.rank.file = rankicon 
		plw.vcon_playerControls[eID].subcon.rank:Invalidate()
	end
	
	-- try shifting this playerbox up and down
	SortSingleVcon(plw.vcon_playerControls[eID], nil, ComparePlayerVcons, true, true)
	SortSingleVcon(plw.vcon_playerControls[eID], nil, ComparePlayerVcons, false, true)
	
	PLW_UpdateVolatilePlayerControls(eID)
end

-- configures player row
local function PLW_ConfigurePlayerControls(entityID)
	
	if not plw.vcon_playerControls[entityID] or not plw.vcon_playerControls[entityID].subcon then
		return
	end
	
	--if main then main:ClearChildren() else Spring.Echo("ERROR"); return end
	
	local main = plw.vcon_playerControls[entityID].main
	local clan = plw.vcon_playerControls[entityID].subcon.clan
	local country = plw.vcon_playerControls[entityID].subcon.country
	local rank = plw.vcon_playerControls[entityID].subcon.rank
	local name = plw.vcon_playerControls[entityID].subcon.name
	local statusText = plw.vcon_playerControls[entityID].subcon.statusText
	local cpuText = plw.vcon_playerControls[entityID].subcon.cpuText
	local pingText = plw.vcon_playerControls[entityID].subcon.pingText
	local cpuImage = plw.vcon_playerControls[entityID].subcon.cpuImage
	local pingImage = plw.vcon_playerControls[entityID].subcon.pingImage
	
	if main then main:SetPos(0, 0, plw_conf.x_window_width, plw_conf.playerbar_height) end
	if clan then 
		SafeAddChild(clan,main)
		if options.plw_showClan.value then
			clan:Show()
			clan:SetPos(plw_conf.x_ccr_begin + plw_conf.x_icon_clan_offset, 0, plw_conf.x_icon_clan_width, plw_conf.playerbar_image_height)
		else
			clan:SetPos(-100, -100, plw_conf.x_icon_clan_width, plw_conf.playerbar_image_height)
			clan:Hide()
		end
	end
	if country then 
		SafeAddChild(country,main) 
		if options.plw_showCountry.value then
			country:Show()
			country:SetPos(plw_conf.x_ccr_begin + plw_conf.x_icon_country_offset, 0, plw_conf.x_icon_country_width, plw_conf.playerbar_image_height)
		else
			country:SetPos(-100, -100, plw_conf.x_icon_country_width, plw_conf.playerbar_image_height)
			country:Hide()
		end
	end
	if rank then 
		SafeAddChild(rank,main)
		if options.plw_showRank.value then
			rank:Show()
			rank:SetPos(plw_conf.x_ccr_begin + plw_conf.x_icon_rank_offset, 0, plw_conf.x_icon_rank_width, plw_conf.playerbar_image_height) 
		else
			rank:SetPos(-100, -100, plw_conf.x_icon_rank_width, plw_conf.playerbar_image_height)
			rank:Hide()
		end
	end
	if name then 
		SafeAddChild(name,main)
		name:SetPos(plw_conf.x_name_begin + plw_conf.x_name_offset, plw_conf.playerbar_text_y, plw_conf.x_name_width - 10, plw_conf.playerbar_text_height)
		name.font.size = plw_conf.playerbar_text_height
		name:SetCaption("ERROR")
		function name:HitTest(x,y) return self end
		
	end
	if statusText then 
		SafeAddChild(statusText,main)
		statusText:SetPos(plw_conf.x_playerstate_begin + plw_conf.x_playerstate_offset, plw_conf.playerbar_text_y, plw_conf.x_playerstate_width, plw_conf.playerbar_text_height)
		function statusText:HitTest(x,y) return self end
		statusText.font.size = plw_conf.playerbar_text_height
		statusText:SetCaption("ERROR")
	end
	
	if cpuImage and cpuImage.parent == main then SafeRemoveChild(cpuImage,main) end
	if pingImage and pingImage.parent == main then SafeRemoveChild(pingImage,main) end
	if cpuText and cpuText.parent == main then SafeRemoveChild(cpuText,main) end
	if pingText and pingText.parent == main then SafeRemoveChild(pingText,main) end
	
	if cpuText and options.plw_cpuPlayerDisp.value == 'text' then 
		cpuText:SetPos(plw_conf.x_cpuping_begin + plw_conf.x_cpu_offset, plw_conf.playerbar_text_y, plw_conf.x_cpu_width, plw_conf.playerbar_text_height) 
		cpuText.font.size = plw_conf.playerbar_text_height
		cpuText:SetCaption("ERROR")
		SafeAddChild(cpuText,main)
	end
	if pingText and options.plw_pingPlayerDisp.value == 'text' then 
		pingText:SetPos(plw_conf.x_cpuping_begin + plw_conf.x_ping_offset, plw_conf.playerbar_text_y, plw_conf.x_ping_width, plw_conf.playerbar_text_height) 
		pingText.font.size = plw_conf.playerbar_text_height
		pingText:SetCaption("ERROR")
		SafeAddChild(pingText,main)
	end
	if cpuImage and options.plw_cpuPlayerDisp.value == 'icon' then 
		cpuImage:SetPos(plw_conf.x_cpuping_begin + plw_conf.x_cpu_offset, 0, plw_conf.x_cpu_width, plw_conf.playerbar_image_height)
		cpuImage.file = "LuaUI/Images/playerlist/cpu.png"
		function cpuImage:HitTest(x,y) return self end
		cpuImage:Invalidate()
		SafeAddChild(cpuImage,main)
	end
	if pingImage and options.plw_pingPlayerDisp.value == 'icon' then 
		pingImage:SetPos(plw_conf.x_cpuping_begin + plw_conf.x_ping_offset, 0, plw_conf.x_ping_width, plw_conf.playerbar_image_height)
		pingImage.file = "LuaUI/Images/playerlist/ping.png"
		function pingImage:HitTest(x,y) return self end
		pingImage:Invalidate()
		SafeAddChild(pingImage,main)
	end
	
	PLW_UpdateStatePlayerControls(entityID)
end

-- creates player row
local function PLW_CreatePlayerControls(entityID)

	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local clanImage = Image:New{}
	local countryImage = Image:New{}
	local rankImage = Image:New{}
	local nameLabel = Label:New{autosize = false}
	local statusLabel = Label:New{autosize = false}
	local cpuLabel = Label:New{autosize = false, align = "center"}
	local pingLabel = Label:New{autosize = false, align = "center"}
	local cpuIm = Image:New{}
	local pingIm = Image:New{}
	
	local subcon = {name = nameLabel, clan = clanImage, country = countryImage, rank = rankImage, statusText = statusLabel, cpuText = cpuLabel, pingText = pingLabel, cpuImage = cpuIm, pingImage = pingIm}
	
	plw.vcon_playerControls[entityID] = CreateVcon(entityID, mainControl, subcon, 0, 0, {})
	
	PLW_ConfigurePlayerControls(entityID)
	
end

-- updates spectator row
local function PLW_UpdateVolatileSpectatorControls(eID)
	if (not spectatorEntities[eID]) or (not plw.vcon_spectatorControls[eID]) or (not plw.vcon_spectatorControls[eID].subcon) then
		return
	end
	
	if spectatorEntities[eID].ping and spectatorEntities[eID].cpu then
		local pingCol, cpuCol, pingText, cpuTxt = FormatPingCpu(spectatorEntities[eID].ping,spectatorEntities[eID].cpu)
		if options.plw_cpuSpecDisp.value == 'text' then
			plw.vcon_spectatorControls[eID].subcon.cpuText.font:SetColor(cpuCol)
			plw.vcon_spectatorControls[eID].subcon.cpuText:SetCaption(cpuTxt)
			plw.vcon_spectatorControls[eID].subcon.cpuText:Invalidate()
		elseif options.plw_cpuSpecDisp.value == 'icon' then
			plw.vcon_spectatorControls[eID].subcon.cpuImage.color = cpuCol
			plw.vcon_spectatorControls[eID].subcon.cpuImage.tooltip = 'CPU: ' .. cpuTxt
			plw.vcon_spectatorControls[eID].subcon.cpuImage:Invalidate()
		end
		if options.plw_pingSpecDisp.value == 'text' then
			plw.vcon_spectatorControls[eID].subcon.pingText.font:SetColor(pingCol)
			plw.vcon_spectatorControls[eID].subcon.pingText:SetCaption(pingText)
			plw.vcon_spectatorControls[eID].subcon.pingText:Invalidate()
		elseif options.plw_pingSpecDisp.value == 'icon' then
			plw.vcon_spectatorControls[eID].subcon.pingImage.color = pingCol
			plw.vcon_spectatorControls[eID].subcon.pingImage.tooltip = 'Ping: ' .. pingText
			plw.vcon_spectatorControls[eID].subcon.pingImage:Invalidate()
		end
	end
end

local function PLW_UpdateStateSpectatorControls(eID)
	if (not spectatorEntities[eID]) or (not plw.vcon_spectatorControls[eID]) or (not plw.vcon_spectatorControls[eID].subcon) then
		return
	end
	--if spectatorEntities[eID].name then plw.vcon_spectatorControls[eID].subcon.name.caption = spectatorEntities[eID].name end
	if spectatorEntities[eID].name then 
		plw.vcon_spectatorControls[eID].subcon.name:SetCaption(spectatorEntities[eID].name) 
		plw.vcon_spectatorControls[eID].subcon.name.OnMouseDown = {function(self, x, y, mouse) Spring.Echo("Open Spectator "..eID.." Interaction Menu") end}
		--plw.vcon_spectatorControls[eID].subcon.name:Invalidate()
	end
	-- local clanicon, countryicon, rankicon = FormatCCR(spectatorEntities[eID].clan, spectatorEntities[eID].faction, spectatorEntities[eID].country, spectatorEntities[eID].level, spectatorEntities[eID].elo)
	-- if clanicon then 
		-- plw.vcon_spectatorControls[eID].subcon.clan.file = clanicon 
		-- plw.vcon_spectatorControls[eID].subcon.clan:Invalidate()
	-- end
	-- if countryicon then 
		-- plw.vcon_spectatorControls[eID].subcon.country.file = countryicon 
		-- plw.vcon_spectatorControls[eID].subcon.country:Invalidate()
	-- end 
	-- if rankicon then 
		-- Spring.Echo("Setting Spectator Rank Icon")
		-- plw.vcon_spectatorControls[eID].subcon.rank.file = rankicon 
		-- plw.vcon_spectatorControls[eID].subcon.rank:Invalidate()
	-- end

	-- try shifting this specbox up and down
	SortSingleVcon(plw.vcon_spectatorControls[eID], nil, CompareSpectatorVcons, true, true)
	SortSingleVcon(plw.vcon_spectatorControls[eID], nil, CompareSpectatorVcons, false, true)
	
	PLW_UpdateVolatileSpectatorControls(eID)
end

-- configures spectator row
local function PLW_ConfigureSpectatorControls(entityID)
	
	if not plw.vcon_spectatorControls[entityID] or not plw.vcon_spectatorControls[entityID].subcon then
		return
	end
	
	local main = plw.vcon_spectatorControls[entityID].main
	-- local clan = plw.vcon_spectatorControls[entityID].subcon.clan
	-- local country = plw.vcon_spectatorControls[entityID].subcon.country
	-- local rank = plw.vcon_spectatorControls[entityID].subcon.rank
	local name = plw.vcon_spectatorControls[entityID].subcon.name
	local statusText = plw.vcon_spectatorControls[entityID].subcon.statusText
	local cpuText = plw.vcon_spectatorControls[entityID].subcon.cpuText
	local pingText = plw.vcon_spectatorControls[entityID].subcon.pingText
	local cpuImage = plw.vcon_spectatorControls[entityID].subcon.cpuImage
	local pingImage = plw.vcon_spectatorControls[entityID].subcon.pingImage
	
	--if main then main:ClearChildren() else Spring.Echo("ERROR"); return end
	
	if main then main:SetPos(0, 0, plw_conf.x_window_width, plw_conf.playerbar_height) end
	if name then 
		name:SetPos(plw_conf.x_name_spectator_begin + plw_conf.x_name_spectator_offset, plw_conf.playerbar_text_y, plw_conf.x_name_spectator_width - 10, plw_conf.playerbar_text_height)
		name.font.size = plw_conf.playerbar_text_height
		name:SetCaption("ERROR")
		function name:HitTest(x,y) return self end
		SafeAddChild(name,main)
	end
	if statusText then 
		statusText:SetPos(plw_conf.x_playerstate_spectator_begin + plw_conf.x_playerstate_spectator_offset, 0, plw_conf.x_icon_playerstate_spectator_width, plw_conf.playerbar_text_height)
		statusText.font.size = plw_conf.playerbar_text_height
		statusText:SetCaption("")
		SafeAddChild(statusText,main)
	end
	
	--if cpuImage and cpuImage.parent == main then SafeRemoveChild(cpuImage,main) end
	--if pingImage and pingImage.parent == main then SafeRemoveChild(pingImage,main) end
	--if cpuText and cpuText.parent == main then SafeRemoveChild(cpuText,main) end
	--if pingText and pingText.parent == main then SafeRemoveChild(pingText,main) end
	
	if cpuText then
		SafeAddChild(cpuText,main) 
		if options.plw_cpuSpecDisp.value == 'text' then
			cpuText:Show()
			cpuText:SetPos(plw_conf.x_cpuping_spectator_begin + plw_conf.x_cpu_spectator_offset, plw_conf.playerbar_text_y, plw_conf.x_cpu_spectator_width, plw_conf.playerbar_text_height) 
			cpuText.font.size = plw_conf.playerbar_text_height
			cpuText:SetCaption("ERROR")
		else
			cpuText:Hide()
		end
	end
	if pingText then 
		SafeAddChild(pingText,main)
		if options.plw_pingSpecDisp.value == 'text' then
			pingText:Show()
			pingText:SetPos(plw_conf.x_cpuping_spectator_begin + plw_conf.x_ping_spectator_offset, plw_conf.playerbar_text_y, plw_conf.x_ping_spectator_width, plw_conf.playerbar_text_height) 
			pingText.font.size = plw_conf.playerbar_text_height
			pingText:SetCaption("ERROR")
		else
			pingText:Hide()
		end
	end
	if cpuImage then 
		SafeAddChild(cpuImage,main)
		if options.plw_cpuSpecDisp.value == 'icon' then
			cpuImage:Show()
			cpuImage:SetPos(plw_conf.x_cpuping_spectator_begin + plw_conf.x_cpu_spectator_offset, 0, plw_conf.x_cpu_spectator_width, plw_conf.playerbar_image_height)
			cpuImage.file = "LuaUI/Images/playerlist/cpu.png"
			function cpuImage:HitTest(x,y) return self end
			cpuImage:Invalidate()
		else
			cpuImage:Hide()
		end
	end
	if pingImage then 
		SafeAddChild(pingImage,main)
		if options.plw_pingSpecDisp.value == 'icon' then
			pingImage:Show()
			pingImage:SetPos(plw_conf.x_cpuping_spectator_begin + plw_conf.x_ping_spectator_offset, 0, plw_conf.x_ping_spectator_width, plw_conf.playerbar_image_height)
			pingImage.file = "LuaUI/Images/playerlist/ping.png"
			function pingImage:HitTest(x,y) return self end
			pingImage:Invalidate()
		else
			pingImage:Hide()
		end
	end

	PLW_UpdateStateSpectatorControls(entityID, true)
end

-- creates spectator row
local function PLW_CreateSpectatorControls(entityID)

	local mainControl = Control:New{padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}
	local nameLabel = Label:New{autosize = false}
	local statusLabel = Label:New{autosize = false}
	local cpuLabel = Label:New{autosize = false, align = "center"}
	local pingLabel = Label:New{autosize = false, align = "center"}
	local cpuIm = Image:New{}
	local pingIm = Image:New{}
	
	local subcon = {name = nameLabel, statusText = statusLabel, cpuText = cpuLabel, pingText = pingLabel, cpuImage = cpuIm, pingImage = pingIm}
	
	plw.vcon_spectatorControls[entityID] = CreateVcon(entityID, mainControl, subcon, 0, 0, {})
	
	PLW_ConfigureSpectatorControls(entityID)
	
end

local function PLW_CreateInitialControls()
	
	PLW_CalculateDimensions()
	
	for eID, _ in pairs(playerEntities) do
		PLW_CreatePlayerControls(eID)
	end
	
	for eID, _ in pairs(spectatorEntities) do
		PLW_CreateSpectatorControls(eID)
	end
	
	for tID, _ in pairs(teamEntities) do
		PLW_CreateTeamControls(tID)
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		PLW_CreateAllyTeamControls(atID)
	end
	
	PLW_CreateStaticControls()
	
	PLW_AutoSetHeight()
end

function PLW_Toggle()
	WG.SetWidgetOption("Chili Dynamic Player List",'Settings/HUD Panels/Dynamic Player Lists/Window List',"plw_visible",not options.plw_visible.value)
	if PLW_UpdateVisibility then PLW_UpdateVisibility() end
end

WG.TogglePlayerlistWindow = PLW_Toggle -- called by global commands widget

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- config for minimal playerlist 

local mpl_conf = {
	bar_height = false,
	icon_height = false,
	text_height = false,
	text_y = false,
	allyteam_buffer = false,

	window_pad_left = false,
	window_pad_right = false,
	bar_width = false,
	name_width = false,
	status_width = false,
	sep_width = false,
	me_width = false,
	
	name_x = false,
	status_x = false,
	sep_x = false,
	
	--options.mpl_namewidth.value
	--options.mpl_textHeight.value
}

local function MPL_CalculateDimensions()
	mpl_conf = {}
	
	mpl_conf.text_height = options.mpl_textHeight.value
	mpl_conf.text_y = 2
	mpl_conf.image_y = 1
	mpl_conf.icon_height = mpl_conf.text_height + 2
	mpl_conf.bar_height = mpl_conf.text_height + 4
	
	mpl_conf.allyteam_buffer = 9
	
	mpl_conf.name_width = options.mpl_namewidth.value * options.mpl_textHeight.value / 2
	mpl_conf.status_width = mpl_conf.bar_height
	mpl_conf.me_width = mpl_conf.bar_height
	mpl_conf.sep_width = 4
	
	mpl_conf.bar_width = mpl_conf.me_width + mpl_conf.me_width + mpl_conf.sep_width + mpl_conf.name_width + mpl_conf.status_width
	
	--mpl_conf.status_x = mpl_conf.bar_width - mpl_conf.status_width
    mpl_conf.status_offset = mpl_conf.status_width;
	mpl_conf.name_x = mpl_conf.bar_width - mpl_conf.name_width
	mpl_conf.sep_x = mpl_conf.name_x - mpl_conf.sep_width
	
	mpl_conf.window_pad_left = 2
	mpl_conf.window_pad_right = 2
end

local function MPL_AutoSetHeight()
	local height = mpl.vcon_scrollPanel.lastChild.main.y + mpl.vcon_scrollPanel.lastChild.main.height
	if not height or height > (options.mpl_maxWindowHeight.value or 600) then height = (options.mpl_maxWindowHeight.value or 600) end
	mpl.windowPlayerlist:SetPos(screen0.width - mpl.windowPlayerlist.width, 700 - height, mpl.windowPlayerlist.width,height)
end

local function MPL_UpdateVisibility()
	if screen0 and mpl.windowPlayerlist then
		if options.mpl_visible.value then
			SafeAddChild(mpl.windowPlayerlist,screen0)
		else
			screen0:RemoveChild(mpl.windowPlayerlist)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for minimal controls

function MPL_UpdateVolatileGlobalControls()

end

function MPL_UpdateStateGlobalControls()

	for atID, _ in pairs(allyTeamEntities) do
		local allyTeamVCon = mpl.vcon_allyTeamControls[atID]
		if allyTeamVCon and allyTeamVCon.parent ~= mpl.vcon_playerList then
			if allyTeamVCon.parent then
				-- TODO remove from ???
			end
			SafeAddChild(mpl.vcon_allyTeamControls[atID].main, mpl.vcon_playerList.main)
			InsertBottomVconChild(mpl.vcon_allyTeamControls[atID], mpl.vcon_playerList)
			SortSingleVcon(mpl.vcon_allyTeamControls[atID], nil, CompareAllyTeamVcons, true, true)
		end
	end

	MPL_UpdateVolatileGlobalControls()

end

function MPL_ConfigureGlobalControls()

	MPL_CalculateDimensions()
	
	if mpl.windowPlayerlist then
		local width = mpl_conf.window_pad_left + mpl_conf.bar_width + mpl_conf.window_pad_right
		mpl.windowPlayerlist:SetPos(screen0.width - width, 400, width, 50)
		mpl.windowPlayerlist.minWidth = mpl_conf.window_pad_left + mpl_conf.bar_width + mpl_conf.window_pad_right
		mpl.windowPlayerlist.maxWidth = mpl_conf.window_pad_left + mpl_conf.bar_width + mpl_conf.window_pad_right
		mpl.windowPlayerlist.minHeight = 50
	end
	
	if mpl.vcon_playerList.main then	
		mpl.vcon_playerList.main:SetPos(mpl_conf.window_pad_left,mpl_conf.allyteam_buffer,mpl_conf.bar_width,0)
		SafeAddChild(mpl.vcon_playerList.main, mpl.vcon_scrollPanel.main)
		InsertBottomVconChild(mpl.vcon_playerList,mpl.vcon_scrollPanel)
	end
	
	MPL_UpdateStateGlobalControls()
	
	MPL_UpdateVisibility()

end

function MPL_CreateGlobalControls()

	MPL_CalculateDimensions()
	
	if mpl.windowPlayerlist then
		mpl.windowPlayerlist:Dispose()
	end
	
	--mpl.windowPlayerlist = Control:New{autosize = false, dockable = false, draggable = false, resizable = false, tweakDraggable = true, disableChildrenHitTest = false, tweakResizable = true, padding = {0, 0, 0, 0}, borderColor = {1,1,1,0}, backgroundColor = {1,1,1,0}}
	
	mpl.windowPlayerlist = Window:New{
		dockable = true,
		color = {0,0,0,0},
		padding = {0, 0, 0, 0};
		--autosize   = true;
		-- parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		parentWidgetName = widget:GetInfo().name, --for gui_chili_docking.lua (minimize function)
	}
	
	if mpl.contentHolder then
		mpl.contentHolder:Dispose()
	end
	
	mpl.contentHolder = Control:New{autosize = false, x = 0, y = 0, right = 0, bottom = 0, padding = {0, 0, 0, 0}, disableChildrenHitTest = false, parent = mpl.windowPlayerlist}

	local scr = Control:New{
		--classname = 'panel',
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0},
		borderColor = {1, 1, 1, 0},
		--color = {0, 0, 0, 0},
		--verticalSmartScroll = true,
		disableChildrenHitTest = false,
		parent = mpl.contentHolder,
	}
	
	mpl.vcon_scrollPanel = CreateVcon(nil, scr, nil, 0, 0, {})
	
	mpl.vcon_scrollPanel.isOuterScrollPanel = true
	
	mpl.vcon_playerList = CreateVcon(false, Control:New{autosize = false, padding = {0, 0, 0, 0},color = {0, 0, 0, 0}}, nil, 0, 0, {})
	
	MPL_ConfigureGlobalControls()

end

function MPL_UpdateVolatileAllyTeamControls(allyTeamID)

end

function MPL_UpdateStateAllyTeamControls(allyTeamID)

	local main = mpl.vcon_allyTeamControls[allyTeamID].main

	for tID, _ in pairs(allyTeamEntities[allyTeamID].memberTEIDs) do
		local nPlayers = 0
		for eID, _ in pairs(teamEntities[tID].memberPEIDs) do
			nPlayers = nPlayers + 1
		end
		local teamVCon = mpl.vcon_teamControls[tID]
		
		if nPlayers == 0 and teamVCon and teamVCon.parent then
			SafeRemoveChild(teamVCon.main,teamVCon.parent.main)
			RemoveVcon(teamVCon)
			--teamVCon.main:SetPos(-2*plw_conf.x_window_width, teamVCon.main.y, teamVCon.main.width, teamVCon.main.height)			
			if mpl.vcon_allyTeamControls[allyTeamID].firstChild then SortVcons(mpl.vcon_allyTeamControls[allyTeamID].firstChild,CompareTeamVcons,false) end
		end
		
		if teamVCon and teamVCon.parent ~= mpl.vcon_allyTeamControls[allyTeamID] then
			if teamVCon.parent then
				local oldparent = teamVCon.parent
				RemoveVcon(teamVCon)
				SafeRemoveChild(teamVCon.main,oldparent.main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,CompareTeamVcons,false) end
			end
			if nPlayers > 0 then
				SafeAddChild(teamVCon.main,mpl.vcon_allyTeamControls[allyTeamID].main)
				InsertBottomVconChild(teamVCon, mpl.vcon_allyTeamControls[allyTeamID])
				SortSingleVcon(teamVCon, nil, CompareTeamVcons, true, true)
			end
		end
	end
	
	-- try shifting this allyteam up and down
	SortSingleVcon(mpl.vcon_allyTeamControls[allyTeamID], nil, CompareAllyTeamVcons, true, true)
	SortSingleVcon(mpl.vcon_allyTeamControls[allyTeamID], nil, CompareAllyTeamVcons, false, true)
	
	MPL_UpdateVolatileAllyTeamControls(allyTeamID)

end

function MPL_ConfigureAllyTeamControls(allyTeamID)

	local main = mpl.vcon_allyTeamControls[allyTeamID].main
	
	if main then main:SetPos(0,0,mpl_conf.bar_width,0) end

	MPL_UpdateStateAllyTeamControls(allyTeamID)

end

function MPL_CreateAllyTeamControls(allyTeamID)

	local mainControl = Control:New{padding = {0,0,0,0},color = {0, 0, 0, 0}}

	mpl.vcon_allyTeamControls[allyTeamID] = CreateVcon(allyTeamID, mainControl, {}, mpl_conf.allyteam_buffer, mpl_conf.allyteam_buffer, {})
	
	MPL_ConfigureAllyTeamControls(allyTeamID)

end

function MPL_UpdateVolatileTeamControls(teamID)

	local metal = mpl.vcon_teamControls[teamID].subcon.metal
	local energy = mpl.vcon_teamControls[teamID].subcon.energy
	local alert = mpl.vcon_teamControls[teamID].subcon.alert
	
	local mC = teamEntities[teamID].m_curr
	local mS = teamEntities[teamID].m_stor
	local eC = teamEntities[teamID].e_curr
	local eS = teamEntities[teamID].e_stor
	
	local res_start = math.max(mpl.vcon_teamControls[teamID].subcon.gLine.x,mpl_conf.sep_x)

	if (not teamEntities[teamID].resigned) and (iAmSpec or teamEntities[teamID].allyTeamID == myAllyTeam) then
		if mS > 0 then
		--if false then
			if mpl.vcon_teamControls[teamID].options.nostorage then
				alert.color = {1,1,1,0}
				alert.tooltip = ""
				mpl.vcon_teamControls[teamID].options.nostorage = false
				alert:Invalidate()
			end
			if (Spring.GetGameFrame() > 0) and (eC < 0.1 * eS) then
				if not mpl.vcon_teamControls[teamID].options.showE then
					energy.color = {1,1,1,1}
					energy.tooltip = "Stalling energy"
					mpl.vcon_teamControls[teamID].options.showE = 2
					energy:SetPos(res_start - mpl_conf.me_width*2, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					energy:Invalidate()
				end
			else
				if mpl.vcon_teamControls[teamID].options.showE then
					energy.color = {1,1,1,0}
					energy.tooltip = ""
					mpl.vcon_teamControls[teamID].options.showE = false
					energy:SetPos(0, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					energy:Invalidate()
				end
			end
			if (Spring.GetGameFrame() > 0) and (mC > 0.99 * mS) then
				if not mpl.vcon_teamControls[teamID].options.showM then
					metal.color = {1,1,1,1}
					metal.tooltip = "Excessing metal"
					mpl.vcon_teamControls[teamID].options.showM = true
					metal:SetPos(res_start - mpl_conf.me_width, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					metal:Invalidate()
				end
				if mpl.vcon_teamControls[teamID].options.showE == 1 then
					energy:SetPos(res_start - mpl_conf.me_width*2, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					mpl.vcon_teamControls[teamID].options.showE = 2
				end
			else
				if mpl.vcon_teamControls[teamID].options.showM then
					metal.color = {1,1,1,0}
					metal.tooltip = ""
					mpl.vcon_teamControls[teamID].options.showM = false
					metal:SetPos(0, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					metal:Invalidate()
				end
				if mpl.vcon_teamControls[teamID].options.showE == 2 then
					energy:SetPos(res_start - mpl_conf.me_width*1, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
					mpl.vcon_teamControls[teamID].options.showE = 1
				end
			end
		else
			if not mpl.vcon_teamControls[teamID].options.nostorage then
				alert.color = {1,1,1,1}
				alert.tooltip = "No storage"
				mpl.vcon_teamControls[teamID].options.nostorage = true
				alert:SetPos(res_start - mpl_conf.me_width, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
				alert:Invalidate()
			end
			if mpl.vcon_teamControls[teamID].options.showE then
				energy.color = {1,1,1,0}
				energy.tooltip = ""
				mpl.vcon_teamControls[teamID].options.showE = false
				energy:SetPos(0, energy.y, mpl_conf.me_width, mpl_conf.icon_height)
				energy:Invalidate()
			end
			if mpl.vcon_teamControls[teamID].options.showM then
				metal.color = {1,1,1,0}
				metal.tooltip = ""
				mpl.vcon_teamControls[teamID].options.showM = false
				metal:SetPos(0, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
				metal:Invalidate()
			end
		end
	else
		if mpl.vcon_teamControls[teamID].options.showE then
			energy.color = {1,1,1,0}
			energy.tooltip = ""
			mpl.vcon_teamControls[teamID].options.showE = false
			energy:SetPos(0, energy.y, mpl_conf.me_width, mpl_conf.icon_height)
			energy:Invalidate()
		end
		if mpl.vcon_teamControls[teamID].options.showM then
			metal.color = {1,1,1,0}
			metal.tooltip = ""
			mpl.vcon_teamControls[teamID].options.showM = false
			metal:SetPos(0, metal.y, mpl_conf.me_width, mpl_conf.icon_height)
			metal:Invalidate()
		end
		if mpl.vcon_teamControls[teamID].options.nostorage then
			alert.color = {1,1,1,0}
			alert.tooltip = ""
			mpl.vcon_teamControls[teamID].options.nostorage = false
			alert:SetPos(0, alert.y, mpl_conf.me_width, mpl_conf.icon_height)
			alert:Invalidate()
		end
	end

end

function MPL_UpdateStateTeamControls(teamID)

	local main = mpl.vcon_teamControls[teamID].main
	local metal = mpl.vcon_teamControls[teamID].subcon.metal
	local energy = mpl.vcon_teamControls[teamID].subcon.energy
	local alert = mpl.vcon_teamControls[teamID].subcon.alert
	local gLine = mpl.vcon_teamControls[teamID].subcon.gLine
	
	local nPlayers = 0
	
	mpl.vcon_teamControls[teamID].options.maxNameWidth = 2
	
	if teamEntities[teamID].isAI then
		nPlayers = 1
		local eID = aiLookup[teamID]
		if mpl.vcon_playerControls[eID] and mpl.vcon_playerControls[eID].parent ~= mpl.vcon_teamControls[teamID] then
			if mpl.vcon_playerControls[eID].parent then
				local oldparent = mpl.vcon_playerControls[eID].parent
				RemoveVcon(mpl.vcon_playerControls[eID])
				SafeRemoveChild(mpl.vcon_playerControls[eID].main,oldparent.main)
				if oldparent.firstChild then SortVcons(oldparent.firstChild,ComparePlayerVcons,false) end
			end
			InsertBottomVconChild(mpl.vcon_playerControls[eID], mpl.vcon_teamControls[teamID])
			SafeAddChild(mpl.vcon_playerControls[eID].main,mpl.vcon_teamControls[teamID].main)
			SortSingleVcon(mpl.vcon_playerControls[eID], nil, ComparePlayerVcons, true, true)
		end
		local namewidth = math.max(2, mpl.vcon_playerControls[eID].subcon.name.font:GetTextWidth(playerEntities[eID].name) + 10)
        if mpl.vcon_playerControls[eID].subcon.status.caption ~= "" then
            namewidth = namewidth + mpl_conf.status_offset
        end
		mpl.vcon_teamControls[teamID].options.maxNameWidth = math.max(mpl.vcon_teamControls[teamID].options.maxNameWidth, namewidth)
	else
		for eID, _ in pairs(teamEntities[teamID].memberPEIDs) do
			nPlayers = nPlayers + 1
			if mpl.vcon_playerControls[eID] and mpl.vcon_playerControls[eID].parent ~= mpl.vcon_teamControls[teamID] then
				if mpl.vcon_playerControls[eID].parent then
					local oldparent = mpl.vcon_playerControls[eID].parent
					RemoveVcon(mpl.vcon_playerControls[eID])
					SafeRemoveChild(mpl.vcon_playerControls[eID].main,oldparent.main)
					if oldparent.firstChild then SortVcons(oldparent.firstChild,ComparePlayerVcons,false) end
				end
				InsertBottomVconChild(mpl.vcon_playerControls[eID], mpl.vcon_teamControls[teamID])
				SafeAddChild(mpl.vcon_playerControls[eID].main,mpl.vcon_teamControls[teamID].main)
				SortSingleVcon(mpl.vcon_playerControls[eID], nil, ComparePlayerVcons, true, true)
			end
			local namewidth = math.max(2, mpl.vcon_playerControls[eID].subcon.name.font:GetTextWidth(playerEntities[eID].name) + 10)
            if mpl.vcon_playerControls[eID].subcon.status.caption ~= "" then
                namewidth = namewidth + mpl_conf.status_offset
            end
			mpl.vcon_teamControls[teamID].options.maxNameWidth = math.max(mpl.vcon_teamControls[teamID].options.maxNameWidth, namewidth)
		end
	end
	
	if metal then 
		metal.tooltip = ""
		metal.color = {1,1,1,0}
		mpl.vcon_teamControls[teamID].options.showM = false
		mpl.vcon_teamControls[teamID].options.nostorage = false
		metal:SetPos(0, mpl_conf.image_y + (nPlayers - 1) * 0.5 * mpl_conf.bar_height, mpl_conf.me_width, mpl_conf.icon_height)
		metal:Invalidate()
	end
	if energy then 
		energy.tooltip = ""
		energy.color = {1,1,1,0}	
		mpl.vcon_teamControls[teamID].options.showE = false
		energy:SetPos(0, mpl_conf.image_y + (nPlayers - 1) * 0.5 * mpl_conf.bar_height, mpl_conf.me_width, mpl_conf.icon_height)
		energy:Invalidate()
	end
	if alert then 
		alert.tooltip = ""
		alert.color = {1,1,1,0}	
		alert:SetPos(0, mpl_conf.image_y + (nPlayers - 1) * 0.5 * mpl_conf.bar_height, mpl_conf.me_width, mpl_conf.icon_height)
		alert:Invalidate()
	end
	if gLine then
		local linex = math.max(mpl_conf.name_x+mpl_conf.name_width-mpl.vcon_teamControls[teamID].options.maxNameWidth-mpl_conf.sep_width,mpl_conf.sep_x)
		if nPlayers > 1 then
			gLine:SetPos(linex,mpl_conf.bar_height*0.2, 2, mpl_conf.bar_height * (nPlayers - 0.4))
			gLine:Invalidate()
		else
			gLine:SetPos(linex+mpl_conf.sep_width,-100, 1, 30)
			gLine:Invalidate()
		end
	end
	
	SortSingleVcon(mpl.vcon_teamControls[teamID], nil, CompareTeamVcons, true, true)
	SortSingleVcon(mpl.vcon_teamControls[teamID], nil, CompareTeamVcons, false, true)

	MPL_UpdateVolatileTeamControls(teamID)

end

function MPL_ConfigureTeamControls(teamID)

	local main = mpl.vcon_teamControls[teamID].main
	local metal = mpl.vcon_teamControls[teamID].subcon.metal
	local energy = mpl.vcon_teamControls[teamID].subcon.energy
	local alert = mpl.vcon_teamControls[teamID].subcon.alert
	local gLine = mpl.vcon_teamControls[teamID].subcon.gLine
	
	if main then main:SetPos(0,0,mpl_conf.bar_width,0) end
	if metal then
		if metal.parent == main then SafeRemoveChild(metal,main) end
		if options.mpl_showMetal.value then
			metal:SetPos(0, 0, mpl_conf.me_width, mpl_conf.icon_height)
			metal.file = "LuaUI/Images/ibeam.png"
			function metal:HitTest(x,y) return self end
			SafeAddChild(metal,main)
		end
	end
	if energy then
		if energy.parent == main then SafeRemoveChild(energy,main) end
		if options.mpl_showEnergy.value then
			energy:SetPos(0, 0, mpl_conf.me_width, mpl_conf.icon_height)
			energy.file = "LuaUI/Images/energy.png"
			function energy:HitTest(x,y) return self end
			SafeAddChild(energy,main)
		end
	end
	if alert then
		if alert.parent == main then SafeRemoveChild(alert,main) end
		if options.mpl_showStorageAlert.value then
			alert:SetPos(0, 0, mpl_conf.me_width, mpl_conf.icon_height)
			alert.file = "LuaUI/Images/Crystal_Clear_app_error.png"
			function alert:HitTest(x,y) return self end
			SafeAddChild(alert,main)
		end
	end
	if gLine then
		gLine:SetPos(-100,0, 2, 30)
		SafeAddChild(gLine,main)
	end

	MPL_UpdateStateTeamControls(teamID)

end

function MPL_CreateTeamControls(teamID)

	local mainControl = Control:New{padding = {0,0,0,0},color = {0, 0, 0, 0}}
	local metalImage = Image:New{}
	local energyImage = Image:New{}
	local alertImage = Image:New{}
	local lline = Line:New{style = "vertical"}
	
	local subcon = {metal = metalImage, energy = energyImage, alert = alertImage, gLine = lline}

	mpl.vcon_teamControls[teamID] = CreateVcon(teamID, mainControl, subcon, 0, 0, {nostorage = false, showM = false, showE = false, maxNameWidth = 1000})

	MPL_ConfigureTeamControls(teamID)

end

function MPL_UpdateVolatilePlayerControls(entityID)

	if (not mpl.vcon_playerControls[entityID]) or (not mpl.vcon_playerControls[entityID].subcon) then 
		return
	end
	
	local main = mpl.vcon_playerControls[entityID].main
	local name = mpl.vcon_playerControls[entityID].subcon.name
	local status = mpl.vcon_playerControls[entityID].subcon.status
	
	
	if status then 
		if playerEntities[entityID].cpu and playerEntities[entityID].ping and playerEntities[entityID].teamID then
			local teamStatusCol = {1,0,1,1}
			local teamStatusText = ""
			local statusTooltip = ""
			teamStatusCol, teamStatusText, statusTooltip = FormatStatus(playerEntities[entityID].active, playerEntities[entityID].resigned, playerEntities[entityID].ping, playerEntities[entityID].cpu, Spring.GetTeamUnitCount(playerEntities[entityID].teamID))
            if teamStatusText ~= status.caption then
                if teamStatusText ~= "" then
                    name:SetPos(mpl_conf.name_x - mpl_conf.status_offset, mpl_conf.text_y, mpl_conf.name_width - 4, mpl_conf.text_height)
                    status.font:SetColor(teamStatusCol)
                    status:SetCaption(teamStatusText)
                    status.tooltip = statusTooltip
                    status:Invalidate()
                else
                    name:SetPos(mpl_conf.name_x, mpl_conf.text_y, mpl_conf.name_width - 4, mpl_conf.text_height)
                    status.font:SetColor{0.35,0.35,0.35,1}
                    status:SetCaption("·")
                    status.tooltip = ""
                    status:Invalidate()
                end
            end
		end
	end
end

function MPL_UpdateStatePlayerControls(entityID)

	if (not mpl.vcon_playerControls[entityID]) or (not mpl.vcon_playerControls[entityID].subcon) then 
		return
	end
	
	local main = mpl.vcon_playerControls[entityID].main
	local name = mpl.vcon_playerControls[entityID].subcon.name
	local status = mpl.vcon_playerControls[entityID].subcon.status
	
	
	if name then
		name.caption = playerEntities[entityID].name 
		if playerEntities[entityID].teamcolor then 
			if playerEntities[entityID].resigned then
				name.font.color = {0.5,0.5,0.5,1}
			else
				name.font.color = playerEntities[entityID].teamcolor
			end
		end
		name:Invalidate()
	end
	if status then 
		status.caption = ""
		status:Invalidate()
	end
	
	SortSingleVcon(mpl.vcon_playerControls[entityID], nil, ComparePlayerVcons, true, true)
	SortSingleVcon(mpl.vcon_playerControls[entityID], nil, ComparePlayerVcons, false, true)
	
	MPL_UpdateVolatilePlayerControls(entityID)
	
end

function MPL_ConfigurePlayerControls(entityID)
	
	if (not mpl.vcon_playerControls[entityID]) or (not mpl.vcon_playerControls[entityID].subcon) then 
		return
	end

	local main = mpl.vcon_playerControls[entityID].main
	local name = mpl.vcon_playerControls[entityID].subcon.name
	local status = mpl.vcon_playerControls[entityID].subcon.status
	
	if main then 
		main:SetPos(0,0,mpl_conf.bar_width, mpl_conf.bar_height)
	end
	if name then
		if name.parent == main then SafeRemoveChild(name,main) end
		name:SetPos(mpl_conf.name_x, mpl_conf.text_y, mpl_conf.name_width - 4, mpl_conf.text_height)
		name.font.size = mpl_conf.text_height
		name:SetCaption("ERROR")
		name.align = "right"
		function name:HitTest(x,y) return self end
		SafeAddChild(name,main)
	end
	if status then
		if status.parent == main then SafeRemoveChild(status,main) end
		status:SetPos(mpl_conf.bar_width - mpl_conf.status_offset, mpl_conf.text_y, mpl_conf.status_width, mpl_conf.text_height)
		status.font.size = mpl_conf.text_height
		status:SetCaption("ERROR")
		status.align = "center"
		function status:HitTest(x,y) return self end
		SafeAddChild(status,main)
	end
	
	
	MPL_UpdateStatePlayerControls(entityID)
	
end

function MPL_CreatePlayerControls(entityID)
	
	local mainControl = Control:New{padding = {0,0,0,0}, color = {0,0,0,0}}
	local nameLabel = Label:New{autosize = false}
	local statusLabel = Label:New{autosize = false}
	
	
	local subcon = {name = nameLabel, status = statusLabel}
	
	mpl.vcon_playerControls[entityID] = CreateVcon(entityID, mainControl, subcon, 0, 0, {})
	
	MPL_ConfigurePlayerControls(entityID)
	
end

-- local function MPL_ConfigureAllControls()
	
	-- MPL_CalculateDimensions()
	
	-- for eID, _ in pairs(playerEntities) do
		-- MPL_ConfigurePlayerControls(eID)
	-- end
	
	-- for eID, _ in pairs(spectatorEntities) do
		-- --MPL_ConfigureSpectatorControls(eID)
	-- end
	
	-- for tID, _ in pairs(teamEntities) do
		-- MPL_ConfigureTeamControls(tID)
	-- end
	
	-- for atID, _ in pairs(allyTeamEntities) do
		-- MPL_ConfigureAllyTeamControls(atID)
	-- end
	
	-- MPL_ConfigureGlobalControls()
	
	-- MPL_AutoSetHeight()
-- end


local function MPL_CreateAllControls()
	
	MPL_CalculateDimensions()
	
	for eID, _ in pairs(playerEntities) do
		MPL_CreatePlayerControls(eID)
	end
	
	for eID, _ in pairs(spectatorEntities) do
		--MPL_CreateSpectatorControls(eID)
	end
	
	for tID, _ in pairs(teamEntities) do
		MPL_CreateTeamControls(tID)
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		MPL_CreateAllyTeamControls(atID)
	end
	
	MPL_CreateGlobalControls()
	
	MPL_AutoSetHeight()
end

function MPL_Toggle()
	WG.SetWidgetOption("Chili Dynamic Player List",'Settings/HUD Panels/Dynamic Player Lists/Minimal List',"mpl_visible",not options.mpl_visible.value)
	if MPL_UpdateVisibility then MPL_UpdateVisibility() end
end

WG.TogglePlayerlistMinimal = MPL_Toggle -- called by global commands widget


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- interface for all displays

local function UpdateAllControls()

	local anyLargeUpdate = false

	for eID, _ in pairs(playerEntities) do
		if playerEntities[eID].needsVisUpdate then
			if playerEntities[eID].needsFullVisUpdate then
				PLW_UpdateStatePlayerControls(eID)
				MPL_UpdateStatePlayerControls(eID)
				playerEntities[eID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatilePlayerControls(eID)
				MPL_UpdateVolatilePlayerControls(eID)
			end
			playerEntities[eID].needsVisUpdate = false	
		end
	end
	
	if options.plw_showSpecs.value then
		for sID, _ in pairs(spectatorEntities) do
			if spectatorEntities[sID].needsVisUpdate then
				if spectatorEntities[sID].needsFullVisUpdate then
					PLW_UpdateStateSpectatorControls(sID)
					spectatorEntities[sID].needsFullVisUpdate = false
					anyLargeUpdate = true
				else
					PLW_UpdateVolatileSpectatorControls(sID)
				end
				spectatorEntities[sID].needsVisUpdate = false	
			end
		end
	end
	
	for tID, _ in pairs(teamEntities) do
		if teamEntities[tID].needsVisUpdate then
			if teamEntities[tID].needsFullVisUpdate then
				PLW_UpdateStateTeamControls(tID)
				MPL_UpdateStateTeamControls(tID)
				teamEntities[tID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatileTeamControls(tID)
				MPL_UpdateVolatileTeamControls(tID)
			end
			teamEntities[tID].needsVisUpdate = false	
		end
	end
	
	for atID, _ in pairs(allyTeamEntities) do
		if allyTeamEntities[atID].needsVisUpdate then
			if allyTeamEntities[atID].needsFullVisUpdate then
				PLW_UpdateStateAllyTeamControls(atID)
				MPL_UpdateStateAllyTeamControls(atID)
				allyTeamEntities[atID].needsFullVisUpdate = false
				anyLargeUpdate = true
			else
				PLW_UpdateVolatileAllyTeamControls(atID)
				MPL_UpdateVolatileAllyTeamControls(atID)
			end
			allyTeamEntities[atID].needsVisUpdate = false	
		end
	end
	
	if playerlistNeedsFullVisUpdate then
		PLW_UpdateStatePlayerListControl()
		MPL_UpdateStateGlobalControls()
		playerlistNeedsFullVisUpdate = false
		anyLargeUpdate = true
	else
		PLW_UpdateVolatileAttritionControl()
		MPL_UpdateVolatileGlobalControls()
	end
	
	if speclistNeedsFullVisUpdate then
		PLW_UpdateStateSpectatorListControl()
		speclistNeedsFullVisUpdate = false
		anyLargeUpdate = true
	end
	
	if anyLargeUpdate then
		PLW_AutoSetHeight()
		MPL_AutoSetHeight()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for entity handling

local function CreateHumanPlayerEntity(pID)
	--local name,act,spectator,tID,atID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(pID)
	--local _,leader,isDead,isAI,side,_,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { isAI = false, playerID = pID, teamID = nil, allyTeamID = nil, active = "", isLeader = true, resigned = false, clan = "", faction = "", country = "", level = "", elo = 0, rank = "", name = "", teamcolor = "", cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateAIPlayerEntity(tID)
	local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(tID)
	--local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { isAI = true, playerID = hostingPlayerID, teamID = tID, allyTeamID = nil, active = "", leader = true, resigned = false, clan = "", faction = "", country = "", level = "", elo = 0, rank = "", name = "", teamcolor = "", cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateSpectatorEntity(pID)
	--local name,act,spectator,tID,atID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(pID)
	return { playerID = pID, active = "", clan = "", faction = "", country = "", level = "", elo = 0, name = "", teamID = nil, cpu = 0, ping = 0, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateTeamEntity(tID)
	local _,leader,isDead,ai,side,_,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	return { teamID = tID, allyTeamID = nil, isAI = ai, memberPEIDs = {}, elo = false, resigned = false, m_mobiles = 0, m_defence = 0, m_income = 0, e_income = 0, m_curr = 0, m_stor = 0, e_curr = 0, e_stor = 0, m_kill = 0, m_loss = 0, teamcolor = nil, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function CreateAllyTeamEntity(atID)
	return { allyteamID = atID, memberTEIDs = {}, resigned = false, clan = "", country = "", name = "", m_mobiles = 0, cumuelo = 0, m_defence = 0, m_income = 0, e_income = 0, m_curr = 0, m_stor = 0, e_curr = 0, e_stor = 0, m_kill = 0, m_loss = 0, ateamcolor = nil, drawTeamname = true, drawTeamEcon = false, needsVisUpdate = false, needsFullVisUpdate = false}
end

local function UpdateGlobalEntity(fullUpdate)

	if fullUpdate then
		local countAT = 0
		drawTeamnames = false
		enableAttrition = false
		for atID, _ in pairs(allyTeamEntities) do
			if allyTeamEntities[atID].drawTeamname then drawTeamnames = true end
			countAT = countAT + 1
		end
		if countAT == 2 then enableAttrition = true end
	end

end

local function UpdateAllyTeamEntity(atID, fullUpdate)
	if allyTeamEntities[atID] then
	
		-- this depends on the team update being done first. kind of ugly but whatever
		allyTeamEntities[atID].m_mobiles = 0
		allyTeamEntities[atID].m_defence = 0
		allyTeamEntities[atID].m_income = 0
		allyTeamEntities[atID].e_income = 0
		allyTeamEntities[atID].m_kill = 0
		allyTeamEntities[atID].m_loss = 0
		allyTeamEntities[atID].m_curr = 0
		allyTeamEntities[atID].m_stor = 0
		allyTeamEntities[atID].e_curr = 0
		allyTeamEntities[atID].e_stor = 0
		allyTeamEntities[atID].cumuelo = 0
		
		local elocount = 0
		for tEID, _ in pairs(allyTeamEntities[atID].memberTEIDs) do
			if teamEntities[tEID].m_mobiles then allyTeamEntities[atID].m_mobiles = allyTeamEntities[atID].m_mobiles + teamEntities[tEID].m_mobiles end
			if teamEntities[tEID].m_defence then allyTeamEntities[atID].m_defence = allyTeamEntities[atID].m_defence + teamEntities[tEID].m_defence end
			if teamEntities[tEID].m_income then allyTeamEntities[atID].m_income = allyTeamEntities[atID].m_income + teamEntities[tEID].m_income end
			if teamEntities[tEID].e_income then allyTeamEntities[atID].e_income = allyTeamEntities[atID].e_income + teamEntities[tEID].e_income end
			if teamEntities[tEID].m_kill then allyTeamEntities[atID].m_kill = allyTeamEntities[atID].m_kill + teamEntities[tEID].m_kill end
			if teamEntities[tEID].m_loss then allyTeamEntities[atID].m_loss = allyTeamEntities[atID].m_loss + teamEntities[tEID].m_loss end
			if teamEntities[tEID].m_curr then allyTeamEntities[atID].m_curr = allyTeamEntities[atID].m_curr + teamEntities[tEID].m_curr end
			if teamEntities[tEID].m_stor then allyTeamEntities[atID].m_stor = allyTeamEntities[atID].m_stor + teamEntities[tEID].m_stor end
			if teamEntities[tEID].e_curr then allyTeamEntities[atID].e_curr = allyTeamEntities[atID].e_curr + teamEntities[tEID].e_curr end
			if teamEntities[tEID].e_stor then allyTeamEntities[atID].e_stor = allyTeamEntities[atID].e_stor + teamEntities[tEID].e_stor end
			elocount = elocount + 1
			if teamEntities[tEID].elo then allyTeamEntities[atID].cumuelo = allyTeamEntities[atID].cumuelo + (teamEntities[tEID].elo ) end
		end
		elocount = math.max(elocount, 1)
		allyTeamEntities[atID].cumuelo = allyTeamEntities[atID].cumuelo / elocount
		
		if fullUpdate then
			
			local allResign = true
			local playercount = 0
			local teamcount = 0
			allyTeamEntities[atID].ateamcolor = {r = 0, g = 0, b = 0, a = 1}
			
			for tEID, _ in pairs(allyTeamEntities[atID].memberTEIDs) do
				if teamEntities[tEID].isAI then
					playercount = playercount + 1
					teamcount = teamcount + 1
					allResign = false
				else
					local thisteamcount = 0
					for pEID, _ in pairs(teamEntities[tEID].memberPEIDs) do
						thisteamcount = thisteamcount + 1
						if allResign and not playerEntities[pEID].resigned then
							allResign = false
						end
					end
					playercount = playercount + thisteamcount
					if thisteamcount > 0 then
						teamcount = teamcount + 1
					end
				end
				if teamEntities[tEID].teamcolor and teamEntities[tEID].teamcolor.r then allyTeamEntities[atID].ateamcolor.r = allyTeamEntities[atID].ateamcolor.r + (teamEntities[tEID].teamcolor.r) / elocount
				else allyTeamEntities[atID].ateamcolor.r = allyTeamEntities[atID].ateamcolor.r + 1/elocount end
				if teamEntities[tEID].teamcolor and teamEntities[tEID].teamcolor.g then allyTeamEntities[atID].ateamcolor.g = allyTeamEntities[atID].ateamcolor.g + (teamEntities[tEID].teamcolor.g) / elocount
				else allyTeamEntities[atID].ateamcolor.r = allyTeamEntities[atID].ateamcolor.r + 1/elocount end
				if teamEntities[tEID].teamcolor and teamEntities[tEID].teamcolor.b then allyTeamEntities[atID].ateamcolor.b = allyTeamEntities[atID].ateamcolor.b + (teamEntities[tEID].teamcolor.b) / elocount
				else allyTeamEntities[atID].ateamcolor.r = allyTeamEntities[atID].ateamcolor.r + 1/elocount end
				
				-- allyTeamEntities[atID].ateamcolor.g = allyTeamEntities[atID].ateamcolor.g + (teamEntities[tEID].teamcolor.g or 1) / elocount
				-- allyTeamEntities[atID].ateamcolor.b = allyTeamEntities[atID].ateamcolor.b + (teamEntities[tEID].teamcolor.b or 1) / elocount
			end
			allyTeamEntities[atID].resigned = allResign
			if teamcount > 1 then allyTeamEntities[atID].drawTeamEcon = true else allyTeamEntities[atID].drawTeamEcon = false end
			if playercount > 1 then allyTeamEntities[atID].drawTeamname = true else allyTeamEntities[atID].drawTeamname = false end
			
			allyTeamEntities[atID].clan = ""
			allyTeamEntities[atID].country = ""
			
			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. atID)
			if string.len(name) > 10 then
				name = Spring.GetGameRulesParam("allyteam_short_name_" .. atID)
			end
			
			allyTeamEntities[atID].name = name
			allyTeamEntities[atID].needsFullVisUpdate = true
			
			UpdateGlobalEntity(true)
		end
	--{ allyteamID = atID, memberEIDs = {}, status = "", resigned = false, clan = "", country = "", name = "", m_mobiles = "", m_defence = "", m_income = "", e_income = ""}
	
		allyTeamEntities[atID].needsVisUpdate = true
	end
end

local function UpdateTeamEntity(tID, fullUpdate)
	local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
	if teamEntities[tID] then
		if fullUpdate then
			local numPlayers = 0
			local allResign = true
			for pEID, _ in pairs(teamEntities[tID].memberPEIDs) do
				numPlayers = numPlayers + 1
				if not teamEntities[tID].elo or (playerEntities[pEID].elo and playerEntities[pEID].elo ~= "" and playerEntities[pEID].elo > teamEntities[tID].elo) then 
					teamEntities[tID].elo = playerEntities[pEID].elo
				end
				if allResign and not playerEntities[pEID].resigned then
					allResign = false
				end
				teamEntities[tID].resigned = allResign
			end
			--if numPlayers > 0 or teamEntities[tID].isAI then
			if true then
				if atID ~= teamEntities[tID].allyTeamID then
					local oldAllyTeam = teamEntities[tID].allyTeamID
					local newAllyTeam = atID
					if oldAllyTeam and allyTeamEntities[oldAllyTeam] and allyTeamEntities[oldAllyTeam].memberTEIDs[tID] then 
						allyTeamEntities[oldAllyTeam].memberTEIDs[tID] = nil 
					end
					if newAllyTeam then
						if not allyTeamEntities[newAllyTeam] then
							allyTeamEntities[newAllyTeam] = CreateAllyTeamEntity(tID)
							playerlistNeedsFullVisUpdate = true
						end
						allyTeamEntities[newAllyTeam].memberTEIDs[tID] = true
					end
					if oldAllyTeam then UpdateAllyTeamEntity(oldAllyTeam, true) end
					if newAllyTeam then UpdateAllyTeamEntity(newAllyTeam, true) end
					teamEntities[tID].allyTeamID = newAllyTeam
				end
			else
				local oldAllyTeam = teamEntities[tID].allyTeamID
				if oldAllyTeam and allyTeamEntities[oldAllyTeam] and allyTeamEntities[oldAllyTeam].memberTEIDs[tID] then 
					allyTeamEntities[oldAllyTeam].memberTEIDs[tID] = nil 
					UpdateAllyTeamEntity(oldAllyTeam, true)
				end
			end
			teamEntities[tID].teamcolor = {r = select(1,Spring.GetTeamColor(tID)), g = select(2,Spring.GetTeamColor(tID)), b = select(3,Spring.GetTeamColor(tID)), a = select(4,Spring.GetTeamColor(tID))}
			teamEntities[tID].needsFullVisUpdate = true
			if atID then UpdateAllyTeamEntity(atID, true) end
		end
		
		teamEntities[tID].m_mobiles = 0
		local army = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_army_current")
		local other = Spring.GetTeamRulesParam(tID,"stats_history_unit_value_other_current")
		if army then teamEntities[tID].m_mobiles = teamEntities[tID].m_mobiles + army end
		if other then teamEntities[tID].m_mobiles = teamEntities[tID].m_mobiles + other end
		teamEntities[tID].m_kill = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_killed_current") or 0
		teamEntities[tID].m_loss = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_lost_current") or 0
		teamEntities[tID].m_defence = Spring.GetTeamRulesParam(tID, "stats_history_unit_value_def_current") or 0
		local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = Spring.GetTeamResources(tID, "energy")
		local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = Spring.GetTeamResources(tID, "metal")
		teamEntities[tID].m_income = mInco or 0
		teamEntities[tID].e_income = (eInco or 0) + 
		(Spring.GetTeamRulesParam(tID, "OD_energyIncome") or 0) - 
		math.max(0, (Spring.GetTeamRulesParam(tID, "OD_energyChange") or 0)) --TODO
		teamEntities[tID].m_curr = mCurr or 0 --TODO
		teamEntities[tID].m_stor = (mStor and HIDDEN_STORAGE) and mStor - HIDDEN_STORAGE or 0
		teamEntities[tID].e_curr = eCurr or 0
		teamEntities[tID].e_stor = (eStor and HIDDEN_STORAGE) and eStor - HIDDEN_STORAGE or 0
		if teamEntities[tID].e_stor > 50000 then teamEntities[tID].e_stor = 1000 end
		
		teamEntities[tID].needsVisUpdate = true
	end
	
end

local function UpdateSpectatorEntity(eID, fullUpdate, initialUpdate)
	if spectatorEntities[eID] then
		local name,act,spectator,tID,atID,ping,cpu,country,rank,customKeys = Spring.GetPlayerInfo(spectatorEntities[eID].playerID)
		local clan, faction, level, elo
		if customKeys then
			clan = customKeys.clan
			faction = customKeys.faction
			level = customKeys.level
			elo = customKeys.elo
			rank = customKeys.icon
		end
        
        if initialUpdate then 
            spectatorEntities[eID].clan = clan
			spectatorEntities[eID].country = country
			spectatorEntities[eID].faction = faction
			spectatorEntities[eID].level = level
			spectatorEntities[eID].elo = elo
			spectatorEntities[eID].name = name
            spectatorEntities[eID].needsFullVisUpdate = true
        end
        
		if fullUpdate then
            if spectatorEntities[eID].teamID ~= tID then
                spectatorEntities[eID].teamID = tID
                spectatorEntities[eID].needsFullVisUpdate = true
            end
		end
		
		spectatorEntities[eID].cpu = cpu
		spectatorEntities[eID].ping = ping
		
		spectatorEntities[eID].needsVisUpdate = true
	end
end

local function UpdatePlayerEntity(eID, fullUpdate, initialUpdate)
	if playerEntities[eID] then
		if playerEntities[eID].isAI then
			local _, ainame, hostingPlayerID, aishortName, _, _ = Spring.GetAIInfo(playerEntities[eID].teamID)
			local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(playerEntities[eID].teamID)
			local _,_,_,_,_,hostping,hostcpu,_,_,_ = Spring.GetPlayerInfo(hostingPlayerID)
			
			if fullUpdate then
				if (IsMission == false) then
					ainame = '<'.. ainame ..'> '.. aishortName
				end
				playerEntities[eID].name = ainame
				playerEntities[eID].allyTeamID = atID
				playerEntities[eID].needsFullVisUpdate = true
				
				if not teamEntities[playerEntities[eID].teamID] then
					teamEntities[playerEntities[eID].teamID] = CreateTeamEntity(playerEntities[eID].teamID)
				end
				teamEntities[playerEntities[eID].teamID].memberPEIDs[eID] = true
				
				teamEntities[playerEntities[eID].teamID].needsFullVisUpdate = true
			end
			--TODO other updates
			playerEntities[eID].cpu = hostcpu
			playerEntities[eID].ping = hostping
			playerEntities[eID].teamcolor = (playerEntities[eID].teamID and playerEntities[eID].teamID ~= -1) and {Spring.GetTeamColor(playerEntities[eID].teamID)} or {1,1,1,1}
		else
			local name,act,spectator,tID,atID,ping,cpu,country,_,customKeys = Spring.GetPlayerInfo(playerEntities[eID].playerID)
			local _,leader,isDead,isAI,side,atID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(tID)
			local clan, faction, level, elo
			if customKeys then
				clan = customKeys.clan
				faction = customKeys.faction
				level = customKeys.level
				elo = customKeys.elo
				rank = customKeys.icon
			end
			
            if initialUpdate then
                playerEntities[eID].clan = clan
				playerEntities[eID].country = country
				playerEntities[eID].faction = faction
				playerEntities[eID].level = level
				playerEntities[eID].elo = elo
				playerEntities[eID].rank = rank
				playerEntities[eID].name = name
                playerEntities[eID].needsFullVisUpdate = true
            end
            
			if fullUpdate then
                if playerEntities[eID].allyTeamID ~= atID then
                    playerEntities[eID].allyTeamID = atID
                    playerEntities[eID].needsFullVisUpdate = true
                end
                
                
                if playerEntities[eID].isLeader ~= (leader == playerEntities[eID].playerID) then
                    playerEntities[eID].isLeader = (leader == playerEntities[eID].playerID)
                    playerEntities[eID].needsFullVisUpdate = true
                end
				
				if spectator and not playerEntities[eID].resigned then
					playerEntities[eID].resigned = true
					local oldTeam = playerEntities[eID].teamID
					if oldTeam and teamEntities[oldTeam] then 
						UpdateTeamEntity(oldTeam, true)
					end
					if not spectatorLookup[playerEntities[eID].playerID] then
						local specEID = #spectatorEntities + 1
						spectatorEntities[specEID] = CreateSpectatorEntity(playerEntities[eID].playerID)
						speclistNeedsFullVisUpdate = true
						spectatorLookup[playerEntities[eID].playerID] = specEID
						UpdateSpectatorEntity(specEID, true)
                        playerEntities[eID].needsFullVisUpdate = true
					end
				end
			
				if tID ~= playerEntities[eID].teamID then
					local oldTeam = playerEntities[eID].teamID
					local newTeam = tID
					if oldTeam and teamEntities[oldTeam] and teamEntities[oldTeam].memberPEIDs[eID] then 
						teamEntities[oldTeam].memberPEIDs[eID] = nil 
					end
					if newTeam then
						if not teamEntities[newTeam] then
							teamEntities[newTeam] = CreateTeamEntity(tID)
						end
						teamEntities[newTeam].memberPEIDs[eID] = true
					end
					if oldTeam then UpdateTeamEntity(oldTeam, true) end
					if newTeam then UpdateTeamEntity(newTeam, true) end
					playerEntities[eID].teamID = newTeam
                    playerEntities[eID].needsFullVisUpdate = true
				end
                
				if tID then UpdateTeamEntity(tID, true) end
			end

			playerEntities[eID].active = act
			playerEntities[eID].cpu = cpu
			playerEntities[eID].ping = ping
			playerEntities[eID].teamcolor = (playerEntities[eID].teamID and playerEntities[eID].teamID ~= -1) and {Spring.GetTeamColor(playerEntities[eID].teamID)} or {1,1,1,1}
		end
		playerEntities[eID].needsVisUpdate = true
	end
end

local function AddHumanEntity(playerID)
	local eID = false
	if playerID then
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank,customKeys = Spring.GetPlayerInfo(playerID)
		spec = spectator
		if spectator then
			if not spectatorLookup[playerID] then
				eID = #spectatorEntities + 1
				spectatorEntities[eID] = CreateSpectatorEntity(playerID)
				spectatorLookup[playerID] = eID
			end
			UpdateSpectatorEntity(eID, true, true)
			speclistNeedsFullVisUpdate = true
		else
			if not humanLookup[playerID] then
				eID = #playerEntities + 1
				playerEntities[eID] = CreateHumanPlayerEntity(playerID)
				humanLookup[playerID] = eID
			end
			
			UpdatePlayerEntity(eID, true, true)
			playerlistNeedsFullVisUpdate = true
		end
	end
	return eID
end

local function AddAIEntity(teamID)
	local eID = false
	if teamID then
		local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
		local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
		
		if not aiLookup[teamID] then
			eID = #playerEntities + 1
			playerEntities[eID] = CreateAIPlayerEntity(teamID)
			aiLookup[teamID] = eID
		end
		
		UpdatePlayerEntity(eID, true, true)
		playerlistNeedsFullVisUpdate = true
	
		-- if not teamEntities[teamID] then
			-- teamEntities[teamID] = CreateTeamEntity(teamID)
		-- end
		UpdateTeamEntity(teamID, true)
	end
	return eID
end

local function CreateInitialEntities()
	local playersList = Spring.GetPlayerList()
	local teamsList = Spring.GetTeamList()
	
	-- look through teams list for AIs.
	for i=1,#teamsList do
		local teamID = teamsList[i]
		if teamID ~= Spring.GetGaiaTeamID() then
			--teams[teamID] = teams[teamID] or {roster = {}}
			local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
			if isAI then
				AddAIEntity(teamID)
			end
		end 
	end
	
	-- look through players list for humans (players and spectators).
	for i=1,#playersList do
		local playerID = playersList[i]
		--Spring.Echo("Playerlist Window Debug: Adding Player with playerID:"..playerID)
		AddHumanEntity(playerID)
	end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- functions for ...

local function checkMyself()
	myID = Spring.GetMyPlayerID()
	myName,_,iAmSpec = Spring.GetPlayerInfo(myID)
	myTeam = Spring.GetMyTeamID()
	myAllyTeam = Spring.GetMyAllyTeamID()
end
	

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- callins

function widget:Update(dt)
	timer = timer + dt
	if timer > options.freq.value then
		timer = 0
		for eID, _ in pairs(playerEntities) do
			UpdatePlayerEntity(eID, false)
		end
		for eID, _ in pairs(spectatorEntities) do
			UpdateSpectatorEntity(eID, false)
		end
		for eID, _ in pairs(teamEntities) do
			UpdateTeamEntity(eID, false)
		end
		for eID, _ in pairs(allyTeamEntities) do
			UpdateAllyTeamEntity(eID, false)
		end
		UpdateGlobalEntity(false)
		
		UpdateAllControls()
	end
	
	if plw_scrollPanelsNeedReset then
		plw.vcon_scrollPanel.main:SetScrollPos(nil,0,true,true)
		plw_scrollPanelsNeedReset = false
	end
	
	-- local invitecount = Spring.GetPlayerRulesParam(Spring.GetMyPlayerID(), "commshare_invitecount")
	-- if invitecount and built then
		-- Spring.Echo("There are " .. invitecount .. " invites")
		-- UpdateInviteTable()
	-- end
	
	
end

function widget:PlayerChanged(playerID)
	--Spring.Echo("Playerlist Window Debug: PlayerChanged called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if not humanLookup[playerID] and not spectatorLookup[playerID] then
			local eID = AddHumanEntity(playerID)
			if humanLookup[playerID] then
				if not plw.vcon_playerControls[eID] then
					PLW_CreatePlayerControls(eID)
				end
				if not mpl.vcon_playerControls[eID] then
					MPL_CreatePlayerControls(eID)
				end
			elseif spectatorLookup[playerID] then
				if not plw.vcon_spectatorControls[eID] then
					PLW_CreateSpectatorControls(eID)
				end
			end
		else
			if humanLookup[playerID] then
				UpdatePlayerEntity(humanLookup[playerID], true)
				if not plw.vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
				if not mpl.vcon_playerControls[humanLookup[playerID]] then
					MPL_CreatePlayerControls(humanLookup[playerID])
				end
			end -- something can become a spectator after UpdatePlayerEntity so this should not be an elseif.
			if spectatorLookup[playerID] then
				UpdateSpectatorEntity(spectatorLookup[playerID], true)
				if not plw.vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		end
	end
end

function widget:PlayerAdded(playerID)
	--Spring.Echo("Playerlist Window Debug: PlayerAdded called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if not humanLookup[playerID] and not spectatorLookup[playerID] then
			local eID = AddHumanEntity(playerID)
			if humanLookup[playerID] then
				if not plw.vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
				if not mpl.vcon_playerControls[humanLookup[playerID]] then
					MPL_CreatePlayerControls(humanLookup[playerID])
				end
			elseif spectatorLookup[playerID] then
				if not plw.vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		else
			if humanLookup[playerID] then
				UpdatePlayerEntity(humanLookup[playerID], true)
				if not plw.vcon_playerControls[humanLookup[playerID]] then
					PLW_CreatePlayerControls(humanLookup[playerID])
				end
				if not mpl.vcon_playerControls[humanLookup[playerID]] then
					MPL_CreatePlayerControls(humanLookup[playerID])
				end
			end -- something can become a spectator after UpdatePlayerEntity so this should not be an elseif.
			if spectatorLookup[playerID] then
				UpdateSpectatorEntity(spectatorLookup[playerID], true)
				if not plw.vcon_spectatorControls[spectatorLookup[playerID]] then
					PLW_CreateSpectatorControls(spectatorLookup[playerID])
				end
			end
		end
	end
end

function widget:PlayerRemoved(playerID)
	--Spring.Echo("Playerlist Window Debug: PlayerRemoved called, pID "..playerID)
	
	checkMyself()
	
	if playerID then
		if humanLookup[playerID] then
			UpdatePlayerEntity(humanLookup[playerID], true)
		elseif spectatorLookup[playerID] then
			UpdateSpectatorEntity(spectatorLookup[playerID], true)
		else
			--AddHumanEntity(playerID)
		end
	end
end

function widget:TeamDied(teamID)
	--Spring.Echo("Playerlist Window Debug: TeamDied called, tID "..teamID)
	
	checkMyself()
	
	if teamID then
		if aiLookup[teamID] then
			UpdatePlayerEntity(aiLookup[teamID], true)
		end
		if teamEntities[teamID] then
			UpdateTeamEntity(teamID)
		end
	end
end

function widget:TeamChanged(teamID)
	--Spring.Echo("Playerlist Window Debug: TeamChanged called, tID "..teamID)
	
	checkMyself()
	
	if teamID then
		local _,leader,isDead,isAI,side,allyTeamID,customTeamKeys,incomeMultiplier = Spring.GetTeamInfo(teamID)
		if isAI then 
			if aiLookup[teamID] then
				UpdatePlayerEntity(aiLookup[teamID], true)
			else
				AddAIEntity(teamID)
			end
		end
		if teamEntities[teamID] then
			UpdateTeamEntity(teamID)
		end
		-- if a team is created we trust that this has been dealt with in a player update.
	end
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	checkMyself()

	Chili = WG.Chili
	Line = Chili.Line
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Label = Chili.Label
	Control = Chili.Control
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	CreateInitialEntities()

	PLW_CreateInitialControls()
	
	MPL_CreateAllControls()
	
	plw_scrollPanelsNeedReset = true

	--options.plw_visible.value = true
	
	-- if options.plw_visible.value then
		-- SafeAddChild(plw.windowPlayerlist,screen0)
	-- else
		-- screen0:RemoveChild(plw.windowPlayerlist)
	-- end
	
	--if PLW_UpdateVisibility then PLW_UpdateVisibility() end

end

function widget:Shutdown()
	--widgetHandler:DeregisterGlobal("PlayerListWindow")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Dynamic Player Lists'
options_order = {
	'plw_allyteamBoxes', 'plw_showClan', 'plw_showCountry', 'plw_showRank', 'plw_show_resourceStatus', 'plw_show_netWorth', 'plw_allyteamBarLoc','plw_dataTextColor','plw_cpuPlayerDisp','plw_pingPlayerDisp',
	--
	'plw_showSpecs','plw_cpuSpecDisp','plw_pingSpecDisp',
	--
	'plw_showAttrition',
	--
	'plw_visible','plw_namewidth',
	--
	'plw_backgroundOpacity','plw_maxWindowHeight','plw_textHeight','plw_windowDraggable','plw_fancySkinning',
	--
	'mpl_visible','mpl_namewidth','mpl_textHeight','mpl_showMetal','mpl_showEnergy','mpl_showStorageAlert','mpl_maxWindowHeight',
	--
	'freq','unsortYourself'
}
options = {
	plw_visible = {
		name = "Toggle Visibility",
		type = 'bool',
		value = false, --set to false when initialisation is complete
		desc = "Set a hotkey here to toggle the playerlist on and off",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		advanced = false,
		OnChange = function() PLW_UpdateVisibility(); plw_scrollPanelsNeedReset = true end,
	},
	freq = {
		name = "Update Frequency",
		type = "number",
		value = 4, min = 0.5, max = 10, step = 0.1,
		noHotkey = true,
		advanced = false,
		path = 'Settings/HUD Panels/Dynamic Player Lists',
	},
	unsortYourself = {
		name = "Sort self to top as player",
		type = 'bool',
		value = true,
		desc = "Display yourself at the top of your team list",
		path = 'Settings/HUD Panels/Dynamic Player Lists',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		noHotkey = true,
		advanced = true
	},
	plw_namewidth = {
		name = "Name Width",
		type = "number",
		value = 20, min = 16, max = 30, step = 1,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		noHotkey = true,
		advanced = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
	},
	plw_backgroundOpacity = {
		name = "Opacity",
		type = "number",
		value = 0.5, min = 0, max = 1, step = 0.05,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		noHotkey = true,
		advanced = false,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
	},
	plw_maxWindowHeight = {
		name = "Maximum playerlist window height",
		type = 'number',
		value = 600,
		min=300,max=750,step=25,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		noHotkey = true,
	},
	plw_textHeight = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = true
	},
	plw_windowDraggable = {
		name = "Playerlist window draggable",
		type = 'bool',
		value = false,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		noHotkey = true,
		advanced = true
	},
	plw_fancySkinning = {
		name = 'Fancy Skinning',
		type = 'category',
		value = false,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List',
		items = {
			{key = 'panel', name = 'None'},
			{key = 'panel_0001', name = 'Flush',},
			{key = 'panel_0001_small', name = 'Flush Small',},
			{key = 'panel_1001_small', name = 'Top Left',},
		},
		OnChange = function (self)
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local className = self.value
			local newClass = skin.panel
			if skin[className] then
				newClass = skin[className]
			end
			
			plw.vcon_scrollPanel.main.tiles = newClass.tiles
			plw.vcon_scrollPanel.main.TileImageFG = newClass.TileImageFG
			--plw.vcon_scrollPanel.main.backgroundColor = newClass.backgroundColor
			plw.vcon_scrollPanel.main.TileImageBK = newClass.TileImageBK
			plw.vcon_scrollPanel.main:Invalidate()
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = true,
		noHotkey = true,
	},
	plw_allyteamBoxes = {
		name = "Draw boxes around allyteams",
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		noHotkey = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_showClan = {
		name = "Display players' clan",
		type = 'bool',
		value = false,
		desc = "Display players' clan",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		noHotkey = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_showCountry = {
		name = "Display players' country",
		type = 'bool',
		value = false,
		desc = "Display players' country",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		noHotkey = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_showRank = {
		name = "Display players' rank",
		type = 'bool',
		value = true,
		desc = "Display players' rank",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		noHotkey = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_show_resourceStatus = {
		name = "Display current income",
		type = 'bool',
		value = true,
		desc = "Display metal and energy income.",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		noHotkey = true,
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_show_netWorth = { --TODO
		name = 'Current net worth display',
		type = 'radioButton',
		value = 'all',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		items = {
			{name = 'Army and Defence', key = 'all', desc = "Display army worth and defence worth independently"},
			{name = 'Combined', key = 'sum', desc = "Display total army plus defence worth in one column"},
			{name = 'Army Only', key = 'army', desc = "Display total army size only"},
			{name = 'None', key = 'disable', desc = "Do not display net worth"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_dataTextColor = {
		name = 'Color player data text by...',
		type = 'radioButton',
		value = 'player',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		items = {
			{name = 'None', key = 'white', desc = "No color"},
			{name = 'Category', key = 'category', desc = "Color indicates category (army/def/metal/energy)"},
			{name = 'Player', key = 'player', desc = "Color indicates player"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_allyteamBarLoc = {
		name = 'Allyteam summary information...',
		type = 'radioButton',
		value = 'with',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		items = {
			{name = 'None', key = 'disable', desc = "Do not display allyteam bars"},
			{name = 'Above players', key = 'above', desc = "Display allyteam bars in a group"},
			{name = 'With players', key = 'with', desc = "Display allyteam bars with their respective players"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_cpuPlayerDisp = {
		name = 'Show cpu status as...',
		type = 'radioButton',
		value = 'icon',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		items = {
			{name = 'None', key = 'disable', desc = "Do not display cpu status"},
			{name = 'Icon', key = 'icon', desc = "Display cpu status as icon with tooltip"},
			{name = 'Text', key = 'text', desc = "Display cpu status as text"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_pingPlayerDisp = {
		name = 'Show ping as...',
		type = 'radioButton',
		value = 'icon',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Player Display Options',
		items = {
			{name = 'None', key = 'disable', desc = "Do not display ping"},
			{name = 'Icon', key = 'icon', desc = "Display ping as icon with tooltip"},
			{name = 'Text', key = 'text', desc = "Display ping as text"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_showSpecs = {
		name = "Display spectators",
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Spectator Display Options',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	plw_cpuSpecDisp = {
		name = 'Show cpu status as...',
		type = 'radioButton',
		value = 'icon',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Spectator Display Options',
		items = {
			{name = 'None', key = 'disable', desc = "Do not display cpu status"},
			{name = 'Icon', key = 'icon', desc = "Display cpu status as icon with tooltip"},
			{name = 'Text', key = 'text', desc = "Display cpu status as text"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_pingSpecDisp = {
		name = 'Show ping as...',
		type = 'radioButton',
		value = 'icon',
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Spectator Display Options',
		items = {
			{name = 'None', key = 'disable', desc = "Do not display ping"},
			{name = 'Icon', key = 'icon', desc = "Display ping as icon with tooltip"},
			{name = 'Text', key = 'text', desc = "Display ping as text"},
		},
		noHotkey = true,
		OnChange = function(self)
			PLW_CreateInitialControls()
			plw_scrollPanelsNeedReset = true
		end,
		advanced = false,
	},
	plw_showAttrition = {
		name = "Display attrition (2-team game only)",
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Window List/Attrition Display Options',
		OnChange = function() PLW_CreateInitialControls(); plw_scrollPanelsNeedReset = true end,
		advanced = false,
	},
	mpl_visible = {
		name = "Toggle Visibility",
		type = 'bool',
		value = true,
		desc = "Set a hotkey here to toggle the playerlist on and off",
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		advanced = false,
		OnChange = function() MPL_UpdateVisibility() end,
	},
	mpl_namewidth = {
		name = "Name Width",
		type = "number",
		value = 20, min = 16, max = 30, step = 1,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		noHotkey = true,
		advanced = true,
		OnChange = function() MPL_CreateAllControls() end,
	},
	mpl_textHeight = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		OnChange = function() MPL_CreateAllControls() end,
		advanced = true
	},
	mpl_showMetal = {
		name = 'Display metal excess indicator',
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		OnChange = function() MPL_CreateAllControls() end,
		advanced = true
	},
	mpl_showEnergy = {
		name = 'Display energy stall indicator',
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		OnChange = function() MPL_CreateAllControls() end,
		advanced = true
	},
	mpl_showStorageAlert = {
		name = 'Display zero-storage indicator',
		type = 'bool',
		value = true,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		OnChange = function() MPL_CreateAllControls() end,
		advanced = true
	},
	mpl_maxWindowHeight = {
		name = "Maximum playerlist height",
		type = 'number',
		value = 400,
		min=200,max=600,step=25,
		path = 'Settings/HUD Panels/Dynamic Player Lists/Minimal List',
		OnChange = function() MPL_CreateAllControls() end,
		noHotkey = true,
	},
}
