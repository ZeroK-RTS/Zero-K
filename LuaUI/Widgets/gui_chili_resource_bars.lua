--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Resource Bars",
    desc      = "",
    author    = "jK",
    date      = "2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
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

local abs = math.abs
local echo = Spring.Echo
local GetMyTeamID = Spring.GetMyTeamID
local GetTeamResources = Spring.GetTeamResources
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers
local Chili

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local col_metal = {136/255,214/255,251/255,1}
local col_energy = {1,1,0,1}
local col_buildpower = {0.8, 0.8, 0.2, 1}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window
local trkbar_metal
local bar_metal
local bar_metal_reserve_overlay
local trkbar_energy
local bar_energy
local bar_energy_overlay
local bar_energy_reserve_overlay
local bar_buildpower
local lbl_metal
local lbl_energy
local lbl_m_expense
local lbl_e_expense
local lbl_m_income
local lbl_e_income

local blink = 0
local blink_periode = 2
local blink_alpha = 1
local blinkM_status = false
local blinkE_status = false
local time_old = 0
local excessE = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local builderDefs = {}
for id,ud in pairs(UnitDefs) do
	if (ud.builder) then
		builderDefs[#builderDefs+1] = id
	elseif (ud.buildSpeed > 0) then
		builderDefs[#builderDefs+1] = id
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Resource Bars'

local function option_workerUsageUpdate()
	DestroyWindow()
	CreateWindow()
end

options = { 
  eexcessflashalways = {name='Always Flash On Energy Excess', type='bool', value=false},
  onlyShowExpense = {name='Only Show Expense', type='bool', value=false},
  enableReserveBar = {name='Enable Metal Reserve', type='bool', value=false, tooltip = "Enables high priority reserve"},
  workerUsage = {name = "Show Worker Usage", type = "bool", value=false, OnChange = option_workerUsageUpdate},
  energyFlash = {name = "Energy Stall Flash", type = "number", value=0.1, min=0,max=1,step=0.02},
  opacity = {
	name = "Opacity",
	type = "number",
	value = 0, min = 0, max = 1, step = 0.01,
	OnChange = function(self) window.color = {1,1,1,self.value}; window:Invalidate() end,
  }
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(s)

	blink = (blink+s)%blink_periode
	blink_alpha = math.abs(blink_periode/2 - blink)

	if blinkM_status then
		bar_metal:SetColor( 1 - 119/255*blink_alpha,214/255,251/255,0.65 + 0.3*blink_alpha )
	end

	if blinkE_status then
		if excessE then
			bar_energy_overlay:SetColor({0,0,0,0})
            bar_energy:SetColor(1-0.5*blink_alpha,1,0,0.65 + 0.35 *blink_alpha)
		else
			-- flash red if stalling
			bar_energy_overlay:SetColor(1,0,0,blink_alpha)
		end
	end

end

local function Format(input, override)
	
	local leadingString = GreenStr .. "+"
	if input < 0 then
		leadingString = RedStr .. "-"
	end
	leadingString = override or leadingString
	input = math.abs(input)
	
	if input < 0.01 then
		return WhiteStr .. "0"
	elseif input < 5 then
		return leadingString .. ("%.2f"):format(input) .. WhiteStr
	elseif input < 50 then
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

function widget:GameFrame(n)

	if (n%32 ~= 2) or not window then 
        return 
    end

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
	
	eStor = eStor - HIDDEN_STORAGE -- reduce by hidden storage
	if eCurr > eStor then eCurr = eStor end -- cap by storage

	if options.onlyShowExpense.value then
		eExpe = eExpe - WG.energyWasted/WG.allies -- if there is energy wastage, dont show it as used pull energy
	else
		ePull = ePull - WG.energyWasted/WG.allies
	end
	
	--// BLINK WHEN EXCESSING OR ON LOW ENERGY
	local wastingM = mCurr >= mStor * 0.9
	if wastingM then
		blinkM_status = true
	elseif (blinkM_status) then
		blinkM_status = false
		bar_metal:SetColor( col_metal )
	end

	local wastingE = false
	if options.eexcessflashalways.value then
		wastingE = (WG.energyWasted > 0)
	else
		wastingE = (WG.energyWasted/WG.allies > eInco*0.05) and (WG.energyWasted/WG.allies > 15)
	end
	local stallingE = (eCurr <= eStor * options.energyFlash.value) and (eCurr < 1000) and (eCurr >= 0)
	if stallingE or wastingE then
		blinkE_status = true
		bar_energy:SetValue( 100 )
		excessE = wastingE
	elseif (blinkE_status) then
		blinkE_status = false
		bar_energy:SetColor( col_energy )
		bar_energy_overlay:SetColor({0,0,0,0})
	end


	local mPercent = 100 * mCurr / mStor
	local ePercent = 100 * eCurr / eStor

	bar_metal:SetValue( mPercent )
	if wastingM then
		bar_metal_reserve_overlay:SetCaption( (GreenStr.."%i/%i"):format(mCurr, mStor) )
	else
		bar_metal_reserve_overlay:SetCaption( ("%i/%i"):format(mCurr, mStor) )
	end

	bar_energy:SetValue( ePercent )
    
	if stallingE then
		bar_energy_reserve_overlay:SetCaption( (RedStr.."%i/%i"):format(eCurr, eStor) )
	elseif wastingE then
        bar_energy_reserve_overlay:SetCaption( (GreenStr.."%i/%i"):format(eCurr, eStor) )
	else
		bar_energy_reserve_overlay:SetCaption( ("%i/%i"):format(eCurr, eStor) )
	end
	
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
	
	local teamIncome = Format(WG.teamIncome or 0)
	local totalODE = Format(-(WG.energyForOverdrive or 0))
	local totalODM = Format(WG.metalFromOverdrive or 0)
	local totalWaste = Format(-(WG.energyWasted or 0))
	local totalOtherE = Format(-totalExpense + (WG.energyForOverdrive or 0) + totalConstruction + (WG.energyWasted or 0))
	local totalConstruction = Format(-totalConstruction)
	
	bar_metal.tooltip = "Local Metal Economy" ..
	"\nBase Extraction: " .. mexInc ..
	"\nOverdrive: " .. odInc ..
	"\nReclaim and Cons: " .. otherM ..
	"\nSharing: " .. shareM .. 
	"\nConstruction: " .. constuction ..
    "\nReserve: " .. math.ceil(WG.metalStorageReserve or 0) ..
	"\n" .. 
	"\nTeam Metal Economy" ..
	"\nTotal Income: " .. totalMetalIncome ..
	"\nBase Extraction: " .. teamMexInc ..
	"\nOverdrive: " .. teamODInc ..
	"\nReclaim and Cons: " .. teamOtherM ..
	"\nConstruction: " .. totalConstruction ..
	"\nWaste: " .. teamWasteM ..
	"\n" .. 
	"\nTotal Stored: " .. totalMetalStored
	
	bar_energy.tooltip = "Local Energy Economy" ..
	"\nIncome: " .. energyInc ..
	"\nSharing & Overdrive: " .. energyShare .. 
	"\nConstruction: " .. constuction .. 
	"\nOther: " .. otherE ..
    "\nReserve: " .. math.ceil(WG.energyStorageReserve or 0) ..
	"\n" .. 
	"\nTeam Energy Economy" ..
	"\nIncome: " .. teamIncome .. 
	"\nOverdrive: " .. totalODE .. " -> " .. totalODM .. " metal" ..
	"\nConstruction: " .. totalConstruction ..
	"\nOther: " .. totalOtherE ..
	"\nWaste: " .. totalWaste

	local mTotal
	if options.onlyShowExpense.value then
		mTotal = mInco - mExpe + mReci
	else
		mTotal = mInco - mPull + mReci
	end

	if (mTotal >= 2) then
		lbl_metal.font:SetColor(0,1,0,1)
	elseif (mTotal > 0.1) then
		lbl_metal.font:SetColor(1,0.7,0,1)
	else
		lbl_metal.font:SetColor(1,0,0,1)
	end
	local abs_mTotal = abs(mTotal)
	if (abs_mTotal <0.1) then
		lbl_metal:SetCaption( "\1770" )
	elseif (abs_mTotal >=10)and((abs(mTotal%1)<0.1)or(abs_mTotal>99)) then
		lbl_metal:SetCaption( ("%+.0f"):format(mTotal) )
	else
		lbl_metal:SetCaption( ("%+.1f"):format(mTotal) )
	end

	local eTotal
	if options.onlyShowExpense.value then
		eTotal = eInco - eExpe
	else
		eTotal = eInco - ePull
	end
	
	if (eTotal >= 2) then
		lbl_energy.font:SetColor(0,1,0,1)
	elseif (eTotal > 0.1) then
		lbl_energy.font:SetColor(1,0.7,0,1)
	--elseif ((eStore - eCurr) < 50) then --// prevents blinking when overdrive is active
	--	lbl_energy.font:SetColor(0,1,0,1)
	else		
		lbl_energy.font:SetColor(1,0,0,1)
	end
	local abs_eTotal = abs(eTotal)
	if (abs_eTotal<0.1) then
		lbl_energy:SetCaption( "\1770" )
	elseif (abs_eTotal>=10)and((abs(eTotal%1)<0.1)or(abs_eTotal>99)) then
		lbl_energy:SetCaption( ("%+.0f"):format(eTotal) )
	else
		lbl_energy:SetCaption( ("%+.1f"):format(eTotal) )
	end

	if options.onlyShowExpense.value then
		lbl_m_expense:SetCaption( ("%.1f"):format(mExpe) )
		lbl_e_expense:SetCaption( ("%.1f"):format(eExpe) )
	else
		lbl_m_expense:SetCaption( ("%.1f"):format(mPull) )
		lbl_e_expense:SetCaption( ("%.1f"):format(ePull) )
	end
	lbl_m_income:SetCaption( ("%.1f"):format(mInco+mReci) )
	lbl_e_income:SetCaption( ("%.1f"):format(eInco) )


	if options.workerUsage.value then
		local bp_aval = 0
		local bp_use = 0
		local builderIDs = Spring.GetTeamUnitsByDefs(GetMyTeamID(), builderDefs)
		if (builderIDs) then
			for i=1,#builderIDs do
				local unit = builderIDs[i]
				local ud = UnitDefs[Spring.GetUnitDefID(unit)]

				local _, metalUse, _,energyUse = Spring.GetUnitResources(unit)
				bp_use = bp_use + math.max(abs(metalUse), abs(energyUse))
				bp_aval = bp_aval + ud.buildSpeed
			end
		end
		if bp_aval == 0 then
			bar_buildpower:SetValue(0)
			bar_buildpower:SetCaption("no workers")
		else
			local buildpercent = bp_use/bp_aval * 100
			bar_buildpower:SetValue(buildpercent)
			bar_buildpower:SetCaption(("%.1f%%"):format(buildpercent))
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	widgetHandler:RegisterGlobal("MexEnergyEvent", MexEnergyEvent)
    widgetHandler:RegisterGlobal("ReserveState", ReserveState)
	--widgetHandler:RegisterGlobal("SendWindProduction", SendWindProduction)
	--widgetHandler:RegisterGlobal("PriorityStats", PriorityStats)

	time_old = GetTimer()

	Spring.SendCommands("resbar 0")

	CreateWindow()

end

function widget:Shutdown()
	window:Dispose()
	Spring.SendCommands("resbar 1")
end

local function updateReserveBars(metal, energy, value)
	if options.enableReserveBar.value then
		if metal then
			local _, mStor = GetTeamResources(GetMyTeamID(), "metal")
			Spring.SendLuaRulesMsg("mreserve:"..value*mStor) 
			WG.metalStorageReserve = value*mStor
			bar_metal_reserve_overlay:SetValue(value)
		end
		if energy then
			local _, eStor = GetTeamResources(GetMyTeamID(), "energy")
			Spring.SendLuaRulesMsg("ereserve:"..value*(eStor - HIDDEN_STORAGE)) 
			WG.energyStorageReserve = value*eStor
			bar_energy_reserve_overlay:SetValue(value)
		end
	end
end

function CreateWindow()

	local bars = 2
	if options.workerUsage.value then
		bars = 3
	end
	local function p(a)
		return tostring(a).."%"
	end
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	--// WINDOW
	window = Chili.Window:New{
		color = {1,1,1,options.opacity.value},
		parent = Chili.Screen0,
		dockable = true,
		name="ResourceBars",
		padding = {0,0,0,0},
		right = 0,
		y = 0,
		clientWidth  = 430,
		clientHeight = 50,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		
		OnMouseDown={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}

	--// METAL
	trkbar_metal = 	Chili.Trackbar:New{
		parent = window,
		height = p(100/bars),
		right  = 26,
		x      = 110,
		y      = p(100/bars),		 
		value = 0,
		min=0, 
		max=1, 
		step=0.01,
		OnMouseUp = { 
			function (self, x, y, mouse)
				updateReserveBars(true, mouse ~= 3, trkbar_metal.value)
			end
			}, 
		noDrawStep = true,
		noDrawBar = true,
		noDrawThumb = true,
	}
	
	Chili.Image:New{
		parent = window,
		height = p(100/bars),
		width  = 25,
		y      = p(100/bars),
		right  = 0,
		file   = 'LuaUI/Images/ibeam.png',
	}
	
	bar_metal_reserve_overlay = Chili.Progressbar:New{
		parent = window,
		color  = {0.5,0.5,0.5,0.5},
		height = p(100/bars),
		right  = 26,
		min = 0,
		max = 1,
		value  = 0,
		x      = 110,
		y      = p(100/bars),
		noSkin = true,
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	
	bar_metal = Chili.Progressbar:New{
		parent = window,
		color  = col_metal,
		height = p(100/bars),
		right  = 26,
                x      = 110,
                y      = p(100/bars),
		tooltip = "This shows your current metal reserves",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	
	lbl_metal = Chili.Label:New{
		parent = window,
		height = p(100/bars),
		width  = 60,
                x      = 10,
                y      = p(100/bars),
		valign = "center",
		align  = "right",
		caption = "0",
		autosize = false,
		font   = {size = 19, outline = true, outlineWidth = 4, outlineWeight = 3,},
		tooltip = "Your net metal income",
	}
	lbl_m_income = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 70,
                y      = p(100/bars),
		caption = "10.0",
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {0,1,0,1}},
		tooltip = "Your metal Income.\nGained primarilly from metal extractors, overdrive and reclaim",
	}
	lbl_m_expense = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 70,
                y      = p(1.5*100/bars),
		caption = "10.0",
		valign = "center",
		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {1,0,0,1}},
		tooltip = "This is the metal demand of your construction",
	}


	--// ENERGY
	trkbar_energy = Chili.Trackbar:New{
		parent = window,
		height = p(100/bars),
		right  = 36,
		x      = 100,
		y      = 1,	 
		value = 0,
		min=0, 
		max=1, 
		step=0.01,
		OnMouseUp = { 
			function (self, x, y, mouse)
				updateReserveBars(mouse ~= 3, true, trkbar_energy.value)
			end
		}, 
		noDrawStep = true,
		noDrawBar = true,
		noDrawThumb = true,
	}
	
	Chili.Image:New{
		parent = window,
		height = p(100/bars),
		width  = 25,
                right  = 10,
                y      = 1,
		file   = 'LuaUI/Images/energy.png',
	}
    
	bar_energy_overlay = Chili.Progressbar:New{
		parent = window,
		color  = col_energy,
		height = p(100/bars),
		value  = 100,
		color  = {0,0,0,0},
		right  = 36,
		x      = 100,
		y      = 1,
		noSkin = true,
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	
	bar_energy_reserve_overlay = Chili.Progressbar:New{
		parent = window,
		color  = {0.5,0.5,0.5,0.5},
		height = p(100/bars),
		right  = 26,
		 value = 0,
		min = 0,
		max = 1,
		right  = 36,
		x      = 100,
		y      = 1,
		noSkin = true,
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
    
	bar_energy = Chili.Progressbar:New{
		parent = window,
		color  = col_energy,
		height = p(100/bars),
		right  = 36,
                x      = 100,
                y      = 1,
		tooltip = "Shows your current energy reserves.\n Anything above 100% will be burned by 'mex overdrive'\n which increases production of your mines",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
	
	lbl_energy = Chili.Label:New{
		parent = window,
		height = p(100/bars),
		width  = 60,
                x      = 0,
                y      = 1,
		valign = "center",
		align  = "right",
		caption = "0",
		autosize = false,
		font   = {size = 19, outline = true, outlineWidth = 4, outlineWeight = 3,},
		tooltip = "Your net energy income.",
	}
	lbl_e_income = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 60,
                y      = 1,
		caption = "10.0",
		valign  = "center",
		align   = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {0,1,0,1}},
		tooltip = "Your energy income.\nGained from powerplants.",
	}
	lbl_e_expense = Chili.Label:New{
		parent = window,
		height = p(50/bars),
		width  = 40,
                x      = 60,
                y      = p(50/bars),
		caption = "10.0",
		valign = "center",
		align  = "center",
		autosize = false,
		font   = {size = 12, outline = true, color = {1,0,0,1}},
		tooltip = "This is the energy demand of your economy, cloakers, shields and overdrive",
	}
	
	-- Activate tooltips for lables and bars, they do not have them in default chili
	function bar_metal:HitTest(x,y) return self	end
	function bar_energy:HitTest(x,y) return self end
    function trkbar_metal:HitTest(x,y) return bar_metal end
    function trkbar_energy:HitTest(x,y) return bar_energy end
	function lbl_energy:HitTest(x,y) return self end
	function lbl_metal:HitTest(x,y) return self end
	function lbl_e_income:HitTest(x,y) return self end
	function lbl_m_income:HitTest(x,y) return self end
	function lbl_e_expense:HitTest(x,y) return self end
	function lbl_m_expense:HitTest(x,y) return self end

	if not options.workerUsage.value then return end
	-- worker usage
	bar_buildpower = Chili.Progressbar:New{
		parent = window,
		color  = col_buildpower,
		height = "33%",
		right  = 6,
		x      = 120,
		y      = "66%",
		tooltip = "",
		font   = {color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, },
	}
end

function DestroyWindow()
	window:Dispose()
	window = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- 1 second lag as energy update will be included in next resource update, not this one
local lastChange = 0
local lastEnergyForOverdrive = 0
local lastEnergyWasted = 0
local lastMetalFromOverdrive = 0
local lastMyMetalFromOverdrive = 0

-- note works only in communism mode
function MexEnergyEvent(teamID, allies, energyWasted, energyForOverdrive, totalIncome, baseMetal, overdriveMetal, myBase, myOverdrive, EnergyChange, teamIncome)
  if (Spring.GetLocalTeamID() == teamID) then 
  	WG.energyWasted = lastEnergyWasted
    lastEnergyWasted = energyWasted
	WG.energyForOverdrive = lastEnergyForOverdrive
    lastEnergyForOverdrive = energyForOverdrive
	WG.change = lastChange
    lastChange = EnergyChange
	WG.mexIncome = baseMetal
	WG.metalFromOverdrive = lastMetalFromOverdrive
    lastMetalFromOverdrive = overdriveMetal
	WG.myMexIncome = myBase
	WG.myMetalFromOverdrive = lastMyMetalFromOverdrive
	lastMyMetalFromOverdrive = myOverdrive
	WG.teamIncome = teamIncome
	WG.allies = allies
  end
end

local lastMstor = 0
local lastEstor = 0

function ReserveState(teamID, metalStorageReserve, energyStorageReserve)
    if (Spring.GetLocalTeamID() == teamID) then 
        local _, mStor = GetTeamResources(teamID, "metal")
		local _, eStor = GetTeamResources(teamID, "energy")
		
        if ((not WG.metalStorageReserve) or WG.metalStorageReserve ~= metalStorageReserve) or (lastMstor ~= mStor) and mStor > 0 then
            lastMstor = mStor
            trkbar_metal:SetValue(metalStorageReserve/mStor)
            bar_metal_reserve_overlay:SetValue(trkbar_metal.value)
        end
		WG.metalStorageReserve = metalStorageReserve
       
		if ((not WG.energyStorageReserve) or WG.energyStorageReserve ~= energyStorageReserve) or (lastEstor ~= eStor) and (eStor - HIDDEN_STORAGE) > 0 then
            lastEstor = eStor
            trkbar_energy:SetValue(energyStorageReserve/(eStor - HIDDEN_STORAGE))
            bar_energy_reserve_overlay:SetValue(trkbar_energy.value)
        end
         WG.energyStorageReserve = energyStorageReserve
    end
end

--[[
function SendWindProduction(teamID, value)
	WG.windEnergy = value
end


function PriorityStats(teamID, highPriorityBP, lowPriorityBP)
	WG.highPriorityBP = highPriorityBP
	WG.lowPriorityBP = lowPriorityBP
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
