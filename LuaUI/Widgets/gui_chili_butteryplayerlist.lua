
function widget:GetInfo()
	return {
		name      = "Buttery Player List",
		desc      = "An inexpensive playerlist.",
		author    = "GoogleFrog, esainane",
		date      = "8 November 2019",
		license   = "GNU GPL, v2 or later",
		layer     = 50,
		enabled   = true,
	}
end

if Spring.GetModOptions().singleplayercampaignbattleid then
	function widget:Initialize()
		Spring.SendCommands("info 0")
	end

	return
end

-- A test game: http://zero-k.info/Battles/Detail/797379
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	if (not maxLength) then
		return myString
	end
	local length = string.len(myString)
	while myFont:GetTextWidth(myString) > maxLength do
		length = length - 1
		myString = string.sub(myString, 0, length)
		if length < 1 then
			return ""
		end
	end
	return myString
end

function Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local truncation = Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	local dotDotWidth = myFont:GetTextWidth("..")
	truncation = Spring.Utilities.GetTruncatedString(truncation, myFont, maxLength - dotDotWidth)
	return truncation .. ".."
end

function Spring.Utilities.TruncateStringIfRequired(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
end

function Spring.Utilities.TruncateStringIfRequiredAndDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local myAllyTeamID          = Spring.GetMyAllyTeamID()
local myTeamID              = Spring.GetMyTeamID()
local myPlayerID            = Spring.GetMyPlayerID()
local mySpectating          = Spring.GetSpectatingState()
local spGetPlayerRulesParam = Spring.GetPlayerRulesParam

VFS.Include("LuaRules/Configs/constants.lua")

if mySpectating then
	myTeamID = false
	myAllyTeamID = false
end
local fallbackAllyTeamID    = Spring.GetMyAllyTeamID()

local Chili

local function GetColorChar(colorTable)
	if colorTable == nil then return string.char(255,255,255,255) end
	local col = {}
	for i = 1, 4 do
		col[i] = math.ceil(colorTable[i]*255)
	end
	return string.char(col[4],col[1],col[2],col[3])
end

local metalBarColor, energyBarColor, noStorageBarColor = {.7,.75,.9,1}, {1,1,0,1}, {.9,0,0,1}

local pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1},
	{1, 1, 1, 1},
}

local textHeightToWidth = .7

local ALLY_COLOR  = {0, 1, 1, 1}
local ENEMY_COLOR = {1, 0, 0, 1}

local PING_TIMEOUT = 2000 -- ms

local MAX_NAME_LENGTH = 150 * textHeightToWidth

local UPDATE_PERIOD = 1

local IMAGE_SHARE  = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/share.png"
local IMAGE_CPU    = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/cpu.png"
local IMAGE_PING   = ":n:" .. LUAUI_DIRNAME .. "Images/playerlist/ping.png"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function PingTimeOut(pingTime)
	if pingTime < 1 then
		return "Ping: " .. (math.floor(pingTime*1000) ..'ms')
	elseif pingTime > 999 then
		return "Ping: " .. ('' .. (math.floor(pingTime*100/60)/100)):sub(1,4) .. 'min'
	end
	--return (math.floor(pingTime*100))/100
	return "Ping: " .. ('' .. (math.floor(pingTime*100)/100)):sub(1,4) .. 's' --needed due to rounding errors.
end

local function CpuUsageOut(cpuUsage)
	return "CPU: " .. math.ceil(cpuUsage*100) .. "%"
end

local function ToGrey(v)
	if v < 0.6 then
		return 0.6 - 0.1*(0.6 - v)
	end
	return 0.6 + 0.1*(v - 0.6)
end

local function GetName(name, font, state)
	if state.isDead then
		name = "<Dead> " .. name
	elseif state.isLagging then
		name = "<Lagging> " .. name
	elseif state.isWaiting then
		name = "<Waiting> " .. name
	elseif state.isAfk then
		name = "<AFK> " .. name
	end
	
	if not font then
		return name
	end
	return Spring.Utilities.TruncateStringIfRequiredAndDotDot(name, font, MAX_NAME_LENGTH) or name
end

local function GetPlayerTeamColor(teamID, isDead)
	local r, g, b, a = Spring.GetTeamColor(teamID)
	if isDead then
		r, g, b = ToGrey(r), ToGrey(g), ToGrey(b)
	end
	return {r, g, b, a}
end

