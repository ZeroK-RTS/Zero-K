--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Economy Panel Default",
    desc      = "",
    author    = "jK, Shadowfury333, GoogleFrog",
    date      = "2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")
local MIN_STORAGE = 0.5

WG.allies = 1
--[[
WG.windEnergy = 0
WG.highPriorityBP = 0
WG.lowPriorityBP = 0
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamResources = Spring.GetTeamResources
local spGetModKeyState = Spring.GetModKeyState
local Chili

local spGetTeamRulesParam = Spring.GetTeamRulesParam

local WARNING_IMAGE = LUAUI_DIRNAME .. "Images/Crystal_Clear_app_error.png"

local GetGridColor = VFS.Include("LuaUI/Headers/overdrive.lua")
local GetFlowStr = VFS.Include("LuaUI/Headers/ecopanels.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_metal   = {136/255,214/255,251/255,1}
local col_energy  = {.93,.93,0,1}
local col_line    = {220/255,220/255,220/255,1}
local col_reserve = {0, 0, 0, 0}
local text_red    = '\255\255\100\100'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window

local fancySkinLeft, fancySkinRight

local metalWarningPanel
local energyWarningPanel
local metalNoStorage
local energyNoStorage

local window_main_display
local window_metal
local image_metal
local bar_metal
local bar_reserve_metal
local window_energy
local image_energy
local bar_energy
local bar_overlay_energy
local bar_reserve_energy
local lbl_storage_metal
local lbl_storage_energy
local lbl_expense_metal
local lbl_expense_energy
local lbl_income_metal
local lbl_income_energy

local positiveColourStr
local negativeColourStr
local col_income
local col_expense
local col_highlight
local col_overdrive

local RESERVE_SEND_TIME = 1

local updateOpacity = false

local reserveSentTimer = false
local blinkMetal = 0
local blinkEnergy = 0
local BLINK_UPDATE_RATE = 0.1
local blinkM_status = false
local blinkE_status = false
local excessE = false
local flashModeEnabled = true

local strings = {
	local_metal_economy = "",
	local_energy_economy = "",
	team_metal_economy = "",
	team_energy_economy = "",
	resbar_base_extraction = "",
	resbar_overdrive = "",
	resbar_reclaim = "",
	resbar_cons = "",
	resbar_sharing = "",
	resbar_construction = "",
	resbar_reserve = "",
	resbar_stored = "",
	resbar_no_storage = "",
	resbar_inc = "",
	resbar_pull = "",
	resbar_generators = "",
	resbar_sharing_and_overdrive = "",
	resbar_other = "",
	resbar_waste = "",
	resbar_waste_total = "",
	resbar_reclaim_total = "",
	resbar_unit_value = "",
	resbar_nano_value = "",
	resbar_overdrive_efficiency = "",
	metal = "",
	metal_excess_warning = "",
	energy_stall_warning = "",
}

function languageChanged ()
	for k, v in pairs(strings) do
		strings[k] = WG.Translate ("interface", k)
	end
	if lbl_storage_metal then
		lbl_storage_metal.tooltip = WG.Translate("interface", "resbar_metal_storage_tooltip")
	end
	if lbl_storage_energy then
		lbl_storage_energy.tooltip = WG.Translate("interface", "resbar_energy_storage_tooltip")
	end
	if lbl_income_metal then
		lbl_income_metal.tooltip = WG.Translate("interface", "resbar_metal_income_tooltip")
	end
	if lbl_income_energy then
		lbl_income_energy.tooltip = WG.Translate("interface", "resbar_energy_income_tooltip")
	end
	if bar_metal then
		bar_metal.tooltip = WG.Translate("interface", "resbar_metal_bar_tooltip")
	end
	if bar_energy then
		bar_energy.tooltip = WG.Translate("interface", "resbar_energy_bar_tooltip")
	end
	if lbl_expense_metal then
		lbl_expense_metal.tooltip = WG.Translate("interface", "resbar_metal_expense_tooltip")
	end
	if lbl_expense_energy then
		lbl_expense_energy.tooltip = WG.Translate("interface", "resbar_energy_expense_tooltip")
	end
	if metalWarningPanel then
		metalWarningPanel.SetText(strings.metal_excess_warning)
	end
	if energyWarningPanel then
		energyWarningPanel.SetText(strings.energy_stall_warning)
	end
	if metalNoStorage then
		metalNoStorage.SetText(strings.resbar_no_storage)
	end
	if energyNoStorage then
		energyNoStorage.SetText(strings.resbar_no_storage)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Economy Panel'

local function option_recreateWindow()
	local x,y,w,h = DestroyWindow()
	if options.ecoPanelHideSpec.value then
		local spectating = select(1, Spring.GetSpectatingState())
		if spectating then
			return false
		end
	end
	
	CreateWindow(x,y,w,h)
	return true
end

local function ApplySkin(skinWindow, className)
	local currentSkin = Chili.theme.skin.general.skinName
	local skin = Chili.SkinHandler.GetSkin(currentSkin)
	
	local newClass = skin.panel
	if className and skin[className] then
		newClass = skin[className]
	end
	
	skinWindow.tiles = newClass.tiles
	skinWindow.TileImageFG = newClass.TileImageFG
	--skinWindow.backgroundColor = newClass.backgroundColor
	skinWindow.TileImageBK = newClass.TileImageBK
	if newClass.padding then
		skinWindow.padding = newClass.padding
		skinWindow:UpdateClientArea()
	end
	skinWindow:Invalidate()
end

local function option_colourBlindUpdate()
	positiveColourStr = (options.colourBlind.value and YellowStr) or GreenStr
	negativeColourStr = (options.colourBlind.value and BlueStr) or RedStr
	col_income = (options.colourBlind.value and {.9,.9,.2,1}) or {.1,1,.2,1}
	col_expense = (options.colourBlind.value and {.2,.3,1,1}) or {1,.3,.2,1}
	col_overdrive = (options.colourBlind.value and {1,1,1,1}) or {.5,1,0,1}
	col_highlight = {1, 0.5, 0.5, 1}
end

options_order = {
	'ecoPanelHideSpec', 'eExcessFlash', 'energyFlash', 'energyWarning', 'metalWarning', 'opacity',
	'enableReserveBar','defaultEnergyReserve','defaultMetalReserve', 'flowAsArrows',
	'colourBlind','fontSize','warningFontSize', 'fancySkinning'}
 
options = {
	ecoPanelHideSpec = {
		name  = 'Hide if spectating',
		type  = 'bool',
		value = false,
		noHotkey = true,
		desc = "Should the panel hide when spectating?",
		OnChange = option_recreateWindow
	},
	eExcessFlash = {
		name  = 'Flash On Energy Excess',
		type  = 'bool',
		value = false,
		noHotkey = true,
		desc = "When enabled energy storage will flash if energy is being excessed. This only occurs if too much energy is left unlinked to metal extractors because normally excess is used for overdrive."
	},
	enableReserveBar = {
		name  = 'Enable Reserve',
		type  = 'bool',
		value = true,
		noHotkey = true,
		desc = "Ctrl+Click on the resource bars will set reserve when enabled. Low and Normal priority constructors cannot use resources in reserve storage."
	},
	defaultEnergyReserve = {
		name  = "Initial Energy Reserve",
		type  = "number",
		value = 0.05, min = 0, max = 1, step = 0.01,
	},
	defaultMetalReserve = {
		name  = "Initial Metal Reserve",
		type  = "number",
		value = 0, min = 0, max = 1, step = 0.01,
	},
	energyFlash = {
		name  = "Energy Stall Flash",
		type  = "number",
		value = 0.1, min=0,max=1,step=0.02,
		desc = "Energy storage will flash when it drops below this fraction of your total storage."
	},
	energyWarning = {
		name  = "Energy Stall Warning",
		type  = "number",
		value = 0.1, min = 0,max = 1, step = 0.02,
		desc = "Recieve a warning when energy storage drops below this value."
	},
	metalWarning = {
		name  = "Metal Excess Warning",
		type  = "number",
		value = 0.9, min = 0,max = 1, step = 0.02,
		desc = "Recieve a warning when metal storage exceeds this value."
	},
	flowAsArrows = {
		name  = "Flow as arrows",
		desc = "Use arrows instead of a number for the flow. Each arrow is 5 resources per second.",
		type  = "bool",
		value = true,
		noHotkey = true,
		OnChange = function(self)
			if bar_metal then
				bar_metal.font.size = self.value and 20 or 16
				bar_metal.fontOffset = self.value and -2 or 1
				if bar_metal.net then
					bar_metal:SetCaption(GetFlowStr(bar_metal.net, self.value, positiveColourStr, negativeColourStr))
				end
				bar_metal:Invalidate()
			end
			if bar_overlay_energy then
				bar_overlay_energy.font.size = self.value and 20 or 16
				bar_overlay_energy.fontOffset = self.value and -2 or 1
				if bar_overlay_energy.net then
					bar_overlay_energy:SetCaption(GetFlowStr(bar_overlay_energy.net, self.value, positiveColourStr, negativeColourStr))
				end
				bar_overlay_energy:Invalidate()
			end
		end,
	},
	opacity = {
		name  = "Opacity",
		type  = "number",
		value = 0.6, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			updateOpacity = self.value
		end,
	},
	colourBlind = {
		name  = "Colourblind mode",
		type  = "bool",
		value = false,
		noHotkey = true,
		OnChange = option_colourBlindUpdate,
		desc = "Uses Blue and Yellow instead of Red and Green for number display"
	},
	fontSize = {
		name  = "Font Size",
		type  = "number",
		value = 20, min = 8, max = 40, step = 1,
		OnChange = option_recreateWindow
	},
	warningFontSize = {
		name  = "Warning Font Size",
		type  = "number",
		value = 14, min = 8, max = 40, step = 1,
		OnChange = option_recreateWindow
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'radioButton',
		value = 'panel',
		items = {
			-- Item keys correspond to what the metal panel should look like.
			{key = 'panel', name = 'None'},
			{key = 'panel_2021', name = 'Flush',},
			{key = 'panel_2011', name = 'Not Flush',},
		},
		OnChange = function (self)
			if self.value == "panel_2011" then
				fancySkinLeft = "panel_2011"
				fancySkinRight = "panel_1021"
			else
				fancySkinLeft = self.value
				fancySkinRight = self.value
			end
			
			ApplySkin(window_metal, fancySkinLeft)
			ApplySkin(window_energy, fancySkinRight)
		end,
		hidden = true,
		noHotkey = true,
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local cp = {}

-- note works only in communism mode
function UpdateCustomParamResourceData()

	local teamID = Spring.GetLocalTeamID()
	cp.allies               = spGetTeamRulesParam(teamID, "OD_allies") or 1
	
	if cp.allies < 1 then
		cp.allies = 1
	end
	
	cp.team_metalBase       = spGetTeamRulesParam(teamID, "OD_team_metalBase") or 0
	cp.team_metalOverdrive  = spGetTeamRulesParam(teamID, "OD_team_metalOverdrive") or 0
	cp.team_metalMisc       = spGetTeamRulesParam(teamID, "OD_team_metalMisc") or 0
	
	cp.team_energyIncome    = spGetTeamRulesParam(teamID, "OD_team_energyIncome") or 0
	cp.team_energyMisc      = spGetTeamRulesParam(teamID, "OD_team_energyMisc") or 0
	cp.team_energyOverdrive = spGetTeamRulesParam(teamID, "OD_team_energyOverdrive") or 0
	cp.team_energyWaste     = spGetTeamRulesParam(teamID, "OD_team_energyWaste") or 0
	
	cp.metalBase       = spGetTeamRulesParam(teamID, "OD_metalBase") or 0
	cp.metalOverdrive  = spGetTeamRulesParam(teamID, "OD_metalOverdrive") or 0
	cp.metalMisc       = spGetTeamRulesParam(teamID, "OD_metalMisc") or 0
    
	cp.metalReclaimTotal = spGetTeamRulesParam(teamID, "stats_history_metal_reclaim_current") or 0
	cp.metalValue        = spGetTeamRulesParam(teamID, "stats_history_unit_value_current") or 0
	cp.nanoframeValue    = spGetTeamRulesParam(teamID, "stats_history_nano_partial_current") or 0
	cp.nanoframeTotal    = spGetTeamRulesParam(teamID, "stats_history_nano_total_current") or 0

	cp.team_metalReclaimTotal = 0
	cp.team_metalValue = 0
	cp.team_nanoframeTotal = 0
	cp.team_nanoframeValue = 0
	cp.team_metalExcess = 0
	local allies = Spring.GetTeamList(Spring.GetMyAllyTeamID())
	if allies then
		for i = 1, #allies do
			local allyID = allies[i]
			cp.team_metalReclaimTotal = cp.team_metalReclaimTotal + (spGetTeamRulesParam(allyID, "stats_history_metal_reclaim_current") or 0)
			cp.team_metalValue        = cp.team_metalValue        + (spGetTeamRulesParam(allyID, "stats_history_unit_value_current")    or 0)
			cp.team_metalExcess       = cp.team_metalExcess       + (spGetTeamRulesParam(allyID, "stats_history_metal_excess_current")  or 0)
			cp.team_nanoframeValue    = cp.team_nanoframeValue    + (spGetTeamRulesParam(allyID, "stats_history_nano_partial_current")  or 0)
			cp.team_nanoframeTotal    = cp.team_nanoframeTotal    + (spGetTeamRulesParam(allyID, "stats_history_nano_total_current")    or 0)
		end
	end
	
	cp.energyIncome    = spGetTeamRulesParam(teamID, "OD_energyIncome") or 0
	cp.energyMisc      = spGetTeamRulesParam(teamID, "OD_energyMisc") or 0
	cp.energyOverdrive = spGetTeamRulesParam(teamID, "OD_energyOverdrive") or 0
	cp.energyChange    = spGetTeamRulesParam(teamID, "OD_energyChange") or 0
	
	-- Spectators read the reserve state of the player they are spectating.
	-- Players have the resource bar keep track of reserve locally.
	if (not reserveSentTimer) or Spring.GetSpectatingState() then
		local teamID = Spring.GetLocalTeamID()
		local mStor = select(2, spGetTeamResources(teamID, "metal")) - HIDDEN_STORAGE
		cp.metalStorageReserve = Spring.GetTeamRulesParam(teamID, "metalReserve") or 0
		if mStor <= 0 and bar_reserve_metal.bars[1].percent ~= 0 then
			bar_reserve_metal.bars[1].percent = 0
			bar_reserve_metal:Invalidate()
		elseif bar_reserve_metal.bars[1].percent*mStor ~= cp.metalStorageReserve then
			bar_reserve_metal.bars[1].percent = cp.metalStorageReserve/mStor
			bar_reserve_metal:Invalidate()
		end
		
		local eStor = select(2, spGetTeamResources(teamID, "energy")) - HIDDEN_STORAGE
		cp.energyStorageReserve = Spring.GetTeamRulesParam(teamID, "energyReserve") or 0
		if eStor <= 0 and bar_reserve_energy.bars[1].percent ~= 0 then
			bar_reserve_energy.bars[1].percent = 0
			bar_reserve_energy:Invalidate()
		elseif bar_reserve_energy.bars[1].percent*eStor ~= cp.energyStorageReserve then
			bar_reserve_energy.bars[1].percent = cp.energyStorageReserve/eStor
			bar_reserve_energy:Invalidate()
		end
	end
end

local function UpdateReserveBars(metal, energy, value, overrideOption, localOnly)
	if options.enableReserveBar.value or overrideOption then
		if value < 0 then
			value = 0
		end
		if value > 1 then
			value = 1
		end
		
		reserveSentTimer = RESERVE_SEND_TIME
		
		if metal then
			local _, mStor = spGetTeamResources(spGetMyTeamID(), "metal")
			if not localOnly then
				Spring.SendLuaRulesMsg("mreserve:"..value*(mStor - HIDDEN_STORAGE))
			end
			cp.metalStorageReserve = value*(mStor - HIDDEN_STORAGE)
			bar_reserve_metal.bars[1].percent = value
			bar_reserve_metal:Invalidate()
		end
		if energy then
			local _, eStor = spGetTeamResources(spGetMyTeamID(), "energy")
			if not localOnly then
				Spring.SendLuaRulesMsg("ereserve:"..value*(eStor - HIDDEN_STORAGE))
			end
			cp.energyStorageReserve = value*(eStor - HIDDEN_STORAGE)
			bar_reserve_energy.bars[1].percent = value
			bar_reserve_energy:Invalidate()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Mix(startColour, endColour, interpParam)
	return {endColour[1] * interpParam + startColour[1] * (1 - interpParam),
	endColour[2] * interpParam + startColour[2] * (1 - interpParam),
	endColour[3] * interpParam + startColour[3] * (1 - interpParam),
	endColour[4] * interpParam + startColour[4] * (1 - interpParam), }
end

local BlinkStatusFunc = {
	[1] = function (index)
		index = index%12
		if index < 6 then
			return index*0.8/5
		else
			return (11 - index)*0.8/5
		end
	end,
	[2] = function (index)
		index = index%8
		if index < 4 then
			return 0.25 + index*0.75/3
		else
			return 0.25 + (7 - index)*0.75/3
		end
	end,
}

local timer = 0
local blinkIndex = 0
local function UpdateBlink(dt)
	timer = timer + dt
	if timer < BLINK_UPDATE_RATE then
		return
	end
	timer = timer - BLINK_UPDATE_RATE
	blinkIndex = (blinkIndex + 1)%24
	
	if blinkM_status then
		bar_metal:SetColor(Mix({col_metal[1], col_metal[2], col_metal[3], 0.65}, col_highlight, BlinkStatusFunc[blinkM_status](blinkIndex)))
	end
	
	if blinkE_status then
		bar_overlay_energy:SetColor(col_expense[1], col_expense[2], col_expense[3], BlinkStatusFunc[blinkE_status](blinkIndex))
	end
	
	metalNoStorage.UpdateFlash(blinkIndex)
	energyNoStorage.UpdateFlash(blinkIndex)
end

local function UpdateWindowOpacity()
	if updateOpacity then
		if (window_metal) then
			window_metal.backgroundColor[4] = updateOpacity
			window_metal:Invalidate()
		end
		if (window_energy) then
			window_energy.backgroundColor[4] = updateOpacity
			window_energy:Invalidate()
		end
		updateOpacity = false
	end
end

local function UpdateReserveSentTimer(dt)
	if not reserveSentTimer then
		return
	end
	reserveSentTimer = reserveSentTimer - dt
	if reserveSentTimer < 0 then
		reserveSentTimer = false
	end
end

local function NoStorageEnergyStall(mInco, mPull, eInco, ePull)
	if eInco >= ePull then
		return false
	end
	-- Known: eInco < ePull
	if mInco >= mPull then
		return true
	end
	-- Known: eInco < ePull, mInco < mPull
	if ePull == 0 or mPull == 0 then
		-- Should be impossible
		return false
	end
	-- The following fails with some priority arrangements.
	return eInco/ePull > mInco/mPull
end

local function Format(input, override)
	local leadingString = positiveColourStr .. "+"
	if input < 0 then
		leadingString = negativeColourStr .. "-"
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.05 then
		if override then
			return override .. "0.0"
		end
		return WhiteStr .. "0"
	elseif input < 100 then
		return leadingString .. ("%.1f"):format(input) .. WhiteStr
	elseif input < 10^3 - 0.5 then
		return leadingString .. ("%.0f"):format(input) .. WhiteStr
	elseif input < 10^4 then
		return leadingString .. ("%.2f"):format(input/1000) .. "k" .. WhiteStr
	elseif input < 10^5 then
		return leadingString .. ("%.1f"):format(input/1000) .. "k" .. WhiteStr
	else
		return leadingString .. ("%.0f"):format(input/1000) .. "k" .. WhiteStr
	end
end

local initialReserveSet = false
function widget:GameFrame(n)

	if (n%TEAM_SLOWUPDATE_RATE ~= 0) then
		return
	end
	
	if not window then
		if not option_recreateWindow() then
			return
		end
	end
	
	if n > 5 and not initialReserveSet then
		UpdateReserveBars(true, false, options.defaultMetalReserve.value, true)
		UpdateReserveBars(false, true, options.defaultEnergyReserve.value, true)
		initialReserveSet = true
	end
	
	UpdateCustomParamResourceData()

	local myTeamID = Spring.GetLocalTeamID()
	local myAllyTeamID = Spring.GetMyAllyTeamID()
	local teams = Spring.GetTeamList(myAllyTeamID)
	
	local totalPull = 0
	local teamEnergyExp = 0
	
	local teamMInco = 0
	local teamMSpent = 0
	local teamMPull = 0
	local teamFreeStorage = 0
	
	local teamEnergyReclaim = 0
	
	local teamTotalMetalStored = 0
	local teamTotalMetalCapacity = 0
	local teamTotalEnergyStored = 0
	local teamTotalEnergyCapacity = 0
	for i = 1, #teams do
		local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = spGetTeamResources(teams[i], "metal")
		mStor = math.max(mStor - HIDDEN_STORAGE, MIN_STORAGE)
		teamMInco = teamMInco + mInco
		teamMSpent = teamMSpent + mExpe
		teamFreeStorage = teamFreeStorage + mStor - mCurr
		teamTotalMetalStored = teamTotalMetalStored + mCurr
		teamTotalMetalCapacity = teamTotalMetalCapacity + mStor
		
		local extraMetalPull = spGetTeamRulesParam(teams[i], "extraMetalPull") or 0
		teamMPull = teamMPull + mPull + extraMetalPull
		
		local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = spGetTeamResources(teams[i], "energy")
		eStor = math.max(eStor - HIDDEN_STORAGE, MIN_STORAGE)
		local extraEnergyPull = spGetTeamRulesParam(teams[i], "extraEnergyPull") or 0
		
		local energyOverdrive = spGetTeamRulesParam(teams[i], "OD_energyOverdrive") or 0
		local energyChange    = spGetTeamRulesParam(teams[i], "OD_energyChange") or 0
		local extraChange     = math.min(0, energyChange) - math.min(0, energyOverdrive)
		
		totalPull = totalPull + ePull + extraEnergyPull + extraChange
		teamEnergyExp = teamEnergyExp + eExpe + extraChange
		teamEnergyReclaim = teamEnergyReclaim + eInco - math.max(0, energyChange)
		
		teamTotalEnergyStored = teamTotalEnergyStored + eCurr
		teamTotalEnergyCapacity = teamTotalEnergyCapacity + eStor
	end

	local teamEnergyIncome = teamEnergyReclaim + cp.team_energyIncome
	
	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = spGetTeamResources(myTeamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = spGetTeamResources(myTeamID, "metal")
	
	local eReclaim = eInco - math.max(0, cp.energyChange)
	eInco = eReclaim + cp.energyIncome
	
	totalPull = totalPull - cp.team_energyWaste
	teamEnergyExp = teamEnergyExp - cp.team_energyWaste
	
	local extraMetalPull = spGetTeamRulesParam(myTeamID, "extraMetalPull") or 0
	local extraEnergyPull = spGetTeamRulesParam(myTeamID, "extraEnergyPull") or 0
	mPull = mPull + extraMetalPull
	
	local extraChange = math.min(0, cp.energyChange) - math.min(0, cp.energyOverdrive)
	eExpe = eExpe + extraChange
	ePull = ePull + extraEnergyPull + extraChange - cp.team_energyWaste/cp.allies
	-- Waste energy is reported as the equal fault of all players.
	
	-- reduce by hidden storage
	mStor = math.max(mStor - HIDDEN_STORAGE, MIN_STORAGE)
	eStor = math.max(eStor - HIDDEN_STORAGE, MIN_STORAGE)
	
	-- Waste
	local teamMetalWaste = math.min(0, teamTotalMetalCapacity - teamTotalMetalStored)
	if teamTotalMetalStored > teamTotalMetalCapacity then
		teamTotalMetalStored = teamTotalMetalCapacity
	end
	
	-- Metal Blink
	if flashModeEnabled and (mCurr >= mStor or teamMetalWaste > 0) then
		blinkM_status = 2
	elseif flashModeEnabled and mCurr >= mStor * 0.9 then
		-- Blink less fast
		blinkM_status = 1
	elseif blinkM_status then
		blinkM_status = false
		bar_metal:SetColor(col_metal)
	end

	-- cap by storage
	if eCurr > eStor then
		eCurr = eStor
	end
	if mCurr > mStor then
		mCurr = mStor
	end
	
	local ODEFlashThreshold = 0.1

	--// Storage, income and pull numbers
	local realEnergyPull = ePull

	local netMetal = mInco - mPull + mReci
	local netEnergy = eInco - realEnergyPull
	
	-- Energy Blink
	local wastingE = false
	if options.eExcessFlash.value then
		wastingE = (cp.team_energyWaste > 0)
	end
	local stallingE = (eCurr <= eStor * options.energyFlash.value) and (eCurr < 1000) and (eCurr >= 0)
	if flashModeEnabled and (stallingE or wastingE) then
		if stallingE and netEnergy < 0 then
			blinkE_status = 2
		else
			blinkE_status = 1
		end
		bar_energy:SetValue( 100 )
		excessE = wastingE
	elseif blinkE_status then
		blinkE_status = false
		bar_energy:SetColor( col_energy )
		bar_overlay_energy:SetColor({0,0,0,0})
	end

	-- Warnings
	local metalWarning = (mStor > 1 and mCurr > mStor * options.metalWarning.value) or (mStor <= 1 and netMetal > 0)
	local energyWarning = (eStor > 1 and eCurr < eStor * options.energyWarning.value) or ((not metalWarning) and eStor <= 1 and eInco < mInco)
	metalWarningPanel.ShowWarning(flashModeEnabled and (metalWarning and not energyWarning))
	energyWarningPanel.ShowWarning(flashModeEnabled and energyWarning)
	
	local mPercent, ePercent
	if mStor > 1 then
		mPercent = 100 * mCurr / mStor
	else
		mPercent = 0
		mCurr = 0
		metalNoStorage.SetFlash(metalWarning)
	end
	
	if eStor > 1 then
		ePercent = 100 * eCurr / eStor
	else
		ePercent = 0
		eCurr = 0
		energyNoStorage.SetFlash((cp.team_energyWaste > 0) or NoStorageEnergyStall(mInco+mReci, mPull, eInco, realEnergyPull))
	end
	
	metalNoStorage.Show(mStor <= 1)
	energyNoStorage.Show(eStor <= 1)
	
	mPercent = math.min(math.max(mPercent, 0), 100)
	ePercent = math.min(math.max(ePercent, 0), 100)

	bar_metal:SetValue( mPercent )
	bar_energy:SetValue( ePercent )
	
	local metalBase = Format(cp.metalBase)
	local metalOverdrive = Format(cp.metalOverdrive)
	local metalReclaim = Format(math.max(0, mInco - cp.metalOverdrive - cp.metalBase - cp.metalMisc - mReci))
	local metalConstructor = Format(cp.metalMisc)
	local metalShare = Format(mReci - mSent)
	local metalConstruction = Format(-mExpe)
	
	local team_metalTotalIncome = Format(teamMInco)
	local team_metalPull = Format(-teamMPull)
	local team_metalBase = Format(cp.team_metalBase)
	local team_metalOverdrive = Format(cp.team_metalOverdrive)
	local team_metalReclaim = Format(math.max(0, teamMInco - cp.team_metalOverdrive - cp.team_metalBase - cp.team_metalMisc))
	local team_metalConstructor = Format(cp.team_metalMisc)
	local team_metalConstruction = Format(-teamMSpent)
	local team_metalWaste = Format(teamMetalWaste)
	
	local energyGenerators = Format(cp.energyIncome - cp.energyMisc)
	local energyReclaim = Format(eReclaim)
	local energyMisc = Format(cp.energyMisc)
	local energyOverdrive = Format(cp.energyOverdrive)
	local energyOther = Format(-eExpe + mExpe - math.min(0, cp.energyOverdrive))
	
	local team_energyIncome = Format(teamEnergyIncome)
	local team_energyGenerators = Format(cp.team_energyIncome - cp.team_energyMisc)
	local team_energyReclaim = Format(teamEnergyReclaim)
	local team_energyMisc = Format(cp.team_energyMisc)
	local team_energyPull = Format(-totalPull)
	local team_energyOverdrive = Format(-cp.team_energyOverdrive)
	local team_energyWaste = Format(-cp.team_energyWaste)
	local team_energyOther = Format(-teamEnergyExp + teamMSpent + cp.team_energyOverdrive)

	local odEff = (cp.team_metalOverdrive > 0) and (cp.team_energyOverdrive / cp.team_metalOverdrive) or 0
	local odColor = GetGridColor((odEff < 1) and 0 or (odEff < 4.2 and 4.2 or odEff)) -- grids below 4.2 have dark colors which make the text illegible; 0 is okay though
	local odEffStr = string.char(255, odColor[1] * 255, odColor[2] * 255, odColor[3] * 255) .. ("%.1f"):format(odEff) .. WhiteStr

	image_metal.tooltip = strings["local_metal_economy"] ..
	"\n  " .. strings["resbar_base_extraction"] .. ": " .. metalBase ..
	"\n  " .. strings["resbar_overdrive"] .. ": " .. metalOverdrive ..
	"\n  " .. strings["resbar_reclaim"] .. ": " .. metalReclaim ..
	"\n  " .. strings["resbar_cons"] .. ": " .. metalConstructor ..
	"\n  " .. strings["resbar_sharing"] .. ": " .. metalShare ..
	"\n  " .. strings["resbar_construction"] .. ": " .. metalConstruction ..
    "\n  " .. strings["resbar_reserve"] .. ": " .. math.ceil(cp.metalStorageReserve or 0) ..
    "\n  " .. strings["resbar_stored"] .. ": " .. ("%i / %i"):format(mCurr, mStor)  ..
	"\n " ..
	"\n  " .. strings["resbar_reclaim_total"] .. ": " .. math.ceil(cp.metalReclaimTotal or 0) ..
	"\n  " .. strings["resbar_unit_value"] .. ": " .. math.ceil(cp.metalValue or 0) ..
	"\n  " .. strings["resbar_nano_value"] .. ": " .. math.ceil(cp.nanoframeValue or 0) .. " / " .. math.ceil(cp.nanoframeTotal or 0) ..
	"\n " ..
	"\n" .. strings["team_metal_economy"] ..
	"\n  " .. strings["resbar_inc"] .. ": " .. team_metalTotalIncome .. "      " .. strings["resbar_pull"] .. ": " .. team_metalPull ..
	"\n  " .. strings["resbar_base_extraction"] .. ": " .. team_metalBase ..
	"\n  " .. strings["resbar_overdrive"] .. ": " .. team_metalOverdrive ..
	"\n  " .. strings["resbar_reclaim"] .. " : " .. team_metalReclaim ..
	"\n  " .. strings["resbar_cons"] .. ": " .. team_metalConstructor ..
	"\n  " .. strings["resbar_construction"] .. ": " .. team_metalConstruction ..
	"\n  " .. strings["resbar_waste"] .. ": " .. team_metalWaste ..
    "\n  " .. strings["resbar_stored"] .. ": " .. ("%i / %i"):format(teamTotalMetalStored, teamTotalMetalCapacity) ..
	"\n" ..
	"\n  " .. strings["resbar_reclaim_total"] .. ": " .. math.ceil(cp.team_metalReclaimTotal or 0) ..
	"\n  " .. strings["resbar_unit_value"] .. ": " .. math.ceil(cp.team_metalValue or 0) ..
	"\n  " .. strings["resbar_nano_value"] .. ": " .. math.ceil(cp.team_nanoframeValue or 0) .. " / " .. math.ceil(cp.team_nanoframeTotal or 0) ..
	"\n  " .. strings["resbar_waste_total"] .. ": " .. math.ceil(cp.team_metalExcess or 0)
	
	image_energy.tooltip = strings["local_energy_economy"] ..
	"\n  " .. strings["resbar_generators"] .. ": " .. energyGenerators ..
	"\n  " .. strings["resbar_reclaim"] .. ": " .. energyReclaim ..
	"\n  " .. strings["resbar_cons"] .. ": " .. energyMisc ..
	"\n  " .. strings["resbar_sharing_and_overdrive"] .. ": " .. energyOverdrive ..
	"\n  " .. strings["resbar_construction"] .. ": " .. metalConstruction ..
	"\n  " .. strings["resbar_other"] .. ": " .. energyOther ..
    "\n  " .. strings["resbar_reserve"] .. ": " .. math.ceil(cp.energyStorageReserve or 0) ..
    "\n  " .. strings["resbar_stored"] .. ": " .. ("%i / %i"):format(eCurr, eStor)  ..
	"\n " ..
	"\n" .. strings["team_energy_economy"] ..
	"\n  " .. strings["resbar_inc"] .. ": " .. team_energyIncome .. "      " .. strings["resbar_pull"] .. ": " .. team_energyPull ..
	"\n  " .. strings["resbar_generators"] .. ": " .. team_energyGenerators ..
	"\n  " .. strings["resbar_reclaim"] .. ": " .. team_energyReclaim ..
	"\n  " .. strings["resbar_cons"] .. ": " .. team_energyMisc ..
	"\n  " .. strings["resbar_overdrive"] .. ": " .. team_energyOverdrive .. " -> " .. team_metalOverdrive .. " " .. strings["metal"] ..
	"\n  " .. strings["resbar_construction"] .. ": " .. team_metalConstruction ..
	"\n  " .. strings["resbar_other"] .. ": " .. team_energyOther ..
	"\n  " .. strings["resbar_waste"] .. ": " .. team_energyWaste ..
	"\n  " .. strings["resbar_overdrive_efficiency"] .. ": " .. odEffStr .. " E/M" ..
    "\n  " .. strings["resbar_stored"] .. ": " .. ("%i / %i"):format(teamTotalEnergyStored, teamTotalEnergyCapacity)
	
	lbl_expense_metal:SetCaption( negativeColourStr..Format(mPull, negativeColourStr.." -") )
	lbl_expense_energy:SetCaption( negativeColourStr..Format(realEnergyPull, negativeColourStr.." -") )
	lbl_income_metal:SetCaption( Format(mInco+mReci, positiveColourStr.."+") )
	lbl_income_energy:SetCaption( Format(eInco, positiveColourStr.."+") )
	lbl_storage_energy:SetCaption(("%.0f"):format(eCurr))
	lbl_storage_metal:SetCaption(("%.0f"):format(mCurr))

	--// Net income indicator on resource bars.
	bar_metal:SetCaption(GetFlowStr(netMetal, options.flowAsArrows.value, positiveColourStr, negativeColourStr))
	bar_overlay_energy:SetCaption(GetFlowStr(netEnergy, options.flowAsArrows.value, positiveColourStr, negativeColourStr))

	-- save so that we can switch representation without recalculating
	bar_metal.net = netMetal
	bar_overlay_energy.net = netEnergy
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Warning Panels

local function GetWarningPanel(parentControl, x, y, right, bottom, text)
	local holder = Chili.Control:New{
		x = x,
		y = y,
		right = right,
		bottom = bottom,
		padding = {0, 0, 0, 0},
		parent = parentControl
	}
	
	local image = Chili.Image:New{
		name   = "warningImage",
		x      = "1%",
		y      = 0,
		bottom = 0,
		width  = "20%",
		keepAspect = true,
		file   = WARNING_IMAGE,
		parent = holder,
	}
	
	local label = Chili.Label:New{
		name   = "warningLabel",
		x      = "21%",
		y      = 0,
		bottom = "8%",
		width  = 200,
		caption = text,
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {size = options.warningFontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		parent = holder,
	}
	
	image:SetVisibility(false)
	label:SetVisibility(false)
	
	local externalFunctions = {}
	
	function externalFunctions.ShowWarning(newShow)
		image:SetVisibility(newShow)
		label:SetVisibility(newShow)
	end
	function externalFunctions.SetText(newText)
		label:SetCaption(newText)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- No Storage Warning Panels

local function GetNoStorageWarning(parentControl, x, y, right, height, barHolder)
	local holder = Chili.Control:New{
		x = x,
		y = y,
		right = right,
		height = height,
		padding = {0, 0, 0, 0},
		parent = parentControl
	}
	
	local line = Chili.Line:New{
		x = 0,
		y = "25%",
		right = 0,
		height = 4,
		borderColor = col_line,
		parent = holder,
	}
	
	local label = Chili.Label:New{
		name   = "warningLabel",
		x      = "5%",
		y      = 0,
		bottom = "8%",
		width  = "90%",
		caption = strings.resbar_no_storage,
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {size = options.warningFontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		parent = holder,
	}
	
	label:BringToFront()
	holder:SetVisibility(false)
	
	local show = false
	local flash = false
	local text = strings.resbar_no_storage
	local blinkValue = 0
	
	local externalFunctions = {}
	
	function externalFunctions.SetText(newText)
		if newText then
			text = newText
		end
		if flash then
			label:SetCaption(text_red .. text)
		else
			label:SetCaption(text)
		end
	end
	
	function externalFunctions.Show(newShow)
		if show == newShow then
			return
		end
		show = newShow
		holder:SetVisibility(show)
		if barHolder then
			barHolder:SetVisibility(not show)
		end
	end
	
	function externalFunctions.SetFlash(newFlash)
		if flash == newFlash then
			return
		end
		flash = newFlash
		externalFunctions.SetText()
		
		if not flash then
			line.borderColor = col_line
			line:Invalidate()
		end
	end
	
	function externalFunctions.UpdateFlash(blinkIndex)
		if not flash then
			return
		end
		local blink_alpha
		if blinkIndex%12 < 6 then
			blink_alpha = (blinkIndex%12)*0.20
		else
			blink_alpha = (11 - blinkIndex%12)*0.20
		end
		
		line.borderColor = Mix(col_line, col_expense, blink_alpha)
		line:Invalidate()
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local externalFunctions = {}

function externalFunctions.SetEconomyPanelVisibility(newVisibility, dispose)
	if dispose then
		local x,y,w,h = DestroyWindow()
		if newVisibility then
			CreateWindow(x,y,w,h)
		end
	else
		window:SetVisibility(newVisibility)
	end
end

function externalFunctions.SetFlashEnabled(newEnabled)
	flashModeEnabled = newEnabled
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	if window then
		window:Dispose()
	end
	WG.ShutdownTranslation(GetInfo().name)
end

function widget:Update(dt)
	UpdateBlink(dt)
	UpdateWindowOpacity()
	UpdateReserveSentTimer(dt)
end

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	WG.EconomyPanel = externalFunctions

	WG.InitializeTranslation (languageChanged, GetInfo().name)
	--widgetHandler:RegisterGlobal("MexEnergyEvent", MexEnergyEvent)
    --widgetHandler:RegisterGlobal("ReserveState", ReserveState)
	--widgetHandler:RegisterGlobal("SendWindProduction", SendWindProduction)
	--widgetHandler:RegisterGlobal("PriorityStats", PriorityStats)

	Spring.SendCommands("resbar 0")
	option_colourBlindUpdate()

	option_recreateWindow()
end

function CreateWindow(oldX, oldY, oldW, oldH)
	local function SetReserveByMouse(self, x, y, mouse, metal)
		local a,c,m,s = spGetModKeyState()
		if not c then
			return
		end
		
		local width = (self.width - self.padding[1] - self.padding[3])
		
		if width > 0 then
			local reserve = x/width
			if mouse ~= 1 then
				UpdateReserveBars(true, true, reserve)
			elseif metal then
				UpdateReserveBars(true, false, reserve)
			else
				UpdateReserveBars(false, true, reserve)
			end
		end
	end
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local mouseDownOnReserve = false
	
	--// Some (only some) Configuration for shared values
	local subWindowWidth = '50%'
	local screenHorizCentre = screenWidth / 2
	local economyPanelWidth = math.min(660,screenWidth-10)

	--// WINDOW
	window = Chili.Window:New{
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = Chili.Screen0,
		dockable = true,
		name="EconomyPanelDefaultTwo",
		padding = {0,-1,0,0},
		-- right = "50%",
		x = oldX or (screenHorizCentre - economyPanelWidth/2),
		y = oldY or 0,
		clientWidth  = oldW or economyPanelWidth,
		clientHeight = oldH or 110,
		minHeight = 100,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		
		OnMouseDown={ function(self) --OnClick don't work here, probably because its children can steal click
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	
	metalWarningPanel = GetWarningPanel(window, "3%", "52%", "53%", "15%", strings.metal_excess_warning)
	energyWarningPanel = GetWarningPanel(window, "53%", "52%", "3%", "15%", strings.energy_stall_warning)
	
	window_main_display = Chili.Panel:New{
		backgroundColor = {0, 0, 0, 0},
		parent = window,
		name = "Main Display",
		padding = {0,0,0,0},
		y      = 0,
		x      = 0,
		right  = 0,
		bottom = "50%",
		dockable = false;
		draggable = false,
		resizable = false,
		
		OnMouseDown={ function(self) --OnClick don't work here, probably because its children can steal click
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	
	--// Panel configuration
	local imageX      = "1%"
	local imageY      = "10%"
	local imageWidth  = "17%"
	local imageHeight = "80%"
	
	local storageX    = "18%"
	local incomeX     = "44%"
	local pullX       = "70%"
	local textY       = "47%"
	local textWidth   = "45%"
	local textHeight  = "26%"
	
	local barX      = "17%"
	local barY      = "10%"
	local barRight  = "4%"
	local barHeight = "38%"
	
	--// METAL
	
	window_metal = Chili.Panel:New{
		classname = fancySkinLeft,
		parent = window_main_display,
		name = "Metal",
		y      = 0,
		x      = 0,
		width  = subWindowWidth,
		bottom = 0,
		backgroundColor = {1,1,1,options.opacity.value},
		dockable = false;
		draggable = false,
		resizable = false,
		
		OnMouseDown={ function(self) --OnClick don't work here, probably because its children can steal click
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}

	image_metal = Chili.Image:New{
		parent = window_metal,
		x      = imageX,
		y      = imageY,
		width  = imageWidth,
		height = imageHeight,
		keepAspect = true,
		file   = 'LuaUI/Images/ibeam.png',
	}
	
	lbl_storage_metal = Chili.Label:New{
		parent = window_metal,
		x      = storageX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		valign = "center",
		align  = "left",
		caption = "0",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
	}
	
	lbl_income_metal = Chili.Label:New{
		parent = window_metal,
		x      = incomeX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = positiveColourStr.."+0.0",
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	lbl_expense_metal = Chili.Label:New{
		parent = window_metal,
		x      = pullX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = negativeColourStr.."-0.0",
		valign = "center",
		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	local metalBarHolder = Chili.Control:New{
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		padding = {0,0,0,0},
		parent = window_metal,
	}
	
	bar_reserve_metal = Chili.Multiprogressbar:New{
		parent = metalBarHolder,
		orientation = "horizontal",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		value  = 0,
		min = 0,
		max = 1,
		noSkin = true,
		font   = {color = {.8,.8,.8,.95}, outlineColor = {0,0,0,0.7}, },
		bars = {
			{
				color1 = col_reserve,
				color2 = col_reserve,
				percent = 0,
				texture = 'LuaUI/Images/whiteStripes.png', -- texture file name
				s = 1, -- tex coords
				t = 1,
				tileSize = 16, --  if set then main axis texture coord = width / tileSize
			},
		}
	}
	
	bar_metal = Chili.Progressbar:New{
		parent = metalBarHolder,
		color  = col_metal,
		orientation = "horizontal",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		value  = 0,
		fontShadow = false,
		fontOffset = -2,
		font = {
			size = 20,
			color = {.8,.8,.8,.95},
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2
		},
		OnMouseDown = {function(self, x, y, mouse)
			mouseDownOnReserve = mouse
			if not widgetHandler:InTweakMode() then
				SetReserveByMouse(self, x, y, mouseDownOnReserve, true)
			end
			return (not widgetHandler:InTweakMode())
		end},	-- this is needed for OnMouseUp to work
		OnMouseUp = {function(self, x, y, mouse)
			if widgetHandler:InTweakMode() or not mouseDownOnReserve then
				return
			end
			SetReserveByMouse(self, x, y, mouseDownOnReserve, true)
			mouseDownOnReserve = false
		end},
		OnMouseMove = {function(self, x, y, mouse)
			if widgetHandler:InTweakMode() or not mouseDownOnReserve then
				return
			end
			SetReserveByMouse(self, x, y, mouseDownOnReserve, true)
		end},
	}
	
	metalNoStorage = GetNoStorageWarning(window_metal, barX, barY, barRight, barHeight, metalBarHolder)
	
	--// ENERGY

	window_energy = Chili.Panel:New{
		classname = fancySkinRight,
		parent = window_main_display,
		name = "Energy",
		y      = 0,
		x      = '50%',
		width  = subWindowWidth,
		bottom = 0,
		backgroundColor = {1,1,1,options.opacity.value},
		dockable = false;
		draggable = false,
		resizable = false,
		
		OnMouseDown={ function(self) --OnClick don't work here, probably because its children can steal click
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	
	image_energy = Chili.Image:New{
		parent = window_energy,
		x      = imageX,
		y      = imageY,
		width  = imageWidth,
		height = imageHeight,
		keepAspect = true,
		file   = 'LuaUI/Images/energy.png',
	}
	
	lbl_storage_energy = Chili.Label:New{
		parent = window_energy,
		x      = storageX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		valign = "center",
		align  = "left",
		caption = "0",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
	}
	
	lbl_income_energy = Chili.Label:New{
		parent = window_energy,
		x      = incomeX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = positiveColourStr.."+0.0",
		valign = "center",
 		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	lbl_expense_energy = Chili.Label:New{
		parent = window_energy,
		x      = pullX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = negativeColourStr.."-0.0",
		valign = "center",
		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
	}
	
	local energyBarHolder = Chili.Control:New{
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		padding = {0,0,0,0},
		parent = window_energy,
	}
	
	bar_reserve_energy = Chili.Multiprogressbar:New{
		parent = energyBarHolder,
		orientation = "horizontal",
		value  = 0,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		min = 0,
		max = 1,
		noSkin = true,
		font   = {color = {.8,.8,.8,.95}, outlineColor = {0,0,0,0.7}, },
		bars = {
			{
				color1 = col_reserve,
				color2 = col_reserve,
				percent = 0,
				texture = 'LuaUI/Images/whiteStripes.png', -- texture file name
				s = 1, -- tex coords
				t = 1,
				tileSize = 16, --  if set then main axis texture coord = width / tileSize
			},
		}
	}
	
	bar_overlay_energy = Chili.Progressbar:New{
		parent = energyBarHolder,
		orientation = "horizontal",
		value  = 100,
		color  = {0,0,0,0},
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		noSkin = true,
		fontShadow = false,
		fontOffset = -2,
		font   = {
			size = 20,
			color = {.8,.8,.8,.95},
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2
		},
	}
    
	bar_energy = Chili.Progressbar:New{
		parent = energyBarHolder,
		color  = col_energy,
		value  = 0,
		orientation = "horizontal",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		fontShadow = false,
		OnMouseDown = {function(self, x, y, mouse)
			mouseDownOnReserve = mouse
			if not widgetHandler:InTweakMode() then
				SetReserveByMouse(self, x, y, mouseDownOnReserve, false)
			end
			return (not widgetHandler:InTweakMode())
		end},	-- this is needed for OnMouseUp to work
		OnMouseUp = {function(self, x, y, mouse)
			if widgetHandler:InTweakMode() or not mouseDownOnReserve then
				return
			end
			SetReserveByMouse(self, x, y, mouseDownOnReserve, false)
			mouseDownOnReserve = false
		end},
		OnMouseMove = {function(self, x, y, mouse)
			if widgetHandler:InTweakMode() or not mouseDownOnReserve then
				return
			end
			SetReserveByMouse(self, x, y, mouseDownOnReserve, false)
		end},
	}

	energyNoStorage = GetNoStorageWarning(window_energy, barX, barY, barRight, barHeight, energyBarHolder)
	
	-- Activate tooltips for lables and bars, they do not have them in default chili
	function image_metal:HitTest(x,y) return self end
	function bar_metal:HitTest(x,y) return self	end
	function image_energy:HitTest(x,y) return self end
	function bar_energy:HitTest(x,y) return self end
	function lbl_storage_energy:HitTest(x,y) return self end
	function lbl_storage_metal:HitTest(x,y) return self end
	function lbl_income_energy:HitTest(x,y) return self end
	function lbl_income_metal:HitTest(x,y) return self end
	function lbl_expense_energy:HitTest(x,y) return self end
	function lbl_expense_metal:HitTest(x,y) return self end

	-- set translatable strings
	languageChanged ()

	-- update the flow string font settings
	local opt_flowstr = options.flowAsArrows
	opt_flowstr.OnChange(opt_flowstr)
end

function DestroyWindow()
	if window then
		local x,y,w,h = window.x, window.y, window.width, window.height
		window:Dispose()
		window = nil
		return x,y,w,h
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
