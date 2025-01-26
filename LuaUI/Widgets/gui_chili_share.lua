function widget:GetInfo()
	return {
		name    = "Chili Share menu v1.24",
		desc    = "FPS style (whole screen, hold to show) player list with comsharing UI",
		author  = "Commshare by Shaman, Playerlist by DeinFreund",
		date    = "12-3-2016",
		license = "PD",
		layer   = 2000,
		enabled = true,
	}
end

local unitCategoryDefs = VFS.Include("LuaRules/Configs/unit_category.lua")
VFS.Include("LuaRules/Configs/constants.lua")

local MIN_STORAGE = 0.5

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
local badgeWidth = 59*0.6
local badgeHeight = 24*0.6
local whrWidth = 35 -- Including margins
local color2incolor = nil
local teamZeroPlayers = {}
local playerInfo = {}
local images = {
	inviteplayer = 'LuaUI/Images/Commshare.png',
	accept = 'LuaUI/Images/epicmenu/check.png',
	decline = 'LuaUI/Images/advplayerslist/cross.png',
	pending = 'LuaUI/Images/epicmenu/questionmark.png',
	leave = 'LuaUI/Images/epicmenu/exit.png',
	kick = 'LuaUI/Images/advplayerslist/cross.png', -- REPLACE ME
	report = 'LuaUI/Images/Crystal_Clear_app_error.png', -- REPLACE ME
	merge = 'LuaUI/Images/Commshare_Merge.png',
	give = 'LuaUI/Images/gift2.png',
	giftmetal = 'LuaUI/Images/ibeam.png',
	giftenergy = 'LuaUI/Images/energy.png',
}
local defaultamount = 100

local UpdateListFunction
local SetWantRebuild
local wantRebuild = false

local KICK_USER = "StartKickPoll_"

local pingCpuColors = {
	'\255\0\255\0',
	'\255\178\255\0',
	'\255\255\255\0',
	'\255\255\153\0',
	'\255\255\0\0',
	'\255\255\255\255',
}

-- RGBA. Used as font color of players' WHR.
local rankColors = {
	["7"] = {1  , 0   , 1  ,  1},
	["6"] = {0  , 0.6 , 1  ,  1},
	["5"] = {0.7, 0.8 , 1  ,  1},
	["4"] = {1  , 1   , 0  ,  1},
	["3"] = {1  , 0.65, 0  ,  1},
	["2"] = {0.8, 0.4 , 0.1,  1},
	["1"] = {1  , 0   , 0  ,  1},
	["0"] = {0.5, 0.5 , 0.5,  1},
}

local function PingTimeOut(pingTime)
	local pingBucket = math.max(1, math.min(5, math.ceil(math.min(pingTime, 1) * 5))) or 6
	if pingTime < 1 then
		return pingCpuColors[pingBucket] .. (math.floor(pingTime*1000) ..'ms')
	elseif pingTime > 999 then
		return pingCpuColors[pingBucket] .. ('' .. (math.floor(pingTime*100/60)/100)):sub(1,4) .. 'min'
	end
	--return (math.floor(pingTime*100))/100
	return pingCpuColors[pingBucket] .. ('' .. (math.floor(pingTime*100)/100)):sub(1,4) .. 's' --needed due to rounding errors.