local function ShareUnits(playername, teamID)
	if not teamID then
		Spring.Echo('Player List: Invalid team to share.')
		return
	end
	local selcnt = Spring.GetSelectedUnitsCount()
	if selcnt > 0 then
		Spring.SendCommands("say a: I gave "..selcnt.." units to "..playername..".")
		Spring.ShareResources(teamID, "units")
	else
		Spring.Echo('Player List: No units selected to share.')
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function FormatResourceAsStr(input)
	if input < 0.05 then
		return "0"
	elseif input < 100 then
		return ("%.1f"):format(input)
	elseif input < 10^3 - 0.5 then
		return ("%.0f"):format(input)
	elseif input < 10^4 then
		return ("%.2f"):format(input/10^3) .. "k"
	elseif input < 10^5 then
		return ("%.1f"):format(input/10^3) .. "k"
	elseif input < 10^6 - 0.5 then
		return ("%.0f"):format(input/10^3) .. "k"
	elseif input < 10^7 then
		return ("%.2f"):format(input/10^6) .. "M"
	elseif input < 10^8 then
		return ("%.1f"):format(input/10^6) .. "M"
	else
		return ("%.0f"):format(input/10^6) .. "M"
	end
end

local MIN_STORAGE = 0.5
local function GetResourceState(teamID)
	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = Spring.GetTeamResources(teamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = Spring.GetTeamResources(teamID, "metal")
	if mCurr == nil or mStor == nil or eCurr == nil or eStor == nil or eInco == nil or mInco == nil or mReci == nil then
		return nil, nil, nil, nil, nil, nil
	end
	mStor = math.max(mStor - HIDDEN_STORAGE, MIN_STORAGE)
	eStor = math.max(eStor - HIDDEN_STORAGE, MIN_STORAGE)

	if eInco then
		local energyIncome = Spring.GetTeamRulesParam(teamID, "OD_energyIncome") or 0
		local energyChange = Spring.GetTeamRulesParam(teamID, "OD_energyChange") or 0
		eInco = eInco + energyIncome - math.max(0, energyChange)
	end

	local mLocalIncome = mInco + mReci

	-- cap by storage
	if eCurr > eStor then
		eCurr = eStor
	end
	if mCurr > mStor then
		mCurr = mStor
	end

	return mCurr, mStor, mLocalIncome, eCurr, eStor, eInco
end

local function BuildColumnOffsets()
	local o = {}
	local offset = 0

	offset = offset + 1
	o.allyTeam = offset
	offset = offset + options.text_height.value * textHeightToWidth

	offset = offset + 1
	o.clan = offset
	offset = offset + options.text_height.value + 3

	offset = offset + 1
	o.country = offset
	offset = offset + options.text_height.value + 3

	offset = offset + 1
	o.rank = offset
	offset = offset + options.text_height.value + 4

	offset = offset + 2
	o.elo = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.name = offset
	offset = offset + MAX_NAME_LENGTH

	offset = offset
	o.army = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.def = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.eco = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.metalLabel = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.energyLabel = offset
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	o.metalBar = offset
	offset = offset + 24

	offset = offset + 2
	o.energyBar = offset
	offset = offset + 24

	offset = offset + 1
	o.cpu = offset
	offset = offset + options.text_height.value

	offset = offset + 1
	o.ping = offset
	offset = offset + options.text_height.value

	offset = offset + 1
	o.share = offset
	offset = offset + options.text_height.value + 1

	o.total = offset

	return o
end

local function UpdateHumanVolatile(entryData, controls, volatileOnly, forceUpdateControls)
	-- Shared human updates - applies to both participants and spectators, as long as there's a real connection.
	-- Ping, CPU, lagging, waiting, or AFK.
	local _, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, _, _ = Spring.GetPlayerInfo(entryData.playerID, false)
	local isSpectator = false
	local newTeamID, newAllyTeamID = teamID, allyTeamID

	entryData.isMe = (entryData.playerID == myPlayerID)

	if spectator then
		isSpectator = true
		newTeamID, newAllyTeamID = entryData.initTeamID,  entryData.initAllyTeamID
	end

	local pingBucket = (active and math.max(1, math.min(5, math.ceil(math.min(pingTime, 1) * 5)))) or 6
	if forceUpdateControls or pingBucket ~= entryData.pingBucket then
		entryData.pingBucket = pingBucket
		if controls then
			controls.imPing.color = pingCpuColors[entryData.pingBucket]
			controls.imPing:Invalidate()
		end
	end

	local cpuBucket = (active and math.max(1, math.min(5, math.ceil(cpuUsage * 5)))) or 6
	if forceUpdateControls or cpuBucket ~= entryData.cpuBucket then
		entryData.cpuBucket = cpuBucket
		if controls then
			controls.imCpu.color = pingCpuColors[entryData.cpuBucket]
			controls.imCpu:Invalidate()
		end
	end

	if controls then
		controls.imCpu.tooltip = CpuUsageOut(cpuUsage)
		controls.imPing.tooltip = PingTimeOut(pingTime)
	end

	local changeName = false

	local newIsLagging = ((pingTime > PING_TIMEOUT) and true) or false
	if forceUpdateControls or newIsLagging ~= entryData.isLagging then
		entryData.isLagging = newIsLagging
		if not entryData.isDead then
			changeName = true
		end
	end

	local newIsWaiting = (not active)
	if forceUpdateControls or newIsWaiting ~= entryData.isWaiting then
		entryData.isWaiting = newIsWaiting
		if not (entryData.isDead or entryData.isLagging) then
			changeName = true
		end
	end

	local newIsAfk = (spGetPlayerRulesParam(entryData.playerID, "lagmonitor_lagging") and true) or false
	if forceUpdateControls or newIsAfk ~= entryData.isAfk then
		entryData.isAfk = newIsAfk
		if not (entryData.isDead or entryData.isLagging or entryData.isWaiting) then
			changeName = true
		end
	end

	if controls and changeName then
		controls.textName:SetCaption(GetName(entryData.name, controls.textName.font, entryData))
	end

	return isSpectator, newTeamID, newAllyTeamID
end

local function UpdateParticipantVolatile(entryData, controls, volatileOnly, forceUpdateControls)
	-- Shared volatile updates - applies to both bots and humans, as long as they're in the battle
	-- Army sizes, resource income, etc.
	local teamID = entryData.teamID
	local mCurr, mStor, mLocalIncome, eCurr, eStor, eInco = GetResourceState(teamID)
	if forceUpdateControls or mCurr ~= entryData.mCurr or mStor ~= entryData.mStor then
		if controls then
			if mCurr == nil or mStor == nil then
				controls.metalBar:SetVisibility(false)
			else
				if mStor == MIN_STORAGE then
					controls.metalBar.color = noStorageBarColor
					controls.metalBar.value = 1
					controls.metalBar.max = 1
				else
					controls.metalBar.color = metalBarColor
					controls.metalBar.value = mCurr
					controls.metalBar.max = mStor
				end
				if forceUpdateControls or entryData.mCurr == nil or entryData.mStor == nil then
					controls.metalBar:SetVisibility(true)
				end
			controls.metalBar:Invalidate()
			end
		end
		entryData.mCurr = mCurr
		entryData.mStor = mStor
	end

	if forceUpdateControls or eCurr ~= entryData.eCurr or eStor ~= entryData.eStor then
		if controls then
			if eCurr == nil or eStor == nil then
				controls.energyBar:SetVisibility(false)
			else
				if eStor == MIN_STORAGE then
					controls.energyBar.color = noStorageBarColor
					controls.energyBar.value = 1
					controls.energyBar.max = 1
				else
					controls.energyBar.color = energyBarColor
					controls.energyBar.value = eCurr
					controls.energyBar.max = eStor
				end
				if forceUpdateControls or entryData.eCurr == nil or entryData.eStor == nil then
					controls.energyBar:SetVisibility(true)
				end
			end
			controls.energyBar:Invalidate()
		end
		entryData.eCurr = eCurr
		entryData.eStor = eStor
	end
	if forceUpdateControls or mLocalIncome ~= entryData.mLocalIncome then
		if controls then
			if mLocalIncome == nil then
				controls.metalLabel:SetVisibility(false)
			else
				controls.metalLabel:SetCaption(FormatResourceAsStr(mLocalIncome))
				if forceUpdateControls or entryData.mLocalIncome == nil then
					controls.metalLabel:SetVisibility(true)
				end
			end
		end
		entryData.mLocalIncome = mLocalIncome
	end
	if forceUpdateControls or eInco ~= entryData.eInco then
		if controls then
			if eInco == nil then
				controls.energyLabel:SetVisibility(false)
			else
				controls.energyLabel:SetCaption(FormatResourceAsStr(eInco))
				if forceUpdateControls or entryData.eInco == nil then
					controls.energyLabel:SetVisibility(true)
				end
			end
		end
		entryData.eInco = eInco
	end

	local statsLength = Spring.GetGameRulesParam("gameover_historyframe") or (Spring.GetTeamStatsHistory(Spring.GetMyTeamID()) - 1)
	local armyTotal = Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_army_" .. statsLength)
	local defTotal = Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_def_" .. statsLength)
	local ecoTotal = Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_econ_" .. statsLength)
	if forceUpdateControls or armyTotal ~= entryData.armyTotal then
		if controls then
			if armyTotal == nil then
				controls.armyLabel:SetVisibility(false)
			else
				controls.armyLabel:SetCaption(FormatResourceAsStr(armyTotal))
				if forceUpdateControls or controls.armyTotal == nil then
					controls.armyLabel:SetVisibility(true)
				end
			end
		end
		entryData.armyTotal = armyTotal
	end
	if forceUpdateControls or defTotal ~= entryData.defTotal then
		if controls then
			if defTotal == nil then
				controls.defLabel:SetVisibility(false)
			else
				controls.defLabel:SetCaption(FormatResourceAsStr(defTotal))
				if forceUpdateControls or entryData.defTotal == nil then
					controls.defLabel:SetVisibility(true)
				end
			end
		end
		entryData.defTotal = defTotal
	end
	if forceUpdateControls or ecoTotal ~= entryData.ecoTotal then
		if controls then
			if ecoTotal == nil then
				controls.ecoLabel:SetVisibility(false)
			else
				controls.ecoLabel:SetCaption(FormatResourceAsStr(ecoTotal))
				if forceUpdateControls or entryData.ecoTotal == nil then
					controls.ecoLabel:SetVisibility(true)
				end
			end
		end
		entryData.ecoTotal = ecoTotal
	end
end

local function UpdateBase(entryData, controls, volatileOnly, forceUpdateControls, newTeamID, newAllyTeamID, isSpectator)
	-- Updates long term controls that don't need to change often.
	-- Controls that take team color on team color change, alliance change, resignation or defeat, etc.
	local resortRequired = false
	
	local teamColoredLabels = {}
	if controls then
		teamColoredLabels = {controls.eloLabel, controls.textName, controls.armyLabel, controls.defLabel, controls.ecoLabel, controls.metalLabel, controls.energyLabel}
	end

	if forceUpdateControls or newTeamID ~= entryData.teamID then
		entryData.teamID = newTeamID
		entryData.isMyTeam = (entryData.teamID == myTeamID)
		resortRequired = true
		if controls then
			local newTeamColor = GetPlayerTeamColor(entryData.teamID, entryData.isDead)
			for i,v in ipairs(teamColoredLabels) do
				v.font.color = newTeamColor
				v:Invalidate()
			end
		end
	end
	
	if forceUpdateControls or newAllyTeamID ~= entryData.allyTeamID then
		entryData.allyTeamID = newAllyTeamID
		resortRequired = true
		if controls then
			controls.textAllyTeam:SetCaption(entryData.allyTeamID + 1)
		end
	end
	
	local isMyAlly = (entryData.allyTeamID == (myAllyTeamID or fallbackAllyTeamID))
	if forceUpdateControls or isMyAlly ~= entryData.isMyAlly then
		entryData.isMyAlly = isMyAlly
		entryData.allyTeamColor = (isMyAlly and ALLY_COLOR) or ENEMY_COLOR
		resortRequired = true
		if controls then
			controls.textAllyTeam.font.color = entryData.allyTeamColor
			controls.textAllyTeam:Invalidate()
		end
	end
	
	local newIsDead = ((isSpectator or Spring.GetTeamRulesParam(entryData.teamID, "isDead")) and true) or false
	if forceUpdateControls or newIsDead ~= entryData.isDead then
		entryData.isDead = newIsDead
		resortRequired = true
		if controls then
			local newTeamColor = GetPlayerTeamColor(entryData.teamID, entryData.isDead)
			controls.textName:SetCaption(GetName(entryData.name, controls.textName.font, entryData))
			for i,v in ipairs(teamColoredLabels) do
				v.font.color = newTeamColor
				v:Invalidate()
			end
			local activeControls = {controls.armyLabel, controls.defLabel, controls.ecoLabel, controls.metalLabel, controls.energyLabel, controls.metalBar, controls.energyBar}
			local newIsActive = not newIsDead
			for i,v in ipairs(activeControls) do
				v:SetVisibility(newIsActive)
			end
		end
	end
	
	local newCanBeSharedTo = not (mySpectating or entryData.isMyTeam or not entryData.isMyAlly)
	if forceUpdateControls or newCanBeSharedTo ~= entryData.canBeSharedTo then
		entryData.canBeSharedTo = newCanBeSharedTo
		if controls then
			controls.metalBar:SetCanBeSharedTo(newCanBeSharedTo)
			controls.energyBar:SetCanBeSharedTo(newCanBeSharedTo)
			controls.btnShare:SetVisibility(newCanBeSharedTo)
		end
	end

	return resortRequired
end

local function UpdateEntryData(entryData, controls, volatileOnly, forceUpdateControls)
	local isSpectator = entryData.isSpectator
	local newIsSpectator = false
	local newTeamID, newAllyTeamID = entryData.teamID, entryData.allyTeamID

	if entryData.playerID then
		newIsSpectator, newTeamID, newAllyTeamID = UpdateHumanVolatile(entryData, controls, volatileOnly, forceUpdateControls)
	end
	if not newIsSpectator then
		UpdateParticipantVolatile(entryData, controls, volatileOnly, forceUpdateControls)
	end
	if volatileOnly then
		return false
	end
	return UpdateBase(entryData, controls, volatileOnly, forceUpdateControls, newTeamID, newAllyTeamID, newIsSpectator)
end

local function GetEntryData(playerID, teamID, allyTeamID, isAiTeam, isDead)
	local entryData = {
		playerID = playerID,
		teamID = teamID,
		allyTeamID = allyTeamID,
		initTeamID = teamID,
		initAllyTeamID = allyTeamID,
		isAiTeam = isAiTeam,
		isDead = isDead,
	}

	if isAiTeam then
		local _, name = Spring.GetAIInfo(teamID)
		entryData.name = name
	elseif playerID then
		local playerName, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country, rank, customKeys = Spring.GetPlayerInfo(playerID, true)
		customKeys = customKeys or {}

		entryData.isMe = (entryData.playerID == myPlayerID)
		entryData.name = playerName
		entryData.country = (country and country ~= '' and ("LuaUI/Images/flags/" .. country ..".png"))
		entryData.rank = ("LuaUI/Images/LobbyRanks/" .. (customKeys.icon or "0_0") .. ".png")

		if customKeys.clan and customKeys.clan ~= "" then
			entryData.clan = "LuaUI/Configs/Clans/" .. customKeys.clan ..".png"
		elseif customKeys.faction and customKeys.faction ~= "" then
			entryData.clan = "LuaUI/Configs/Factions/" .. customKeys.faction .. ".png"
		end

		if customKeys.elo and customKeys.elo ~= "" then
			entryData.elo = customKeys.elo
		end
	end
	
	if not entryData.name then
		entryData.name = "noname"
	end
	
	UpdateEntryData(entryData)
	
	return entryData
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- TODO: This should probably be factored out into an API function, see gui_chili_share
local function GiveResource(target,kind,num)
	local _, leader, _, isAI = Spring.GetTeamInfo(target, false)
	local name = select(1,Spring.GetPlayerInfo(leader, false))
	if isAI then
		name = select(2,Spring.GetAIInfo(target))
	end
	if #Spring.GetPlayerList(target,true) > 1 then
		name = name .. "'s squad"
	end
	Spring.SendCommands("say a: I gave " .. math.floor(num) .. " " .. kind .. " to " .. name .. ".")
	Spring.ShareResources(target,kind,num)
end

local function GetUserControls(playerID, teamID, allyTeamID, isAiTeam, isDead, parent)
	local offset             = 0
	local offsetY            = 0
	local height             = options.text_height.value + 4
	local userControls = {}

	userControls.entryData = GetEntryData(playerID, teamID, allyTeamID, isAiTeam, isDead)

	userControls.mainControl = Chili.Control:New {
		name = playerID,
		x = 0,
		bottom = 0,
		right = 0,
		height = height,
		padding = {0, 0, 0, 0},
		parent = parent
	}

	offset = offset + 1
	userControls.textAllyTeam = Chili.Label:New {
		name = "textAllyTeam",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = userControls.entryData.allyTeamID + 1,
		textColor = userControls.entryData.allyTeamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + options.text_height.value * textHeightToWidth

	offset = offset + 1
	if userControls.entryData.clan then
		userControls.imClan = Chili.Image:New {
			name = "imClan",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.clan,
		}
	end
	offset = offset + options.text_height.value + 3

	offset = offset + 1
	if userControls.entryData.country then
		userControls.imCountry = Chili.Image:New {
			name = "imCountry",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.country,
		}
	end
	offset = offset + options.text_height.value + 3

	offset = offset + 1
	if userControls.entryData.rank then
		userControls.imRank = Chili.Image:New {
			name = "imRank",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = userControls.entryData.rank,
		}
	end
	offset = offset + options.text_height.value + 4


	local teamColor = GetPlayerTeamColor(userControls.entryData.teamID, userControls.entryData.isDead)

	offset = offset + 2
	if userControls.entryData.elo and userControls.entryData.elo ~= "" then
		userControls.eloLabel = Chili.Label:New {
			name = "eloLabel",
			x = offset,
			y = offsetY + 1,
			right = 0,
			bottom = 3,
			parent = userControls.mainControl,
			caption = userControls.entryData.elo,
			textColor = teamColor,
			fontsize = options.text_height.value,
			fontShadow = true,
			autosize = false,
		}
	end
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	local userName = userControls.entryData.name
	offset = offset
	userControls.textName = Chili.Label:New {
		name = "textName",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		align = "left",
		parent = userControls.mainControl,
		caption = GetName(userName, nil, userControls.entryData),
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	userControls.textName:SetCaption(GetName(userName, userControls.textName.font, userControls.entryData))
	offset = offset + MAX_NAME_LENGTH

	offset = offset
	userControls.armyLabel = Chili.Label:New {
		name = "armyLabel",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = "?",
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	userControls.defLabel = Chili.Label:New {
		name = "defLabel",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = "?",
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	userControls.ecoLabel = Chili.Label:New {
		name = "ecoLabel",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = "?",
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	userControls.metalLabel = Chili.Label:New {
		name = "metalLabel",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = "?",
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	userControls.energyLabel = Chili.Label:New {
		name = "energyLabel",
		x = offset,
		y = offsetY + 1,
		right = 0,
		bottom = 3,
		parent = userControls.mainControl,
		caption = "?",
		textColor = teamColor,
		fontsize = options.text_height.value,
		fontShadow = true,
		autosize = false,
	}
	offset = offset + 4 * options.text_height.value * textHeightToWidth

	offset = offset
	userControls.metalBar = Chili.Progressbar:New {
		name = "metalBar",
		x = offset,
		y = offsetY,
		height = options.text_height.value,
		width = 24,
		color = metalBarColor,
		min = 0,
		max = 500 or 1,
		allyTooltip = "Double click to share 100 metal to " .. userName,
		OnDblClick = {function()
			GiveResource(userControls.entryData.teamID,"metal",100)
		end},
		SetCanBeSharedTo = function(self, canGift)
			if canGift then
				self.tooltip = self.allyTooltip
			else
				self.tooltip = ""
			end
			self:Invalidate()
		end,
		parent = userControls.mainControl
	}
	function userControls.metalBar:HitTest(x,y) return self end
	offset = offset + 24

	offset = offset + 2
	userControls.energyBar = Chili.Progressbar:New {
		name = "energyBar",
		x = offset,
		y = offsetY,
		height = options.text_height.value,
		width = 24,
		color = energyBarColor,
		min = 0,
		max = 500 or 1,
		allyTooltip = "Double click to share 100 energy to " .. userName,
		OnDblClick = {function()
			GiveResource(userControls.entryData.teamID,"energy",100)
		end},
		SetCanBeSharedTo = function(self, canGift)
			if canGift then
				self.tooltip = self.allyTooltip
			else
				self.tooltip = ""
			end
			self:Invalidate()
		end,
		parent = userControls.mainControl
	}
	function userControls.energyBar:HitTest(x,y) return self end
	offset = offset + 24

	offset = offset + 1
	if userControls.entryData.cpuBucket then
		userControls.imCpu = Chili.Image:New {
			name = "imCpu",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = IMAGE_CPU,
			color = pingCpuColors[userControls.entryData.cpuBucket],
		}
		function userControls.imCpu:HitTest(x,y) return self end
	end
	offset = offset + options.text_height.value
	
	offset = offset + 1
	if userControls.entryData.pingBucket then
		userControls.imPing = Chili.Image:New {
			name = "imPing",
			x = offset,
			y = offsetY,
			width = options.text_height.value + 3,
			height = options.text_height.value + 3,
			parent = userControls.mainControl,
			keepAspect = true,
			file = IMAGE_PING,
			color = pingCpuColors[userControls.entryData.pingBucket],
		}
		function userControls.imPing:HitTest(x,y) return self end
	end
	offset = offset + options.text_height.value

	offset = offset + 1
	userControls.btnShare = Chili.Button:New {
		name = "btnShare",
		x = offset + 2,
		y = offsetY + 2,
		width = options.text_height.value - 1,
		height = options.text_height.value - 1,
		parent = userControls.mainControl,
		caption = "",
		tooltip = "Double click to share selected units to " .. userControls.entryData.name,
		padding ={0,0,0,0},
		OnDblClick = {function(self)
			ShareUnits(userControls.entryData.name, userControls.entryData.teamID)
		end},
	}
	Chili.Image:New {
		name = "imShare",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		parent = userControls.btnShare,
		keepAspect = true,
		file = IMAGE_SHARE,
	}
	userControls.btnShare:SetVisibility(userControls.entryData.canBeSharedTo)
	offset = offset + options.text_height.value + 1

	UpdateEntryData(userControls.entryData, userControls, false, true)

	return userControls
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local playerlistWindow
local listControls = {}
local header = nil
local playersByPlayerID = {}
local teamByTeamID = {}

local function Compare(lc, rc)
	local a, b
	if options.alignToTop.value then
		a, b = lc.entryData, rc.entryData
	else
		a, b = rc.entryData, lc.entryData
	end

	if not a.isMe ~= not b.isMe then
		return a.isMe
	end
	
	if not a.isMyTeam ~= not b.isMyTeam then
		return a.isMyTeam
	end
	
	if not a.isMyAlly ~= not b.isMyAlly then
		return a.isMyAlly
	end
	
	if a.allyTeamID ~= b.allyTeamID then
		return b.allyTeamID > a.allyTeamID
	end
	
	if not a.isDead ~= not b.isDead then
		return b.isDead
	end

	if not a.isAiTeam ~= not b.isAiTeam then
		return b.isAiTeam
	end
	
	if a.elo ~= b.elo then
		return a.elo > b.elo
	end

	if a.teamID ~= b.teamID then
		return a.teamID > b.teamID
	end
	
	if a.playerID then
		return (not b.playerID) or a.playerID > b.playerID
	end
	return (not not b.playerID)
end

local function SortEntries()
	if not playerlistWindow then
		return
	end
	
	table.sort(listControls, Compare)
	
	local toTop = options.alignToTop.value
	local offset = 0
	for i = 1, #listControls do
		if toTop then
			listControls[i].mainControl._relativeBounds.top = offset
			listControls[i].mainControl._relativeBounds.bottom = nil
		else
			listControls[i].mainControl._relativeBounds.top = nil
			listControls[i].mainControl._relativeBounds.bottom = offset
		end
		listControls[i].mainControl:UpdateClientArea(false)
		
		offset = offset + options.text_height.value + 2
	end

	if header then
		if toTop then
			header._relativeBounds.top = offset
			header._relativeBounds.bottom = nil
		else
			header._relativeBounds.top = nil
			header._relativeBounds.bottom = offset
		end
		header:UpdateClientArea(false)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateTeam(teamID)
	local controls = teamByTeamID[teamID]
	if not controls then
		return
	end
	
	local toSort = UpdateEntryData(controls.entryData, controls)
	if toSort then
		SortEntries()
	end
end

local function UpdatePlayer(playerID)
	local controls = playersByPlayerID[playerID]
	if not controls then
		return
	end
	
	local toSort = UpdateEntryData(controls.entryData, controls)
	if toSort then
		SortEntries()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function InitializePlayerlist()
	if playerlistWindow then
		playerlistWindow:Dispose()
		playerlistWindow = nil
	end
	
	if listControls then
		for i = 1, #listControls do
			if listControls[i].mainControl then
				listControls[i].mainControl:Dispose()
			end
		end
		listControls = {}
		playersByPlayerID = {}
		teamByTeamID = {}
	end
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local offsets = BuildColumnOffsets()

	local windowWidth = offsets.total

	--// WINDOW
	playerlistWindow = Chili.Window:New{
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = Chili.Screen0,
		dockable = true,
		name = "Buttery Player List",
		padding = {0, 0, 0, 0},
		x = screenWidth - windowWidth,
		y = math.floor(screenHeight/10),
		width = windowWidth,
		minWidth = windowWidth,
		clientHeight = math.floor(screenHeight/2),
		minHeight = 100,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
	}

	header = Chili.Control:New{
		name = "Player List Column Headers",
		x = 0,
		bottom = 0,
		right = 0,
		height = options.text_height.value + 4,
		padding = {0,0,0,0},
		parent = playerlistWindow
	}
	for i,v in ipairs({{"allyTeam","A"},{"clan","C",3},{"country","L"},{"rank","R"},{"elo","Elo"},{"name","Player"},{"army","Army"},{"def","Porc"},{"eco","Eco"},{"metalLabel","Metal"},{"energyLabel","Energy"},{"cpu","C"},{"ping","P"},{"share","S"}}) do
		Chili.Label:New{
			name = v[1] .. " Header",
			x = offsets[v[1]] + (v[3] or 0),
			y = 1,
			right = 0,
			bottom = 3,
			parent = header,
			caption = v[2],
			fontsize = options.text_height.value,
			fontShadow = true,
			autosize = false
		}
	end

	local gaiaTeamID = Spring.GetGaiaTeamID
	local teamList = Spring.GetTeamList()

	-- Crude and Buttery both crash if they see two teams with the same leaderID (any squadding)
	-- This is a terrible, terrible workaround in the meantime.
	local leadersSeenBodge = {}

	for i = 1, #teamList do
		local teamID = teamList[i]
		if teamID ~= gaiaTeamID then
			local _, leaderID, isDead, isAiTeam, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
			if leaderID < 0 then
				leaderID = Spring.GetTeamRulesParam(teamID, "initLeaderID") or leaderID
			end
			
			if leaderID >= 0 then
				if isAiTeam then
					leaderID = nil
				end

				if not (leaderID and leadersSeenBodge[leaderID]) then
					if leaderID then
						leadersSeenBodge[leaderID] = true
					end
					local controls = GetUserControls(leaderID, teamID, allyTeamID, isAiTeam, isDead, playerlistWindow)

					listControls[#listControls + 1] = controls
					teamByTeamID[teamID] = controls
					if leaderID then
						playersByPlayerID[leaderID] = controls
					end
				end
			end
		end
	end
	
	SortEntries()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Player List'
options_order = {'text_height', 'backgroundOpacity', 'alignToTop'}
options = {
	text_height = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min = 10, max = 18, step = 1,
		OnChange = InitializePlayerlist,
		advanced = true
	},
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			playerlistWindow.backgroundColor = {1,1,1,self.value}
			playerlistWindow.borderColor = {1,1,1,self.value}
			playerlistWindow:Invalidate()
		end,
	},
	alignToTop = {
		name = "Align to top",
		type = 'bool',
		value = false,
		desc = "Align list entries to top (i.e. don't push to bottom)",
		OnChange = SortEntries,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastUpdate = 0
function widget:Update(dt)
	lastUpdate = lastUpdate + dt
	if lastUpdate < UPDATE_PERIOD then
		return
	end
	lastUpdate = 0
	
	for i = 1, #listControls do
		UpdateEntryData(listControls[i].entryData, listControls[i], true)
	end
end

function widget:PlayerChanged(playerID)
	local updateAll = false
	if playerID == myPlayerID then
		if mySpectating ~= Spring.GetSpectatingState() then
			updateAll = true
			mySpectating = Spring.GetSpectatingState()
		end
		if myAllyTeamID ~= (not mySpectating and Spring.GetMyAllyTeamID()) then
			updateAll = true
			myAllyTeamID = (not mySpectating and Spring.GetMyAllyTeamID())
		end
		if myTeamID ~= (not mySpectating and Spring.GetMyTeamID()) then
			updateAll = true
			myTeamID = (not mySpectating and Spring.GetMyTeamID())
		end
	end

	if updateAll then
		local toSort = false
		for i = 1, #listControls do
			toSort = UpdateEntryData(listControls[i].entryData, listControls[i], false, true) or toSort
		end

		if toSort then
			SortEntries()
		end
		return
	end
	
	UpdatePlayer(playerID)
end

function widget:PlayerAdded(playerID)
	UpdatePlayer(playerID)
end

function widget:PlayerRemoved(playerID)
	UpdatePlayer(playerID)
end

function widget:TeamDied(teamID)
	UpdateTeam(teamID)
end

function widget:TeamChanged(teamID)
	UpdateTeam(teamID)
end

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	InitializePlayerlist()
	Spring.SendCommands("info 0")
end

--function widget:Shutdown()
--	Spring.SendCommands("info 1")
--end
