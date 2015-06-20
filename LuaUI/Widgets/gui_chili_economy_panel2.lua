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

WG.energyWasted = 0
WG.energyForOverdrive = 0
WG.allies = 1
--[[
WG.windEnergy = 0 
WG.highPriorityBP = 0
WG.lowPriorityBP = 0
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local reverseCompatibility = (Game.version:find('91.0') == 1) or (Game.version:find('94') and not Game.version:find('94.1.1'))

local abs = math.abs
local echo = Spring.Echo
local GetMyTeamID = Spring.GetMyTeamID
local GetTeamResources = Spring.GetTeamResources
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers
local spGetModKeyState = Spring.GetModKeyState
local Chili

local spGetTeamRulesParam = Spring.GetTeamRulesParam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {.93,.93,0,1}
local col_reserve = {0, 0, 0, 0}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window

local window_main_display
local image_metal
local bar_metal
local bar_reserve_metal
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
local col_overdrive

local blink = 0
local blink_periode = 1.4
local blink_alpha = 1
local blinkM_status = false
local blinkE_status = false
local time_old = 0
local excessE = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Economy Panel'

local function option_recreateWindow()
	DestroyWindow()
	CreateWindow()
end

local function option_colourBlindUpdate()
	positiveColourStr = (options.colourBlind.value and YellowStr) or GreenStr
	negativeColourStr = (options.colourBlind.value and BlueStr) or RedStr
	col_income = (options.colourBlind.value and {.9,.9,.2,1}) or {.1,1,.2,1}
	col_expense = (options.colourBlind.value and {.2,.3,1,1}) or {1,.3,.2,1}
	col_overdrive = (options.colourBlind.value and {1,1,1,1}) or {.5,1,0,1}
end

options_order = {
	'eExcessFlash', 'energyFlash','opacity',
	'enableReserveBar','defaultEnergyReserve','defaultMetalReserve',
	'colourBlind','fontSize'}
 
options = { 
	eExcessFlash = {
		name  = 'Flash On Energy Excess', 
		type  = 'bool', 
		value = false,
		advanced = true,
		desc = "When enabled energy storage will flash if energy is being excessed. This only occurs if too much energy is left unlinked to metal extractors because normally excess is used for overdrive."
	},
	enableReserveBar = {
		name  = 'Enable Reserve', 
		type  = 'bool', 
		value = true, 
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
	opacity = {
		name  = "Opacity",
		type  = "number",
		value = 0.6, min = 0, max = 1, step = 0.01,
		OnChange = function(self) window.color = {1,1,1,self.value}; window:Invalidate() end,
	},
	colourBlind = {
		name  = "Colourblind mode",
		type  = "bool", 
		value = false, 
		OnChange = option_colourBlindUpdate, 
		desc = "Uses Blue and Yellow instead of Red and Green for number display"
	},
	fontSize = {
		name  = "Font Size",
		type  = "number",
		value = 20, min = 8, max = 40, step = 1,
		OnChange = option_recreateWindow
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- 1 second lag as energy update will be included in next resource update, not this one
local lastChange = 0
local lastEnergyForOverdrive = 0
local lastEnergyWasted = 0
local lastMetalFromOverdrive = 0
local lastMyMetalFromOverdrive = 0

-- note works only in communism mode
function UpdateEconomyDataFromRulesParams()
	local teamID = Spring.GetLocalTeamID()
  
  	local allies = spGetTeamRulesParam(teamID, "OD_allies") or 1
	local energyWasted = spGetTeamRulesParam(teamID, "OD_energyWasted") or 0
	local energyForOverdrive = spGetTeamRulesParam(teamID, "OD_energyForOverdrive") or 0
	--local totalMetalIncome = spGetTeamRulesParam(teamID, "OD_totalMetalIncome") or 0
	local baseMetal = spGetTeamRulesParam(teamID, "OD_baseMetal") or 0
	local overdriveMetal = spGetTeamRulesParam(teamID, "OD_overdriveMetal") or 0
	local myBase = spGetTeamRulesParam(teamID, "OD_myBase") or 0
	local myOverdrive = spGetTeamRulesParam(teamID, "OD_myOverdrive") or 0
	local energyChange = spGetTeamRulesParam(teamID, "OD_energyChange") or 0
	local teamEnergyIncome = spGetTeamRulesParam(teamID, "OD_teamEnergyIncome") or 0

	WG.energyWasted = lastEnergyWasted
	lastEnergyWasted = energyWasted
	WG.energyForOverdrive = lastEnergyForOverdrive
	lastEnergyForOverdrive = energyForOverdrive
	WG.change = lastChange
	lastChange = energyChange
	WG.mexIncome = baseMetal
	WG.metalFromOverdrive = lastMetalFromOverdrive
	lastMetalFromOverdrive = overdriveMetal
	WG.myMexIncome = myBase
	WG.myMetalFromOverdrive = lastMyMetalFromOverdrive
	lastMyMetalFromOverdrive = myOverdrive
	WG.teamEnergyIncome = teamEnergyIncome
	WG.allies = allies
end

local function updateReserveBars(metal, energy, value, overrideOption)
	if options.enableReserveBar.value or overrideOption then
		if value < 0 then value = 0 end
		if value > 1 then value = 1 end
		if metal then
			local _, mStor = GetTeamResources(GetMyTeamID(), "metal")
			Spring.SendLuaRulesMsg("mreserve:"..value*mStor) 
			WG.metalStorageReserve = value*mStor
			bar_reserve_metal.bars[1].percent = value
			bar_reserve_metal:Invalidate()
		end
		if energy then
			local _, eStor = GetTeamResources(GetMyTeamID(), "energy")
			Spring.SendLuaRulesMsg("ereserve:"..value*(eStor - HIDDEN_STORAGE)) 
			WG.energyStorageReserve = value*(eStor - HIDDEN_STORAGE)
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

function widget:Update(s)

	blink = (blink+s)%blink_periode
	local sawtooth = math.abs(blink/blink_periode - 0.5)*2
	blink_alpha = sawtooth*0.92
	
	blink_colourBlind = options.colourBlind.value and 1 or 0

	--Colour strings are only used for the flashing captions because engine 91.0 has a bug that keeps the string showing when the colour is changed to {0,0,0,0}
	--Once engine 97+ is adopted officially, the captions should use SetColor (followed by Invalidate if that remains necessary)

	if blinkM_status then
		bar_metal:SetColor(Mix({col_metal[1], col_metal[2], col_metal[3], 0.65}, col_expense, blink_alpha))
	end

	if blinkE_status then
		bar_overlay_energy:SetColor(col_expense[1], col_expense[2], col_expense[3], blink_alpha)
	end
end

local function Format(input, override)
	
	local leadingString = positiveColourStr .. "+"
	if input < 0 then
		leadingString = negativeColourStr .. "-"
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.01 then
		if override then
			return override .. "0.0"
		end
		return WhiteStr .. "0"
	elseif input < 100 then
		return leadingString .. ("%.1f"):format(input) .. WhiteStr
	elseif input < 10^3 then
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

	if (n%TEAM_SLOWUPDATE_RATE ~= 0) or not window then 
        return 
    end
	
	if n > 5 and not initialReserveSet then
		updateReserveBars(true, false, options.defaultMetalReserve.value, true)
		updateReserveBars(false, true, options.defaultEnergyReserve.value, true)
		initialReserveSet = true
	end
	
	UpdateEconomyDataFromRulesParams()

	local myTeamID = GetMyTeamID()
	local myAllyTeamID = Spring.GetMyAllyTeamID()
	local teams = Spring.GetTeamList(myAllyTeamID)
	
	local totalConstruction = 0
	local totalExpense = 0
	local teamMInco = 0
	local teamMSpent = 0
	local teamFreeStorage = 0
	local teamTotalMetalStored = 0
	for i = 1, #teams do
		local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = GetTeamResources(teams[i], "metal")
		totalConstruction = totalConstruction + mExpe
		teamMInco = teamMInco + mInco
		teamMSpent = teamMSpent + mExpe
		teamFreeStorage = teamFreeStorage + mStor - mCurr
		teamTotalMetalStored = teamTotalMetalStored + mCurr
		local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = GetTeamResources(teams[i], "energy")
		totalExpense = totalExpense + eExpe
	end

	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = GetTeamResources(myTeamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = GetTeamResources(myTeamID, "metal")
	
	local extraMetalPull = spGetTeamRulesParam(myTeamID, "extraMetalPull") or 0
	local extraEnergyPull = spGetTeamRulesParam(myTeamID, "extraEnergyPull") or 0
	mPull = mPull + extraMetalPull
	ePull = ePull + extraEnergyPull
	
	eStor = eStor - HIDDEN_STORAGE -- reduce by hidden storage
	if eCurr > eStor then 
		eCurr = eStor -- cap by storage
	end 

	ePull = ePull - WG.energyWasted/WG.allies
	
	--// BLINK WHEN EXCESSING OR ON LOW ENERGY
	local wastingM = mCurr >= mStor * 0.9
	if wastingM then
		blinkM_status = true
	elseif (blinkM_status) then
		blinkM_status = false
		bar_metal:SetColor( col_metal )
	end

	local ODEFlashThreshold = 0.1

	local wastingE = false
	if options.eExcessFlash.value then
		wastingE = (WG.energyWasted > 0)
	end
	local stallingE = (eCurr <= eStor * options.energyFlash.value) and (eCurr < 1000) and (eCurr >= 0)
	if stallingE or wastingE then
		blinkE_status = true
		bar_energy:SetValue( 100 )
		excessE = wastingE
	elseif (blinkE_status) then
		blinkE_status = false
		bar_energy:SetColor( col_energy )
		bar_overlay_energy:SetColor({0,0,0,0})
	end


	local mPercent = 100 * mCurr / mStor
	local ePercent = 100 * eCurr / eStor

	mPercent = math.min(math.max(mPercent, 0), 100)
	ePercent = math.min(math.max(ePercent, 0), 100)

	bar_metal:SetValue( mPercent )
	bar_energy:SetValue( ePercent )
	
	local mexInc = Format(WG.myMexIncome or 0)
	local odInc = Format((WG.myMetalFromOverdrive or 0))
	local otherM = Format(mInco - (WG.myMetalFromOverdrive or 0) - (WG.myMexIncome or 0) - mReci)
	local shareM = Format(mReci - mSent)
	local constuction = Format(-mExpe)
	
	local teamMexInc = Format(WG.mexIncome or 0)
	local teamODInc = Format(WG.metalFromOverdrive or 0)
	local teamOtherM = Format(teamMInco - (WG.metalFromOverdrive or 0) - (WG.mexIncome or 0))
	local teamWasteM = Format(math.min(teamFreeStorage - teamMInco - teamMSpent,0))
	local totalMetalIncome = Format(teamMInco)
	local totalMetalStored = Format((teamTotalMetalStored or 0), "")
	
	local energyInc = Format(eInco - math.max(0, (WG.change or 0)))
	local energyShare =  Format(WG.change or 0)
	local otherE = Format(-eExpe - math.min(0, (WG.change or 0)) + mExpe)
	
	local teamEnergyIncome = Format(WG.teamEnergyIncome or 0)
	local totalODE = Format(-(WG.energyForOverdrive or 0))
	local totalODM = Format(WG.metalFromOverdrive or 0)
	local totalWaste = Format(-(WG.energyWasted or 0))
	local totalOtherE = Format(-totalExpense + (WG.energyForOverdrive or 0) + totalConstruction + (WG.energyWasted or 0))
	local totalConstruction = Format(-totalConstruction)
	
	image_metal.tooltip = "Local Metal Economy" ..
	"\nBase Extraction: " .. mexInc ..
	"\nOverdrive: " .. odInc ..
	"\nReclaim and Cons: " .. otherM ..
	"\nSharing: " .. shareM .. 
	"\nConstruction: " .. constuction ..
    "\nReserve: " .. math.ceil(WG.metalStorageReserve or 0) ..
    "\nStored: " .. ("%i / %i"):format(mCurr, mStor)  ..
	"\n" .. 
	"\nTeam Metal Economy" ..
	"\nTotal Income: " .. totalMetalIncome ..
	"\nBase Extraction: " .. teamMexInc ..
	"\nOverdrive: " .. teamODInc ..
	"\nReclaim and Cons: " .. teamOtherM ..
	"\nConstruction: " .. totalConstruction ..
	"\nWaste: " .. teamWasteM
	
	image_energy.tooltip = "Local Energy Economy" ..
	"\nIncome: " .. energyInc ..
	"\nSharing & Overdrive: " .. energyShare .. 
	"\nConstruction: " .. constuction .. 
	"\nOther: " .. otherE ..
    "\nReserve: " .. math.ceil(WG.energyStorageReserve or 0) ..
    "\nStored: " .. ("%i / %i"):format(eCurr, eStor)  ..
	"\n" .. 
	"\nTeam Energy Economy" ..
	"\nIncome: " .. teamEnergyIncome .. 
	"\nOverdrive: " .. totalODE .. " -> " .. totalODM .. " metal" ..
	"\nConstruction: " .. totalConstruction ..
	"\nOther: " .. totalOtherE ..
	"\nWaste: " .. totalWaste

	--// Storage, income and pull numbers
	local realEnergyPull = ePull
	
	lbl_expense_metal:SetCaption( negativeColourStr..Format(mPull, negativeColourStr.." -") )
	lbl_expense_energy:SetCaption( negativeColourStr..Format(realEnergyPull, negativeColourStr.." -") )
	lbl_income_metal:SetCaption( Format(mInco+mReci, positiveColourStr.."+") )
	lbl_income_energy:SetCaption( Format(eInco, positiveColourStr.."+") )
	lbl_storage_energy:SetCaption(("%.0f"):format(eCurr))
	lbl_storage_metal:SetCaption(("%.0f"):format(mCurr))

	--// Net income indicator on resource bars.
	local netMetal = mInco - mPull + mReci
	if netMetal < -27.5 then
		bar_metal:SetCaption(negativeColourStr.."<<<<<<")
	elseif netMetal < -22.5 then
		bar_metal:SetCaption(negativeColourStr.."<<<<<")
	elseif netMetal < -17.5 then
		bar_metal:SetCaption(negativeColourStr.."<<<<")
	elseif netMetal < -12.5 then
		bar_metal:SetCaption(negativeColourStr.."<<<")
	elseif netMetal < -7.5 then
		bar_metal:SetCaption(negativeColourStr.."<<")
	elseif netMetal < -2.5 then
		bar_metal:SetCaption(negativeColourStr.."<")
	elseif netMetal < 2.5 then
		bar_metal:SetCaption("")
	elseif netMetal < 7.5 then
		bar_metal:SetCaption(positiveColourStr..">")
	elseif netMetal < 12.5 then
		bar_metal:SetCaption(positiveColourStr..">>")
	elseif netMetal < 17.5 then
		bar_metal:SetCaption(positiveColourStr..">>>")
	elseif netMetal < 22.5 then
		bar_metal:SetCaption(positiveColourStr..">>>>")
	elseif netMetal < 27.5 then
		bar_metal:SetCaption(positiveColourStr..">>>>>")
	else
		bar_metal:SetCaption(positiveColourStr..">>>>>>")
	end
	
	local netEnergy = eInco - realEnergyPull
	if netEnergy < -27.5 then
		bar_energy:SetCaption(negativeColourStr.."<<<<<<")
	elseif netEnergy < -22.5 then
		bar_energy:SetCaption(negativeColourStr.."<<<<<")
	elseif netEnergy < -17.5 then
		bar_energy:SetCaption(negativeColourStr.."<<<<")
	elseif netEnergy < -12.5 then
		bar_energy:SetCaption(negativeColourStr.."<<<")
	elseif netEnergy < -7.5 then
		bar_energy:SetCaption(negativeColourStr.."<<")
	elseif netEnergy < -2.5 then
		bar_energy:SetCaption(negativeColourStr.."<")
	elseif netEnergy < 2.5 then
		bar_energy:SetCaption("")
	elseif netEnergy < 7.5 then
		bar_energy:SetCaption(positiveColourStr..">")
	elseif netEnergy < 12.5 then
		bar_energy:SetCaption(positiveColourStr..">>")
	elseif netEnergy < 17.5 then
		bar_energy:SetCaption(positiveColourStr..">>>")
	elseif netEnergy < 22.5 then
		bar_energy:SetCaption(positiveColourStr..">>>>")
	elseif netEnergy < 27.5 then
		bar_energy:SetCaption(positiveColourStr..">>>>>")
	else
		bar_energy:SetCaption(positiveColourStr..">>>>>>")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	window:Dispose()
	Spring.SendCommands("resbar 1")
end

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	--widgetHandler:RegisterGlobal("MexEnergyEvent", MexEnergyEvent)
    --widgetHandler:RegisterGlobal("ReserveState", ReserveState)
	--widgetHandler:RegisterGlobal("SendWindProduction", SendWindProduction)
	--widgetHandler:RegisterGlobal("PriorityStats", PriorityStats)

	time_old = GetTimer()

	Spring.SendCommands("resbar 0")
	option_colourBlindUpdate()

	CreateWindow()
end

function CreateWindow()
	local function SetReserveByMouse(self, x, y, mouse, metal)
		local a,c,m,s = spGetModKeyState()
		if not c then
			return
		end
		
		local reserve = (x) / (self.width - self.padding[1] - self.padding[3])
		if mouse ~= 1 then
			updateReserveBars(true, true, reserve)
		elseif metal then
			updateReserveBars(true, false, reserve)
		else
			updateReserveBars(false, true, reserve)
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
		-- color = {1,1,1,options.opacity.value},
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = Chili.Screen0,
		dockable = true,
		name="EconomyPanelDefault",
		padding = {0,0,0,0},
		-- right = "50%",
		x = screenHorizCentre - economyPanelWidth/2,
		y = 0,
		clientWidth  = economyPanelWidth,
		clientHeight = 50,
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
	
	window_main_display = Chili.Panel:New{
		backgroundColor = {0, 0, 0, 0},
		parent = window,
		name = "Main Display",
		padding = {0,0,0,0},
		y      = 0,
		x      = 0,
		right  = 0,
		bottom = 0,
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
	local imageWidth  = "80%"
	local imageHeight = "17%"
	
	local storageX    = "18%"
	local incomeX     = "44%"
	local pullX       = "70%"
	local textY       = "41%"
	local textWidth   = "45%"
	local textHeight  = "26%"
	
	local barX      = "17%"
	local barY      = "9%"
	local barRight  = "4%"
	local barHeight = "38%"
	
	--// METAL
	
	local window_metal = Chili.Panel:New{
		parent = window_main_display,
		name = "Metal",
		y      = 0,
		x      = 0,
		width  = subWindowWidth,
		bottom = 0,
		padding = {0,0,0,0},
		color = {1,1,1,options.opacity.value},
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
		height = imageWidth,
		width  = imageHeight,
		keepAspect = true,
		file   = 'LuaUI/Images/ibeam.png',
	}
	
	lbl_storage_metal = Chili.Label:New{
		parent = window_metal,
		x      = storageX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		valign = "bottom",
		align  = "left",
		caption = "0",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
		tooltip = "Your metal storage.",
	}
	
	lbl_income_metal = Chili.Label:New{
		parent = window_metal,
		x      = incomeX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = positiveColourStr.."+0.0",
		valign = "bottom",
 		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		tooltip = "Your metal Income.\nGained from metal extractors, overdrive and reclaim",
	}
	
	lbl_expense_metal = Chili.Label:New{
		parent = window_metal,
		x      = pullX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = negativeColourStr.."-0.0",
		valign = "bottom",
		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		tooltip = "Your metal demand. Construction and morph demand metal.",
	}
	
	bar_reserve_metal = Chili.Multiprogressbar:New{
		parent = window_metal,
		orientation = "horizontal",
		value  = 0,
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
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
		parent = window_metal,
		color  = col_metal,
		orientation = "horizontal",
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		value  = 0,
		fontShadow = false,
		tooltip = "Represents your storage capacity. Filled portion is used storage.\nFlashes if maximun storage is reached and you start wasting metal.",
		font   = {
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
	
	--// ENERGY

	local window_energy = Chili.Panel:New{
		parent = window_main_display,
		name = "Energy",
		y      = 0,
		x      = '50%',
		width  = subWindowWidth,
		bottom = 0,
		color = {1,1,1,options.opacity.value},
		padding = {0,0,0,0},
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
		height = imageWidth,
		width  = imageHeight,
		keepAspect = true,
		file   = 'LuaUI/Images/energy.png',
	}	
	
	lbl_storage_energy = Chili.Label:New{
		parent = window_energy,
		x      = storageX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		valign = "bottom",
		align  = "left",
		caption = "0",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
		tooltip = "Your energy storage.",
	}
	
	lbl_income_energy = Chili.Label:New{
		parent = window_energy,
		x      = incomeX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = positiveColourStr.."+0.0",
		valign = "bottom",
 		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		tooltip = "Your energy income.\nGained from powerplants.",
	}
	
	lbl_expense_energy = Chili.Label:New{
		parent = window_energy,
		x      = pullX,
		y      = textY,
		height = textWidth,
		width  = textHeight,
		caption = negativeColourStr.."-0.0",
		valign = "bottom",
		align  = "left",
		autosize = false,
		font   = {size = options.fontSize.value, outline = true, outlineWidth = 2, outlineWeight = 2},
		tooltip = "This is this total energy demand of your economy and abilities which require energy upkeep",
	}
	
	bar_reserve_energy = Chili.Multiprogressbar:New{
		parent = window_energy,
		orientation = "horizontal",
		value  = 0,
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
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
		parent = window_energy,
		orientation = "horizontal",
		value  = 100,
		color  = {0,0,0,0},
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		noSkin = true,
		font   = {color = {.8,.8,.8,.95}, outlineColor = {0,0,0,0.7}, },
	}
    
	bar_energy = Chili.Progressbar:New{
		parent = window_energy,
		color  = col_energy,
		value  = 0,
		orientation = "horizontal",
		x      = barX,
		y      = barY,
		right  = barRight,
		height = barHeight,
		fontShadow = false,
		tooltip = "Represents your storage capacity. Filled portion is used storage.\nFlashes if maximun storage is reached and you start wasting energy.",
		font   = {
			size = 20, 
			color = {.8,.8,.8,.95}, 
			outline = true,
			outlineWidth = 2, 
			outlineWeight = 2
		},
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
end

function DestroyWindow()
	window:Dispose()
	window = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[
local lastMstor = 0
local lastEstor = 0

function ReserveState(teamID, metalStorageReserve, energyStorageReserve)
    if (Spring.GetLocalTeamID() == teamID) then 
        local _, mStor = GetTeamResources(teamID, "metal")
        local _, eStor = GetTeamResources(teamID, "energy")

        if ((not WG.metalStorageReserve) or WG.metalStorageReserve ~= metalStorageReserve) or (lastMstor ~= mStor) and mStor > 0 then
            lastMstor = mStor
            bar_reserve_metal:SetValue(metalStorageReserve/mStor)
        end
        WG.metalStorageReserve = metalStorageReserve
       
        if ((not WG.energyStorageReserve) or WG.energyStorageReserve ~= energyStorageReserve) or (lastEstor ~= eStor) and (eStor - HIDDEN_STORAGE) > 0 then
            lastEstor = eStor
            bar_reserve_energy:SetValue(energyStorageReserve/(eStor - HIDDEN_STORAGE))
        end
        WG.energyStorageReserve = energyStorageReserve
    end
end
--]]
--[[
function SendWindProduction(teamID, value)
	WG.windEnergy = value
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