end


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
	fixHotkeys = {
		name  = "Fix hotkeys on start",
		type  = "bool",
		value = true,
		desc = "Fixes old hotkey issues once and then disables.",
		advanced = true,
		noHotkey = true,
	},
	enableNumWHR = {
		name  = "Show player rating",
		type  = "bool",
		value = false,
		desc = "Shows the WHR current rating of each player after their name. Uses the rating category of the current game mode (Casual or MM).",
		noHotkey = true,
		OnChange = function(self)
			if SetWantRebuild then
				SetWantRebuild()
			end
		end,
	},
	sharemenu = {
		name = 'Show Player List',
		desc = 'Hold this button to bring up the Player List.',
		type = 'button',
		hotkey = "tab",
		OnChange = function(self)
			if window then
				if wantRebuild and UpdateListFunction then
					UpdateListFunction()
					wantRebuild = false
				end
				window:SetVisibility(true)
			end
		end,
		path = 'Hotkeys/Misc',
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


--returns offensive, defensive metal value
local function getValueStats(teamID)
	local def, off = 0, 0
	for _, unitID in pairs(Spring.GetTeamUnits(teamID)) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if unitDefID then
			local metal = Spring.Utilities.GetUnitCost(unitID, unitDefID)
			local isbuilt = not select(3, Spring.GetUnitIsStunned(unitID))
			if metal and isbuilt then
				local cat = unitDefID and unitCategoryDefs[unitDefID]
				if cat == "army" then
					off = off + metal
				elseif cat == "def" then
					def = def + metal
				end
			end
		end
	end
	return off, def
end

-- returns income, pull, netIncome, storedAmount, storageSize each one is first metal then energy
local function getEcoInfo(teamID)
	
	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = Spring.GetTeamResources(teamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = Spring.GetTeamResources(teamID, "metal")
	
	if not mCurr then
		return
	end
	
	local allies               = Spring.GetTeamRulesParam(teamID, "OD_allies") or 1
	local team_metalBase       = Spring.GetTeamRulesParam(teamID, "OD_team_metalBase") or 0
	local team_metalOverdrive  = Spring.GetTeamRulesParam(teamID, "OD_team_metalOverdrive") or 0
	local team_metalMisc       = Spring.GetTeamRulesParam(teamID, "OD_team_metalMisc") or 0
	
	local team_energyIncome    = Spring.GetTeamRulesParam(teamID, "OD_team_energyIncome") or 0
	local team_energyOverdrive = Spring.GetTeamRulesParam(teamID, "OD_team_energyOverdrive") or 0
	local team_energyWaste     = Spring.GetTeamRulesParam(teamID, "OD_team_energyWaste") or 0
	
	local metalBase       = Spring.GetTeamRulesParam(teamID, "OD_metalBase") or 0
	local metalOverdrive  = Spring.GetTeamRulesParam(teamID, "OD_metalOverdrive") or 0
	local metalMisc       = Spring.GetTeamRulesParam(teamID, "OD_metalMisc") or 0
    
	local energyIncome    = Spring.GetTeamRulesParam(teamID, "OD_energyIncome") or 0
	local energyOverdrive = Spring.GetTeamRulesParam(teamID, "OD_energyOverdrive") or 0
	local energyChange    = Spring.GetTeamRulesParam(teamID, "OD_energyChange") or 0
	
	
	local eReclaim = eInco - math.max(0, energyChange)
	eInco = eReclaim + energyIncome
	
	
	local extraMetalPull = Spring.GetTeamRulesParam(teamID, "extraMetalPull") or 0
	local extraEnergyPull = Spring.GetTeamRulesParam(teamID, "extraEnergyPull") or 0
	mPull = mPull + extraMetalPull
	
	local extraChange = math.min(0, energyChange) - math.min(0, energyOverdrive)
	eExpe = eExpe + extraChange
	ePull = ePull + extraEnergyPull + extraChange - team_energyWaste/allies
	-- Waste energy is reported as the equal fault of all players.
	
	-- reduce by hidden storage
	mStor = math.max(mStor - HIDDEN_STORAGE, MIN_STORAGE)
	eStor = math.max(eStor - HIDDEN_STORAGE, MIN_STORAGE)

	-- cap by storage
	if eCurr > eStor then
		eCurr = eStor
	end
	if mCurr > mStor then
		mCurr = mStor
	end

	--// Storage, income and pull numbers
	local realEnergyPull = ePull

	local netMetal = mInco - mPull + mReci
	local netEnergy = eInco - realEnergyPull
	
	local mPercent, ePercent
	if mStor <= 1 then
		mCurr = 0
	end
	
	if eStor <= 1 then
		eCurr = 0
	end
	
	

	return mInco+mReci, eInco, mPull, realEnergyPull, netMetal, netEnergy, mCurr, eCurr, mStor, eStor
end

local function RenderName(subject)
	--Spring.Echo("rendername " .. subject.name .. ":" ..subject.id .. tostring(subject.active) .. tostring(subject.spec) ..tostring(subject.ai))
	local name = subject.name
	local active = subject.ai or subject.active
	--Spring.Echo("active " .. tostring(active))
	local spec = not subject.ai and subject.spec
	local myAllyTeamID = Spring.GetMyAllyTeamID()
	local mySpec = Spring.GetSpectatingState()
	--Spring.Echo(tostring(active) .. " " .. tostring(spec))
	local playerpanel = givemepanel[subject.id]
	if not spec and active and ((subject.allyteam == myAllyTeamID) or mySpec) then
		local incomeM, incomeE, pullM, pullE, netM, netE, storedM, storedE, storageM, storageE = getEcoInfo(subject.team)
		if incomeM then
			--Spring.Echo("metal: " .. amt .. "/" .. stor)
			local colorIncomeM = '\255\1\255\1'
			local colorNetM = '\255\1\255\1'
			local colorIncomeE = '\255\1\255\1'
			local colorNetE = '\255\1\255\1'
			if (incomeM < 0) then
				colorIncomeM = '\255\255\1\1'
			end
			if (incomeE < 0) then
				colorIncomeE = '\255\255\1\1'
			end
			if (netM < 0) then
				colorNetM = '\255\255\1\1'
			end
			if (netE < 0) then
				colorNetE = '\255\255\1\1'
			end
			if (incomeM < 1000) then
				incomeM = round(incomeM, 1)
			else
				incomeM = round(incomeM / 1000, 1) .. "K"
			end
			if (incomeE < 1000) then
				incomeE = round(incomeE, 1)
			else
				incomeE = round(incomeE / 1000, 1) .. "K"
			end
			netM = round(netM, 1)
			netE = round(netE, 1)
			givemebuttons[subject.id]["metalin"]:SetText(colorIncomeM .. incomeM) --colorNetM .. netM ..'\255\255\255\255' .. " / " ..
			givemebuttons[subject.id]["energyin"]:SetText( colorIncomeE .. incomeE) --colorNetE .. netE .. '\255\255\255\255'.. " / " ..
			givemebuttons[subject.id]["metalbar"]:SetValue(math.min(1,storedM / storageM))
			givemebuttons[subject.id]["energybar"]:SetValue(math.min(1,storedE / storageE))
			
			local off, def = getValueStats(subject.team)
			if (off < 1000) then
				off = round(off, 0)
			elseif (off < 10000) then
				off = round(off/1000, 1).. "K"
			else
				off = round(off/1000, 0).. "K"
			end
			if (def < 1000) then
				def = round(def, 0)
			elseif (def < 10000) then
				def = round(def/1000, 1).. "K"
			else
				def = round(def/1000, 0) .. "K"
			end
			givemebuttons[subject.id]["off"]:SetText(off)
			givemebuttons[subject.id]["def"]:SetText(def)
		end
	end
	if (subject.player) then
		local pingTime = select(6, Spring.GetPlayerInfo(subject.player, false))
		givemebuttons[subject.id]["ping"]:SetText(PingTimeOut(pingTime))
	elseif givemebuttons[subject.id]["ping"] then
		givemebuttons[subject.id]["ping"]:SetText("\255\180\180\180 n/a")
	end
	local oldText = givemebuttons[subject.id]["text"].text
	if spec then
		givemebuttons[subject.id]["text"]:SetText('\255\255\255\255' .. name)
	elseif active and not spec then
		givemebuttons[subject.id]["text"]:SetText(color2incolor(Spring.GetTeamColor(subject.team)) .. name)
	elseif not active and not spec then
		givemebuttons[subject.id]["text"]:SetText('\255\255\255\255' .. name )
	end
	if (oldText ~= givemebuttons[subject.id]["text"].text) then
		givemebuttons[subject.id]["text"]:Invalidate()
	end
end

local oldSubjects = {}

local function SafeSetButtonVisibility(button, visibility)
	if not button then
		return
	end
	button:SetVisibility(visibility)
end

local function UpdatePlayer(subject)
	--Spring.Echo("playerupdate " .. subject.name)
	if givemebuttons[subject.id] == nil or built == false then
		local name = subject.name
		--Spring.Echo("player" .. subject.id .. "( " .. name .. ") is not a player!")
		return
	end
	oldSubjects[subject.id] = subject
	local myPlayerID = Spring.GetMyPlayerID()
	local mySpec, specFullView = Spring.GetSpectatingState()
	local myteamID = Spring.GetMyTeamID()
	local myallyteamID = Spring.GetMyAllyTeamID()
	local amiteamleader = (select(2,Spring.GetTeamInfo(myteamID, false)) == myPlayerID)
	--Spring.Echo("I am spec " .. tostring(mySpec))
	--Spring.Echo(subject.name)
	local teamID = subject.team
	local allyteamID = subject.allyteam
	local teamLeader = subject.player and select(2, Spring.GetTeamInfo(teamID, false)) == subject.player
	--Spring.Echo("leader: " .. tostring(teamLeader))
	--Spring.Echo("ai: " .. tostring(subject.ai))
	--Spring.Echo("allyteam: " .. allyteamID)
	--Spring.Echo("myallyteam: " .. myallyteamID)
	if subject.player and subject.player == myPlayerID then
		if givemebuttons[subject.id]["leave"] then
			if (teamLeader or sharemode == false or mySpec) then
				SafeSetButtonVisibility(givemebuttons[subject.id]["leave"], false)
			elseif not teamLeader and #Spring.GetPlayerList(myteamID) > 1 and sharemode then
				SafeSetButtonVisibility(givemebuttons[subject.id]["leave"], true)
			end
		end
		SafeSetButtonVisibility(givemebuttons[subject.id]["pingCtrl"], true)
	elseif subject.ai then
		--Spring.Echo("dec3")
		SafeSetButtonVisibility(givemebuttons[subject.id]["metalbar"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energybar"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["metalin"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energyin"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["offHolder"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["defHolder"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["pingCtrl"], false)
		if subject.allyteam ~= myallyteamID or specFullView then -- hostile ai's stuff.
			--Spring.Echo("dec4")
			SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
			if (not specFullView ) then
				--Spring.Echo("dec5")
				SafeSetButtonVisibility(givemebuttons[subject.id]["metalbar"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["offHolder"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["defHolder"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energybar"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metalin"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energyin"], false)
			end
		end
	elseif subject.allyteam ~= myallyteamID or specFullView then -- hostile people's stuff.
		--Spring.Echo("dec6")
		SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["accept"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["pingCtrl"], true)
		if (not specFullView or subject.spec) then
			--Spring.Echo("dec7")
			SafeSetButtonVisibility(givemebuttons[subject.id]["metalbar"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["offHolder"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["defHolder"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["energybar"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["metalin"], false)
			SafeSetButtonVisibility(givemebuttons[subject.id]["energyin"], false)
		end
	elseif mySpec then -- Spectator, but not fullview
		SafeSetButtonVisibility(givemebuttons[subject.id]["pingCtrl"], true)
		SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
	else -- other people's stuff.
		SafeSetButtonVisibility(givemebuttons[subject.id]["pingCtrl"], true)
		if teamID == myteamID then
			if amiteamleader then
				--Spring.Echo("dec8")
				SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
			else
				--Spring.Echo("dec9")
				SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
			end
			if sharemode == false then
				--Spring.Echo("dec10")
				SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], true)
			end
		else
			SafeSetButtonVisibility(givemebuttons[subject.id]["kick"], false)
			if teamLeader == false then
				--Spring.Echo("dec11")
				SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], false)
				SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], false)
			else
				--Spring.Echo("dec12")
				SafeSetButtonVisibility(givemebuttons[subject.id]["commshare"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["metal"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["energy"], true)
				SafeSetButtonVisibility(givemebuttons[subject.id]["unit"], true)
			end
		end
	end
	if (subject.spec) then
		SafeSetButtonVisibility(givemebuttons[subject.id]["metalbar"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["offHolder"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["defHolder"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energybar"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["metalin"], false)
		SafeSetButtonVisibility(givemebuttons[subject.id]["energyin"], false)
	end
	RenderName(subject)
end

local function InvitePlayer(playerid)
	local name, _, _, teamID = Spring.GetPlayerInfo(playerid, false)
	local leaderID = select(2,Spring.GetTeamInfo(teamID, false))
	Spring.SendLuaRulesMsg("sharemode invite " .. playerid)
	if #Spring.GetPlayerList(teamID) > 1 and playerid == leaderID then
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
		local teamlist = Spring.GetTeamList(Spring.GetMyAllyTeamID())
		local clanmembers = {}
		for i=1, #teamlist do
			local players = Spring.GetPlayerList(teamlist[i],true)
			for j=1, #players do
				local customKeys = select(10, Spring.GetPlayerInfo(players[j])) or {}
				local clanShort = customKeys.clan     or ""
				local clanLong  = customKeys.clanfull or ""
				--Spring.Echo(select(1,Spring.GetPlayerInfo(players[j], false)) .. " : " .. clanLong)
				if clanLong == myclanLong and players[j] ~= Spring.GetMyPlayerID() and select(4,Spring.GetPlayerInfo(players[j], false)) ~= Spring.GetMyTeamID() then
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
	local leader = select(2,Spring.GetTeamInfo(Spring.GetMyTeamID(), false))
	local name = select(1,Spring.GetPlayerInfo(leader, false))
	Spring.SendCommands("say a: I left " .. name .. "'s squad.")
	Spring.SendLuaRulesMsg("sharemode unmerge")
end

local function InviteChange(playerid)
	local name = select(1,Spring.GetPlayerInfo(playerid, false))
	Spring.SendLuaRulesMsg("sharemode accept " .. playerid)
	--Spring.SendCommands("say a:I have joined " .. name .. "'s squad.") -- Removed to reduce information overload.
end

local function Hideme()
	window:Hide()
	showing = false
end

local function KickPlayer(playerid)
	Spring.SendCommands("say a: I kicked " .. select(1,Spring.GetPlayerInfo(playerid, false)) .. " from my squad.")
	Spring.SendLuaRulesMsg("sharemode kick " .. playerid)
end

local function BattleKickPlayer(subject)
	Spring.SendCommands("say !poll kick " .. subject.name)
end

local function HandleKickMessage(msg)
	if string.find(msg, KICK_USER) ~= 1 then
		return
	end
	local data = msg:split("_")
	if not (data and data[2]) then
		return
	end
	
	Spring.SendCommands("say !poll kick " .. data[2])
	return true
end

local function ReportPlayer(subject)
	local extraText = ""
	local isSpec = select(3, Spring.GetPlayerInfo(subject.id, false))
	extraText = extraText .. ((isSpec and "Spectator, ") or "Player, ")

	--[[ Somewhat obsolete given the direct link to battle gives all that info,
	     but let it hang around in case we discover cases where it doesn't ]]
	local utils = Spring.Utilities
	local gametype = utils.Gametype
	if gametype.isCoop() then
		local humans = #(Spring.GetTeamList(0) or {})
		extraText = extraText .. humans .. " vs " .. (gametype.isChickens() and "Chickens" or "Bots")
	elseif gametype.isTeamFFA() then
		local playerCount = #Spring.GetTeamList() - 1 -- ignore gaia
		extraText = extraText .. playerCount .. "-man, " .. utils.GetTeamCount() .. "-way Team FFA"
	elseif gametype.isFFA() then
		extraText = extraText .. utils.GetTeamCount() .. "-way FFA"
	else
		local teamCountFirst = #(Spring.GetTeamList(0) or {}) -- fixme: technically the teams dont need to be 0 and 1
		local teamCountSecond = #(Spring.GetTeamList(1) or {})
		extraText = extraText .. teamCountFirst .. "v" .. teamCountSecond
	end
	extraText = extraText .. " on " .. Game.mapName

	local gameID = Spring.GetGameRulesParam("GameID")
	if gameID then
		extraText = extraText .. " https://zero-k.info/Battles/EngineDetail/" .. gameID
	end

	local seconds = math.floor(Spring.GetGameFrame()/30)
	local minutes = math.floor(seconds/60)
	extraText = extraText .. " at " .. string.format("%d:%02d", minutes, seconds - 60*minutes)
	Spring.SendLuaMenuMsg("reportUser;" .. subject.name .. ";" .. extraText)
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
	local _, leader, _, isAI = Spring.GetTeamInfo(target, false)
	local name = select(1,Spring.GetPlayerInfo(leader, false))
	if isAI then
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
	local _, leader, _, isAI = Spring.GetTeamInfo(target, false)
	local name = select(1,Spring.GetPlayerInfo(leader, false))
	if isAI then
		name = select(2,Spring.GetAIInfo(target))
	end
	local playerslist = Spring.GetPlayerList(target,true)
	if #playerslist > 1 then
		name = name .. "'s squad"
	end
	local num = 0
	local currentResourceValue = Spring.GetTeamResources(select(1,Spring.GetMyTeamID(),kind))
	if mod == "all" then
		num = currentResourceValue
	elseif mod ~= nil then
		num = math.min(mod, currentResourceValue)
	else
		return
	end
	Spring.SendCommands("say a: I gave " .. math.floor(num) .. " " .. kind .. " to " .. name .. ".")
	Spring.ShareResources(target,kind,num)
end


local function InitName(subject, playerPanel)
	--Spring.Echo("Initializing " .. subject.name .. " with parent " .. tostring(playerPanel))
	local buttonsize = fontSize + 4
	local barWidth = 35
	playerfontsize[subject.id] = fontSize
	givemebuttons[subject.id] = {}
	givemepanel[subject.id] = playerPanel
	local sizefont = playerfontsize[subject.id]
	
	local smallFontSize = math.floor(sizefont/2) + 4
	local smallerFontSize = math.floor(sizefont/2) + 2
	
	givemebuttons[subject.id]["text"] = chili.TextBox:New{
		parent=playerPanel,
		width=146,
		height = sizefont+1,
		objectOverrideFont = WG.GetFont(sizefont + 1),
		x=69 + 2*buttonsize,
		text=subject.name ,
		y=13
	}
	givemebuttons[subject.id]["text"]:Invalidate()
	while (givemebuttons[subject.id]["text"].font:GetTextWidth(subject.name) > givemebuttons[subject.id]["text"].width - buttonsize) do
		givemebuttons[subject.id]["text"].font = WG.GetFont(givemebuttons[subject.id]["text"].font.size - 1)
		givemebuttons[subject.id]["text"]:Invalidate()
	end
	
	local bottomRowStartX = 67
	local bottomRowStartY = 37
	local bottomInfoStartX = bottomRowStartX + 4*buttonsize + 6
	local metalBarX = givemebuttons[subject.id]["text"].x + givemebuttons[subject.id]["text"].width + (options.enableNumWHR.value and whrWidth or 0)
	local infoSize = 48
	
	if subject.ai or subject.player ~= Spring.GetMyPlayerID() then
		givemebuttons[subject.id]["unit"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=bottomRowStartX,
			y=bottomRowStartY,
			OnClick= {function () GiveUnit(subject.team) end},
			padding={5,5,5,5},
			children = {chili.Image:New{file=images.give,
			width='100%',
			height='100%'}},
			tooltip="Give selected units.",
			noFont = true,
		}
		givemebuttons[subject.id]["metal"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=givemebuttons[subject.id]["unit"].x + buttonsize,
			y=givemebuttons[subject.id]["unit"].y,
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
			noFont = true,
		}
		givemebuttons[subject.id]["energy"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=givemebuttons[subject.id]["metal"].x + buttonsize,
			y=givemebuttons[subject.id]["metal"].y,
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
			noFont = true,
		}
	end
	givemebuttons[subject.id]["ping"] = chili.TextBox:New{
		file="LuaUI/Images/playerlist/ping.png",
		width='100%',
		height='100%',
		x=12,
		y=3,
		textColor={1,1,1,1},
		objectOverrideFont = WG.GetFont(smallFontSize),
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		text= "100ms"
	}
	givemebuttons[subject.id]["off"] = chili.TextBox:New{
		width='100%',
		height='100%',
		x=19,
		y=5,
		textColor={1,0.4,0.4,1},
		objectOverrideFont = WG.GetFont(smallFontSize),
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		text= ""
	}
	givemebuttons[subject.id]["def"] = chili.TextBox:New{
		width='100%',
		height='100%',
		x=19,
		y=5,
		textColor={0.52,0.52,1,1},
		objectOverrideFont = WG.GetFont(smallFontSize),
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		text= ""
	}
	givemebuttons[subject.id]["pingCtrl"] = chili.Control:New{
		parent=playerPanel,
		children={
			chili.Image:New{
				file="LuaUI/Images/playerlist/ping.png",
				width=10,
				height=15,
				x=0,
				y=0,
				margin = {0,0,0,0},
				padding = {0,0,0,0},
				color={1,1,1,0.8}
			},
			givemebuttons[subject.id]["ping"]
		},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		width=60,
		x = metalBarX + buttonsize + 3,
		y = givemebuttons[subject.id]["text"].y - 2,
		height=buttonsize,
		tooltip = "This player's network delay (ping)"
	}
	
	givemebuttons[subject.id]["metalbar"] = chili.Progressbar:New{
		parent = playerPanel,
		height = 9,
		autosize= false,
		min=0,
		max=1,
		width = barWidth,
		x = metalBarX,
		y = bottomRowStartY - 1,
		color={136/255,214/255,251/255,1},
		tooltip = "Your ally's metal.",
		noFont = true,
	}
	givemebuttons[subject.id]["energybar"] = chili.Progressbar:New{
		parent = playerPanel,
		height = 9,
		autosize= false,
		min=0,
		max=1,
		width = barWidth,
		x=givemebuttons[subject.id]["metalbar"].x,
		y=givemebuttons[subject.id]["metalbar"].y + 12,
		color={.93,.93,0,1},
		tooltip = "Your ally's energy.",
		noFont = true,
	}
	
	givemebuttons[subject.id]["metalin"] = chili.TextBox:New{
		parent=playerPanel,
		height='50%',
		width=100,
		objectOverrideFont = WG.GetFont(smallerFontSize),
		x=givemebuttons[subject.id]["metalbar"].x + givemebuttons[subject.id]["metalbar"].width + 2,
		y=givemebuttons[subject.id]["metalbar"].y + 1,
		tooltip = "Your ally's metal income."
	}
	givemebuttons[subject.id]["energyin"] = chili.TextBox:New{
		parent=playerPanel,
		height='50%',
		width=100,
		objectOverrideFont = WG.GetFont(smallerFontSize),
		x=givemebuttons[subject.id]["energybar"].x + givemebuttons[subject.id]["energybar"].width + 2,
		y=givemebuttons[subject.id]["energybar"].y + 1,
		tooltip = "Your ally's energy income."
	}
	givemebuttons[subject.id]["offHolder"] = chili.Control:New{
		parent=playerPanel,
		children={
			chili.Image:New{
				file='LuaUI/Images/commands/Bold/attack.png',
				width=16,
				height=16,
				x=1,
				y=2,
				margin = {0,0,0,0},
				padding = {0,0,0,0},
				color={1,1,1,1}
			},
			givemebuttons[subject.id]["off"]
		},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		width=50,
		x = bottomInfoStartX,
		y = bottomRowStartY + 1,
		height=20,
		tooltip = "This player's offensive units"
	}
	givemebuttons[subject.id]["defHolder"] = chili.Control:New{
		parent=playerPanel,
		children={
			chili.Image:New{
				file='LuaUI/Images/commands/Bold/guard.png',
				width=16,
				height=16,
				x=1,
				y=2,
				margin = {0,0,0,0},
				padding = {0,0,0,0},
				color={1,1,1,1}
			},
			givemebuttons[subject.id]["def"]
		},
		margin = {0,0,0,0},
		padding = {0,0,0,0},
		width=50,
		x = bottomInfoStartX + infoSize,
		y = bottomRowStartY + 1,
		height=20,
		tooltip = "This player's defence"
	}
	
	if subject.player ~= Spring.GetMyPlayerID() then
		if subject.player then
			local commshareButtonX = givemebuttons[subject.id]["energy"].x + buttonsize
			local commshareButtonY = givemebuttons[subject.id]["energy"].y
			
			givemebuttons[subject.id]["accept"] = chili.Button:New{
				parent = playerPanel,
				height = buttonsize,
				width = buttonsize,
				x= commshareButtonX,
				y= commshareButtonY,
				OnClick = {function () InviteChange(subject.player,true) end},
				padding={1,1,1,1},
				tooltip = "Click this to accept this player's invite!",
				children={
					chili.Image:New{
						file=images.merge,
						width='100%',
						height='100%'
					}
				},
				noFont = true,
			}
			givemebuttons[subject.id]["commshare"] = chili.Button:New{
				parent = playerPanel,
				height = buttonsize,
				width = buttonsize,
				x= commshareButtonX,
				y= commshareButtonY,
				OnClick = {function () InvitePlayer(subject.player,false) end},
				padding={1,1,1,1},
				tooltip = "Invite this player to join your squad.\nPlayers on a squad share control of units and have access to all resources each individual player would have/get normally.\nOnly invite people you trust. Use with caution!",
				children={
					chili.Image:New{
						file=images.inviteplayer,
						width='100%',
						height='100%'
					}
				},
				noFont = true,
			}
			givemebuttons[subject.id]["kick"] = chili.Button:New{
				parent = playerPanel,
				height = buttonsize,
				width = buttonsize,
				x= commshareButtonX,
				y= commshareButtonY,
				OnClick = {function () KickPlayer(subject.player) end},
				padding={1,1,1,1},
				tooltip = "Kick this player from your squad.",
				children={
					chili.Image:New{
						file=images.leave,
						width='100%',
						height='100%'
					}
				},
				noFont = true,
			}
			givemebuttons[subject.id]["battlekick"] = chili.Button:New{
				parent = playerPanel,
				height = buttonsize,
				width = buttonsize,
				x= metalBarX,
				y= givemebuttons[subject.id]["text"].y - 6,
				OnClick = {function () ReportPlayer(subject) end},
				padding={2,2,2,2},
				tooltip = "Report this player to moderators.",
				children={
					chili.Image:New{
						file=images.report,
						width='100%',
						height='100%'
					}
				},
				noFont = true,
			}
			--givemebuttons[subject.id]["battlekick"] = chili.Button:New{
			--	parent = playerPanel,
			--	height = buttonsize,
			--	width = buttonsize,
			--	x= metalBarX,
			--	y= givemebuttons[subject.id]["text"].y - 6,
			--	OnClick = {function () BattleKickPlayer(subject) end},
			--	padding={1,1,1,1},
			--	tooltip = "Kick this player from the battle.",
			--	children={
			--		chili.Image:New{
			--			file=images.kick,
			--			width='100%',
			--			height='100%'
			--		}
			--	},
			--	noFont = true,
			--}
		end
	else
		givemebuttons[subject.id]["leave"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x=bottomRowStartX,
			y=bottomRowStartY,
			OnClick = {function () LeaveMySquad() end},
			padding={1,1,1,1},
			tooltip = "Leave your squad.",
			children={
				chili.Image:New{
					file=images.leave,
					width='100%',
					height='100%',
					x='0%',
					y=0
				}
			},
			noFont = true,
		}
		givemebuttons[subject.id]["battlekick"] = chili.Button:New{
			parent = playerPanel,
			height = buttonsize,
			width = buttonsize,
			x= metalBarX,
			y= givemebuttons[subject.id]["text"].y - 6,
			OnClick = {function () ReportPlayer(subject) end},
			padding={2,2,2,2},
			tooltip = "Report this player to moderators.",
			children={
				chili.Image:New{
					file=images.report,
					width='100%',
					height='100%'
				}
			},
			noFont = true,
		}
	end
	local icon, elo, badges, clan, avatar, faction, admin
	if (subject.player) then
		local pdata = select(10, Spring.GetPlayerInfo(subject.player))
		icon = pdata.icon
		elo = pdata.elo
		badges = pdata.badges
		clan = pdata.clan
		avatar = pdata.avatar
		faction = pdata.faction
	end
	if (playerInfo[subject.name]) then
		--Spring.Echo("Using extra info for " .. subject.name)
		clan = playerInfo[subject.name].clan
		icon = playerInfo[subject.name].icon
		badges = playerInfo[subject.name].badges
		avatar = playerInfo[subject.name].avatar
		faction = playerInfo[subject.name].faction
		admin = playerInfo[subject.name].admin
	end

	-- approximate known bots skill (FIXME: bots should probably have their own distinct icon, and chickens another)
	if subject.ai then
		icon = "0_0" -- >mfw unknown bot

		if (string.match(string.lower(subject.name), "chicken")) then icon = "7_1" end
		if (string.match(string.lower(subject.name), "circuit")) then icon = "7_3" end
		if (string.match(string.lower(subject.name),     "kgb")) then icon = "6_5" end
		if (string.match(string.lower(subject.name),     "csi")) then icon = "5_4" end
		if (string.match(string.lower(subject.name),     "cai")) then icon = "3_2" end
	end

	--Spring.Echo("badges: " .. tostring(badges))
	local clanImg = nil
	local avatarImg = nil
	local adminImg = nil
	avatar = avatar or "clogger"
	local rankImg = "LuaUI/Images/LobbyRanks/" .. (icon or "0_0") .. ".png"
	if clan and clan ~= "" then
		clanImg = "LuaUI/Configs/Clans/" .. clan ..".png"
	elseif faction and faction ~= "" then
		clanImg = "LuaUI/Configs/Factions/" .. faction ..".png"
	end
	if avatar then
		avatar = avatar .. ".png"
		local unitpic = "unitpics/" .. avatar
		if VFS.FileExists(unitpic, VFS.GAME) then
			avatarImg = unitpic
		else
			avatarImg = "LuaUI/Configs/Avatars/" .. avatar
		end
	end
	if admin then
		adminImg = "LuaUI/Images/playerlist/police.png"
	end
	if (rankImg) then
		chili.Image:New{parent=playerPanel,
			file=rankImg,
			width=16,
			height=16,
			x = 64 + buttonsize + 5,
			y = givemebuttons[subject.id]["text"].y - 1
		}
	end

	if (adminImg) then
		--if givemebuttons[subject.id]["battlekick"] then
		--	givemebuttons[subject.id]["battlekick"]:Dispose()
		--end
		--givemebuttons[subject.id]["admin"] = chili.Button:New{
		--	parent = playerPanel,
		--	height = buttonsize,
		--	width = buttonsize,
		--	x= bottomRowStartX + givemebuttons[subject.id]["text"].width + 2 * buttonsize,
		--	y= givemebuttons[subject.id]["text"].y - 4,
		--	padding={1,1,1,1},
		--	tooltip = "Zero-K Administrator",
		--	children={
		--		chili.Image:New{
		--			file=adminImg,
		--			width=16,
		--			height=16,
		--			x = 2,
		--			y = 2
		--		}
		--	},
		--	caption=" "
		--}
	end
	if (clanImg) then
		chili.Image:New{parent=playerPanel,
			file=clanImg,
			width=buttonsize -6 ,
			height= buttonsize-6,
			x = 64 + buttonsize*0 + 6,
			y = givemebuttons[subject.id]["text"].y - 1
		}
	end
	--adjust text  centering
	givemebuttons[subject.id]["text"].y = givemebuttons[subject.id]["text"].y + (1 + sizefont - givemebuttons[subject.id]["text"].font.size) / 3
	givemebuttons[subject.id]["text"]:Invalidate()
	if (avatarImg) then
		local avatarControl = chili.Image:New{parent=playerPanel,
			file=avatarImg,
			width=64,
			height= 64,
			x = 0,
			y = 0
		}
		if (badges) then
			for i, badge in ipairs(badges:split(",")) do
				if (badge ~= "" and i < 3) then
					local badgeImg = "LuaUI/Images/badges/" .. badge .. ".png"
					chili.Image:New{
						parent=avatarControl,
						file=badgeImg,
						width=badgeWidth,
						x = 1,
						bottom = 1 + (i - 1)*badgeHeight,
						height=badgeHeight,
						tooltip = "A special award",
						color = {1, 1, 1, 0.86},
					}
				end
			end
		end
	end

	if options.enableNumWHR.value and elo then
		local whrMargin = 2
		
		chili.TextBox:New{
			parent=playerPanel,
			width=whrWidth - 2*whrMargin,
			x= givemebuttons[subject.id]["text"].x + givemebuttons[subject.id]["text"].width + whrMargin,
			y= givemebuttons[subject.id]["text"].y + 1 ,
			tooltip = "WHR Current Rating",
			text = elo,
			textColor = (icon and rankColors[icon:sub(3,3)]) or {1,1,1,1}
		}
	end

	--Spring.Echo("Playerpanel size: " .. playerPanel.width .. "x" .. playerPanel.height .. "\nTextbox size: " .. playerPanel.width*0.4 .. "x" .. playerPanel.height)
	local isSpec = select(3,Spring.GetPlayerInfo(subject.id, false))
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
	windowWidth = 768 + (options.enableNumWHR.value and (2 * whrWidth) or 0)
	windowHeight = 666
	--Spring.Echo("Window size: " .. window.width .. "x" .. window.height)
	
	local playerpanels = {}
	local allypanels = {}
	local allpanels = {}
	local playerHeight =  64
	local playerWidth =  339 + (options.enableNumWHR.value and whrWidth or 0)
	local lastAllyTeam = 0
	for _, subject in ipairs(subjects) do
		if (not playerpanels[subject.allyteam]) then
			playerpanels[subject.allyteam] = {}
		end
		lastAllyTeam = subject.allyteam
		playerpanels[subject.allyteam][#playerpanels[subject.allyteam] + 1] = chili.Control:New{
			backgroundColor={1,0,0,0},
			height = playerHeight,
			width=playerWidth,
			x = 0,
			padding = {0,0,0,0},
			margin = {0,0,0,0},
			y = #playerpanels[subject.allyteam] * playerHeight
		}
		InitName(subject, playerpanels[subject.allyteam][#playerpanels[subject.allyteam]])
	end
	local allyteams = Spring.GetAllyTeamList()
	allyteams[#allyteams + 1] = 100
	local heightOffset = 0
	local XOffset = 0
	local titleSize = 25
	local nextHeightOffset = 0
	for _, subject in ipairs(subjects) do
		allyTeamID = subject.allyteam
		if (playerpanels[allyTeamID]) then
			--Spring.Echo(playerpanels[allyTeamID])
			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID)
			if (not name) then
				name = "Team " .. allyTeamID
			end
			if (allyTeamID >= 100) then
				name = "Spectators"
			end
			local height = #playerpanels[allyTeamID] * playerHeight + 20
			local color = {0,1,0,1}
			if (allyTeamID ~= Spring.GetMyAllyTeamID()) then
				color = {1,0,0,1}
			end
			if (allyTeamID >= 100) then
				color = {1,1,1,1}
			end
			local panelWidth = playerWidth + 20
			if (allyTeamID >= lastAllyTeam and XOffset < 1) then
				XOffset = windowWidth / 2 - panelWidth / 2 - 10
			end
			local panelX = XOffset
			XOffset = XOffset + panelWidth + 20
			local localHeightOffset = heightOffset
			local label = chili.Label:New{
				width=panelWidth,
				height = titleSize,
				x = panelX,
				y = localHeightOffset + 10,
				caption=name,
				objectOverrideFont = WG.GetFont(titleSize - 4),
				textColor=color,
				align='center'
			}
			allypanels[#allypanels + 1] = label
			localHeightOffset = localHeightOffset + titleSize
			allypanels[#allypanels + 1] = chili.Control:New{
				backgroundColor=color,
				borderColor=color,
				children=playerpanels[allyTeamID],
				width=panelWidth,
				height = height,
				padding = {10,10,10,10},
				x = panelX,
				y = localHeightOffset
			}
			local width = math.max(2, label.font:GetTextWidth(name) + 30)
			allypanels[#allypanels + 1] = chili.Control:New{
				width=panelWidth,
				height=height,
				x = panelX,
				y = localHeightOffset - 13,
				children = {
					chili.Line:New{
						x = 0,
						y = 0,
						width = math.max(0, (panelWidth - width )/2)
					},
					chili.Line:New{
						x = (panelWidth + width )/2 - 12,
						y = 0,
						width = math.max(0, (panelWidth - width )/2 + 12)
					}
				}
			}
			localHeightOffset = localHeightOffset + height + 10
			playerpanels[allyTeamID] = nil
			nextHeightOffset = math.max(localHeightOffset, nextHeightOffset)
			if (XOffset + panelWidth > windowWidth) then
				XOffset = 0
				heightOffset = nextHeightOffset
			end
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
		objectOverrideFont = WG.GetFont(17),
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
UpdateListFunction = Buildme

function SetWantRebuild()
	if (mySubjectID < 0 or not subjects[mySubjectID]) then
		return
	end
	if (not window) or (window and window.visible) then
		Buildme()
	else
		wantRebuild = true
	end
end

local function UpdateInviteTable()
	local myPlayerID = Spring.GetMyPlayerID()
	for i=1,Spring.GetPlayerRulesParam(myPlayerID, "commshare_invitecount") do
		local playerID = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_id")
		local timeleft = Spring.GetPlayerRulesParam(myPlayerID, "commshare_invite_"..i.."_timeleft") or 0
		if (givemebuttons[givemesubjects[playerID].id]) then
			--Spring.Echo("Invite from: " .. tostring(playerID) .. "\nTime left: " .. timeleft)
			if playerID == automergeid then
				InviteChange(playerID)
				return
			end
			--Spring.Echo("Invite: " .. playerID .. " : " .. timeleft)
			if invites[playerID] == nil and timeleft > 1 and deadinvites[playerID] ~= timeleft then
				invites[playerID] = timeleft
				SafeSetButtonVisibility(givemebuttons[givemesubjects[playerID].id]["accept"], true)
			elseif invites[playerID] == timeleft then
				invites[playerID] = nil -- dead invite
				deadinvites[playerID] = timeleft
				SafeSetButtonVisibility(givemebuttons[givemesubjects[playerID].id]["accept"], false)
			elseif timeleft == 1 then
				SafeSetButtonVisibility(givemebuttons[givemesubjects[playerID].id]["accept"], false)
				invites[playerID] = nil
			elseif invites[playerID] and timeleft > 1 then
				invites[playerID] = timeleft
					SafeSetButtonVisibility(givemebuttons[givemesubjects[playerID].id]["accept"], true)
					--Spring.Echo("showing")
			end
		-- else
			--Spring.Echo("No accept for player " .. select(1, Spring.GetPlayerInfo(playerID, false)))
		end
	end
end

local function UpdatePlayers()
	if (mySubjectID >= 0 and subjects[mySubjectID]) then
		for _, subject in ipairs(subjects) do
			UpdatePlayer(subject)
		end
	end
end


function widget:GameProgress(serverFrameNum)
	if needsremerging and serverFrameNum - Spring.GetGameFrame() < 90 then
		needsremerging = false
		Spring.SendLuaRulesMsg("sharemode remerge")
		--Spring.Echo("Sent remerge request")
	end
end

local function EloComparator(subject1, subject2)
	if (not subject2.player and not subject1.player) then return subject1.id > subject2.id end
	if (not subject2.player) then return true end
	if (not subject1.player) then return false end
	local elo1 = tonumber(select(10,Spring.GetPlayerInfo(subject1.player)).elo)
	local elo2 = tonumber(select(10,Spring.GetPlayerInfo(subject2.player)).elo)
	if (not elo2 and not elo1) then return subject1.id > subject2.id end
	if (not elo2) then return true end
	if (not elo1) then return false end
	return elo1 > elo2
end

local function UpdateAllyTeam(allyTeam)
	--Spring.Echo("Updating subject team " .. allyTeam)
	local temp = {}
	local nonSpecs = false
	for _, teamID in ipairs(Spring.GetTeamList(allyTeam)) do
		local _, leader, dead, ai = Spring.GetTeamInfo(teamID, false)
		if (ai) then
			temp[#temp + 1] = {id = #temp + 1, team = teamID, ai = true, name = select(2, Spring.GetAIInfo(teamID)), allyteam = allyTeam, dead = dead}
			nonSpecs = true
		else
			for _, playerID in ipairs(Spring.GetPlayerList(teamID)) do
				local name,active,spec = Spring.GetPlayerInfo(playerID, false)
				if playerID ~= Spring.GetMyPlayerID() and (teamID ~= 0 or teamZeroPlayers[playerID]) or not spec then
					temp[#temp + 1] = {id = #temp + 1, team = teamID, player = playerID, name = name, allyteam = allyTeam, active = active, spec = spec, dead = dead}
				end
				nonSpecs = nonSpecs or active and not spec
			end
		end
	end
	table.sort(temp, EloComparator)
	if (nonSpecs or Spring.GetGameFrame() < 1) then
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
		local name,active,spec, teamID, allyTeam = Spring.GetPlayerInfo(playerID, false)
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
		SetWantRebuild()
	end
end

function widget:ReceiveUserInfo(info)
	playerInfo[info.name] = info
	
	if (built) then
		UpdateSubjects()
		if ( mySubjectID >= 0) then
			--Spring.Echo("Rebuilding")
			SetWantRebuild()
		end
	end
end

function widget:PlayerChanged(playerID)
	if (built) then
		UpdateSubjects()
		if ( mySubjectID >= 0) then
			--Spring.Echo("Rebuilding")
			SetWantRebuild()
		end
	end
end


local lastUpdate = -100
local dtSum = 0
local lastWindow = false
local myAllyTeamID = -1

function widget:Update(dt)
	if window and not window.visible then
		return
	end
	if window and window.visible then
		local showkey = string.lower(WG.crude.GetHotkey("epic_chili_share_menu_v1.24_sharemenu"))
		if (Spring.GetKeyState(Spring.GetKeyCode(showkey)) ~= window.visible) then
			window:ToggleVisibility()
		end
	end
	local f = Spring.GetGameFrame()
	local alt,ctrl,_,shift = Spring.GetModKeyState()
	dtSum = dtSum + dt
	if (f - lastUpdate >= 30 or dtSum >= 2 or window and lastWindow ~= window.visible) then
		lastWindow = window and window.visible
		dtSum = 0
		lastUpdate = f
		local invitecount = Spring.GetPlayerRulesParam(Spring.GetMyPlayerID(), "commshare_invitecount")
		
		for _, subject in ipairs(subjects) do
			if (givemebuttons[subject.id] and givemebuttons[subject.id]["accept"]) then
				SafeSetButtonVisibility(givemebuttons[subject.id]["accept"], false)
			end
		end
		if invitecount and built then
			--Spring.Echo("There are " .. invitecount .. " invites")
			UpdateInviteTable()
		end
		UpdateSubjects()
		if (Spring.GetMyAllyTeamID() ~= myAllyTeamID) then
			SetWantRebuild()
		end
		if (built and mySubjectID >= 0 and window.visible) then
			UpdatePlayers()
		end
		myAllyTeamID = Spring.GetMyAllyTeamID()
	end
	if buildframe < -1 and mySubjectID >= 0 then
		mycurrentteamid = Spring.GetMyTeamID()
		local modOptions = {}
		modOptions = Spring.GetModOptions()
		--Spring.Echo("Share mode is " .. tostring(modOptions["sharemode"]))
		if modOptions["sharemode"] == "invite" or modOptions["sharemode"] == nil then
			sharemode = true
		end
		modOptions = nil
		UpdateSubjects()
		SetWantRebuild()
		UpdatePlayers()
	end
	if buildframe > -1 and not built then
		built = true -- block PlayerChanged from doing anything until we've set up initial states.
		local modOptions = {}
		local iscommsharing = Spring.GetTeamRulesParam(Spring.GetMyTeamID(),"isCommsharing")
		modOptions = Spring.GetModOptions()
		--Spring.Echo("Automerge: " .. tostring(options.automation_clanmerge.value) .. "\niscommsharing: " .. tostring(iscommsharing == 1))
		if sharemode and not iscommsharing and options.automation_clanmerge.value == true then
			--Spring.Echo("Clan merge is enabled!")
			MergeWithClanMembers()
		end
		UpdatePlayers()
	end
end

function widget:RecvLuaMsg(msg)
	HandleKickMessage(msg)
end

function widget:Initialize()
	local spectating = Spring.GetSpectatingState()
	
	for _, playerID in ipairs(Spring.GetPlayerList()) do
		local name,active,spec, teamID, allyTeam = Spring.GetPlayerInfo(playerID, false)
		if teamID == 0 and not spec then
			teamZeroPlayers[playerID] = true
		end
	end
	chili = WG.Chili
	color2incolor = chili.color2incolor
	screen0 = chili.Screen0
	if options.fixHotkeys.value then
		WG.crude.SetHotkey("sharedialog","")
		options.fixHotkeys.value = false
	end
end
